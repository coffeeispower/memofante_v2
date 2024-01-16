import 'package:flutter/material.dart';
import 'package:memofante/models/store.dart';
import 'package:memofante/pages/root_widget.dart';

late ObjectBox objectBox;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();
  runApp(const RootWidget());
}
