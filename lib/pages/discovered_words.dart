import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/main.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import './review_page.dart';
import '../models/discovered_word.dart';

class DiscoveredWords extends StatefulWidget {
  const DiscoveredWords({super.key});
  @override
  State<DiscoveredWords> createState() => _DiscoveredWordsState();
}

class _DiscoveredWordsState extends State<DiscoveredWords> {
  final discoveredWordsBox = objectBox.store.box<DiscoveredWord>();
  late List<DiscoveredWord> discoveredWordsList;
  late StreamSubscription<List<DiscoveredWord>> discoveredWordsSubscription;
  var dictionaryIsLoaded = false;
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
    Future.delayed(const Duration(milliseconds: 200), () {
      final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 365),
          content:
              Text(AppLocalizations.of(context)!.snackbars__downloadingDict),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages__discoveredWords__title),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.remove_red_eye),
            label: const Text("Review"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReviewConfirmationDialog(
                    discoveredWordsBox: discoveredWordsBox),
              );
            },
          ),
        ],
      ),
      body: dictionaryIsLoaded
          ? ListView(
              children: discoveredWordsList
                  .map((e) => DiscoveredWordItem(
                        discoveredWordsBox: discoveredWordsBox,
                        word: e,
                      ))
                  .toList(),
            )
          : const Text("Loading dictionary..."),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showMaterialModalBottomSheet(
            context: context,
            bounce: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20), bottom: Radius.circular(0))),
            builder: (context) =>
                AddDiscoveredWordModal(discoveredWordsBox: discoveredWordsBox),
          );
        },
        tooltip: t.pages__discoveredWords__add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReviewConfirmationDialog extends StatefulWidget {
  const ReviewConfirmationDialog({
    super.key,
    required this.discoveredWordsBox,
  });
  final Box<DiscoveredWord> discoveredWordsBox;

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
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => Scaffold(
                        body: ReviewPage(
                      discoveredWordBox: widget.discoveredWordsBox,
                      enableReadingExercises: enableReadingExercises,
                      enableMeaningExercises: enableMeaningExercises,
                    )),
                  ));
                },
          child: Text(t.dialogs__startReview__ok),
        )
      ],
    );
  }
}

class DiscoveredWordItem extends StatelessWidget {
  const DiscoveredWordItem(
      {super.key, required this.discoveredWordsBox, required this.word});
  final DiscoveredWord word;
  final Box<DiscoveredWord> discoveredWordsBox;
  DictEntry get entry => dictionary.searchEntryFromId(word.entryNumber)!;
  String get wordStringOfDiscoveredWord =>
      entry.word.isNotEmpty ? entry.word.first : entry.readings.first;
  @override
  Widget build(BuildContext context) {
    return ListTile(
        trailing: PopupMenuButton<String>(
          onSelected: (String choice) {
            _handleMenuAction(choice, context);
          },
          itemBuilder: (BuildContext context) {
            final t = AppLocalizations.of(context)!;
            return [
              PopupMenuItem<String>(
                value: "show_stats",
                mouseCursor: SystemMouseCursors.click,
                child: ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text(t.pages__discoveredWords__contextMenu__stats)),
              ),
              PopupMenuItem<String>(
                value: "delete",
                mouseCursor: SystemMouseCursors.click,
                child: ListTile(
                    leading: const Icon(Icons.delete),
                    title: Text(t.pages__discoveredWords__contextMenu__delete)),
              ),
            ];
          },
        ),
        title: Text(this.wordStringOfDiscoveredWord));
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (choice) {
      case "delete":
        discoveredWordsBox
            .query(DiscoveredWord_.entryNumber.equals(word.entryNumber))
            .build()
            .remove();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.snackbars__discoveredWord__deleted(
              this.wordStringOfDiscoveredWord)),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              word.id = 0;
              discoveredWordsBox.put(word);
            },
          ),
        ));
        break;
      default:
        throw UnimplementedError("$choice is not implemented yet");
    }
  }
}

class AddDiscoveredWordModal extends StatefulWidget {
  const AddDiscoveredWordModal({super.key, required this.discoveredWordsBox});
  final Box<DiscoveredWord> discoveredWordsBox;
  @override
  State<AddDiscoveredWordModal> createState() => _AddDiscoveredWordModalState();
}

class _AddDiscoveredWordModalState extends State<AddDiscoveredWordModal> {
  String keyword = "";
  List<DictEntry> results = [];
  void _search() {
    setState(() {
      this.results = dictionary.searchFromJPWord(this.keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: (value) => this.keyword = value,
                onEditingComplete: _search,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  hintText: "言葉を入力してください",
                  border: const OutlineInputBorder(),
                  labelText: "Search",
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
                            widget.discoveredWordsBox.put(
                              DiscoveredWord(
                                entryNumber: entry.id,
                                successMeaningReviews: 0,
                                failedMeaningReviews: 0,
                                successReadingReviews: 0,
                                failedReadingReviews: 0,
                              ),
                              mode: PutMode.insert,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                  ))
              .toList(),
    );
  }
}

class WordSearchResultListTile extends StatelessWidget {
  final DictEntry entry;
  final void Function(DictEntry entry)? onAdd;
  const WordSearchResultListTile({super.key, required this.entry, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
            "${entry.word.join(", ")} (${entry.readings.reversed.join(", ")})"),
        trailing: onAdd != null
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => onAdd!(entry),
                color: Colors.blue,
              )
            : null,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              entry.meanings.map((e) => Text(" - ${e.join(", ")}")).toList(),
        ),
      ),
    );
  }
}
