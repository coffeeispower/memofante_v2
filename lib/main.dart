import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter/material.dart' hide RootWidget;
import 'package:kana_kit/kana_kit.dart';
import 'package:memofante/models/store.dart';
import 'package:memofante/base/root_widget.dart';

final kanaKit =
    KanaKit(config: KanaKitConfig.defaultConfig.copyWith(upcaseKatakana: true));
late ObjectBox objectBox;
final audioPlayer = AudioPlayer();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();

  if(!Platform.isAndroid && !Platform.isIOS) {
    await FlutterDiscordRPC.initialize(
      "1221903147396632638",
    );
    await FlutterDiscordRPC.instance.connect(autoRetry: true, retryDelay: const Duration(seconds: 5));
  }
  runApp(const RootWidget());
}
