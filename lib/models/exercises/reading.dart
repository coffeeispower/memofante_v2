import 'package:flutter/material.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../dict.dart';
import '../discovered_word.dart';
import '../exercises.dart';

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
  Widget correctAnswer(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpansionTile(
          title: Text(t.correct_answers),
          initiallyExpanded: true,
          children: entry.readings
              .map((e) => ListTile(
                    title: Text(
                      e,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                  ))
              .toList(),
        ),
        ExpansionTile(
          title: Text(t.show_meanings),
          children: entry.meanings
              .map((e) => ListTile(
                    title: Text(
                      e.join(", "),
                      style: Theme.of(context).textTheme.bodyLarge!,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget question(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Text(t.readingExercise__question(entry.word.first),
        style: Theme.of(context).textTheme.headlineMedium);
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
