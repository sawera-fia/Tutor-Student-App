import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String studentId;
  final String tutorId;
  final String bookingId; // The session this rating is for
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RatingModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'tutorId': tutorId,
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      };

  factory RatingModel.fromFirestore(String id, Map<String, dynamic> json) {
    return RatingModel(
      id: id,
      studentId: (json['studentId'] ?? '') as String,
      tutorId: (json['tutorId'] ?? '') as String,
      bookingId: (json['bookingId'] ?? '') as String,
      rating: (json['rating'] ?? 5) as int,
      comment: json['comment'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
    );
  }

  RatingModel copyWith({
    String? id,
    String? studentId,
    String? tutorId,
    String? bookingId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

