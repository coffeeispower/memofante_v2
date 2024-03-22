import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    _goToNextExercise();
  }

  void _goToNextExercise() {
    state = ExerciseState.pending;
    bottomSheetController?.close();
    stringInputController.clear();
    final nextExercise = getNextExercise(widget.discoveredWordBox,
        widget.enableReadingExercises, widget.enableMeaningExercises);
    if (nextExercise != null) {
      currentExercise = nextExercise;
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(AppLocalizations.of(context)!.no_discovered_words)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(8.0 * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          currentExercise.question(context),
          if (currentExercise.answerType == AnswerType.japaneseString)
            TextField(
              enabled: state == ExerciseState.pending,
              controller: stringInputController,
              onEditingComplete: () => stringInputController.text =
                  kanaKit.toKana(stringInputController.text),
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
                label: Text(t.stop_review),
              ),
              if (state == ExerciseState.pending)
                ElevatedButton.icon(
                  onPressed: () => setState(_checkAnswer),
                  icon: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green,
                  ),
                  label: Text(t.check),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(_goToNextExercise),
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  label: Text(t.next),
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
      case AnswerType.japaneseString:
        stringInputController.text = kanaKit.toKana(stringInputController.text);
        if (currentExercise.checkAnswer(stringInputController.text)) {
          state = ExerciseState.success;
        } else {
          state = ExerciseState.fail;
        }
        break;
      case AnswerType.englishString:
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
        currentExercise.incrementSuccessCount();
        break;
      case ExerciseState.fail:
        bottomSheetController = showBottomSheet(
          context: context,
          builder: (context) => WrongAnswerModal(exercise: currentExercise),
          enableDrag: false,
        );
        currentExercise.incrementFailCount();
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    stringInputController.dispose();
  }
}

class CorrectAnswerModal extends StatelessWidget {
  const CorrectAnswerModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                  loc.success_review_headline,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.green,
                      ),
                ),
                Text(loc.success_review_message)
              ],
            ),
          )
        ],
      ),
    );
  }
}

class WrongAnswerModal extends StatelessWidget {
  final Exercise exercise;
  const WrongAnswerModal({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                      loc.fail_review_headline,
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: Colors.red,
                              ),
                    ),
                    Text(loc.fail_review_message),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          exercise.correctAnswer(context),
        ],
      ),
    );
  }
}
