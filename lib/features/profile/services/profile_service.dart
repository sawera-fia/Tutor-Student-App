import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update user profile data
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? city,
    String? country,
    List<String>? subjects,
    double? hourlyRate,
    int? yearsOfExperience,
    List<String>? teachingModes,
    String? profileImageUrl,
  }) async {
    try {
      print('🔄 [ProfileService] Starting profile update for user: $userId');

      final updateData = <String, dynamic>{};

      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (bio != null && bio.isNotEmpty) updateData['bio'] = bio;
      if (city != null && city.isNotEmpty) updateData['city'] = city;
      if (country != null && country.isNotEmpty)
        updateData['country'] = country;
      if (subjects != null && subjects.isNotEmpty) {
        // Remove duplicates and update
        updateData['subjects'] = subjects.toSet().toList();
        print(
          '📚 [ProfileService] Subjects to save: ${updateData['subjects']}',
        );
      }
      if (hourlyRate != null && hourlyRate > 0)
        updateData['hourlyRate'] = hourlyRate;
      if (yearsOfExperience != null && yearsOfExperience >= 0)
        updateData['yearsOfExperience'] = yearsOfExperience;
      if (teachingModes != null && teachingModes.isNotEmpty) {
        // Remove duplicates and convert to string format for Firebase
        final uniqueModes = teachingModes.toSet().toList();
        updateData['teachingModes'] = uniqueModes;
        print(
          '🎓 [ProfileService] Teaching modes to save: ${updateData['teachingModes']}',
        );
      }
      if (profileImageUrl != null && profileImageUrl.isNotEmpty)
        updateData['profileImageUrl'] = profileImageUrl;

      // Use DateTime.now() instead of FieldValue.serverTimestamp() to avoid type issues
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      print('📝 [ProfileService] Update data: $updateData');

      // Check if document exists first
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('User document does not exist');
      }

      print('🧹 [ProfileService] Raw data: $updateData');

      try {
        await docRef.update(updateData);
        print(
          '✅ [ProfileService] Profile updated successfully for user: $userId',
        );
      } catch (updateError) {
        print('❌ [ProfileService] Update error: $updateError');
        print('❌ [ProfileService] Failed data: $updateData');

        // Try to identify the problematic field
        for (final entry in updateData.entries) {
          try {
            await docRef.update({entry.key: entry.value});
            print('✅ [ProfileService] Field "${entry.key}" is valid');
          } catch (fieldError) {
            print(
              '❌ [ProfileService] Field "${entry.key}" with value "${entry.value}" (${entry.value.runtimeType}) is causing error: $fieldError',
            );
          }
        }

        rethrow;
      }
    } catch (e) {
      print('❌ [ProfileService] Error updating profile: $e');
      rethrow;
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final userModel = UserModel.fromJson({
        ...data,
        'id': user.uid,
        'email': user.email ?? '',
        'createdAt': data['createdAt'] ?? Timestamp.fromDate(DateTime.now()),
        'updatedAt': data['updatedAt'] ?? Timestamp.fromDate(DateTime.now()),
        'role': data['role'] ?? 'student',
      });

      return userModel;
    } catch (e) {
      print('❌ [ProfileService] Error getting user profile: $e');
      return null;
    }
  }

  /// Update user's display name in Firebase Auth
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        print('✅ [ProfileService] Display name updated in Firebase Auth');
      }
    } catch (e) {
      print('❌ [ProfileService] Error updating display name: $e');
      rethrow;
    }
  }

  /// Get available subjects list (you can customize this)
  List<String> getAvailableSubjects() {
    return [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'English',
      'History',
      'Geography',
      'Computer Science',
      'Economics',
      'Business Studies',
      'Art',
      'Music',
      'Physical Education',
      'Psychology',
      'Sociology',
      'Political Science',
      'Literature',
      'Philosophy',
      'Statistics',
      'Engineering',
    ];
  }

  /// Get available teaching modes
  List<String> getAvailableTeachingModes() {
    return ['Online', 'Physical', 'Hybrid'];
  }
}
