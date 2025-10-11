import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/user_model.dart';

class TutorMapScreen extends StatefulWidget {
  final UserModel tutor;

  const TutorMapScreen({super.key, required this.tutor});

  @override
  State<TutorMapScreen> createState() => _TutorMapScreenState();
}

class _TutorMapScreenState extends State<TutorMapScreen> {
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _requesting = true);
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _requesting = false);
  }

  Future<void> _openExternalMaps() async {
    final List<String> parts = [];
    if (widget.tutor.address != null && widget.tutor.address!.trim().isNotEmpty)
      parts.add(widget.tutor.address!.trim());
    if (widget.tutor.city != null && widget.tutor.city!.trim().isNotEmpty)
      parts.add(widget.tutor.city!.trim());
    if (widget.tutor.country != null && widget.tutor.country!.trim().isNotEmpty)
      parts.add(widget.tutor.country!.trim());
    final String query = parts.isEmpty ? widget.tutor.name : parts.join(', ');
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tutor.name),
        actions: [
          IconButton(
            tooltip: 'Open in Google Maps',
            onPressed: _openExternalMaps,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_requesting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading location...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTutorCard(),
          const SizedBox(height: 24),
          _buildLocationCard(),
          const SizedBox(height: 24),
          _buildMapPlaceholder(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTutorCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  Text(
                    widget.tutor.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.tutor.subjects?.isNotEmpty == true)
                    Text(
                      widget.tutor.subjects!.join(', '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final addressParts = <String>[];
    if (widget.tutor.address?.trim().isNotEmpty == true) {
      addressParts.add(widget.tutor.address!.trim());
    }
    if (widget.tutor.city?.trim().isNotEmpty == true) {
      addressParts.add(widget.tutor.city!.trim());
    }
    if (widget.tutor.country?.trim().isNotEmpty == true) {
      addressParts.add(widget.tutor.country!.trim());
    }

    final fullAddress = addressParts.join(', ');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fullAddress.isNotEmpty ? fullAddress : 'Address not available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Interactive Map',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Open in Google Maps" to view on map',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openExternalMaps,
            icon: const Icon(Icons.map),
            label: const Text('Open in Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
