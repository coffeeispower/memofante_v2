import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/base/widgets/responsive_state.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/objectbox.g.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:ruby_text/ruby_text.dart';

class DiscoveredWordItem extends StatefulWidget {
  DiscoveredWordItem({
    super.key,
    required this.discoveredWordsBox,
    required this.word,
  });
  final DiscoveredWord word;
  final Box<DiscoveredWord> discoveredWordsBox;

  State<DiscoveredWordItem> createState() => _DiscoveredWordItemState();
}

class _DiscoveredWordItemState extends ResponsiveState<DiscoveredWordItem> {
  DictEntry get entry => dictionary.searchEntryFromId(widget.word.entryNumber)!;
  String get wordStringOfDiscoveredWord => entry.word.isEmpty || entry.onlyKana
      ? entry.readings.first
      : entry.word.first;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FractionallySizedBox(
        widthFactor: size == PageSize.mobile ? 1 : .3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: RubyText(
                  [
                    RubyTextData(
                      wordStringOfDiscoveredWord,
                      ruby: entry.readings.last,
                    )
                  ],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              PopupMenuButton<String>(
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
                        title:
                            Text(t.pages__discoveredWords__contextMenu__stats),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: "delete",
                      mouseCursor: SystemMouseCursors.click,
                      child: ListTile(
                        leading: const Icon(Icons.delete),
                        title:
                            Text(t.pages__discoveredWords__contextMenu__delete),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (choice) {
      case "delete":
        widget.discoveredWordsBox
            .query(DiscoveredWord_.entryNumber.equals(widget.word.entryNumber))
            .build()
            .remove();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.snackbars__discoveredWord__deleted(
              this.wordStringOfDiscoveredWord)),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              widget.word.id = 0;
              widget.discoveredWordsBox.put(widget.word);
            },
          ),
        ));
        break;
      default:
        throw UnimplementedError("$choice is not implemented yet");
    }
  }
}
