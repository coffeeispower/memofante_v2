import 'package:objectbox/objectbox.dart';

@Entity()
class DiscoveredWord {
  @Id()
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

  DiscoveredWord({
    required this.entryNumber,
    required this.successMeaningReviews,
    required this.failedMeaningReviews,
    required this.successReadingReviews,
    required this.failedReadingReviews,
  });
}
