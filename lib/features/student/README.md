# Student Dashboard

The Student Dashboard is a comprehensive interface for students to browse, search, and filter available tutors.

## Features

### 🎯 **Core Functionality**
- **Tutor Listings**: View all available tutors with detailed information
- **Search**: Search tutors by name, subject, or location
- **Advanced Filtering**: Filter by subject, hourly rate, teaching mode, and location
- **Dual View Modes**: Switch between list view and map view
- **Real-time Updates**: Live data from Firebase Firestore

### 🔍 **Filtering Options**
- **Subject**: Filter by specific subjects (Math, Science, English, etc.)
- **Hourly Rate**: Set maximum budget per hour ($10 - $200)
- **Teaching Mode**: Online, Physical, or Both
- **Location**: Filter by city or country
- **Distance**: Set maximum distance from current location (5-100 km)

### 📱 **User Interface**
- **Modern Design**: Clean, intuitive interface with Material Design 3
- **Responsive Layout**: Adapts to different screen sizes
- **Interactive Elements**: Smooth animations and transitions
- **Accessibility**: Proper contrast and readable text

## Architecture

### 📁 **File Structure**
```
lib/features/student/
├── application/
│   └── student_dashboard_state.dart    # State management
├── data/
│   └── student_dashboard_service.dart   # Data operations
├── presentation/
│   └── student_dashboard_screen.dart    # Main UI
├── widgets/
│   ├── tutor_card.dart                  # Individual tutor display
│   └── filter_bottom_sheet.dart        # Filter interface
└── index.dart                           # Exports
```

### 🏗️ **State Management**
- **Riverpod**: Modern state management solution
- **AsyncValue**: Handles loading, success, and error states
- **StateNotifier**: Manages dashboard state and operations

### 🔌 **Data Layer**
- **Firebase Firestore**: Real-time database integration
- **Query Optimization**: Efficient filtering and search
- **Error Handling**: Graceful error handling with user feedback

## Usage

### 🚀 **Basic Implementation**
```dart
import 'package:your_app/features/student/index.dart';

// Navigate to student dashboard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StudentDashboardScreen(),
  ),
);
```

### 🔧 **Customization**
The dashboard can be customized by:
- Modifying filter options in `FilterBottomSheet`
- Adjusting tutor card layout in `TutorCard`
- Customizing search logic in `StudentDashboardService`
- Updating UI themes and colors

### 📊 **Data Requirements**
Tutors must have the following fields in Firestore:
- `role`: Must be "teacher"
- `isAvailable`: Must be true
- `subjects`: Array of subjects they teach
- `hourlyRate`: Numeric hourly rate
- `city`/`country`: Location information
- `isOnlineAvailable`/`isPhysicalAvailable`: Teaching mode flags

## Future Enhancements

### 🗺️ **Map Integration**
- Google Maps integration for location-based search
- Real-time location tracking
- Distance calculations
- Interactive map markers

### 💬 **Communication Features**
- In-app messaging with tutors
- Video call integration
- Booking and scheduling system
- Review and rating system

### 📱 **Advanced Features**
- Push notifications
- Offline support
- Advanced analytics
- Multi-language support

## Dependencies

### 📦 **Required Packages**
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  cloud_firestore: ^4.0.0
  google_maps_flutter: ^2.5.0  # For future map integration
  geolocator: ^10.0.0          # For location services
  geocoding: ^2.1.0            # For address geocoding
```

## Contributing

When contributing to the Student Dashboard:

1. **Follow Flutter Best Practices**: Use proper widget structure and state management
2. **Maintain Code Quality**: Follow the existing code style and patterns
3. **Test Thoroughly**: Ensure all features work correctly on different devices
4. **Update Documentation**: Keep this README and code comments up to date
5. **Handle Errors Gracefully**: Implement proper error handling and user feedback

## Troubleshooting

### 🔧 **Common Issues**

**No tutors displayed:**
- Check if tutors have `role: "teacher"` and `isAvailable: true`
- Verify Firestore security rules allow reading user data
- Check network connectivity and Firebase configuration

**Filters not working:**
- Ensure tutor data has the required fields (subjects, hourlyRate, etc.)
- Check if the filter values match the data format in Firestore
- Verify the service methods are properly implemented

**Search not functioning:**
- Check if the search query is being passed correctly
- Verify the search logic in `StudentDashboardService`
- Ensure proper error handling for empty results

### 📱 **Performance Tips**

1. **Implement Pagination**: For large datasets, consider implementing pagination
2. **Cache Results**: Cache frequently accessed data to improve performance
3. **Optimize Queries**: Use Firestore indexes for complex queries
4. **Lazy Loading**: Load images and heavy content on demand

## License

This project follows the same license as the main application. Please refer to the main project's LICENSE file for details.

---

**Note**: This dashboard is designed to work with the existing authentication system and user models. Ensure proper integration with the main app's navigation and state management.
