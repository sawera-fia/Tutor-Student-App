import '../../../shared/models/user_model.dart';

class LocationService {
  static LocationService? _instance;
  LocationService._internal();

  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  /// Get a simple address string for a tutor
  String getTutorAddress(UserModel tutor) {
    final List<String> addressParts = [];

    if (tutor.address != null && tutor.address!.trim().isNotEmpty) {
      addressParts.add(tutor.address!.trim());
    }
    if (tutor.city != null && tutor.city!.trim().isNotEmpty) {
      addressParts.add(tutor.city!.trim());
    }
    if (tutor.country != null && tutor.country!.trim().isNotEmpty) {
      addressParts.add(tutor.country!.trim());
    }

    return addressParts.join(', ');
  }

  /// Check if tutor has location information
  bool hasLocationInfo(UserModel tutor) {
    return (tutor.address?.trim().isNotEmpty == true) ||
        (tutor.city?.trim().isNotEmpty == true) ||
        (tutor.country?.trim().isNotEmpty == true);
  }
}
