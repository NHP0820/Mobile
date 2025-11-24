import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late final TabController _tabs;

  File? _localImage;
  String? _firestoreImageUrl;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _bootstrap();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _auth.currentUser?.reload();
    await _loadUserImage();
    await _loadUserDetails();
    if (mounted) setState(() {});
  }

  Future<void> _loadUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['displayName'] ?? user.displayName ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _bioController.text = data['bio'] ?? '';
      } else {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = '';
        _bioController.text = '';
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = '';
      _bioController.text = '';
    }
  }

  Future<void> _saveUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoURL': _firestoreImageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snap.exists &&
          (snap.data()?['photoURL'] as String?)?.isNotEmpty == true) {
        final photoUrl = snap.data()!['photoURL'] as String;
        if (photoUrl.startsWith('data:image')) {
          setState(() {
            _firestoreImageUrl = photoUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user image: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final file = File(picked.path);
    setState(() => _localImage = file);

    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final imageDataUrl = 'data:image/jpeg;base64,$base64String';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': imageDataUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _localImage = null;
        _firestoreImageUrl = imageDataUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.code}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  ImageProvider<Object>? _avatarProvider() {
    if (_localImage != null) return FileImage(_localImage!);
    if (_firestoreImageUrl != null && _firestoreImageUrl!.isNotEmpty) {
      try {
        final b64 = _firestoreImageUrl!.split(',').last;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Mechanic');
    final email = user?.email ?? '—';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: const Color(0xFF1976D2),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 50,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 38,
                              backgroundImage: _avatarProvider(),
                              child:
                              (_localImage == null &&
                                  (_firestoreImageUrl == null ||
                                      _firestoreImageUrl!.isEmpty))
                                  ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                                  : null,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Account'),
                  Tab(text: 'Security'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              // ===== ACCOUNT TAB =====
              Builder(
                builder: (context) {
                  final bottomPad =
                      MediaQuery.of(context).viewInsets.bottom + 24;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomPad,
                    ),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              if (_isEditing) ...[
                                TextButton(
                                  onPressed: () {
                                    setState(() => _isEditing = false);
                                    _loadUserDetails(); // reset values
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _saveUserDetails,
                                  child: const Text('Save'),
                                ),
                              ] else
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // UID (Read-only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'User ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.uid ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bioController,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: const Icon(Icons.info),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: !_isEditing,
                          fillColor: _isEditing ? null : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                          onPressed: () async {
                            await _auth.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (route) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              Builder(
                builder: (context) {
                  final bottomPad =
                      MediaQuery.of(context).viewInsets.bottom + 24;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We'll email you a reset link.",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Send reset link'),
                          onPressed: () async {
                            final e = user?.email;
                            if (e == null || e.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No email linked to this account',
                                  ),
                                ),
                              );
                              return;
                            }
                            await _auth.sendPasswordResetEmail(email: e);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reset link sent to $e'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

