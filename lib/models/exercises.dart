import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:memofante/dict.dart';

enum AnswerType {
  englishString,
  japaneseString,
  multipleChoice,
}

abstract class Exercise {
  String question(AppLocalizations t);
  AnswerType get answerType;
  bool checkAnswer(Object answer);
}

class ReadingExercise implements Exercise {
  final DictEntry entry;
  const ReadingExercise({required this.entry});
  @override
  bool checkAnswer(Object answerIn) {
    assert(answerIn is String);
    return entry.readings.contains(answerIn as String);
  }

  @override
  AnswerType get answerType => AnswerType.japaneseString;

  @override
  String question(AppLocalizations t) {
    return t.readingExercise__question(entry.word.first);
  }
}

enum ExerciseState { pending, success, fail }
