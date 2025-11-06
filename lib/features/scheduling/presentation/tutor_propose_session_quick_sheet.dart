import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/application/auth_state.dart';
import 'tutor_propose_session_sheet.dart';

class TutorProposeSessionQuickSheet extends ConsumerStatefulWidget {
  const TutorProposeSessionQuickSheet({super.key});

  @override
  ConsumerState<TutorProposeSessionQuickSheet> createState() => _TutorProposeSessionQuickSheetState();
}

class _TutorProposeSessionQuickSheetState extends ConsumerState<TutorProposeSessionQuickSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _findAndOpen() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final input = _controller.text.trim();
      if (input.isEmpty) {
        setState(() => _error = 'Enter student email or ID');
        return;
      }

      UserModel? student;
      final users = FirebaseFirestore.instance.collection('users');
      if (input.contains('@')) {
        // Search by email
        final q = await users.where('email', isEqualTo: input).limit(1).get();
        if (q.docs.isEmpty) {
          setState(() => _error = 'No user found with that email');
          return;
        }
        final d = q.docs.first;
        final data = d.data();
        student = UserModel.fromJson({
          ...data,
          'id': d.id,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      } else {
        // Search by ID
        final doc = await users.doc(input).get();
        if (!doc.exists) {
          setState(() => _error = 'No user found with that ID');
          return;
        }
        final data = doc.data()!;
        student = UserModel.fromJson({
          ...data,
          'id': doc.id,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }

      if (student.role != UserRole.student) {
        setState(() => _error = 'Selected user is not a student');
        return;
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: TutorProposeSessionSheet(student: student!),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final isTutor = currentUser?.role == UserRole.teacher;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (!isTutor)
                  const Text('Only tutors can propose sessions', style: TextStyle(color: Colors.red)),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Student email or ID',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading || !isTutor ? null : _findAndOpen,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: const Text('Find Student'),
                  ),
                ),
                const SizedBox(height: 16), // Extra padding for mobile
              ],
            ),
          ),
        ),
      ),
    );
  }
}


