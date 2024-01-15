import "package:jm_dict/jm_dict.dart";

import "./dict.dart";

class JMDictDictionary implements Dictionary {
  final JMDict jmDict = JMDict();
  @override
  Future<void> download() {
    return this.jmDict.initFromNetwork(forceUpdate: false);
  }

  @override
  List<DictEntry> searchFromENWord(String word) {
    // TODO: implement searchFromENWord
    throw UnimplementedError();
  }

  @override
  List<DictEntry> searchFromJPWord(String word) {
    // TODO: implement searchFromJPWord
    throw UnimplementedError();
  }
}
