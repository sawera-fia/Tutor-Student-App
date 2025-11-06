import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/availability_model.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('availability');

  Future<AvailabilityModel?> getForTutor(String tutorId) async {
    final doc = await _col.doc(tutorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AvailabilityModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> upsert(AvailabilityModel model) async {
    final now = DateTime.now().toUtc();
    final data = model.copyWith(updatedAt: now).toJson();
    await _col.doc(model.id).set({
      ...data,
      'tutorId': model.tutorId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateWeeklyBlocks(
    String tutorId,
    List<WeeklyAvailabilityBlock> blocks,
  ) async {
    await _col.doc(tutorId).set({
      'weeklyBlocks': blocks.map((b) => b.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setTimezone(String tutorId, String timezone) async {
    await _col.doc(tutorId).set({
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setModes(String tutorId, List<TeachingMode> modes) async {
    await _col.doc(tutorId).set({
      'modes': modes.map((m) => m.name).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setExceptions(
    String tutorId,
    List<AvailabilityException> exceptions,
  ) async {
    await _col.doc(tutorId).set({
      'exceptions': exceptions.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}


