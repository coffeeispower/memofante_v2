import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/material.dart' hide RootWidget;
import 'package:kana_kit/kana_kit.dart';
import 'package:memofante/models/store.dart';
import 'package:memofante/base/root_widget.dart';

final kanaKit =
    KanaKit(config: KanaKitConfig.defaultConfig.copyWith(upcaseKatakana: true));
late DiscordRPC discordRpc;
late ObjectBox objectBox;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();
  DiscordRPC.initialize();
  discordRpc = DiscordRPC(applicationId: "1221903147396632638");
  discordRpc.start();
  runApp(const RootWidget());
}
