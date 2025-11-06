import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection('ratings');

  /// Submit a rating for a tutor
  Future<String> submitRating({
    required String studentId,
    required String tutorId,
    required String bookingId,
    required int rating, // 1-5
    String? comment,
  }) async {
    // Check if rating already exists for this booking
    final existing = await _col
        .where('bookingId', isEqualTo: bookingId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    final now = FieldValue.serverTimestamp();
    String ratingId;

    if (existing.docs.isNotEmpty) {
      // Update existing rating
      ratingId = existing.docs.first.id;
      await _col.doc(ratingId).update({
        'rating': rating,
        if (comment != null) 'comment': comment,
        'updatedAt': now,
      });
    } else {
      // Create new rating
      final doc = await _col.add({
        'studentId': studentId,
        'tutorId': tutorId,
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
        'createdAt': now,
        'updatedAt': now,
      });
      ratingId = doc.id;
    }

    // Update tutor's average rating
    await _updateTutorRating(tutorId);

    // ignore: avoid_print
    print('[RatingService] Rating submitted: $ratingId');
    return ratingId;
  }

  /// Get all ratings for a tutor
  Stream<List<RatingModel>> watchRatingsForTutor(String tutorId) {
    return _col
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RatingModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Get rating for a specific booking
  Future<RatingModel?> getRatingForBooking(String bookingId, String studentId) async {
    final snap = await _col
        .where('bookingId', isEqualTo: bookingId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return RatingModel.fromFirestore(snap.docs.first.id, snap.docs.first.data());
  }

  /// Check if student has rated a booking
  Future<bool> hasRated(String bookingId, String studentId) async {
    final snap = await _col
        .where('bookingId', isEqualTo: bookingId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Update tutor's average rating and total reviews count
  Future<void> _updateTutorRating(String tutorId) async {
    final ratings = await _col
        .where('tutorId', isEqualTo: tutorId)
        .get();

    if (ratings.docs.isEmpty) {
      // No ratings, set to null
      await _firestore.collection('users').doc(tutorId).update({
        'rating': null,
        'totalReviews': 0,
      });
      return;
    }

    double sum = 0;
    for (final doc in ratings.docs) {
      sum += (doc.data()['rating'] ?? 5) as int;
    }

    final average = sum / ratings.docs.length;
    final totalReviews = ratings.docs.length;

    await _firestore.collection('users').doc(tutorId).update({
      'rating': average,
      'totalReviews': totalReviews,
    });

    // ignore: avoid_print
    print('[RatingService] Updated tutor $tutorId rating: $average ($totalReviews reviews)');
  }

  /// Delete a rating
  Future<void> deleteRating(String ratingId, String tutorId) async {
    await _col.doc(ratingId).delete();
    await _updateTutorRating(tutorId);
    // ignore: avoid_print
    print('[RatingService] Deleted rating: $ratingId');
  }
}

