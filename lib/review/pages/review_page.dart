import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:memofante/base/widgets/responsive_state.dart';
import 'package:memofante/main.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:memofante/models/exercises.dart';
import 'package:memofante/models/sync/transaction.dart';
import 'package:memofante/objectbox.g.dart';

class ReviewPage extends StatefulWidget {
  final bool enableReadingExercises;
  final bool enableMeaningExercises;

  const ReviewPage({
    super.key,
    required this.discoveredWordBox,
    required this.transactionsBox,
    required this.enableReadingExercises,
    required this.enableMeaningExercises,
  });
  final Box<DiscoveredWord> discoveredWordBox;
  final Box<Transaction> transactionsBox;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ResponsiveState<ReviewPage> {
  Exercise? currentExercise;
  ExerciseState state = ExerciseState.pending;
  TextEditingController stringInputController = TextEditingController();
  PersistentBottomSheetController? bottomSheetController;
  final startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  @override
  void initState() {
    super.initState();
    _goToNextExercise();
  }

  void _goToNextExercise() {
    state = ExerciseState.pending;
    bottomSheetController?.close();
    stringInputController.clear();
    final nextExercise = getNextExercise(
        widget.discoveredWordBox,
        widget.transactionsBox,
        widget.enableReadingExercises,
        widget.enableMeaningExercises);
    currentExercise = nextExercise;

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (currentExercise == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(AppLocalizations.of(context)!.no_discovered_words)));
        return;
      }

      final t = AppLocalizations.of(context)!;
      try {
        FlutterDiscordRPC.instance.setActivity(
          activity: RPCActivity(
            state: t.discordPresenceStateReviewing,
            details: t.discordPresenceDetailsReviewing(currentExercise!.word),
            assets: const RPCAssets(
              smallImage: "reviewing",
              largeImage: "memofante-icon",
            ),
            timestamps: RPCTimestamps(
              start: startTime,
            ),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentExercise == null) {
      return Container();
    }
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0 * 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 8 * 70),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              currentExercise!.question(context),
              const SizedBox(height: 20),
              if (currentExercise!.answerType == AnswerType.japaneseString)
                TextField(
                  enabled: state == ExerciseState.pending,
                  controller: stringInputController,
                  onEditingComplete: () => stringInputController.text =
                      kanaKit.toKana(stringInputController.text),
                  onSubmitted: (_) => setState(_checkAnswer),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              if (currentExercise!.answerType == AnswerType.englishString)
                TextField(
                  textAlign: TextAlign.center,
                  enabled: state == ExerciseState.pending,
                  controller: stringInputController,
                  onSubmitted: (_) => setState(_checkAnswer),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              const SizedBox(
                height: 16.0,
              ),
              OverflowBar(
                alignment: MainAxisAlignment.start,
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
        ),
      ),
    );
  }

  /// Checks the answer and updates the exercise state and the statistics of the word
  void _checkAnswer() {
    switch (currentExercise!.answerType) {
      case AnswerType.japaneseString:
        stringInputController.text = kanaKit.toKana(stringInputController.text);
        if (currentExercise!.checkAnswer(stringInputController.text)) {
          state = ExerciseState.success;
        } else {
          state = ExerciseState.fail;
        }
        break;
      case AnswerType.englishString:
        if (currentExercise!.checkAnswer(stringInputController.text)) {
          state = ExerciseState.success;
        } else {
          state = ExerciseState.fail;
        }
        break;
      case AnswerType.multipleChoice:
        throw UnimplementedError();
    }
    final t = AppLocalizations.of(context)!;
    switch (state) {
      case ExerciseState.pending:
        throw UnimplementedError();
      case ExerciseState.success:
        audioPlayer.play(AssetSource("duolingo-correct.mp3"));
        try {
          FlutterDiscordRPC.instance.setActivity(
            activity: RPCActivity(
              state: t.success_review_headline,
              details: t.discordPresenceDetailsReviewing(currentExercise!.word),
              assets: const RPCAssets(
                smallImage: "checkmark",
                largeImage: "memofante-icon",
              ),
              timestamps: RPCTimestamps(
                start: startTime,
              ),
            ),
          );
        } catch (_) {}
        bottomSheetController = showBottomSheet(
          context: context,
          builder: (context) => const CorrectAnswerModal(),
          enableDrag: false,
        );
        bottomSheetController!.closed.then((_) {
          final t = AppLocalizations.of(context)!;
          try {
            FlutterDiscordRPC.instance.setActivity(
              activity: RPCActivity(
                state: t.discordPresenceStateReviewing,
                details:
                    t.discordPresenceDetailsReviewing(currentExercise!.word),
                assets: const RPCAssets(
                  smallImage: "reviewing",
                  largeImage: "memofante-icon",
                ),
                timestamps: RPCTimestamps(
                  start: startTime,
                ),
              ),
            );
          } catch (_) {}
        });
        currentExercise!.incrementSuccessCount();
        break;
      case ExerciseState.fail:
        audioPlayer.play(AssetSource("duolingo-wrong.mp3"));
        try {
          FlutterDiscordRPC.instance.setActivity(
            activity: RPCActivity(
              state: t.success_review_headline,
              details: t.discordPresenceDetailsReviewing(currentExercise!.word),
              assets: const RPCAssets(
                smallImage: "x",
                largeImage: "memofante-icon",
              ),
              timestamps: RPCTimestamps(
                start: startTime,
              ),
            ),
          );
        } catch (_) {}
        bottomSheetController = showBottomSheet(
          context: context,
          builder: (context) => WrongAnswerModal(exercise: currentExercise!),
          enableDrag: false,
        );

        bottomSheetController!.closed.then((_) {
          final t = AppLocalizations.of(context)!;
          try {
            FlutterDiscordRPC.instance.setActivity(
              activity: RPCActivity(
                state: t.fail_review_headline,
                details:
                    t.discordPresenceDetailsReviewing(currentExercise!.word),
                assets: const RPCAssets(
                  smallImage: "reviewing",
                  largeImage: "memofante-icon",
                ),
                timestamps: RPCTimestamps(
                  start: startTime,
                ),
              ),
            );
          } catch (_) {}
        });
        currentExercise!.incrementFailCount();
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
