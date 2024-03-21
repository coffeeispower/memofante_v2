import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/main.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:memofante/models/exercises.dart';
import 'package:memofante/objectbox.g.dart';

class ReviewPage extends StatefulWidget {
  final bool enableReadingExercises;
  final bool enableMeaningExercises;

  const ReviewPage({
    super.key,
    required this.discoveredWordBox,
    required this.enableReadingExercises,
    required this.enableMeaningExercises,
  });
  final Box<DiscoveredWord> discoveredWordBox;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late Exercise currentExercise;
  ExerciseState state = ExerciseState.pending;
  TextEditingController stringInputController = TextEditingController();
  PersistentBottomSheetController? bottomSheetController;
  @override
  void initState() {
    super.initState();
    _nextExercise();
  }

  void _nextExercise() {
    state = ExerciseState.pending;
    currentExercise = _randomExercise();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(8.0 * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentExercise.question(t),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (currentExercise.answerType == AnswerType.japaneseString)
            TextField(
              enabled: state == ExerciseState.pending,
              controller: stringInputController,
              onChanged: ((value) {
                stringInputController.text = kanaKit.toKana(value);
              }),
              onSubmitted: (_) => setState(_checkAnswer),
            ),
          if (currentExercise.answerType == AnswerType.englishString)
            TextField(
              enabled: state == ExerciseState.pending,
              controller: stringInputController,
              onSubmitted: (_) => setState(_checkAnswer),
            ),
          ButtonBar(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(
                  Icons.stop_circle,
                  size: 16,
                  color: Colors.redAccent,
                ),
                label: const Text("Stop Review"),
              ),
              if (state == ExerciseState.pending)
                ElevatedButton.icon(
                  onPressed: () => setState(_checkAnswer),
                  icon: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green,
                  ),
                  label: const Text("Check"),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(_nextExercise),
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  label: const Text("Next"),
                )
            ],
          )
        ],
      ),
    );
  }

  /// Checks the answer and updates the exercise state and the statistics of the word
  void _checkAnswer() {
    switch (currentExercise.answerType) {
      case AnswerType.englishString:
      case AnswerType.japaneseString:
        if (currentExercise.checkAnswer(stringInputController.text)) {
          state = ExerciseState.success;
        } else {
          state = ExerciseState.fail;
        }
        break;
      case AnswerType.multipleChoice:
        throw UnimplementedError();
    }
    switch (state) {
      case ExerciseState.pending:
        throw UnimplementedError();
      case ExerciseState.success:
        bottomSheetController = showBottomSheet(
          context: context,
          builder: (context) => const CorrectAnswerModal(),
          enableDrag: false,
        );
        break;
      case ExerciseState.fail:
        bottomSheetController = showBottomSheet(
          context: context,
          builder: (context) => const WrongAnswerModal(),
          enableDrag: false,
        );
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    stringInputController.dispose();
  }

  Exercise _randomExercise() {
    bottomSheetController?.close();
    stringInputController.clear();
    return ReadingExercise(
        entry: dictionary.searchEntryFromId(widget.discoveredWordBox
            .query()
            .build()
            .findFirst()!
            .entryNumber)!);
  }
}

class CorrectAnswerModal extends StatelessWidget {
  const CorrectAnswerModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'That is the correct answer!',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.green,
                      ),
                ),
                const Text('Press "Next" to go to the next exercise')
              ],
            ),
          )
        ],
      ),
    );
  }
}

class WrongAnswerModal extends StatelessWidget {
  const WrongAnswerModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.red,
                ),
                child: const Icon(
                  Icons.error_outline_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Wrong!',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.red,
                      ),
                ),
                const Text(
                    'You\'ll do better the next time!\nPress "Next" to go to the next exercise.')
              ],
            ),
          )
        ],
      ),
    );
  }
}
