import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart' as user_models;
import '../../../shared/models/availability_model.dart' as avail_models;
import '../application/scheduling_providers.dart';

class RequestSessionSheet extends ConsumerStatefulWidget {
  final user_models.UserModel tutor;
  const RequestSessionSheet({super.key, required this.tutor});

  @override
  ConsumerState<RequestSessionSheet> createState() => _RequestSessionSheetState();
}

class _RequestSessionSheetState extends ConsumerState<RequestSessionSheet> {
  String? _subject;
  avail_models.TeachingMode? _mode;
  DateTime? _date;
  TimeOfDay? _time;
  int _durationMinutes = 60;
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.tutor.subjects != null && widget.tutor.subjects!.isNotEmpty) {
      _subject = widget.tutor.subjects!.first;
    }
    // default price from hourlyRate
    final rate = widget.tutor.hourlyRate ?? 0;
    _priceController.text = (rate > 0 ? (rate * (_durationMinutes / 60)).round() : 0).toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<avail_models.TeachingMode>> _modeItems() {
    final teachesNull = widget.tutor.teachingMode == null;
    final canOnline = teachesNull ||
        widget.tutor.teachingMode == user_models.TeachingMode.online ||
        widget.tutor.teachingMode == user_models.TeachingMode.both;
    final canPhysical = teachesNull ||
        widget.tutor.teachingMode == user_models.TeachingMode.physical ||
        widget.tutor.teachingMode == user_models.TeachingMode.both;
    final items = <DropdownMenuItem<avail_models.TeachingMode>>[];
    if (canOnline) {
      items.add(const DropdownMenuItem(
        value: avail_models.TeachingMode.online,
        child: Text('Online'),
      ));
      _mode ??= avail_models.TeachingMode.online;
    }
    if (canPhysical) {
      items.add(const DropdownMenuItem(
        value: avail_models.TeachingMode.physical,
        child: Text('Physical'),
      ));
      _mode ??= _mode ?? avail_models.TeachingMode.physical;
    }
    return items;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _onDurationChanged(int minutes) {
    setState(() {
      _durationMinutes = minutes;
      final rate = widget.tutor.hourlyRate ?? 0;
      _priceController.text = (rate > 0 ? (rate * (_durationMinutes / 60)).round() : 0).toString();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null || _subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }
    final startLocal = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    final startUtc = startLocal.toUtc();
    final endUtc = startUtc.add(Duration(minutes: _durationMinutes));
    final priceCents = int.tryParse(_priceController.text.trim()) ?? 0;

    // Determine mode if not selected
    avail_models.TeachingMode finalMode;
    if (_mode != null) {
      finalMode = _mode!;
    } else {
      final teachesNull = widget.tutor.teachingMode == null;
      final supportsOnline = teachesNull ||
          widget.tutor.teachingMode == user_models.TeachingMode.online ||
          widget.tutor.teachingMode == user_models.TeachingMode.both;
      final supportsPhysical = teachesNull ||
          widget.tutor.teachingMode == user_models.TeachingMode.physical ||
          widget.tutor.teachingMode == user_models.TeachingMode.both;
      if (supportsOnline && !supportsPhysical) {
        finalMode = avail_models.TeachingMode.online;
      } else if (!supportsOnline && supportsPhysical) {
        finalMode = avail_models.TeachingMode.physical;
      } else {
        finalMode = avail_models.TeachingMode.online; // sensible default
      }
    }

    try {
      // ignore: avoid_print
      print('[RequestSessionSheet] submitting tutor=${widget.tutor.id} subject=$_subject mode=${_mode?.name} start=$startUtc end=$endUtc priceCents=${priceCents * 100}');
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.createRequest(
        initiatorId: user.uid,
        studentId: user.uid, // initiated from student view
        tutorId: widget.tutor.id,
        subject: _subject!,
        mode: finalMode,
        startAtUtc: startUtc,
        endAtUtc: endUtc,
        priceCents: priceCents * 100, // store cents
        currency: 'USD',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent')),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[RequestSessionSheet] error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Request Session',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _subject,
                    items: (widget.tutor.subjects ?? ['General'])
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Subject'),
                    onChanged: (v) => setState(() => _subject = v),
                    validator: (v) => v == null || v.isEmpty ? 'Select subject' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<avail_models.TeachingMode>(
                    value: _mode,
                    items: _modeItems(),
                    decoration: const InputDecoration(labelText: 'Mode'),
                    onChanged: (v) => setState(() => _mode = v),
                    // Optional: no validator, defaults intelligently
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Date'),
                          controller: TextEditingController(
                            text: _date == null
                                ? ''
                                : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                          ),
                          onTap: _pickDate,
                          validator: (_) => _date == null ? 'Pick date' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Time'),
                          controller: TextEditingController(
                            text: _time == null
                                ? ''
                                : _time!.format(context),
                          ),
                          onTap: _pickTime,
                          validator: (_) => _time == null ? 'Pick time' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _durationMinutes,
                          items: const [30, 45, 60, 90, 120]
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                              .toList(),
                          decoration: const InputDecoration(labelText: 'Duration'),
                          onChanged: (v) => _onDurationChanged(v ?? 60),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (USD)'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Enter valid price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Send Request'),
                    ),
                  ),
                  const SizedBox(height: 16), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


