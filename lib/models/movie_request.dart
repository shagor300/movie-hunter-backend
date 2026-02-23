import 'package:hive/hive.dart';

part 'movie_request.g.dart';

@HiveType(typeId: 10)
class MovieRequest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String movieName;

  @HiveField(2)
  final String? year;

  @HiveField(3)
  final String? language;

  @HiveField(4)
  final String? quality;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final DateTime requestedAt;

  @HiveField(7)
  String status; // pending, processing, completed, rejected

  MovieRequest({
    required this.id,
    required this.movieName,
    this.year,
    this.language,
    this.quality,
    this.note,
    required this.requestedAt,
    this.status = 'pending',
  });
}
