import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/discovered_words/widgets/discovered_word_list.dart';
import 'package:memofante/main.dart';
import 'package:memofante/models/sync/sync.dart';
import 'package:memofante/models/sync/transaction.dart';
import 'package:memofante/objectbox.g.dart' hide SyncState;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../review/pages/review_page.dart';
import '../../models/discovered_word.dart';
import 'package:memofante/base/widgets/world_search_result_list_tile.dart';

class DiscoveredWords extends StatefulWidget {
  const DiscoveredWords({super.key});
  @override
  State<DiscoveredWords> createState() => _DiscoveredWordsState();
}

class _DiscoveredWordsState extends State<DiscoveredWords> {
  final discoveredWordsBox = objectBox.store.box<DiscoveredWord>();
  final transactionsBox = objectBox.store.box<Transaction>();
  late List<DiscoveredWord> discoveredWordsList;
  late StreamSubscription<List<DiscoveredWord>> discoveredWordsSubscription;
  var dictionaryIsLoaded = false;
  void richPresence(AppLocalizations t) {
    try {
      FlutterDiscordRPC.instance.setActivity(
          activity: RPCActivity(
        state: t.discordPresenceStateDiscoveredWords,
        assets: const RPCAssets(
          largeImage: "memofante-icon",
        ),
        timestamps: RPCTimestamps(
          start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    discoveredWordsSubscription = discoveredWordsBox
        .query()
        .watch(triggerImmediately: true)
        .map((event) => event.find())
        .listen((words) {
      setState(() {
        discoveredWordsList = words;
      });
    });
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final t = AppLocalizations.of(context)!;
      richPresence(t);
      final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 365),
          content: Text(t.snackbars__downloadingDict),
        ),
      );
      dictionary.download().whenComplete(() {
        snackbarController.close();
        setState(() => dictionaryIsLoaded = true);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    discoveredWordsSubscription.cancel();
  }

  Future<bool> promptSyncCode(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final TextEditingController codeController =
        TextEditingController(text: prefs.getString('syncCode'));
    final TextEditingController urlController = TextEditingController(
        text: prefs.getString('syncServerUrl') ?? 'wss://memofante-sync-backend.fly.dev');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;

        return AlertDialog(
        title: Text(t.sync_settings__title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: t.sync_settings__sync_code,
                hintText: 'e.g. 918364'
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: t.sync_settings__sync_server_url,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'syncCode': codeController.text,
              'syncServerUrl': urlController.text,
            }),
            child: const Text('OK'),
          ),
        ],
      );
      },
    );
    if (result == null) return false;
    // Save the sync details in SharedPreferences
    await prefs.setString('syncCode', result['syncCode']!);
    await prefs.setString('syncServerUrl', result['syncServerUrl']!);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages__discoveredWords__title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              if (!await promptSyncCode(context)) return;
              final syncClient =
                  Provider.of<SyncWebSocketClient>(context, listen: false);
              syncClient.updateSyncSettingsFromSharedPreferences();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.remove_red_eye),
            label: const Text("Review"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReviewConfirmationDialog(
                    discoveredWordsBox: discoveredWordsBox,
                    transactionsBox: transactionsBox,
                    onReviewEnd: () => richPresence(t)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: dictionaryIsLoaded
            ? DiscoveredWordList(
                discoveredWordList: discoveredWordsList,
                discoveredWordsBox: discoveredWordsBox,
                transactionsBox: transactionsBox,
              )
            : Text(t.loading_dictionary),
      ),
      floatingActionButton: Builder(builder: (context) {
        final syncClient = Provider.of<SyncWebSocketClient>(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            FloatingActionButton(
              heroTag: "sync",
              onPressed: () async {
                syncClient.requestSync();
              },
              tooltip: "Sync",
              mini: true,
              backgroundColor: Colors.white,
              child: syncClient.syncState != SyncState.idle
                  ? const RotatingIcon(icon: Icon(Icons.sync))
                  : const Icon(Icons.sync),
            ),
            FloatingActionButton(
              heroTag: "add_word",
              onPressed: () {
                showMaterialModalBottomSheet(
                  context: context,
                  bounce: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                          bottom: Radius.circular(0))),
                  builder: (context) => AddDiscoveredWordModal(
                      discoveredWordsBox: discoveredWordsBox,
                      transactionsBox: transactionsBox),
                ).then((value) => richPresence(t));
              },
              tooltip: t.pages__discoveredWords__add,
              child: const Icon(Icons.add),
            ),
          ],
        );
      }),
    );
  }
}

class ReviewConfirmationDialog extends StatefulWidget {
  const ReviewConfirmationDialog({
    super.key,
    required this.discoveredWordsBox,
    required this.transactionsBox,
    required this.onReviewEnd,
  });
  final Box<DiscoveredWord> discoveredWordsBox;
  final Box<Transaction> transactionsBox;
  final Function() onReviewEnd;
  @override
  State<ReviewConfirmationDialog> createState() =>
      _ReviewConfirmationDialogState();
}

class _ReviewConfirmationDialogState extends State<ReviewConfirmationDialog> {
  bool enableReadingExercises = true;
  bool enableMeaningExercises = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.dialogs__startReview__title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(t.dialogs__startReview__description),
          Row(
            children: [
              Checkbox(
                  value: enableReadingExercises,
                  onChanged: ((value) =>
                      setState(() => enableReadingExercises = value!))),
              Text(t.dialogs__startReview__enableReadingExercises,
                  softWrap: true)
            ],
          ),
          Row(
            children: [
              Checkbox(
                  value: enableMeaningExercises,
                  onChanged: ((value) =>
                      setState(() => enableMeaningExercises = value!))),
              Text(
                t.dialogs__startReview__enableMeaningExercises,
                softWrap: true,
              )
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            t.dialogs__startReview__cancel,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: !enableMeaningExercises && !enableReadingExercises
              ? null
              : () {
                  Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(
                        builder: (context) => Scaffold(
                            body: ReviewPage(
                          discoveredWordBox: widget.discoveredWordsBox,
                          transactionsBox: widget.transactionsBox,
                          enableReadingExercises: enableReadingExercises,
                          enableMeaningExercises: enableMeaningExercises,
                        )),
                      ))
                      .then((_) => widget.onReviewEnd());
                },
          child: Text(t.dialogs__startReview__ok),
        )
      ],
    );
  }
}

class AddDiscoveredWordModal extends StatefulWidget {
  const AddDiscoveredWordModal({
    super.key,
    required this.discoveredWordsBox,
    required this.transactionsBox,
  });
  final Box<DiscoveredWord> discoveredWordsBox;
  final Box<Transaction> transactionsBox;
  @override
  State<AddDiscoveredWordModal> createState() => _AddDiscoveredWordModalState();
}

class _AddDiscoveredWordModalState extends State<AddDiscoveredWordModal> {
  String keyword = "";
  List<DictEntry> results = [];
  final startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  void _search() {
    setState(() {
      this.results = dictionary.searchFromJPWord(this.keyword);
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final t = AppLocalizations.of(context)!;
      try {
        FlutterDiscordRPC.instance.setActivity(
            activity: RPCActivity(
          state: t.discordPresenceStateAddingWord,
          assets: const RPCAssets(
            smallImage: "adding-word",
            largeImage: "memofante-icon",
          ),
          timestamps: RPCTimestamps(
            start: startTime,
          ),
        ));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ListView(
      controller: ModalScrollController.of(context),
      children: <Widget>[
            // This is the little handle at the top, so the user knows that he can drag this down to dismiss
            Container(
              height: 5,
              margin: const EdgeInsets.symmetric(
                  vertical: 4 * 3, horizontal: 4 * 32),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              // Searh Box
              child: TextField(
                onChanged: (value) {
                  this.keyword = value;

                  final t = AppLocalizations.of(context)!;
                  try {
                    FlutterDiscordRPC.instance.setActivity(
                        activity: RPCActivity(
                      details: keyword.isEmpty
                          ? null
                          : t.discordPresenceDetailsAddingWord(keyword),
                      state: t.discordPresenceStateAddingWord,
                      assets: const RPCAssets(
                        smallImage: "adding-word",
                        largeImage: "memofante-icon",
                      ),
                      timestamps: RPCTimestamps(
                        start: startTime,
                      ),
                    ));
                  } catch (_) {}
                },
                onEditingComplete: _search,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: const OutlineInputBorder(),
                  labelText: t.searchWordsLabel,
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    hoverColor: Colors.transparent,
                    mouseCursor: SystemMouseCursors.basic,
                    onPressed: _search,
                  ),
                ),
              ),
            ),
          ] +
          // The results
          results
              .map((result) => WordSearchResultListTile(
                    entry: result,
                    onAdd: !widget.discoveredWordsBox.contains(result.id)
                        ? (entry) {
                            final word = DiscoveredWord(
                              entryNumber: entry.id,
                              successMeaningReviews: 0,
                              failedMeaningReviews: 0,
                              successReadingReviews: 0,
                              failedReadingReviews: 0,
                            );
                            widget.discoveredWordsBox.put(
                              word,
                              mode: PutMode.insert,
                            );
                            Transaction.registerAddWord(
                                widget.transactionsBox, word);
                            Navigator.of(context).pop();
                          }
                        : null,
                  ))
              .toList(),
    );
  }
}

class RotatingIcon extends StatefulWidget {
  final Icon icon;
  final Duration duration;

  const RotatingIcon({
    Key? key,
    required this.icon,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _RotatingIconState createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat()
        ..reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.icon,
    );
  }
}
