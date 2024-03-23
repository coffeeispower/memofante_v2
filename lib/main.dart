import 'package:flutter/material.dart' hide RootWidget;
import 'package:kana_kit/kana_kit.dart';
import 'package:memofante/models/store.dart';
import 'package:memofante/home/root_widget.dart';

final kanaKit =
    KanaKit(config: KanaKitConfig.defaultConfig.copyWith(upcaseKatakana: true));
late ObjectBox objectBox;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();
  runApp(const RootWidget());
}
