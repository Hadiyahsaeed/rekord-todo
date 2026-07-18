import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _roleController = TextEditingController();
  
  // Clean avatar presets to make your profile look sharp instantly!
  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=tech',
    'https://api.dicebear.com/7.x/bottts/png?seed=stark',
    'https://api.dicebear.com/7.x/bottts/png?seed=matrix',
  ];
  String _selectedAvatar = 'https://api.dicebear.com/7.x/bottts/png?seed=tech';

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text('Profile Deck', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            if (_usernameController.text.isEmpty) {
              _usernameController.text = data['username'] ?? '';
              _bioController.text = data['bio'] ?? '';
              _roleController.text = data['role'] ?? 'Developer';
              _selectedAvatar = data['avatarUrl'] ?? _avatars[0];
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF7C3AED),
                    child: CircleAvatar(
                      radius: 51,
                      backgroundColor: const Color(0xFF0F172A),
                      backgroundImage: NetworkImage(_selectedAvatar),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select Identity Avatar', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _avatars.map((url) {
                    bool isSel = _selectedAvatar == url;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = url),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(color: isSel ? const Color(0xFF7C3AED) : Colors.transparent, width: 2)
                        ),
                        child: CircleAvatar(radius: 22, backgroundColor: const Color(0xFF1E293B), backgroundImage: NetworkImage(url)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('Username / Handle'),
                TextField(controller: _usernameController, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Your username...')),
                const SizedBox(height: 18),
                _buildFieldLabel('Role Designation'),
                TextField(controller: _roleController, style: const TextStyle(color: Colors.white), decoration: _inputStyle('e.g. Developer, Student, Creator')),
                const SizedBox(height: 18),
                _buildFieldLabel('Bio Manifesto'),
                TextField(controller: _bioController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Tell your story...')),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () async {
                    await _firestoreService.updateUserProfile(user.uid, {
                      'username': _usernameController.text.trim(),
                      'role': _roleController.text.trim(),
                      'bio': _bioController.text.trim(),
                      'avatarUrl': _selectedAvatar,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Framework Schema Saved!'), backgroundColor: Color(0xFF10B981))
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Save Configuration', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => authProvider.signOut(),
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                  label: Text('Sign Out of Core Sync', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334155))),
    );
  }
}