import 'dart:math';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:memofante/objectbox.g.dart';

enum AnswerType {
  englishString,
  japaneseString,
  multipleChoice,
}

abstract class Exercise {
  String question(AppLocalizations t);
  AnswerType get answerType;
  String get correctAnswer;
  List<List<String>>? get meanings;
  bool checkAnswer(Object answer);

  /// Increments the success rate of this exercise in the database
  /// Making this exercise less likely to appear as the next exercise
  void incrementSuccessCount();

  /// Increments the fail rate of this exercise in the database
  /// Making this exercise more likely to appear as the next exercise
  void incrementFailCount();

  /// Calculates the score of this exercise
  /// The higher the score the more likely to appear as the next exercise this exercise will be
  double calculateScore();
}

class ReadingExercise implements Exercise {
  final DiscoveredWord discoveredWord;
  final Box<DiscoveredWord> discoveredWordsBox;
  DictEntry get entry =>
      dictionary.searchEntryFromId(discoveredWord.entryNumber)!;
  const ReadingExercise(
      {required this.discoveredWord, required this.discoveredWordsBox});
  @override
  bool checkAnswer(Object answerIn) {
    assert(answerIn is String);
    return entry.readings.contains(answerIn as String);
  }

  @override
  AnswerType get answerType => AnswerType.japaneseString;
  @override
  String get correctAnswer => entry.readings.join(", ");
  @override
  List<List<String>>? get meanings => entry.meanings;
  @override
  String question(AppLocalizations t) {
    return t.readingExercise__question(entry.word.first);
  }

  @override
  void incrementFailCount() {
    discoveredWord.failedReadingReviews++;
    discoveredWord.lastReadingReview = DateTime.now();
    discoveredWordsBox.put(discoveredWord);
  }

  @override
  void incrementSuccessCount() {
    discoveredWord.successReadingReviews++;
    discoveredWord.lastReadingReview = DateTime.now();
    discoveredWordsBox.put(discoveredWord);
  }

  @override
  double calculateScore() {
    return calculateScoreGeneric(
      discoveredWord.totalReadingReviews,
      discoveredWord.failedReadingRate,
      discoveredWord.lastReadingReview,
    );
  }
}

double calculateScoreGeneric(
    int totalReviews, double failureRate, DateTime? lastReviewed) {
  const failureWeight = 2.0;
  const fewReviewsWeight = 5.0;
  const timeElapsedSincelastReviewWeight = 10.0;
  final failureRateFixed = failureRate.isNaN ? 0.0 : failureRate;
  final failureScore = failureWeight * failureRateFixed;
  final fewReviewsScore =
      fewReviewsWeight * (1.0 - sigmoid(totalReviews.toDouble()));
  final elapsedTimeSinceLastReview = lastReviewed != null
      ? DateTime.now().difference(lastReviewed).inSeconds
      : null;
  final elapsedTimeScore = elapsedTimeSinceLastReview != null
      ? sigmoid(elapsedTimeSinceLastReview.toDouble()) *
          timeElapsedSincelastReviewWeight
      : timeElapsedSincelastReviewWeight;
  return failureScore + fewReviewsScore + elapsedTimeScore;
}

enum ExerciseState { pending, success, fail }

double sigmoid(double x) {
  return 1.0 / (1.0 + exp(-x));
}

Exercise? getNextExercise(Box<DiscoveredWord> discoveredWordsBox,
    bool enableReadingExercises, bool enableMeaningExercises) {
  List<DiscoveredWord> discoveredWords = discoveredWordsBox.getAll();
  List<Exercise> exercises = [];
  for (var word in discoveredWords) {
    if (enableReadingExercises) {
      exercises.add(ReadingExercise(
          discoveredWord: word, discoveredWordsBox: discoveredWordsBox));
    }
  }
  if (exercises.isEmpty) {
    return null;
  }
  exercises
      .sort((ex1, ex2) => ex2.calculateScore().compareTo(ex1.calculateScore()));
  int randomIndex =
      Random().nextInt(5 > exercises.length ? exercises.length : 5);
  return exercises[randomIndex];
}
