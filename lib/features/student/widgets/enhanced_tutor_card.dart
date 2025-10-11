import 'package:flutter/material.dart';
import '../presentation/tutor_map_screen.dart';
import '../../../shared/models/user_model.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TutorMapScreen(tutor: widget.tutor)),
    );
  }

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
                            if (widget.tutor.isPhysicalAvailable == true)
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

                  if (widget.tutor.isOnlineAvailable == true ||
                      widget.tutor.isPhysicalAvailable == true)
                    Row(
                      children: [
                        if (widget.tutor.isOnlineAvailable == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_call,
                                  size: 12,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.tutor.isOnlineAvailable == true &&
                            widget.tutor.isPhysicalAvailable == true)
                          const SizedBox(width: 8),
                        if (widget.tutor.isPhysicalAvailable == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_pin,
                                  size: 12,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Physical',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  if (widget.tutor.hourlyRate != null)
                    Row(
                      children: [
                        Text(
                          '\$${widget.tutor.hourlyRate!.toStringAsFixed(0)}/hr',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
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
                        if (widget.tutor.totalReviews != null &&
                            widget.tutor.totalReviews! > 0)
                          Text(
                            ' (${widget.tutor.totalReviews})',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
