import 'package:isar/isar.dart';

part 'profile.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  String? name;
  String? email;
  String? photoUrl;
  String? uid;
  List<String>? tags;

}
