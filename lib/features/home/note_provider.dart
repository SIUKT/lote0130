import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0130/core/providers/providers.dart';
import 'package:lote0130/features/home/models/note.dart';
import 'package:lote0130/features/home/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(
    ref.watch(isarProvider),
    ref.watch(supabaseClientProvider),
  );
});

final noteProvider =
    StateNotifierProvider<NoteStateNotifier, List<Note>>((ref) {
  return NoteStateNotifier(
    ref.watch(noteRepositoryProvider),
  );
});

class NoteStateNotifier extends StateNotifier<List<Note>> {
  NoteStateNotifier(this._noteRepository) : super([]);

  final NoteRepository _noteRepository;

  Future<void> loadNotes(String? userId) async {
    state = await _noteRepository.loadNotes(userId);
  }

  Future<void> addNote(String? userId, String? context, String text,
      String languageCode, List<String> tags) async {
    final variant = Variant()
      ..text = text
      ..languageCode = languageCode;
    final sentence = Sentence()
      ..variants = [variant]
      ..currentVariantIndex = 0;
    final note = Note()
      ..context = context
      ..sentences = [sentence]
      ..tags = tags
      ..currentSentenceIndex = 0
      ..isSynced = false;

    // 先保存到本地
    await _noteRepository.saveNote(note..userId = userId);
    state = [note, ...state];

    // 如果有用户ID，尝试后台上传
    if (userId != null) {
      try {
        await _noteRepository.saveAndUploadNote(userId, note);
        // 刷新状态
        state = state.map((n) => n.id == note.id ? note : n).toList();
      } catch (e) {
        print('上传失败：$e');
      }
    }
  }

  Future<void> deleteNote(Note note) async {
    state = state.where((n) => n.id != note.id).toList();
    await _noteRepository.deleteNote(note);
  }

  Future<void> getCloudNotes(String userId) async {
    await _noteRepository.getCloudNotes(userId);
  }

  Future<void> syncLocalNotesToCloud(String userId) async {
    await _noteRepository.syncLocalNotesToCloud(userId);
  }
}
