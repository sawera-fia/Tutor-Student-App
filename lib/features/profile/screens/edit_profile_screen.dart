import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  List<String> _selectedSubjects = [];
  List<String> _selectedTeachingModes = [];
  List<String> _availableSubjects = [];
  List<String> _availableTeachingModes = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _availableSubjects = _profileService.getAvailableSubjects();
    _availableTeachingModes = _profileService.getAvailableTeachingModes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _hourlyRateController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      print('🔄 [EditProfile] Loading user profile...');
      final user = await _profileService.getCurrentUserProfile();
      if (user != null) {
        print(
          '✅ [EditProfile] Profile loaded successfully: ${user.name} (${user.role})',
        );
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _bioController.text = user.bio ?? '';
          _cityController.text = user.city ?? '';
          _countryController.text = user.country ?? '';
          _hourlyRateController.text = user.hourlyRate?.toString() ?? '';
          _yearsOfExperienceController.text =
              user.yearsOfExperience?.toString() ?? '';
          _selectedSubjects = List<String>.from(user.subjects ?? []);
          _selectedTeachingModes =
              user.teachingModes
                  ?.map((e) => e.toString().split('.').last)
                  .toList() ??
              [];
        });
      } else {
        print('❌ [EditProfile] No user profile found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No profile found. Please try logging in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [EditProfile] Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 [EditProfile] Starting profile update for user: ${user.uid}');

      await _profileService.updateProfile(
        userId: user.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        subjects: _selectedSubjects.isEmpty ? null : _selectedSubjects,
        hourlyRate: _hourlyRateController.text.trim().isEmpty
            ? null
            : double.tryParse(_hourlyRateController.text.trim()),
        yearsOfExperience: _yearsOfExperienceController.text.trim().isEmpty
            ? null
            : int.tryParse(_yearsOfExperienceController.text.trim()),
        teachingModes: _selectedTeachingModes.isEmpty
            ? null
            : _selectedTeachingModes,
      );

      print('✅ [EditProfile] Profile updated successfully');

      // Update display name in Firebase Auth
      try {
        await _profileService.updateDisplayName(_nameController.text.trim());
        print('✅ [EditProfile] Display name updated in Firebase Auth');
      } catch (e) {
        print('⚠️ [EditProfile] Warning: Could not update display name: $e');
        // Don't fail the entire operation for this
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Use GoRouter to navigate back based on user role
        print('🔄 [EditProfile] Navigating back to dashboard');
        try {
          if (_currentUser?.role == UserRole.teacher) {
            context.go('/tutor-dashboard');
          } else {
            context.go('/student-dashboard');
          }
        } catch (e) {
          print('⚠️ [EditProfile] Navigation error, using fallback: $e');
          // Fallback navigation
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      print('❌ [EditProfile] Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSubjectSelector() {
    // Create a copy of selected subjects for the dialog
    List<String> tempSelectedSubjects = List.from(_selectedSubjects);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Subjects'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableSubjects.length,
              itemBuilder: (context, index) {
                final subject = _availableSubjects[index];
                final isSelected = tempSelectedSubjects.contains(subject);

                return CheckboxListTile(
                  title: Text(subject),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        if (!tempSelectedSubjects.contains(subject)) {
                          tempSelectedSubjects.add(subject);
                        }
                      } else {
                        tempSelectedSubjects.remove(subject);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubjects = List.from(tempSelectedSubjects);
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeachingModeSelector() {
    // Create a copy of selected teaching modes for the dialog
    List<String> tempSelectedModes = List.from(_selectedTeachingModes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Teaching Modes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableTeachingModes.length,
              itemBuilder: (context, index) {
                final mode = _availableTeachingModes[index];
                final isSelected = tempSelectedModes.contains(mode);

                return CheckboxListTile(
                  title: Text(mode),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        if (!tempSelectedModes.contains(mode)) {
                          tempSelectedModes.add(mode);
                        }
                      } else {
                        tempSelectedModes.remove(mode);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTeachingModes = List.from(tempSelectedModes);
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text('Error loading profile')));
    }

    final isTutor = _currentUser!.role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Location
              _buildSectionTitle('Location'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                    ),
                  ),
                ],
              ),

              if (isTutor) ...[
                const SizedBox(height: 24),

                // Tutor-specific fields
                _buildSectionTitle('Teaching Information'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (USD)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final rate = double.tryParse(value.trim());
                      if (rate == null || rate < 0) {
                        return 'Please enter a valid hourly rate';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _yearsOfExperienceController,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final years = int.tryParse(value.trim());
                      if (years == null || years < 0) {
                        return 'Please enter a valid number of years';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Subjects
                InkWell(
                  onTap: _showSubjectSelector,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.subject),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Subjects'),
                              if (_selectedSubjects.isEmpty)
                                const Text(
                                  'Tap to select subjects',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                Text(
                                  _selectedSubjects.join(', '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Teaching Modes
                InkWell(
                  onTap: _showTeachingModeSelector,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Teaching Modes'),
                              if (_selectedTeachingModes.isEmpty)
                                const Text(
                                  'Tap to select teaching modes',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                Text(
                                  _selectedTeachingModes.join(', '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}
