import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/jm_dict_impl.dart';
import 'package:signals/signals_flutter.dart';

Dictionary dictionary = JMDictDictionary();
final dictionaryIsDownloading = signal(true);
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    dictionary.download().then((_) => dictionaryIsDownloading.value = false);
    return MaterialApp(
      title: 'Memofante',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DiscoveredWords(title: 'Dis'),
    );
  }
}

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Watch(((context) {
        if (dictionaryIsDownloading.value) {
          return const Center(child: Text("Downloading Dictionary..."));
        } else {
          return Text("TODO");
        }
      })),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
