import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/main.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../models/discovered_word.dart';

class DiscoveredWords extends StatefulWidget {
  const DiscoveredWords({super.key});
  @override
  State<DiscoveredWords> createState() => _DiscoveredWordsState();
}

class _DiscoveredWordsState extends State<DiscoveredWords> {
  final discoveredWordsBox = objectBox.store.box<DiscoveredWord>();
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () async {
      final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(days: 365),
              content: Text(
                  AppLocalizations.of(context)!.snackbars__downloadingDict)));
      dictionary.download().whenComplete(snackbarController.close);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(AppLocalizations.of(context)!.pages__discoveredWords__title),
      ),
      body: ListView(
        children: discoveredWordsBox
            .getAll()
            .map((e) => ListTile(
                title:
                    Text(dictionary.searchEntryFromId(e.entryNumber)!.word[0])))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showMaterialModalBottomSheet(
            context: context,
            bounce: true,
            builder: (context) =>
                AddDiscoveredWordModal(discoveredWordsBox: discoveredWordsBox),
          );
        },
        tooltip: AppLocalizations.of(context)!.pages__discoveredWords__add,
        child: const Icon(Icons.add),
      ),
    );
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
  void _search(String word) {
    this.keyword = word;
    this.results = dictionary.searchFromJPWord(this.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: ModalScrollController.of(context),
      children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) => setState(() => this.keyword = keyword),
                onSubmitted: _search,
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    hintText: "言葉を入力してください",
                    border: OutlineInputBorder(),
                    labelText: "Search",
                    prefixIcon: Icon(Icons.search)),
              ),
            ),
          ] +
          results
              .map((result) => WordSearchResultListTile(entry: result))
              .toList(),
    );
  }
}

class WordSearchResultListTile extends StatelessWidget {
  final DictEntry entry;
  const WordSearchResultListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(entry.word.join(", ")),
      onTap: () => {},
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(entry.readings.reversed.join(", ")),
            ] +
            entry.meanings.map((e) => Text(" - " + e.join(", "))).toList(),
      ),
    );
  }
}
