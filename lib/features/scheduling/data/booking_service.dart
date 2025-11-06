import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('bookings');

  Future<BookingModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return BookingModel.fromFirestore(doc.id, doc.data()!);
  }

  Stream<List<BookingModel>> watchForUser(String userId) {
    return _col
        .where('participants', arrayContains: userId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<bool> _hasConflict({
    required String tutorId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final statuses = ['pending', 'accepted'];
    final q = await _col
        .where('tutorId', isEqualTo: tutorId)
        .where('status', whereIn: statuses)
        .where('startAt', isLessThan: Timestamp.fromDate(endUtc))
        .get();
    for (final doc in q.docs) {
      final data = doc.data();
      final s = (data['startAt'] as Timestamp).toDate().toUtc();
      final e = (data['endAt'] as Timestamp).toDate().toUtc();
      final overlaps = s.isBefore(endUtc) && e.isAfter(startUtc);
      if (overlaps) return true;
    }
    return false;
  }

  Future<String> createRequest({
    required String initiatorId,
    required String studentId,
    required String tutorId,
    required String subject,
    required TeachingMode mode,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required int priceCents,
    String currency = 'USD',
  }) async {
    if (await _hasConflict(
      tutorId: tutorId,
      startUtc: startAtUtc,
      endUtc: endAtUtc,
    )) {
      throw Exception('Time slot is no longer available.');
    }

    final now = FieldValue.serverTimestamp();
    final requiresAcceptanceBy = initiatorId == tutorId ? studentId : tutorId;
    final doc = await _col.add({
      'studentId': studentId,
      'tutorId': tutorId,
      'participants': [studentId, tutorId],
      'subject': subject,
      'mode': mode.name,
      'startAt': Timestamp.fromDate(startAtUtc.toUtc()),
      'endAt': Timestamp.fromDate(endAtUtc.toUtc()),
      'status': BookingStatus.pending.name,
      'priceCents': priceCents,
      'currency': currency,
      'initiatorId': initiatorId,
      'requiresAcceptanceBy': requiresAcceptanceBy,
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

  Future<void> accept(String bookingId, String actorUserId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(bookingId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Booking not found');
      final data = snap.data()!;
      if ((data['requiresAcceptanceBy'] ?? '') != actorUserId) {
        throw Exception('Not authorized to accept');
      }
      final startUtc = (data['startAt'] as Timestamp).toDate().toUtc();
      final endUtc = (data['endAt'] as Timestamp).toDate().toUtc();
      final hasConflict = await _hasConflict(
        tutorId: (data['tutorId'] ?? '') as String,
        startUtc: startUtc,
        endUtc: endUtc,
      );
      if (hasConflict) throw Exception('Time slot now conflicts');
      tx.update(ref, {
        'status': BookingStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> decline(String bookingId, String actorUserId, {String? reason}) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    if ((snap['requiresAcceptanceBy'] ?? '') != actorUserId) {
      throw Exception('Not authorized to decline');
    }
    await ref.update({
      'status': BookingStatus.declined.name,
      if (reason != null) 'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancel(String bookingId, String actorUserId, {String? reason}) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    final participants = List<String>.from(snap['participants'] ?? []);
    if (!participants.contains(actorUserId)) throw Exception('Not authorized');
    await ref.update({
      'status': BookingStatus.cancelled.name,
      if (reason != null) 'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reschedule({
    required String bookingId,
    required String requesterId,
    required DateTime newStartUtc,
    required DateTime newEndUtc,
  }) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    final data = snap.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    if (!participants.contains(requesterId)) throw Exception('Not authorized');

    final tutorId = (data['tutorId'] ?? '') as String;
    if (await _hasConflict(tutorId: tutorId, startUtc: newStartUtc, endUtc: newEndUtc)) {
      throw Exception('New time conflicts with another booking');
    }
    await ref.update({
      'startAt': Timestamp.fromDate(newStartUtc.toUtc()),
      'endAt': Timestamp.fromDate(newEndUtc.toUtc()),
      'status': BookingStatus.pending.name, // require re-accept
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}


