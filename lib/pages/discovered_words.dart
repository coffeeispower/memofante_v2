import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';

class DiscoveredWords extends StatefulWidget {
  const DiscoveredWords({super.key});
  @override
  State<DiscoveredWords> createState() => _DiscoveredWordsState();
}

class _DiscoveredWordsState extends State<DiscoveredWords> {
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
      body: const Text("todo"),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: AppLocalizations.of(context)!.pages__discoveredWords__add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
