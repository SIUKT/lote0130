import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  String? cloudId;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<Sentence>? sentences;
  String? context;
  List<String>? tags;

  int? currentSentenceIndex;

  Note() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note()
      ..cloudId = json['cloudId']
      ..createdAt = DateTime.parse(json['createdAt']).toLocal()
      ..updatedAt = DateTime.parse(json['updatedAt']).toLocal()
      ..sentences = (json['sentences'] as List).map((e) => Sentence.fromJson(e)).toList()
      ..context = json['context']
      ..currentSentenceIndex = json['currentSentenceIndex']
      ..tags = (json['tags'] as List).map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'cloudId': cloudId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sentences': sentences?.map((e) => e.toJson()).toList(),
      'context': context,
      'currentSentenceIndex': currentSentenceIndex,
      'tags': tags,
    };
  }
}

@embedded
class Sentence {
  List<Variant>? variants;
  String? question;

  int? currentVariantIndex;

  Sentence();

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence()
      ..variants = (json['variants'] as List).map((e) => Variant.fromJson(e)).toList()
      ..question = json['question']
      ..currentVariantIndex = json['currentVariantIndex'];
  }

  Map<String, dynamic> toJson() {
    return {
      'variants': variants?.map((e) => e.toJson()).toList(),
      'question': question,
      'currentVariantIndex': currentVariantIndex,
    };
  }
}

@embedded
class Variant {
  String? languageCode;
  String? text;
  List<QnA>? qnas;

  Variant();

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant()
      ..languageCode = json['languageCode']
      ..text = json['text']
      ..qnas = (json['qnas'] as List).map((e) => QnA.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'text': text,
      'qnas': qnas?.map((e) => e.toJson()).toList(),
    };
  }
}

@embedded
class QnA {
  String? question;
  String? answer;
  String? answerTranslation;

  DateTime? createdAt;
  DateTime? updatedAt;

  QnA() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  factory QnA.fromJson(Map<String, dynamic> json) {
    return QnA()
      ..question = json['question']
      ..answer = json['answer']
      ..answerTranslation = json['answerTranslation']
      ..createdAt = DateTime.parse(json['createdAt']).toLocal()
      ..updatedAt = DateTime.parse(json['updatedAt']).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'answerTranslation': answerTranslation,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
