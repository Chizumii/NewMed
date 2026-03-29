import 'dart:typed_data';
import 'package:newmed/view/widgets/footer_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../viewmodel/database_provider.dart';
import '../../widgets/pages.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const khaki      = Color(0xFFF0E68C);
  static const khakiDeep  = Color(0xFFD4C96A);
  static const ink        = Color(0xFF0F172A);
  static const inkSoft    = Color(0xFF1E293B);
  static const surface    = Color(0xFFFAF9F6);
  static const card       = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE8E4D9);
  static const muted      = Color(0xFF94A3B8);
  static const rose       = Color(0xFFC2185B);
  static const success    = Color(0xFF16A34A);
  static const danger     = Color(0xFFDC2626);
}

class _T {
  static const display = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: _C.ink,
    letterSpacing: -1.2,
    height: 1.1,
  );
  static const sectionHead = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _C.ink,
    letterSpacing: -0.4,
  );
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: _C.rose,
    letterSpacing: 1.4,
  );
  static const body = TextStyle(
    fontSize: 14,
    color: _C.inkSoft,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 11,
    color: _C.muted,
    letterSpacing: 0.2,
  );
}
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _institutionCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _majorCtrl;
  late TextEditingController _batchCtrl;
  late TextEditingController _lineCtrl;

  Uint8List? _newCvBytes;
  String?    _newCvName;
  Uint8List? _newPortfolioBytes;
  String?    _newPortfolioName;

  @override
  void initState() {
    super.initState();
    final user = context.read<DatabaseProvider>().currentUser;
    _nameCtrl        = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl       = TextEditingController(text: user?.email ?? '');
    _institutionCtrl = TextEditingController(text: user?.institution ?? '');
    _roleCtrl        = TextEditingController(text: user?.role.toUpperCase() ?? 'MAHASISWA');
    _phoneCtrl       = TextEditingController(text: user?.phone ?? '');
    _majorCtrl       = TextEditingController(text: user?.major ?? '');
    _batchCtrl       = TextEditingController(text: user?.batch ?? '');
    _lineCtrl        = TextEditingController(text: user?.lineId ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _institutionCtrl, _roleCtrl,
                     _phoneCtrl, _majorCtrl, _batchCtrl, _lineCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final provider = context.read<DatabaseProvider>();
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      _toast('Uploading avatar…');
      final bytes   = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      final error   = await provider.uploadProfilePicture(bytes, fileExt);
      if (mounted) {
        error == null
            ? _toast('Photo updated!', isSuccess: true)
            : _toast(error, isError: true);
      }
    }
  }

  Future<void> _pickDocument(bool isCv) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      setState(() {
        if (isCv) { _newCvBytes = file.bytes; _newCvName = file.name; }
        else { _newPortfolioBytes = file.bytes; _newPortfolioName = file.name; }
      });
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri)) throw Exception('Could not launch $uri');
  }

  Future<void> _saveProfileData() async {
    final provider = context.read<DatabaseProvider>();
    _toast('Saving changes…');
    final error = await provider.updateProfileDataComplete(
      fullName:       _nameCtrl.text.trim(),
      institution:    _institutionCtrl.text.trim(),
      major:          _majorCtrl.text.trim(),
      batch:          _batchCtrl.text.trim(),
      phone:          _phoneCtrl.text.trim(),
      lineId:         _lineCtrl.text.trim(),
      cvBytes:        _newCvBytes,
      cvName:         _newCvName,
      portfolioBytes: _newPortfolioBytes,
      portfolioName:  _newPortfolioName,
    );
    if (mounted) {
      if (error == null) {
        setState(() {
          _newCvBytes = _newPortfolioBytes = null;
          _newCvName  = _newPortfolioName  = null;
        });
        _toast('Profile updated successfully!', isSuccess: true);
      } else {
        _toast(error, isError: true);
      }
    }
  }

  void _toast(String msg, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isSuccess ? _C.success : isError ? _C.danger : _C.inkSoft,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();
    final user     = provider.currentUser;
    final isSiswa  = user?.role.toLowerCase() == 'siswa';

    return Scaffold(
      backgroundColor: _C.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Navbar(isLoggedIn: true, activePage: 'Profile'),

            // ── Hero Banner ────────────────────────────────────────────────
            _HeroBanner(
              user: user,
              onAvatarTap: _pickAndUploadImage,
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Personal Info Card
                    _SectionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          _buildLabel('Full Name'),
                          _buildTextField(_nameCtrl, icon: Icons.badge_outlined),
                          _buildLabel('Email Address'),
                          _buildTextField(_emailCtrl,
                              icon: Icons.alternate_email_rounded,
                              isReadOnly: true),
                          _buildLabel(isSiswa ? 'School' : 'Institution'),
                          _buildTextField(_institutionCtrl,
                              icon: Icons.account_balance_outlined),
                          if (!isSiswa) ...[
                            _buildLabel('Major / Jurusan'),
                            _buildTextField(_majorCtrl,
                                icon: Icons.menu_book_outlined,
                                hint: 'e.g. Computer Science'),
                            _buildLabel('Batch / Angkatan'),
                            _buildTextField(_batchCtrl,
                                icon: Icons.calendar_month_outlined,
                                hint: 'e.g. 2022'),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Card
                    _SectionCard(
                      icon: Icons.contact_phone_outlined,
                      title: 'Contact Details',
                      child: Column(
                        children: [
                          _buildLabel('Phone Number'),
                          _buildTextField(_phoneCtrl,
                              icon: Icons.phone_iphone_rounded,
                              hint: '+62 8xx xxxx xxxx'),
                          _buildLabel('Line ID'),
                          _buildTextField(_lineCtrl,
                              icon: Icons.chat_bubble_outline_rounded,
                              hint: 'your_line_id'),
                        ],
                      ),
                    ),

                    // Documents Card (hidden for siswa)
                    if (!isSiswa) ...[
                      const SizedBox(height: 20),
                      _SectionCard(
                        icon: Icons.folder_open_rounded,
                        title: 'Documents',
                        child: Column(
                          children: [
                            _buildDocumentSection(
                              label: 'Curriculum Vitae (CV)',
                              newBytes: _newCvBytes,
                              newName: _newCvName,
                              existingUrl: user?.cvUrl,
                              onPick: () => _pickDocument(true),
                            ),
                            const SizedBox(height: 16),
                            _buildDocumentSection(
                              label: 'Portfolio',
                              newBytes: _newPortfolioBytes,
                              newName: _newPortfolioName,
                              existingUrl: user?.portfolioUrl,
                              onPick: () => _pickDocument(false),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _C.inkSoft,
                            side: const BorderSide(color: _C.border, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),

                        // Save button
                        if (provider.isLoading)
                          Container(
                            height: 48,
                            width: 140,
                            decoration: BoxDecoration(
                              color: _C.khaki,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: _C.ink),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _saveProfileData,
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 18),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.khaki,
                              foregroundColor: _C.ink,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 36, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

            const FooterSection(),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text.toUpperCase(), style: _T.label),
      );

  Widget _buildTextField(
    TextEditingController c, {
    IconData? icon,
    bool isReadOnly = false,
    String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextFormField(
          controller: c,
          readOnly: isReadOnly,
          style: _T.body.copyWith(
              color: isReadOnly ? _C.muted : _C.ink,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _T.caption,
            prefixIcon: icon != null
                ? Icon(icon,
                    color: isReadOnly ? _C.muted : _C.khakiDeep, size: 20)
                : null,
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF4F4F2) : _C.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.khakiDeep, width: 2),
            ),
          ),
        ),
      );

  Widget _buildDocumentSection({
    required String label,
    Uint8List? newBytes,
    String? newName,
    String? existingUrl,
    required VoidCallback onPick,
  }) {
    final isImageNew = newName != null &&
        RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false).hasMatch(newName);
    final isImageOld = existingUrl != null &&
        RegExp(r'\.(jpg|jpeg|png)', caseSensitive: false).hasMatch(existingUrl);
    final hasFile = newName != null || (existingUrl != null && existingUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          decoration: BoxDecoration(
            color: _C.card,
            border: Border.all(
                color: hasFile ? _C.khakiDeep.withOpacity(0.5) : _C.border,
                width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              // Image preview
              if (isImageNew && newBytes != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.memory(newBytes,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                )
              else if (isImageOld && newBytes == null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(existingUrl!,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // File icon badge
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _C.khaki.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        (isImageNew || isImageOld)
                            ? Icons.image_rounded
                            : Icons.picture_as_pdf_rounded,
                        color: _C.khakiDeep, size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // File name / status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (newName != null)
                            Text(newName,
                                style: _T.body.copyWith(
                                    color: _C.success,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                          else if (existingUrl != null && existingUrl.isNotEmpty)
                            Text('File saved',
                                style: _T.body.copyWith(
                                    fontWeight: FontWeight.w700))
                          else
                            const Text('No file uploaded', style: _T.caption),
                          const SizedBox(height: 2),
                          const Text('PDF, DOC, JPG, PNG — max 5 MB',
                              style: _T.caption),
                        ],
                      ),
                    ),

                    // Action icons
                    Row(
                      children: [
                        if (existingUrl != null &&
                            existingUrl.isNotEmpty &&
                            newName == null)
                          IconButton(
                            onPressed: () => _launchUrl(existingUrl),
                            icon: const Icon(Icons.open_in_new_rounded,
                                color: _C.muted, size: 20),
                            tooltip: 'Open file',
                          ),
                        TextButton.icon(
                          onPressed: onPick,
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(hasFile ? 'Change' : 'Upload'),
                          style: TextButton.styleFrom(
                            foregroundColor: _C.ink,
                            backgroundColor: _C.khaki,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAvatarTap;

  const _HeroBanner({required this.user, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _C.ink,
        // Subtle diagonal stripe texture
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative khaki arc
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.khaki.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.khaki.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Stack(
                        children: [
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _C.khaki, width: 3),
                              image: DecorationImage(
                                image: (user?.avatarUrl != null &&
                                        user!.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                                    : const NetworkImage(
                                        'https://cdn-icons-png.freepik.com/512/6522/6522516.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2, right: 2,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: _C.khaki,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _C.ink, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: _C.ink),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Name / role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Your Name',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _C.khaki.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _C.khaki.withOpacity(0.4)),
                            ),
                            child: Text(
                              user?.role.toUpperCase() ?? 'MAHASISWA',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _C.khaki,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.institution ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _C.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _C.khaki.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _C.khaki, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title, style: _T.sectionHead.copyWith(color: Colors.white)),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: child,
          ),
        ],
      ),
    );
  }
}