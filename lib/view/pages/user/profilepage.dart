import 'dart:typed_data';
import 'package:newmed/view/widgets/footer_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import '../../../../viewmodel/database_provider.dart';
import '../../widgets/pages.dart'; 

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
  String? _newCvName;
  Uint8List? _newPortfolioBytes;
  String? _newPortfolioName;

  @override
  void initState() {
    super.initState();
    final user = context.read<DatabaseProvider>().currentUser;

    _nameCtrl = TextEditingController(text: user?.fullName ?? "");
    _emailCtrl = TextEditingController(text: user?.email ?? "");
    _institutionCtrl = TextEditingController(text: user?.institution ?? "");
    _roleCtrl = TextEditingController(text: user?.role.toUpperCase() ?? "MAHASISWA");
    
    _phoneCtrl = TextEditingController(text: user?.phone ?? "");
    _majorCtrl = TextEditingController(text: user?.major ?? "");
    _batchCtrl = TextEditingController(text: user?.batch ?? "");
    _lineCtrl = TextEditingController(text: user?.lineId ?? "");
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _institutionCtrl.dispose();
    _roleCtrl.dispose(); _phoneCtrl.dispose(); _majorCtrl.dispose(); _batchCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  // ... (Fungsi _pickAndUploadImage, _pickDocument, _launchUrl tetap sama)
  Future<void> _pickAndUploadImage() async {
    final provider = context.read<DatabaseProvider>();
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading avatar...")));
      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      String? error = await provider.uploadProfilePicture(bytes, fileExt);

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto berhasil diubah!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _pickDocument(bool isCv) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        if (isCv) {
          _newCvBytes = file.bytes;
          _newCvName = file.name;
        } else {
          _newPortfolioBytes = file.bytes;
          _newPortfolioName = file.name;
        }
      });
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _saveProfileData() async {
    final provider = context.read<DatabaseProvider>();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving data...")));

    String? error = await provider.updateProfileDataComplete(
      fullName: _nameCtrl.text.trim(),
      institution: _institutionCtrl.text.trim(),
      major: _majorCtrl.text.trim(),
      batch: _batchCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      lineId: _lineCtrl.text.trim(),
      
      cvBytes: _newCvBytes,
      cvName: _newCvName,
      portfolioBytes: _newPortfolioBytes,
      portfolioName: _newPortfolioName,
    );

    if (mounted) {
      if (error == null) {
        setState(() {
          _newCvBytes = null; _newCvName = null;
          _newPortfolioBytes = null; _newPortfolioName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();
    final user = provider.currentUser;
    
    // Logika pengecekan Siswa
    bool isSiswa = user?.role.toLowerCase() == "siswa";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Navbar(isLoggedIn: true, activePage: "Profile"),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Profile Section", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Container(width: 120, height: 4, color: const Color(0xFF0F172A)),
                    const SizedBox(height: 40),

                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(user.avatarUrl!)
                                      : const NetworkImage("https://cdn-icons-png.freepik.com/512/6522/6522516.png"),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(color: Colors.deepPurple, width: 3),
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]),
                                child: const Icon(Icons.camera_alt, color: Colors.deepPurple, size: 20),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(child: Text(user?.fullName ?? "User", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    
                    const SizedBox(height: 40),

                    _buildLabel("Full Name"), _buildTextField(_nameCtrl, icon: Icons.person),
                    _buildLabel("Email"), _buildTextField(_emailCtrl, icon: Icons.email, isReadOnly: true),
                    
                    // Dinamis: Ganti label Institution jadi School jika Siswa
                    _buildLabel(isSiswa ? "School" : "Institution"), 
                    _buildTextField(_institutionCtrl, icon: Icons.school),
                    
                    // Sembunyikan Major dan Year jika Siswa
                    if (!isSiswa) ...[
                      _buildLabel("Major / Jurusan"), 
                      _buildTextField(_majorCtrl, icon: Icons.book, hint: "Insert your major"),
                      _buildLabel("Batch / Angkatan"), 
                      _buildTextField(_batchCtrl, icon: Icons.calendar_today, hint: "Insert your batch/year"),
                    ],
                    
                    _buildLabel("Phone Number"), _buildTextField(_phoneCtrl, icon: Icons.phone, hint: "Insert your phone number"),
                    _buildLabel("Line ID"), _buildTextField(_lineCtrl, icon: Icons.chat_bubble, hint: "Insert your Line ID"),

                    // Dinamis: Sembunyikan Section Documents jika Siswa
                    if (!isSiswa) ...[
                      const SizedBox(height: 30),
                      const Divider(),
                      const Text("Documents", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 15),

                      _buildDocumentSection(
                        label: "Curriculum Vitae (CV)",
                        newBytes: _newCvBytes,
                        newName: _newCvName,
                        existingUrl: user?.cvUrl,
                        onPick: () => _pickDocument(true),
                      ),

                      const SizedBox(height: 20),

                      _buildDocumentSection(
                        label: "Portfolio",
                        newBytes: _newPortfolioBytes,
                        newName: _newPortfolioName,
                        existingUrl: user?.portfolioUrl,
                        onPick: () => _pickDocument(false),
                      ),
                    ],

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                          child: const Text("Back"),
                        ),
                        
                        if (provider.isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _saveProfileData,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2185B), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                            child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    )
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

  // ... (Helper widgets _buildDocumentSection, _buildLabel, _buildTextField tetap sama)
  Widget _buildDocumentSection({
    required String label,
    Uint8List? newBytes,
    String? newName,
    String? existingUrl,
    required VoidCallback onPick,
  }) {
    bool isImageNew = newName != null && (newName.endsWith('.jpg') || newName.endsWith('.png') || newName.endsWith('.jpeg'));
    bool isImageOld = existingUrl != null && (existingUrl.contains('.jpg') || existingUrl.contains('.png') || existingUrl.contains('.jpeg'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              if (isImageNew && newBytes != null)
                Container(
                  height: 200, width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: MemoryImage(newBytes), fit: BoxFit.cover)),
                )
              else if (isImageOld && newBytes == null)
                Container(
                  height: 200, width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage(existingUrl), fit: BoxFit.cover)),
                ),

              Row(
                children: [
                  Icon((isImageNew || isImageOld) ? Icons.image : Icons.picture_as_pdf, color: const Color(0xFF3F054F), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newName != null) Text("New: $newName", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis)
                        else if (existingUrl != null && existingUrl.isNotEmpty) const Text("File Uploaded (Saved)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))
                        else const Text("No file uploaded", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text("Max 5MB (PDF, JPG, PNG)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (existingUrl != null && newName == null)
                        IconButton(
                          onPressed: () => _launchUrl(existingUrl),
                          icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                          tooltip: "Open in New Tab",
                        ),
                      ElevatedButton.icon(
                        onPressed: onPick,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: const Color(0xFF3F054F), elevation: 0),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(existingUrl != null || newName != null ? "Change" : "Upload"),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.bold)));
  Widget _buildTextField(TextEditingController c, {IconData? icon, bool isReadOnly = false, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(controller: c, readOnly: isReadOnly, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon), filled: true, fillColor: isReadOnly ? Colors.grey[100] : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
  );
}