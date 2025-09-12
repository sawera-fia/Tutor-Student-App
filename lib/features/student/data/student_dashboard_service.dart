import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_model.dart';

class StudentDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all available tutors (relaxed query to match single 'users' collection)
  Future<List<UserModel>> getAvailableTutors() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting available tutors: $e');
      throw Exception('Failed to load tutors: $e');
    }
  }

  // Get filtered tutors based on criteria (tolerant of missing fields)
  Future<List<UserModel>> getFilteredTutors({
    String? subject,
    double? maxHourlyRate,
    String? teachingMode,
    String? location,
    double? maxDistance,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher');

      // Apply basic Firestore-side filters that are likely indexed
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subjects', arrayContains: subject);
      }

      if (maxHourlyRate != null) {
        query = query.where('hourlyRate', isLessThanOrEqualTo: maxHourlyRate);
      }

      final QuerySnapshot snapshot = await query.get();
      List<UserModel> tutors = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side filters for optional/nullable fields
      if (teachingMode != null && teachingMode.isNotEmpty) {
        final mode = teachingMode.toLowerCase();
        tutors = tutors.where((tutor) {
          final online = tutor.isOnlineAvailable == true;
          final physical = tutor.isPhysicalAvailable == true;
          if (mode == 'online') return online;
          if (mode == 'physical') return physical;
          return online && physical; // both
        }).toList();
      }

      if (location != null && location.isNotEmpty) {
        final search = location.toLowerCase();
        tutors = tutors.where((tutor) {
          final city = (tutor.city ?? '').toLowerCase();
          final country = (tutor.country ?? '').toLowerCase();
          return city.contains(search) || country.contains(search);
        }).toList();
      }

      // TODO: Apply distance filtering once coordinates are available

      return tutors;
    } catch (e) {
      print('Error getting filtered tutors: $e');
      throw Exception('Failed to load filtered tutors: $e');
    }
  }

  // Search tutors by name, subject, or location
  Future<List<UserModel>> searchTutors(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAvailableTutors();
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      final List<UserModel> allTutors = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      final String searchQuery = query.toLowerCase();

      return allTutors.where((tutor) {
        if (tutor.name.toLowerCase().contains(searchQuery)) return true;

        if (tutor.subjects != null) {
          for (String subject in tutor.subjects!) {
            if (subject.toLowerCase().contains(searchQuery)) return true;
          }
        }

        if (tutor.city?.toLowerCase().contains(searchQuery) == true)
          return true;
        if (tutor.country?.toLowerCase().contains(searchQuery) == true)
          return true;
        if (tutor.bio?.toLowerCase().contains(searchQuery) == true) return true;

        return false;
      }).toList();
    } catch (e) {
      print('Error searching tutors: $e');
      throw Exception('Failed to search tutors: $e');
    }
  }

  // Get tutor by ID
  Future<UserModel?> getTutorById(String tutorId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(tutorId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting tutor by ID: $e');
      throw Exception('Failed to get tutor: $e');
    }
  }
}
