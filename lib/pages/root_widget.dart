import 'package:flutter/material.dart';
import 'package:memofante/dict.dart';
import 'package:memofante/jm_dict_impl.dart';

import 'discovered_words.dart';

final Dictionary dictionary = JMDictDictionary();

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memofante',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DiscoveredWords(title: 'Discovered Words'),
    );
  }
}
