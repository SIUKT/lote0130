-- 创建 notes 表
create table notes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  context text,
  tags text[] default '{}'::text[] not null,
  current_sentence_index int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 创建 sentences 表
create table sentences (
  id uuid default gen_random_uuid() primary key,
  note_id uuid references notes on delete cascade not null,
  question text,
  current_variant_index int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 创建 variants 表
create table variants (
  id uuid default gen_random_uuid() primary key,
  sentence_id uuid references sentences on delete cascade not null,
  language_code text not null,
  text text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 创建 qnas 表
create table qnas (
  id uuid default gen_random_uuid() primary key,
  variant_id uuid references variants on delete cascade not null,
  question text,
  answer text,
  answer_translation text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 创建索引
create index notes_user_id_idx on notes(user_id);
create index sentences_note_id_idx on sentences(note_id);
create index variants_sentence_id_idx on variants(sentence_id);
create index qnas_variant_id_idx on qnas(variant_id);

-- 设置 RLS
alter table notes enable row level security;
alter table sentences enable row level security;
alter table variants enable row level security;
alter table qnas enable row level security;

-- notes 表的 RLS 策略
create policy "用户可以查看自己的笔记"
  on notes for select
  using (auth.uid() = user_id);

create policy "用户可以创建自己的笔记"
  on notes for insert
  with check (auth.uid() = user_id);

create policy "用户可以更新自己的笔记"
  on notes for update
  using (auth.uid() = user_id);

create policy "用户可以删除自己的笔记"
  on notes for delete
  using (auth.uid() = user_id);

-- sentences 表的 RLS 策略
create policy "用户可以查看自己笔记的句子"
  on sentences for select
  using (
    exists (
      select 1 from notes
      where notes.id = sentences.note_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以创建自己笔记的句子"
  on sentences for insert
  with check (
    exists (
      select 1 from notes
      where notes.id = sentences.note_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以更新自己笔记的句子"
  on sentences for update
  using (
    exists (
      select 1 from notes
      where notes.id = sentences.note_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以删除自己笔记的句子"
  on sentences for delete
  using (
    exists (
      select 1 from notes
      where notes.id = sentences.note_id
      and notes.user_id = auth.uid()
    )
  );

-- variants 表的 RLS 策略
create policy "用户可以查看自己笔记的变体"
  on variants for select
  using (
    exists (
      select 1 from sentences
      join notes on notes.id = sentences.note_id
      where sentences.id = variants.sentence_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以创建自己笔记的变体"
  on variants for insert
  with check (
    exists (
      select 1 from sentences
      join notes on notes.id = sentences.note_id
      where sentences.id = variants.sentence_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以更新自己笔记的变体"
  on variants for update
  using (
    exists (
      select 1 from sentences
      join notes on notes.id = sentences.note_id
      where sentences.id = variants.sentence_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以删除自己笔记的变体"
  on variants for delete
  using (
    exists (
      select 1 from sentences
      join notes on notes.id = sentences.note_id
      where sentences.id = variants.sentence_id
      and notes.user_id = auth.uid()
    )
  );

-- qnas 表的 RLS 策略
create policy "用户可以查看自己笔记的问答"
  on qnas for select
  using (
    exists (
      select 1 from variants
      join sentences on sentences.id = variants.sentence_id
      join notes on notes.id = sentences.note_id
      where variants.id = qnas.variant_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以创建自己笔记的问答"
  on qnas for insert
  with check (
    exists (
      select 1 from variants
      join sentences on sentences.id = variants.sentence_id
      join notes on notes.id = sentences.note_id
      where variants.id = qnas.variant_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以更新自己笔记的问答"
  on qnas for update
  using (
    exists (
      select 1 from variants
      join sentences on sentences.id = variants.sentence_id
      join notes on notes.id = sentences.note_id
      where variants.id = qnas.variant_id
      and notes.user_id = auth.uid()
    )
  );

create policy "用户可以删除自己笔记的问答"
  on qnas for delete
  using (
    exists (
      select 1 from variants
      join sentences on sentences.id = variants.sentence_id
      join notes on notes.id = sentences.note_id
      where variants.id = qnas.variant_id
      and notes.user_id = auth.uid()
    )
  );

-- 创建获取完整笔记的函数
create or replace function get_complete_note(note_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  -- 检查权限
  if not exists (
    select 1 from notes
    where id = note_id
    and user_id = auth.uid()
  ) then
    raise exception '没有权限访问此笔记';
  end if;

  -- 获取笔记基本信息
  select jsonb_build_object(
    'id', n.id,
    'userId', n.user_id,
    'context', n.context,
    'tags', n.tags,
    'currentSentenceIndex', n.current_sentence_index,
    'createdAt', n.created_at,
    'updatedAt', n.updated_at,
    'sentences', (
      -- 获取句子信息
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'question', s.question,
          'currentVariantIndex', s.current_variant_index,
          'createdAt', s.created_at,
          'updatedAt', s.updated_at,
          'variants', (
            -- 获取变体信息
            select jsonb_agg(
              jsonb_build_object(
                'id', v.id,
                'languageCode', v.language_code,
                'text', v.text,
                'createdAt', v.created_at,
                'updatedAt', v.updated_at,
                'qnas', (
                  -- 获取问答信息
                  select jsonb_agg(
                    jsonb_build_object(
                      'id', q.id,
                      'question', q.question,
                      'answer', q.answer,
                      'answerTranslation', q.answer_translation,
                      'createdAt', q.created_at,
                      'updatedAt', q.updated_at
                    )
                  )
                  from qnas q
                  where q.variant_id = v.id
                )
              )
            )
            from variants v
            where v.sentence_id = s.id
          )
        )
      )
      from sentences s
      where s.note_id = n.id
    )
  ) into result
  from notes n
  where n.id = note_id;

  return result;
end;
$$;
