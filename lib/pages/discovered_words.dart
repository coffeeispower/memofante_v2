import 'package:flutter/material.dart';

import 'root_widget.dart';

class DiscoveredWords extends StatefulWidget {
  const DiscoveredWords({super.key, required this.title});
  final String title;
  @override
  State<DiscoveredWords> createState() => _DiscoveredWordsState();
}

class _DiscoveredWordsState extends State<DiscoveredWords> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () async {
      final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              duration: Duration(days: 365),
              content: Text(
                  "Downloading dictionary, lookup results maybe incomplete or broken during this process...")));
      await dictionary.download();
      snackbarController.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Text("todo"),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Add word',
        child: const Icon(Icons.add),
      ),
    );
  }
}
