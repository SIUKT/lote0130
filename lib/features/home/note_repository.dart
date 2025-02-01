import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:lote0130/features/home/models/note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  NoteRepository(this._isar, this._supabase);

  Future<List<Note>> loadNotes(String? userId) async {
    if (userId == null) {
      print('加载所有note');
      final notes = await _isar.notes
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .userIdIsNull()
          .sortByCreatedAtDesc()
          .findAll();
      print(notes);
      return notes;
    }
    return _isar.notes
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> getCloudNotes(String userId) async {
    final notes = await _supabase.from('notes').select().eq('user_id', userId);
    for (final note in notes) {
      await _saveNote(Note.fromJson(note)..isSynced = true);
    }
  }

  Future<void> syncLocalNotesToCloud(String userId) async {
    final notes = await loadNotes(null);
    for (final note in notes) {
      if (note.isSynced != true) {
        await saveAndUploadNote(userId, note);
      }
    }
  }

  Future<void> syncNotes(String userId, List<Note> notes) async {
    for (final note in notes) {
      if (note.isSynced != true) {
        await saveAndUploadNote(userId, note);
      }
    }
  }

  // 先存储到本地然后上传，上传成功更新本地的isSynced字段
  Future<void> saveAndUploadNote(String? userId, Note note) async {
    await _saveNote(note..userId = userId);
    if (userId == null) return;
    // 检测网络连接
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.isEmpty ||
        connectivityResult[0] != ConnectivityResult.wifi) {
      print('无网络连接');
      throw Exception('无网络连接');
    }

    print('正在保存笔记');

    await _uploadNote(note);
    for (int i = 0; i < note.sentences!.length; i++) {
      await _uploadSentence(note, i, note.sentences![i]);
      for (int j = 0; j < note.sentences![i].variants!.length; j++) {
        await _uploadVariant(note, i, j, note.sentences![i].variants![j]);
        for (int k = 0; k < note.sentences![i].variants![j].qnas!.length; k++) {
          await _uploadQnA(
              note, i, j, k, note.sentences![i].variants![j].qnas![k]);
        }
      }
    }
  }

  Future<void> _saveNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(note);
    });
  }

  Future<void> saveNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(note);
    });
  }

  Future<void> _updateNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(note..isSynced = false);
    });
  }

  Future<void> _updateSentence(
      Note note, int sentenceIndex, Sentence sentence) async {
    final data = await _supabase
        .from('sentences')
        .update(
          sentence.toJson(),
        )
        .select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传sentence失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note..sentences![sentenceIndex].isSynced = true,
      );
    });
  }

  Future<void> _updateVariant(
      Note note, int sentenceIndex, int variantIndex, Variant variant) async {
    final data = await _supabase
        .from('variants')
        .update(
          variant.toJson(),
        )
        .select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传variant失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note..sentences![sentenceIndex].variants![variantIndex] = variant,
      );
    });
  }

  Future<void> _updateQnA(Note note, int sentenceIndex, int variantIndex,
      int qnaIndex, QnA qna) async {
    final data = await _supabase
        .from('qnas')
        .update(
          qna.toJson(),
        )
        .select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传qna失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note
          ..sentences![sentenceIndex].variants![variantIndex].qnas![qnaIndex] =
              qna,
      );
    });
  }

  Future<void> deleteNote(Note note) async {
    if (note.cloudId == null) {
      await _isar.writeTxn(() async {
        await _isar.notes.delete(note.id);
      });
    } else {
      await _isar.writeTxn(() async {
        await _isar.notes.put(note..isDeleted = true);
      });
      final data = await _supabase
          .from('notes')
          .delete()
          .match({'id': note.cloudId!}).select();
      if (data[0]['id'] != null) {
        await _isar.writeTxn(() async {
          await _isar.notes.delete(note.id);
        });
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.delete(note.id);
    });
  }

  Future<void> _deleteSentence(
      Note note, int sentenceIndex, Sentence sentence) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note..sentences!.removeAt(sentenceIndex),
      );
    });
  }

  Future<void> _deleteVariant(
      Note note, int sentenceIndex, int variantIndex, Variant variant) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note..sentences![sentenceIndex].variants!.removeAt(variantIndex),
      );
    });
  }

  Future<void> _deleteQnA(Note note, int sentenceIndex, int variantIndex,
      int qnaIndex, QnA qna) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note
          ..sentences![sentenceIndex]
              .variants![variantIndex]
              .qnas!
              .removeAt(qnaIndex),
      );
    });
  }

  Future<void> _removeNote(int noteId) async {
    final data =
        await _supabase.from('notes').delete().match({'id': noteId}).select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('删除note失败');
      throw Exception('删除失败');
    }
  }

  Future<void> _uploadNote(Note note) async {
    // 准备上传数据，移除 id 字段
    final json = note.toJson();
    json.remove('id'); // 移除 id 字段，让数据库自动生成

    final data = await _supabase.from('notes').insert(json).select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传note失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(note
        ..isSynced = true
        ..cloudId = cloudId);
    });
  }

  Future<void> _uploadSentence(
      Note note, int sentenceIndex, Sentence sentence) async {
    // 准备上传数据
    final json = sentence.toJson();
    json.remove('id');
    json['note_id'] = note.cloudId; // 添加外键关联

    final data = await _supabase.from('sentences').insert(json).select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传sentence失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note
          ..sentences![sentenceIndex].cloudId = cloudId
          ..sentences![sentenceIndex].isSynced = true,
      );
    });
  }

  Future<void> _uploadVariant(
      Note note, int sentenceIndex, int variantIndex, Variant variant) async {
    // 准备上传数据
    final json = variant.toJson();
    json.remove('id');
    json['sentence_id'] = note.sentences![sentenceIndex].cloudId; // 添加外键关联

    final data = await _supabase.from('variants').insert(json).select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传variant失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note
          ..sentences![sentenceIndex].variants![variantIndex].cloudId = cloudId
          ..sentences![sentenceIndex].variants![variantIndex].isSynced = true,
      );
    });
  }

  Future<void> _uploadQnA(Note note, int sentenceIndex, int variantIndex,
      int qnaIndex, QnA qna) async {
    // 准备上传数据
    final json = qna.toJson();
    json.remove('id');
    json['variant_id'] = note
        .sentences![sentenceIndex].variants![variantIndex].cloudId; // 添加外键关联

    final data = await _supabase.from('qnas').insert(json).select();
    final cloudId = data[0]['id'];

    if (cloudId == null) {
      print('上传qna失败');
      throw Exception('上传失败');
    }

    await _isar.writeTxn(() async {
      await _isar.notes.put(
        note
          ..sentences![sentenceIndex]
              .variants![variantIndex]
              .qnas![qnaIndex]
              .cloudId = cloudId
          ..sentences![sentenceIndex]
              .variants![variantIndex]
              .qnas![qnaIndex]
              .isSynced = true,
      );
    });
  }
}
