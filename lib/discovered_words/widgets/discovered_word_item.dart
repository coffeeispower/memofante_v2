import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:memofante/models/discovered_word.dart';

class DiscoveredWordItem extends StatelessWidget {
  const DiscoveredWordItem({
    super.key,
    required this.discoveredWordsBox,
    required this.word,
  });
  final DiscoveredWord word;
  final Box<DiscoveredWord> discoveredWordsBox;

  DictEntry get entry => dictionary.searchEntryFromId(word.entryNumber)!;
  String get wordStringOfDiscoveredWord => entry.word.isEmpty || entry.onlyKana
      ? entry.readings.first
      : entry.word.first;

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
      title: Text(this.wordStringOfDiscoveredWord),
      subtitle: Text("meaning"),
    );
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
