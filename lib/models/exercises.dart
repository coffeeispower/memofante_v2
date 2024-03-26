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
T weightedRandom<T>(List<T> items, List<double> weights) {
  if (items.length != weights.length) {
    throw Exception('Items and weights must be of the same size');
  }

  if (items.isEmpty) {
    throw Exception('Items must not be empty');
  }

  List<double> cumulativeWeights = [];
  for (int i = 0; i < weights.length; i++) {
    cumulativeWeights.add(weights[i] + (i == 0 ? 0 : cumulativeWeights[i - 1]));
  }

  final maxCumulativeWeight = cumulativeWeights[cumulativeWeights.length - 1];
  final randomNumber = maxCumulativeWeight * Random().nextDouble();
  T? result;

  for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
    if (cumulativeWeights[itemIndex] >= randomNumber) {
      return result = items[itemIndex];
    }
  }
  return result!;
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

  return weightedRandom(exercises, exercises.map((e) => e.calculateScore()).toList());
}
