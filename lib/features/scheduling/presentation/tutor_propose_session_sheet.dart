import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/user_model.dart' as user_models;
import '../../../shared/models/availability_model.dart' as avail_models;
import '../../auth/application/auth_state.dart';
import '../application/scheduling_providers.dart';

class TutorProposeSessionSheet extends ConsumerStatefulWidget {
  final user_models.UserModel student;
  const TutorProposeSessionSheet({super.key, required this.student});

  @override
  ConsumerState<TutorProposeSessionSheet> createState() => _TutorProposeSessionSheetState();
}

class _TutorProposeSessionSheetState extends ConsumerState<TutorProposeSessionSheet> {
  String? _subject;
  avail_models.TeachingMode _mode = avail_models.TeachingMode.online;
  DateTime? _date;
  TimeOfDay? _time;
  int _durationMinutes = 60;
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
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

  Future<void> _submit(user_models.UserModel tutor) async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null || _subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
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
    final priceDollars = int.tryParse(_priceController.text.trim()) ?? 0;

    try {
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.createRequest(
        initiatorId: tutor.id,
        studentId: widget.student.id,
        tutorId: tutor.id,
        subject: _subject!,
        mode: _mode,
        startAtUtc: startUtc,
        endAtUtc: endUtc,
        priceCents: priceDollars * 100,
        currency: 'USD',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal sent')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to propose session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    return currentUserAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
      data: (tutor) {
        if (tutor == null || tutor.role != user_models.UserRole.teacher) {
          return const SizedBox(height: 200, child: Center(child: Text('Tutor session proposal only')));
        }
        // Initialize defaults from tutor profile
        _subject ??= (tutor.subjects?.isNotEmpty ?? false) ? tutor.subjects!.first : 'General';
        if (_priceController.text.isEmpty && (tutor.hourlyRate ?? 0) > 0) {
          _priceController.text = (tutor.hourlyRate ?? 0).round().toString();
        }

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
                        const Text('Propose Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _subject,
                      items: (tutor.subjects ?? ['General'])
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Subject'),
                      onChanged: (v) => setState(() => _subject = v),
                      validator: (v) => v == null || v.isEmpty ? 'Select subject' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<avail_models.TeachingMode>(
                      value: _mode,
                      items: const [
                        DropdownMenuItem(
                          value: avail_models.TeachingMode.online,
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: avail_models.TeachingMode.physical,
                          child: Text('Physical'),
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Mode'),
                      onChanged: (v) => setState(() => _mode = v ?? avail_models.TeachingMode.online),
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
                              text: _time == null ? '' : _time!.format(context),
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
                            onChanged: (v) => setState(() => _durationMinutes = v ?? 60),
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
                        onPressed: () => _submit(tutor),
                        child: const Text('Send Proposal'),
                      ),
                    ),
                    const SizedBox(height: 16), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


