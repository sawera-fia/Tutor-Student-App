import 'package:cloud_firestore/cloud_firestore.dart';
import 'availability_model.dart';

enum BookingStatus { pending, accepted, declined, cancelled, completed }

class BookingModel {
  final String id;
  final String studentId;
  final String tutorId;
  final String subject;
  final TeachingMode mode;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final BookingStatus status;
  final int priceCents;
  final String currency;
  final String? meetingProvider;
  final String? meetingId;
  final String? cancelReason;
  final String initiatorId; // who created the request
  final String requiresAcceptanceBy; // who must accept
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.subject,
    required this.mode,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.status,
    required this.priceCents,
    required this.currency,
    this.meetingProvider,
    this.meetingId,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  BookingModel copyWith({
    String? id,
    String? studentId,
    String? tutorId,
    String? subject,
    TeachingMode? mode,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    BookingStatus? status,
    int? priceCents,
    String? currency,
    String? meetingProvider,
    String? meetingId,
    String? cancelReason,
    String? initiatorId,
    String? requiresAcceptanceBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      subject: subject ?? this.subject,
      mode: mode ?? this.mode,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      status: status ?? this.status,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      meetingProvider: meetingProvider ?? this.meetingProvider,
      meetingId: meetingId ?? this.meetingId,
      cancelReason: cancelReason ?? this.cancelReason,
      initiatorId: initiatorId ?? this.initiatorId,
      requiresAcceptanceBy: requiresAcceptanceBy ?? this.requiresAcceptanceBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'tutorId': tutorId,
        'subject': subject,
        'mode': mode.name,
        'startAt': Timestamp.fromDate(startAtUtc.toUtc()),
        'endAt': Timestamp.fromDate(endAtUtc.toUtc()),
        'status': status.name,
        'priceCents': priceCents,
        'currency': currency,
        if (meetingProvider != null) 'meetingProvider': meetingProvider,
        if (meetingId != null) 'meetingId': meetingId,
        if (cancelReason != null) 'cancelReason': cancelReason,
        'initiatorId': initiatorId,
        'requiresAcceptanceBy': requiresAcceptanceBy,
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      };

  factory BookingModel.fromFirestore(String id, Map<String, dynamic> json) {
    final modeName = (json['mode'] ?? 'online') as String;
    final statusName = (json['status'] ?? 'pending') as String;
    return BookingModel(
      id: id,
      studentId: (json['studentId'] ?? '') as String,
      tutorId: (json['tutorId'] ?? '') as String,
      subject: (json['subject'] ?? '') as String,
      mode: modeName == 'physical' ? TeachingMode.physical : TeachingMode.online,
      startAtUtc:
          (json['startAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
      endAtUtc:
          (json['endAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => BookingStatus.pending,
      ),
      priceCents: (json['priceCents'] ?? 0) as int,
      currency: (json['currency'] ?? 'USD') as String,
      meetingProvider: json['meetingProvider'] as String?,
      meetingId: json['meetingId'] as String?,
      cancelReason: json['cancelReason'] as String?,
      initiatorId: (json['initiatorId'] ?? '') as String,
      requiresAcceptanceBy: (json['requiresAcceptanceBy'] ?? '') as String,
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
      updatedAt:
          (json['updatedAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc(),
    );
  }
}


