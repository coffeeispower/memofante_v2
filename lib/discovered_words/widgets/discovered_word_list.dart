import 'package:flutter/material.dart';
import 'package:memofante/base/widgets/responsive_state.dart';
import 'package:memofante/discovered_words/widgets/discovered_word_item.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:memofante/objectbox.g.dart';

class DiscoveredWordList extends StatefulWidget {
  DiscoveredWordList({
    super.key,
    required this.discoveredWordList,
    required this.discoveredWordsBox,
  });

  final List<DiscoveredWord> discoveredWordList;
  final Box<DiscoveredWord> discoveredWordsBox;

  State<DiscoveredWordList> createState() => _DiscoveredWordListState();
}

class _DiscoveredWordListState extends ResponsiveState<DiscoveredWordList> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: 1,
          verticalDirection: VerticalDirection.down,
          children: widget.discoveredWordList
              .map(
                (e) => DiscoveredWordItem(
                  discoveredWordsBox: widget.discoveredWordsBox,
                  word: e,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
