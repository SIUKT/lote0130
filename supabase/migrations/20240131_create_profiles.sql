-- Create profiles table
create table profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text not null,
  username text,
  avatar_url text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint username_length check (char_length(username) >= 3)
);

-- Set up Row Level Security (RLS)
alter table profiles enable row level security;

-- Create policies
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update their own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create indexes
create index profiles_username_idx on profiles (username);
create index profiles_email_idx on profiles (email);

-- Set up realtime
alter publication supabase_realtime add table profiles;

-- This SQL snippet alters the existing profiles table to add two new fields: tags and language_codes.

alter table profiles 
  add column tags text[] default '{}'::text[] not null,
  add column language_codes text[] default '{}'::text[] not null;