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
    return (jmDict.search(keyword: word) ?? [])
        .map((entry) => fromJmDictEntry(entry))
        .toList();
  }

  @override
  DictEntry? searchEntryFromId(int id) {
    final entry = jmDict.searchById(id);
    if (entry == null) {
      return null;
    }

    return fromJmDictEntry(entry);
  }
}

List<ReadingElement> readingElementsSortedByPriority(JMDictEntry entry) {
  var readingElements = entry.readingElements.toList();
  readingElements.sort((e1, e2) =>
      (e1.frequencyOfUseRanking ?? 0).compareTo(e2.frequencyOfUseRanking ?? 0));
  return readingElements;
}

DictEntry fromJmDictEntry(JMDictEntry entry) {
  return DictEntry(
      id: entry.entrySequence,
      word: (entry.kanjiElements ?? {})
          .map((kanjiElement) => kanjiElement.element)
          .toList(),
      meanings: entry.senseElements
          .map((sense) => sense.glossaries
              .where((glossary) =>
                  glossary.language == SenseLanguage.eng &&
                  glossary.text.isNotEmpty)
              .map((e) => e.text)
              .toList())
          .where((element) => element.isNotEmpty)
          .toList(),
      readings: readingElementsSortedByPriority(entry)
          .map((element) => element.element)
          .toList(),
      onlyKana: entry.senseElements.any((element) =>
          (element.information ?? {}).any((element) => element == "uk")));
}
