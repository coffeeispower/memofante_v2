import 'dart:convert';

import 'package:memofante/models/discovered_word.dart';
import 'package:objectbox/objectbox.dart';
import 'package:memofante/objectbox.g.dart';

@Entity()
class Transaction {
  @Id()
  int id;
  String type;
  DateTime date;
  String? wordJson;
  int? entryNumber;

  Transaction({
    this.id = 0,
    required this.type,
    required this.date,
    this.wordJson,
    this.entryNumber,
  });

  factory Transaction.addWord({
    required DiscoveredWord word,
    required DateTime date,
  }) {
    return Transaction(
      type: "add_word",
      date: date,
      wordJson: jsonEncode(word.toJson()),
    );
  }

  factory Transaction.removeWord({
    required int entryNumber,
    required DateTime date,
  }) {
    return Transaction(
      type: "remove_word",
      date: date,
      entryNumber: entryNumber,
    );
  }
  static void registerAddWord(Box<Transaction> box, DiscoveredWord word) =>
      box.put(Transaction.addWord(word: word, date: DateTime.now()));

  static void registerRemoveWord(Box<Transaction> box, int entryNumber) =>
      box.put(Transaction.removeWord(
          entryNumber: entryNumber, date: DateTime.now()));

  static List<Transaction> fetchAllTransactions(Box<Transaction> box) =>
      box.getAll();
  static void flushTransactions(Box<Transaction> box) => box.removeAll();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
    };
    if (type == "add_word") {
      if (wordJson != null) {
        try {
          data['word'] = jsonDecode(wordJson!);
        } catch (_) {
          data['word'] = null;
        }
      }
    } else if (type == "remove_word") {
      data['entryNumber'] = entryNumber;
    }
    return data;
  }
}
