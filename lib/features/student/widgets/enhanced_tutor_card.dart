import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../presentation/tutor_map_screen.dart';
import '../../../shared/models/user_model.dart';
import '../../chat/services/chat_service.dart';
import 'request_session_sheet.dart';

class EnhancedTutorCard extends StatefulWidget {
  final UserModel tutor;
  final VoidCallback onTap;

  const EnhancedTutorCard({
    super.key,
    required this.tutor,
    required this.onTap,
  });

  @override
  State<EnhancedTutorCard> createState() => _EnhancedTutorCardState();
}

class _EnhancedTutorCardState extends State<EnhancedTutorCard> {
  void _openMapScreen(BuildContext context) {
    if (widget.tutor.location != null && widget.tutor.location!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TutorMapScreen(tutor: widget.tutor)),
      );
    }
  }

  bool get isOnline =>
      widget.tutor.teachingMode == TeachingMode.online ||
      widget.tutor.teachingMode == TeachingMode.both;

  bool get isPhysical =>
      widget.tutor.teachingMode == TeachingMode.physical ||
      widget.tutor.teachingMode == TeachingMode.both;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Tutor Profile Info ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      widget.tutor.name.isNotEmpty
                          ? widget.tutor.name[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.tutor.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                              ),
                            ),
                            if (isPhysical)
                              IconButton(
                                tooltip: 'View location',
                                onPressed: () => _openMapScreen(context),
                                icon: const Icon(Icons.location_on_outlined),
                                color: Theme.of(context).primaryColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (widget.tutor.subjects != null &&
                            widget.tutor.subjects!.isNotEmpty)
                          Text(
                            widget.tutor.subjects!.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// --- Tutor Bio ---
              if (widget.tutor.bio != null && widget.tutor.bio!.isNotEmpty)
                Text(
                  widget.tutor.bio!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 16),

              /// --- Location & Mode Tags ---
              Row(
                children: [
                  if (widget.tutor.city != null || widget.tutor.country != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.tutor.city ?? ''}${widget.tutor.city != null && widget.tutor.country != null ? ', ' : ''}${widget.tutor.country ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 16),
                  if (isOnline || isPhysical)
                    Row(
                      children: [
                        if (isOnline) _buildTag(context, 'Online', Colors.blue),
                        if (isOnline && isPhysical) const SizedBox(width: 8),
                        if (isPhysical)
                          _buildTag(context, 'Physical', Colors.green),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 16),

              /// --- Rate, Experience, Rating ---
              Row(
                children: [
                  if (widget.tutor.hourlyRate != null)
                    Text(
                      '\$${widget.tutor.hourlyRate!.toStringAsFixed(0)}/hr',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (widget.tutor.yearsOfExperience != null)
                    Row(
                      children: [
                        Icon(Icons.work, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.tutor.yearsOfExperience} yrs exp.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (widget.tutor.rating != null && widget.tutor.rating! > 0)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          widget.tutor.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 20),

              /// --- Chat Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to start chat'),
                          ),
                        );
                        return;
                      }

                      final currentUserId = user.uid;
                      final tutorId = widget.tutor.id;

                      if (tutorId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tutor ID not found')),
                        );
                        return;
                      }

                      final chatService = ChatService();
                      final chatId = await chatService.getOrCreateChat(
                        currentUserId,
                        tutorId,
                      );

                      context.go(
                        '/chatScreen',
                        extra: {
                          'chatId': chatId,
                          'tutor': widget.tutor,
                          'currentUserId': currentUserId,
                        },
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unable to start chat: $e')),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Chat with Tutor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Request Session Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(ctx).viewInsets.bottom,
                          ),
                          child: RequestSessionSheet(tutor: widget.tutor),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Request Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Online' ? Icons.video_call : Icons.person_pin,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
