import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher }
enum TeachingMode { online, physical, both }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Common fields
  final String? phoneNumber;
  final String? city;
  final String? country;

  // Added for signup compatibility
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;

  // Teacher-specific fields
  final String? bio;
  final List<String>? subjects;
  final double? hourlyRate;
  final String? location;
  final TeachingMode? teachingMode;
  final int? yearsOfExperience;
  final double? rating;
  final bool? isAvailable;
  final bool? isOnlineAvailable;
  final bool? isPhysicalAvailable;
  final List<TeachingMode>? teachingModes;
  final List<String>? languages;
  final String? qualifications;
  final String? university;
  final String? degree;
  final String? specializations;
  final bool? isVerified;
  final int? totalReviews;

  // Student-specific fields
  final List<String>? interestedSubjects;
  final String? grade;
  final String? currentSchool;
  final String? studentEducationLevel;
  final List<String>? learningGoals;
  final String? preferredTeachingMode;
  final String? preferredSchedule;
  final double? budgetPerHour;
  final List<String>? preferredLanguages;
  final String? learningStyle;
  final String? currentAcademicLevel;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,

    // Common
    this.phoneNumber,
    this.city,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.address,

    // Teacher
    this.bio,
    this.subjects,
    this.hourlyRate,
    this.location,
    this.teachingMode,
    this.yearsOfExperience,
    this.rating,
    this.isAvailable,
    this.isOnlineAvailable,
    this.isPhysicalAvailable,
    this.teachingModes,
    this.languages,
    this.qualifications,
    this.university,
    this.degree,
    this.specializations,
    this.isVerified,
    this.totalReviews,

    // Student
    this.interestedSubjects,
    this.grade,
    this.currentSchool,
    this.studentEducationLevel,
    this.learningGoals,
    this.preferredTeachingMode,
    this.preferredSchedule,
    this.budgetPerHour,
    this.preferredLanguages,
    this.learningStyle,
    this.currentAcademicLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // Common
      'phoneNumber': phoneNumber,
      'city': city,
      'country': country,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'address': address,

      // Teacher
      'bio': bio,
      'subjects': subjects,
      'hourlyRate': hourlyRate,
      'location': location,
      'teachingMode': teachingMode?.toString().split('.').last,
      'yearsOfExperience': yearsOfExperience,
      'rating': rating,
      'isAvailable': isAvailable,
      'isOnlineAvailable': isOnlineAvailable,
      'isPhysicalAvailable': isPhysicalAvailable,
      'teachingModes': teachingModes?.map((e) => e.toString().split('.').last).toList(),
      'languages': languages,
      'qualifications': qualifications,
      'university': university,
      'degree': degree,
      'specializations': specializations,
      'isVerified': isVerified,
      'totalReviews': totalReviews,

      // Student
      'interestedSubjects': interestedSubjects,
      'grade': grade,
      'currentSchool': currentSchool,
      'studentEducationLevel': studentEducationLevel,
      'learningGoals': learningGoals,
      'preferredTeachingMode': preferredTeachingMode,
      'preferredSchedule': preferredSchedule,
      'budgetPerHour': budgetPerHour,
      'preferredLanguages': preferredLanguages,
      'learningStyle': learningStyle,
      'currentAcademicLevel': currentAcademicLevel,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.student,
      ),
      profileImageUrl: json['profileImageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // Common
      phoneNumber: json['phoneNumber'],
      city: json['city'],
      country: json['country'],
      dateOfBirth: (json['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: json['gender'],
      address: json['address'],

      // Teacher
      bio: json['bio'],
      subjects: json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      hourlyRate: (json['hourlyRate'] is num)
          ? (json['hourlyRate'] as num).toDouble()
          : null,
      location: json['location'],
      teachingMode: json['teachingMode'] != null
          ? TeachingMode.values.firstWhere(
              (e) => e.toString().split('.').last == json['teachingMode'],
              orElse: () => TeachingMode.online,
            )
          : null,
      yearsOfExperience: json['yearsOfExperience'],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      isAvailable: json['isAvailable'],
      isOnlineAvailable: json['isOnlineAvailable'],
      isPhysicalAvailable: json['isPhysicalAvailable'],
      teachingModes: json['teachingModes'] != null
          ? (json['teachingModes'] as List)
              .map((e) => TeachingMode.values.firstWhere(
                  (mode) => mode.toString().split('.').last == e,
                  orElse: () => TeachingMode.online))
              .toList()
          : null,
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      qualifications: json['qualifications'],
      university: json['university'],
      degree: json['degree'],
      specializations: json['specializations'],
      isVerified: json['isVerified'],
      totalReviews: json['totalReviews'],

      // Student
      interestedSubjects: json['interestedSubjects'] != null
          ? List<String>.from(json['interestedSubjects'])
          : null,
      grade: json['grade'],
      currentSchool: json['currentSchool'],
      studentEducationLevel: json['studentEducationLevel'],
      learningGoals:
          json['learningGoals'] != null ? List<String>.from(json['learningGoals']) : null,
      preferredTeachingMode: json['preferredTeachingMode'],
      preferredSchedule: json['preferredSchedule'],
      budgetPerHour: (json['budgetPerHour'] is num)
          ? (json['budgetPerHour'] as num).toDouble()
          : null,
      preferredLanguages: json['preferredLanguages'] != null
          ? List<String>.from(json['preferredLanguages'])
          : null,
      learningStyle: json['learningStyle'],
      currentAcademicLevel: json['currentAcademicLevel'],
    );
  }

  /// ✅ Fully compatible `copyWith()` method
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? city,
    String? country,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? bio,
    List<String>? subjects,
    double? hourlyRate,
    String? location,
    TeachingMode? teachingMode,
    int? yearsOfExperience,
    double? rating,
    bool? isAvailable,
    bool? isOnlineAvailable,
    bool? isPhysicalAvailable,
    List<TeachingMode>? teachingModes,
    List<String>? languages,
    String? qualifications,
    String? university,
    String? degree,
    String? specializations,
    bool? isVerified,
    int? totalReviews,
    List<String>? interestedSubjects,
    String? grade,
    String? currentSchool,
    String? studentEducationLevel,
    List<String>? learningGoals,
    String? preferredTeachingMode,
    String? preferredSchedule,
    double? budgetPerHour,
    List<String>? preferredLanguages,
    String? learningStyle,
    String? currentAcademicLevel,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      location: location ?? this.location,
      teachingMode: teachingMode ?? this.teachingMode,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnlineAvailable: isOnlineAvailable ?? this.isOnlineAvailable,
      isPhysicalAvailable: isPhysicalAvailable ?? this.isPhysicalAvailable,
      teachingModes: teachingModes ?? this.teachingModes,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      specializations: specializations ?? this.specializations,
      isVerified: isVerified ?? this.isVerified,
      totalReviews: totalReviews ?? this.totalReviews,
      interestedSubjects: interestedSubjects ?? this.interestedSubjects,
      grade: grade ?? this.grade,
      currentSchool: currentSchool ?? this.currentSchool,
      studentEducationLevel: studentEducationLevel ?? this.studentEducationLevel,
      learningGoals: learningGoals ?? this.learningGoals,
      preferredTeachingMode: preferredTeachingMode ?? this.preferredTeachingMode,
      preferredSchedule: preferredSchedule ?? this.preferredSchedule,
      budgetPerHour: budgetPerHour ?? this.budgetPerHour,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      learningStyle: learningStyle ?? this.learningStyle,
      currentAcademicLevel: currentAcademicLevel ?? this.currentAcademicLevel,
    );
  }
}
