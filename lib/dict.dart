import 'jm_dict_impl.dart';

class DictEntry {
  /// The ID of this entry, it is unique to this entry,
  /// so if you need to check for word uniqueness, use this id instead of the `word` field.
  final int id;

  /// Reading of this word in かな
  final List<String> readings;

  /// Word with 漢字
  final List<String> word;

  /// Meanings of this word
  final List<List<String>> meanings;

  /// Whether this word appears more frequently in かな than in 漢字
  final bool onlyKana;

  /// A score of the frequency of this word
  ///
  /// If it is `null`, the frequency will be completely ignored when calculating the review score
  final int? frequency;
  const DictEntry(
      {required this.id,
      required this.word,
      required this.meanings,
      required this.readings,
      required this.onlyKana,
      this.frequency});
}

abstract class Dictionary {
  Future<void> download();
  List<DictEntry> searchFromJPWord(String word);
  List<DictEntry> searchFromENWord(String word);
  DictEntry? searchEntryFromId(int id);
}

final Dictionary dictionary = JMDictDictionary();
