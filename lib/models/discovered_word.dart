import 'package:memofante/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

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
      (successReadingReviews as double) / (totalReadingReviews as double);
  double get successMeaningRate =>
      (successMeaningReviews as double) / (totalMeaningReviews as double);
  double get successRate =>
      (successReadingReviews as double) / (totalReadingReviews as double);

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
}
