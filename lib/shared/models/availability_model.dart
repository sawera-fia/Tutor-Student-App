import 'package:cloud_firestore/cloud_firestore.dart';

enum TeachingMode { online, physical }

class WeeklyAvailabilityBlock {
  final int weekday; // 0=Mon ... 6=Sun
  final String startTime; // "HH:mm" in tutor's timezone
  final String endTime; // "HH:mm" in tutor's timezone
  final int bufferMinutes;

  const WeeklyAvailabilityBlock({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.bufferMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'startTime': startTime,
        'endTime': endTime,
        'bufferMinutes': bufferMinutes,
      };

  factory WeeklyAvailabilityBlock.fromJson(Map<String, dynamic> json) {
    return WeeklyAvailabilityBlock(
      weekday: (json['weekday'] ?? 0) as int,
      startTime: (json['startTime'] ?? '00:00') as String,
      endTime: (json['endTime'] ?? '00:00') as String,
      bufferMinutes: (json['bufferMinutes'] ?? 0) as int,
    );
  }
}

class AvailabilityException {
  final DateTime date; // UTC calendar date
  final bool isBlocked; // fully blocked day
  final String? overrideStart; // optional "HH:mm" local
  final String? overrideEnd; // optional "HH:mm" local

  const AvailabilityException({
    required this.date,
    required this.isBlocked,
    this.overrideStart,
    this.overrideEnd,
  });

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
        'isBlocked': isBlocked,
        if (overrideStart != null) 'overrideStart': overrideStart,
        if (overrideEnd != null) 'overrideEnd': overrideEnd,
      };

  factory AvailabilityException.fromJson(Map<String, dynamic> json) {
    final ts = json['date'] as Timestamp?;
    return AvailabilityException(
      date: ts?.toDate().toUtc() ?? DateTime.now().toUtc(),
      isBlocked: (json['isBlocked'] ?? false) as bool,
      overrideStart: json['overrideStart'] as String?,
      overrideEnd: json['overrideEnd'] as String?,
    );
  }
}

class AvailabilityModel {
  final String id; // tutorId as doc id
  final String tutorId;
  final String timezone; // IANA TZ name e.g., "America/New_York"
  final List<WeeklyAvailabilityBlock> weeklyBlocks;
  final List<AvailabilityException> exceptions;
  final List<TeachingMode> modes; // online/physical
  final DateTime createdAt;
  final DateTime updatedAt;

  const AvailabilityModel({
    required this.id,
    required this.tutorId,
    required this.timezone,
    required this.weeklyBlocks,
    required this.exceptions,
    required this.modes,
    required this.createdAt,
    required this.updatedAt,
  });

  AvailabilityModel copyWith({
    String? id,
    String? tutorId,
    String? timezone,
    List<WeeklyAvailabilityBlock>? weeklyBlocks,
    List<AvailabilityException>? exceptions,
    List<TeachingMode>? modes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      timezone: timezone ?? this.timezone,
      weeklyBlocks: weeklyBlocks ?? this.weeklyBlocks,
      exceptions: exceptions ?? this.exceptions,
      modes: modes ?? this.modes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'tutorId': tutorId,
        'timezone': timezone,
        'weeklyBlocks': weeklyBlocks.map((b) => b.toJson()).toList(),
        'exceptions': exceptions.map((e) => e.toJson()).toList(),
        'modes': modes.map((m) => m.name).toList(),
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      };

  factory AvailabilityModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    final blocks = (json['weeklyBlocks'] as List<dynamic>? ?? [])
        .map((e) => WeeklyAvailabilityBlock.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
    final exc = (json['exceptions'] as List<dynamic>? ?? [])
        .map((e) => AvailabilityException.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
    final List<String> modeNames = List<String>.from(json['modes'] ?? []);
    final modes = modeNames
        .map((n) => n == 'physical' ? TeachingMode.physical : TeachingMode.online)
        .toList();
    return AvailabilityModel(
      id: id,
      tutorId: (json['tutorId'] ?? '') as String,
      timezone: (json['timezone'] ?? 'UTC') as String,
      weeklyBlocks: blocks,
      exceptions: exc,
      modes: modes,
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
      updatedAt:
          (json['updatedAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
    );
  }
}


