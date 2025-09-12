import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedSubject;
  final double? maxHourlyRate;
  final String? selectedTeachingMode;
  final String? selectedLocation;
  final double? maxDistance;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    this.selectedSubject,
    this.maxHourlyRate,
    this.selectedTeachingMode,
    this.selectedLocation,
    this.maxDistance,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedSubject;
  double? _maxHourlyRate;
  String? _selectedTeachingMode;
  String? _selectedLocation;
  double? _maxDistance;

  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'History', 'Geography',
    'Physics', 'Chemistry', 'Biology', 'Computer Science', 'Literature'
  ];

  final List<String> _teachingModes = ['Online', 'Physical', 'Both'];

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.selectedSubject;
    _maxHourlyRate = widget.maxHourlyRate;
    _selectedTeachingMode = widget.selectedTeachingMode;
    _selectedLocation = widget.selectedLocation;
    _maxDistance = widget.maxDistance;
  }

  void _applyFilters() {
    widget.onApplyFilters({
      'subject': _selectedSubject,
      'maxHourlyRate': _maxHourlyRate,
      'teachingMode': _selectedTeachingMode,
      'location': _selectedLocation,
      'maxDistance': _maxDistance,
    });
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedSubject = null;
      _maxHourlyRate = null;
      _selectedTeachingMode = null;
      _selectedLocation = null;
      _maxDistance = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Tutors',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject filter
                  _buildSectionTitle('Subject'),
                  _buildSubjectFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Hourly rate filter
                  _buildSectionTitle('Maximum Hourly Rate'),
                  _buildHourlyRateFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Teaching mode filter
                  _buildSectionTitle('Teaching Mode'),
                  _buildTeachingModeFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Location filter
                  _buildSectionTitle('Location'),
                  _buildLocationFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Distance filter
                  _buildSectionTitle('Maximum Distance (km)'),
                  _buildDistanceFilter(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _subjects.map((subject) {
        final isSelected = _selectedSubject == subject;
        return FilterChip(
          label: Text(subject),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedSubject = selected ? subject : null;
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildHourlyRateFilter() {
    return Column(
      children: [
        if (_maxHourlyRate != null)
          Text(
            '\$${_maxHourlyRate!.toStringAsFixed(0)}/hour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        Slider(
          value: _maxHourlyRate ?? 100,
          min: 10,
          max: 200,
          divisions: 19,
          label: '\$${(_maxHourlyRate ?? 100).toStringAsFixed(0)}',
          onChanged: (value) {
            setState(() {
              _maxHourlyRate = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$10', style: TextStyle(color: Colors.grey[600])),
            Text('\$200', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildTeachingModeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _teachingModes.map((mode) {
        final isSelected = _selectedTeachingMode == mode;
        return FilterChip(
          label: Text(mode),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTeachingMode = selected ? mode : null;
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildLocationFilter() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Enter city or country',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        setState(() {
          _selectedLocation = value.isEmpty ? null : value;
        });
      },
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      children: [
        if (_maxDistance != null)
          Text(
            '${_maxDistance!.toStringAsFixed(0)} km',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        Slider(
          value: _maxDistance ?? 50,
          min: 5,
          max: 100,
          divisions: 19,
          label: '${(_maxDistance ?? 50).toStringAsFixed(0)} km',
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 km', style: TextStyle(color: Colors.grey[600])),
            Text('100 km', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}
