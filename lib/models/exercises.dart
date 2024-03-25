import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/objectbox.g.dart';
import 'discovered_word.dart';
import 'exercises/reading.dart';
import 'exercises/text_meaning.dart';

enum AnswerType {
  englishString,
  japaneseString,
  multipleChoice,
}

abstract class Exercise {
  Widget question(BuildContext context);
  Widget correctAnswer(BuildContext context);

  AnswerType get answerType;
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

  String get word;
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
    final entry = dictionary.searchEntryFromId(word.entryNumber)!;
    if (enableReadingExercises && entry.word.isNotEmpty) {
      exercises.add(ReadingExercise(
          discoveredWord: word, discoveredWordsBox: discoveredWordsBox));
    }
    if (enableMeaningExercises && entry.meanings.isNotEmpty) {
      exercises.add(TextMeaningExercise(
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
