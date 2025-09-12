import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/user_model.dart';

class TutorMapScreen extends StatefulWidget {
  final UserModel tutor;

  const TutorMapScreen({super.key, required this.tutor});

  @override
  State<TutorMapScreen> createState() => _TutorMapScreenState();
}

class _TutorMapScreenState extends State<TutorMapScreen> {
  geocoding.Location? _tutorLocation;
  Position? _myPosition;
  String? _resolvedAddress;
  String? _error;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _requesting = true);
    try {
      await _resolveTutorAddress();
      await _getCurrentLocation();
    } catch (_) {}
    setState(() => _requesting = false);
  }

  Future<void> _resolveTutorAddress() async {
    try {
      final List<String> parts = [];
      if (widget.tutor.address != null &&
          widget.tutor.address!.trim().isNotEmpty) {
        parts.add(widget.tutor.address!.trim());
      }
      if (widget.tutor.city != null && widget.tutor.city!.trim().isNotEmpty) {
        parts.add(widget.tutor.city!.trim());
      }
      if (widget.tutor.country != null &&
          widget.tutor.country!.trim().isNotEmpty) {
        parts.add(widget.tutor.country!.trim());
      }
      final query = parts.isEmpty ? widget.tutor.name : parts.join(', ');
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isEmpty) {
        setState(() => _error = 'Could not locate the tutor address.');
        return;
      }
      setState(() {
        _tutorLocation = locations.first;
        _resolvedAddress = query;
      });
    } catch (e) {
      setState(() => _error = 'Failed to locate the tutor address.');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _error = 'Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission permanently denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _myPosition = pos);
    } catch (e) {
      setState(() => _error = 'Failed to get your location.');
    }
  }

  double? _distanceKm() {
    if (_tutorLocation == null || _myPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      _myPosition!.latitude,
      _myPosition!.longitude,
      _tutorLocation!.latitude,
      _tutorLocation!.longitude,
    );
    return meters / 1000.0;
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
    await launchUrl(uri, mode: LaunchMode.platformDefault);
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onOpenMaps: _openExternalMaps);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Tutor address'),
              subtitle: Text(_resolvedAddress ?? 'Not available'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.my_location_outlined),
              title: const Text('Your location'),
              subtitle: Text(
                _myPosition != null
                    ? '${_myPosition!.latitude.toStringAsFixed(5)}, ${_myPosition!.longitude.toStringAsFixed(5)}'
                    : 'Location unavailable',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_distanceKm() != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Approx. distance'),
                subtitle: Text('${_distanceKm()!.toStringAsFixed(2)} km'),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openExternalMaps,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onOpenMaps;

  const _ErrorView({required this.message, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}
