import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../../ratings/data/rating_service.dart';
import '../../ratings/presentation/rate_tutor_sheet.dart';
import '../../auth/application/auth_state.dart';
import '../../scheduling/presentation/request_session_sheet.dart';
import '../../chat/services/chat_service.dart';

class ViewProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends ConsumerState<ViewProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  double? _averageRating;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _user = UserModel.fromJson({
            ...data,
            'id': doc.id,
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          });
          _averageRating = _user?.rating;
          _totalReviews = _user?.totalReviews ?? 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ViewProfileScreen] Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final isCurrentUser = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? 'Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: _user!.profileImageUrl != null
                                  ? NetworkImage(_user!.profileImageUrl!)
                                  : null,
                              child: _user!.profileImageUrl == null
                                  ? Text(
                                      _user!.name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 32, color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_user!.role == UserRole.teacher && _averageRating != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < _averageRating!.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_averageRating!.toStringAsFixed(1)} ($_totalReviews reviews)',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Action Buttons
                      if (!isCurrentUser) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (currentUser?.role == UserRole.student &&
                                  _user!.role == UserRole.teacher) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        builder: (ctx) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                          ),
                                          child: RequestSessionSheet(tutor: _user!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.schedule),
                                    label: const Text('Request Session'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final chatService = ChatService();
                                      final chatId = await chatService.getOrCreateChat(
                                        currentUser!.id,
                                        widget.userId,
                                      );
                                      if (mounted) {
                                        context.go('/chatScreen', extra: {
                                          'chatId': chatId,
                                          'tutor': _user!,
                                          'currentUserId': currentUser.id,
                                        });
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Message'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Profile Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_user!.role == UserRole.teacher) ...[
                              if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                                _buildSectionTitle('About'),
                                const SizedBox(height: 8),
                                Text(
                                  _user!.bio!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_user!.subjects != null && _user!.subjects!.isNotEmpty) ...[
                                _buildSectionTitle('Subjects'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _user!.subjects!
                                      .map((subject) => Chip(
                                            label: Text(subject),
                                            backgroundColor: Colors.blue.shade50,
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_user!.hourlyRate != null) ...[
                                _buildInfoRow(Icons.attach_money, 'Hourly Rate',
                                    '\$${_user!.hourlyRate!.toStringAsFixed(0)}/hour'),
                                const SizedBox(height: 16),
                              ],
                              if (_user!.yearsOfExperience != null) ...[
                                _buildInfoRow(Icons.work, 'Experience',
                                    '${_user!.yearsOfExperience} years'),
                                const SizedBox(height: 16),
                              ],
                              if (_user!.qualifications != null) ...[
                                _buildInfoRow(Icons.school, 'Qualifications',
                                    _user!.qualifications!),
                                const SizedBox(height: 16),
                              ],
                              if (_user!.languages != null && _user!.languages!.isNotEmpty) ...[
                                _buildInfoRow(Icons.language, 'Languages',
                                    _user!.languages!.join(', ')),
                                const SizedBox(height: 16),
                              ],
                            ] else ...[
                              // Student profile
                              if (_user!.currentSchool != null) ...[
                                _buildInfoRow(Icons.school, 'School', _user!.currentSchool!),
                                const SizedBox(height: 16),
                              ],
                              if (_user!.grade != null) ...[
                                _buildInfoRow(Icons.grade, 'Grade', _user!.grade!),
                                const SizedBox(height: 16),
                              ],
                              if (_user!.interestedSubjects != null &&
                                  _user!.interestedSubjects!.isNotEmpty) ...[
                                _buildSectionTitle('Interested Subjects'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _user!.interestedSubjects!
                                      .map((subject) => Chip(
                                            label: Text(subject),
                                            backgroundColor: Colors.green.shade50,
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                            if (_user!.city != null || _user!.country != null) ...[
                              _buildInfoRow(
                                Icons.location_on,
                                'Location',
                                [if (_user!.city != null) _user!.city, if (_user!.country != null) _user!.country]
                                    .where((e) => e != null)
                                    .join(', '),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Reviews Section (for teachers)
                      if (_user!.role == UserRole.teacher && _totalReviews > 0) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Reviews ($_totalReviews)'),
                              const SizedBox(height: 16),
                              StreamBuilder(
                                stream: RatingService().watchRatingsForTutor(widget.userId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final ratings = snapshot.data ?? [];
                                  if (ratings.isEmpty) {
                                    return const Text('No reviews yet');
                                  }
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: ratings.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final rating = ratings[index];
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(rating.studentId)
                                            .get(),
                                        builder: (context, studentSnap) {
                                          String studentName = 'Anonymous';
                                          if (studentSnap.hasData && studentSnap.data!.exists) {
                                            final data = studentSnap.data!.data() as Map<String, dynamic>?;
                                            studentName = data?['name'] as String? ?? 'Anonymous';
                                          }
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              child: Text(studentName[0].toUpperCase()),
                                            ),
                                            title: Row(
                                              children: [
                                                ...List.generate(5, (i) {
                                                  return Icon(
                                                    i < rating.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  );
                                                }),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  studentName,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                if (rating.comment != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(rating.comment!),
                                                ],
                                                const SizedBox(height: 4),
                                                Text(
                                                  rating.createdAt.toLocal().toString().substring(0, 10),
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

