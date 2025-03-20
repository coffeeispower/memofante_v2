import 'package:memofante/objectbox.g.dart';
import "package:objectbox/objectbox.dart";

@Entity()
class DiscoveredWord {
  @Id()
  int id;
  @Unique()
  int entryNumber;

  int failedMeaningReviews;
  int failedReadingReviews;
  int get failedReviews => failedReadingReviews + failedMeaningReviews;

  int successMeaningReviews;
  int successReadingReviews;
  int get successReviews => successReadingReviews + successMeaningReviews;

  double get successReadingRate =>
      (successReadingReviews.toDouble()) / (totalReadingReviews.toDouble());
  double get successMeaningRate =>
      (successMeaningReviews.toDouble()) / (totalMeaningReviews.toDouble());

  double get failedReadingRate =>
      (failedReadingReviews.toDouble()) / (totalReadingReviews.toDouble());
  double get failedMeaningRate =>
      (failedMeaningReviews.toDouble()) / (totalMeaningReviews.toDouble());

  int get totalReadingReviews => successReadingReviews + failedReadingReviews;
  int get totalMeaningReviews => successMeaningReviews + failedMeaningReviews;
  int get totalReviews => totalReadingReviews + totalMeaningReviews;

  DateTime? lastReadingReview;
  DateTime? lastMeaningReview;
  DateTime? get lastReview {
    List<DateTime?> reviewDates = [lastReadingReview, lastMeaningReview];
    return reviewDates.where((date) => date != null).fold<DateTime?>(null,
        (maxDate, currentDate) {
      return maxDate == null || currentDate!.isAfter(maxDate)
          ? currentDate
          : maxDate;
    });
  }

  DiscoveredWord(
      {required this.entryNumber,
      required this.successMeaningReviews,
      required this.failedMeaningReviews,
      required this.successReadingReviews,
      required this.failedReadingReviews,
      this.id = 0});

  static DiscoveredWord? lookupFromEntryNumber(
      {required Box<DiscoveredWord> box, required int entryNumber}) {
    return box
        .query(DiscoveredWord_.entryNumber.equals(entryNumber))
        .build()
        .findUnique();
  }

  Map<String, dynamic> toJson() {
    return {
      'entryNumber': entryNumber,
      'failedMeaningReviews': failedMeaningReviews,
      'failedReadingReviews': failedReadingReviews,
      'successMeaningReviews': successMeaningReviews,
      'successReadingReviews': successReadingReviews,
      'lastReadingReview': lastReadingReview?.toIso8601String(),
      'lastMeaningReview': lastMeaningReview?.toIso8601String(),
    };
  }

  factory DiscoveredWord.fromJson(Map<String, dynamic> json) {
    return DiscoveredWord(
      entryNumber: json['entryNumber'] as int,
      successMeaningReviews: json['successMeaningReviews'] as int,
      failedMeaningReviews: json['failedMeaningReviews'] as int,
      successReadingReviews: json['successReadingReviews'] as int,
      failedReadingReviews: json['failedReadingReviews'] as int,
    )
      ..lastReadingReview = json['lastReadingReview'] != null
          ? DateTime.parse(json['lastReadingReview'] as String)
          : null
      ..lastMeaningReview = json['lastMeaningReview'] != null
          ? DateTime.parse(json['lastMeaningReview'] as String)
          : null;
  }
}
