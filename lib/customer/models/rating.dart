// lib/models/rating.dart
class Rating {
  final double rate;
  final int count;

  Rating({required this.rate, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    rate: (json['rate'] as num).toDouble(),
    count: json['count'] as int,
  );
}
