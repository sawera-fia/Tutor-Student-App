import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher }
enum TeachingMode { online, physical, both }
enum EducationLevel { primary, secondary, highSchool, university, graduate }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Common fields for both roles
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? country;
  final String? timezone;

  // Teacher-specific fields
  final String? bio;
  final List<String>? subjects;
  final double? hourlyRate;
  final String? location;
  final bool? isOnlineAvailable;
  final bool? isPhysicalAvailable;
  final List<TeachingMode>? teachingModes;
  final List<String>? availableTimeSlots;
  final String? experience;
  final List<String>? qualifications;
  final List<String>? certifications;
  final String? teacherEducationLevel; // Renamed to avoid conflict
  final String? university;
  final String? degree;
  final int? yearsOfExperience;
  final List<String>? languages;
  final String? specializations;
  final double? rating;
  final int? totalReviews;
  final bool? isVerified;
  final bool? isAvailable;

  // Student-specific fields
  final List<String>? interestedSubjects;
  final String? grade;
  final String? currentSchool;
  final String? studentEducationLevel; // Renamed to avoid conflict
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
    
    // Common fields
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.country,
    this.timezone,
    
    // Teacher fields
    this.bio,
    this.subjects,
    this.hourlyRate,
    this.location,
    this.isOnlineAvailable,
    this.isPhysicalAvailable,
    this.teachingModes,
    this.availableTimeSlots,
    this.experience,
    this.qualifications,
    this.certifications,
    this.teacherEducationLevel,
    this.university,
    this.degree,
    this.yearsOfExperience,
    this.languages,
    this.specializations,
    this.rating,
    this.totalReviews,
    this.isVerified,
    this.isAvailable,
    
    // Student fields
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
      
      // Common fields
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'address': address,
      'city': city,
      'country': country,
      'timezone': timezone,
      
      // Teacher fields
      'bio': bio,
      'subjects': subjects,
      'hourlyRate': hourlyRate,
      'location': location,
      'isOnlineAvailable': isOnlineAvailable,
      'isPhysicalAvailable': isPhysicalAvailable,
      'teachingModes': teachingModes?.map((e) => e.toString().split('.').last).toList(),
      'availableTimeSlots': availableTimeSlots,
      'experience': experience,
      'qualifications': qualifications,
      'certifications': certifications,
      'teacherEducationLevel': teacherEducationLevel,
      'university': university,
      'degree': degree,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
      'specializations': specializations,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      
      // Student fields
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
      
      // Common fields
      phoneNumber: json['phoneNumber'],
      dateOfBirth: (json['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: json['gender'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      timezone: json['timezone'],
      
      // Teacher fields
      bio: json['bio'],
      subjects: json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      hourlyRate: json['hourlyRate']?.toDouble(),
      location: json['location'],
      isOnlineAvailable: json['isOnlineAvailable'],
      isPhysicalAvailable: json['isPhysicalAvailable'],
      teachingModes: json['teachingModes'] != null 
          ? (json['teachingModes'] as List).map((e) => TeachingMode.values.firstWhere(
              (mode) => mode.toString().split('.').last == e,
              orElse: () => TeachingMode.online,
            )).toList()
          : null,
      availableTimeSlots: json['availableTimeSlots'] != null 
          ? List<String>.from(json['availableTimeSlots']) 
          : null,
      experience: json['experience'],
      qualifications: json['qualifications'] != null ? List<String>.from(json['qualifications']) : null,
      certifications: json['certifications'] != null ? List<String>.from(json['certifications']) : null,
      teacherEducationLevel: json['teacherEducationLevel'],
      university: json['university'],
      degree: json['degree'],
      yearsOfExperience: json['yearsOfExperience'],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      specializations: json['specializations'],
      rating: json['rating']?.toDouble(),
      totalReviews: json['totalReviews'],
      isVerified: json['isVerified'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
      
      // Student fields
      interestedSubjects: json['interestedSubjects'] != null 
          ? List<String>.from(json['interestedSubjects']) 
          : null,
      grade: json['grade'],
      currentSchool: json['currentSchool'],
      studentEducationLevel: json['studentEducationLevel'],
      learningGoals: json['learningGoals'] != null ? List<String>.from(json['learningGoals']) : null,
      preferredTeachingMode: json['preferredTeachingMode'],
      preferredSchedule: json['preferredSchedule'],
      budgetPerHour: json['budgetPerHour']?.toDouble(),
      preferredLanguages: json['preferredLanguages'] != null ? List<String>.from(json['preferredLanguages']) : null,
      learningStyle: json['learningStyle'],
      currentAcademicLevel: json['currentAcademicLevel'],
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Common fields
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? country,
    String? timezone,
    
    // Teacher fields
    String? bio,
    List<String>? subjects,
    double? hourlyRate,
    String? location,
    bool? isOnlineAvailable,
    bool? isPhysicalAvailable,
    List<TeachingMode>? teachingModes,
    List<String>? availableTimeSlots,
    String? experience,
    List<String>? qualifications,
    List<String>? certifications,
    String? teacherEducationLevel,
    String? university,
    String? degree,
    int? yearsOfExperience,
    List<String>? languages,
    String? specializations,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    bool? isAvailable,
    
    // Student fields
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
      
      // Common fields
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      
      // Teacher fields
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      location: location ?? this.location,
      isOnlineAvailable: isOnlineAvailable ?? this.isOnlineAvailable,
      isPhysicalAvailable: isPhysicalAvailable ?? this.isPhysicalAvailable,
      teachingModes: teachingModes ?? this.teachingModes,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      certifications: certifications ?? this.certifications,
      teacherEducationLevel: teacherEducationLevel ?? this.teacherEducationLevel,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      
      // Student fields
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