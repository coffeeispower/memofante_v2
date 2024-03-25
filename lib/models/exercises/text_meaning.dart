import 'package:flutter/material.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../dict.dart';
import '../discovered_word.dart';
import '../exercises.dart';

class TextMeaningExercise implements Exercise {
  final DiscoveredWord discoveredWord;
  final Box<DiscoveredWord> discoveredWordsBox;
  const TextMeaningExercise({
    required this.discoveredWord,
    required this.discoveredWordsBox,
  });

  @override
  AnswerType get answerType => AnswerType.englishString;

  DictEntry get entry =>
      dictionary.searchEntryFromId(discoveredWord.entryNumber)!;

  @override
  double calculateScore() {
    return calculateScoreGeneric(
      discoveredWord.totalMeaningReviews,
      discoveredWord.failedMeaningRate,
      discoveredWord.lastMeaningReview,
    );
  }

  @override
  bool checkAnswer(Object answerIn) {
    assert(answerIn is String);
    String removeTextInParentheses(String input) {
      // Define a regular expression to match text within parentheses
      RegExp regex = RegExp(r'\([^()]*\)');

      // Replace all matches of the regex pattern with an empty string
      return input.replaceAll(regex, '');
    }

    return entry.meanings.expand((m) => m).any((potentialCorrectAnswer) =>
        removeTextInParentheses(potentialCorrectAnswer)
            .trim()
            .similarityTo(answerIn as String) >=
        0.7);
  }

  @override
  void incrementFailCount() {
    discoveredWord.failedMeaningReviews++;
    discoveredWord.lastReadingReview = DateTime.now();
    discoveredWordsBox.put(discoveredWord);
  }

  @override
  void incrementSuccessCount() {
    discoveredWord.successMeaningReviews++;
    discoveredWord.lastReadingReview = DateTime.now();
    discoveredWordsBox.put(discoveredWord);
  }

  @override
  Widget correctAnswer(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ExpansionTile(
      title: Text(t.correct_answers),
      initiallyExpanded: true,
      children: entry.meanings
          .map((e) => ListTile(
                title: Text(
                  e.join(", "),
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget question(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          t.meaningExercise__question,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (entry.word.isEmpty)
          Text(
            entry.readings.first,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else
          RubyText(
            [RubyTextData(entry.word.first, ruby: entry.readings.last)],
            style: const TextStyle(fontSize: 30),
          ),
      ],
    );
  }
  
  @override
  String get word => entry.word.first;
}
