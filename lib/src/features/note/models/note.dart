import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  String? cloudId;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<NoteContent>? contents;
}

@embedded
class NoteContent{}

@embedded
class NoteVariant{}