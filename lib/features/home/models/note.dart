import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  String? userId;
  String? cloudId;
  bool? isSynced = false;
  bool? isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<Sentence>? sentences;
  String? context;
  List<String>? tags;

  String? get currentContent => sentences?[currentSentenceIndex ?? 0]
      .variants?[sentences?[currentSentenceIndex ?? 0].currentVariantIndex ?? 0]
      .text;
  String? get currentLang => sentences?[currentSentenceIndex ?? 0]
      .variants?[sentences?[currentSentenceIndex ?? 0].currentVariantIndex ?? 0]
      .languageCode;
  String? get initialContent => sentences?[0].variants?[0].text;
  String? get initialLang => sentences?[0].variants?[0].languageCode;

  bool get allPartsSynced {
    if (!isSynced!) {
      return false;
    }
    for (var sentence in sentences ?? []) {
      if (!sentence.isSynced!) {
        return false;
      }
      for (var variant in sentence.variants ?? []) {
        if (!variant.isSynced!) {
          return false;
        }
        for (var qna in variant.qnas ?? []) {
          if (!qna.isSynced!) {
            return false;
          }
        }
      }
    }
    return true;
  }

  int? currentSentenceIndex;

  Note() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    sentences = [];
    tags = [];
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note()
      ..userId = json['user_id']
      ..cloudId = json['id']
      ..createdAt = DateTime.parse(json['created_at']).toLocal()
      ..updatedAt = DateTime.parse(json['updated_at']).toLocal()
      // ..sentences =
      //     (json['sentences'] as List).map((e) => Sentence.fromJson(e)).toList()
      ..context = json['context']
      ..currentSentenceIndex = json['current_sentence_index']
      ..tags = (json['tags'] as List).map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'id': cloudId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // 'sentences': sentences?.map((e) => e.toJson()).toList(),
      'context': context,
      'current_sentence_index': currentSentenceIndex,
      'tags': tags,
    };
  }
}

@embedded
class Sentence {
  String? cloudId;
  List<Variant>? variants;
  String? question;

  int? currentVariantIndex;
  bool? isSynced = false;
  DateTime? createdAt;
  DateTime? updatedAt;

  Sentence() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    variants = [];
  }

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence()
      ..cloudId = json['id']
      // ..variants =
      //     (json['variants'] as List).map((e) => Variant.fromJson(e)).toList()
      ..question = json['question']
      ..currentVariantIndex = json['current_variant_index']
      ..createdAt = DateTime.parse(json['created_at']).toLocal()
      ..updatedAt = DateTime.parse(json['updated_at']).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': cloudId,
      // 'variants': variants?.map((e) => e.toJson()).toList(),
      'question': question,
      'current_variant_index': currentVariantIndex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

@embedded
class Variant {
  String? cloudId;
  String? languageCode;
  String? text;
  List<QnA>? qnas;
  bool? isSynced = false;

  DateTime? createdAt;
  DateTime? updatedAt;

  Variant() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    qnas = [];
  }

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant()
      ..cloudId = json['id']
      ..languageCode = json['language_code']
      ..text = json['text']
      // ..qnas = (json['qnas'] as List).map((e) => QnA.fromJson(e)).toList()
      ..createdAt = DateTime.parse(json['created_at']).toLocal()
      ..updatedAt = DateTime.parse(json['updated_at']).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': cloudId,
      'language_code': languageCode,
      'text': text,
      // 'qnas': qnas?.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}

@embedded
class QnA {
  String? cloudId;
  String? question;
  String? answer;
  String? answerTranslation;
  bool? isSynced = false;

  DateTime? createdAt;
  DateTime? updatedAt;

  QnA() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  factory QnA.fromJson(Map<String, dynamic> json) {
    return QnA()
      ..cloudId = json['id']
      ..question = json['question']
      ..answer = json['answer']
      ..answerTranslation = json['answer_translation']
      ..createdAt = DateTime.parse(json['created_at']).toLocal()
      ..updatedAt = DateTime.parse(json['updated_at']).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': cloudId,
      'question': question,
      'answer': answer,
      'answer_translation': answerTranslation,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
