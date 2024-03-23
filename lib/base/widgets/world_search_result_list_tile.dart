import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';

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
