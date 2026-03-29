import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../model/custom_models.dart';
import '../../viewmodel/database_provider.dart';

class RegistrationFormCard extends StatefulWidget {
  final EventModel event;

  const RegistrationFormCard({super.key, required this.event});

  @override
  State<RegistrationFormCard> createState() => _RegistrationFormCardState();
}

class _RegistrationFormCardState extends State<RegistrationFormCard> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final institutionController = TextEditingController();
  final majorController = TextEditingController();
  final yearController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedDivision;
  String? selectedSubEvent;
  List<String> divisions = [];
  List<String> subEvents = [];

  String userStatus = "Mahasiswa";
  bool isAccessDenied = false;

  PlatformFile? cvFile;
  PlatformFile? portfolioFile;
  PlatformFile? paymentFile;

  String? _existingCvUrl;
  String? _existingPortfolioUrl;

  bool _isLoading = false;

  // Warna Utama (Kuning Khaki)
  final Color mainYellow = const Color(0xFFF0E68C);

  @override
  void initState() {
    super.initState();

    final provider = context.read<DatabaseProvider>();
    final user = provider.currentUser;
    final category = widget.event.category.toLowerCase();

    if (user != null) {
      String userRole = user.role.toLowerCase();
      if (userRole == "siswa" && (category == "event" || category == "pengmas")) {
        isAccessDenied = true;
      }
      userStatus = (userRole == "siswa") ? "Siswa" : "Mahasiswa";
    }

    if (category == 'lomba') {
      subEvents = List.from(widget.event.subEvents);
    } else {
      divisions = List.from(widget.event.divisions);
      if (divisions.isEmpty) divisions = ["General Participant"];
    }

    if (user != null) {
      nameController.text = user.fullName;
      institutionController.text = user.institution ?? "";
      majorController.text = user.major ?? "";
      yearController.text = user.batch ?? "";
      phoneController.text = user.phone ?? "";
      _existingCvUrl = user.cvUrl;
      _existingPortfolioUrl = user.portfolioUrl;
    }
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "jpg", "png", "jpeg"],
      withData: true,
    );
    if (result != null) return result.files.first;
    return null;
  }

  Future<void> _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                size: 60,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (isSuccess) Navigator.pop(context);
                  },
                  child: Text(isSuccess ? "Selesai" : "Coba Lagi"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final category = widget.event.category.toLowerCase();

    if (category == 'event' && (cvFile == null && (_existingCvUrl == null || _existingCvUrl!.isEmpty))) {
      _showResultDialog(isSuccess: false, title: "Dokumen Kurang", message: "CV wajib dilampirkan.");
      return;
    }
    if (category == 'lomba' && paymentFile == null) {
      _showResultDialog(isSuccess: false, title: "Dokumen Kurang", message: "Bukti pembayaran wajib diunggah.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<DatabaseProvider>();
      String? finalCvUrl = cvFile != null ? await provider.uploadFile(cvFile!.bytes!, cvFile!.extension!, "cv") : _existingCvUrl;
      String? finalPfUrl = portfolioFile != null ? await provider.uploadFile(portfolioFile!.bytes!, portfolioFile!.extension!, "portfolio") : _existingPortfolioUrl;
      String? finalPaymentUrl = (category == 'lomba' && paymentFile != null) ? await provider.uploadFile(paymentFile!.bytes!, paymentFile!.extension!, "payment") : null;

      final success = await provider.registerToEvent(
        widget.event.id,
        (category == 'lomba') ? (selectedSubEvent ?? "Umum") : (selectedDivision ?? "Umum"),
        finalCvUrl,
        finalPaymentUrl ?? finalPfUrl,
      );

      if (success && mounted) {
        await _showResultDialog(isSuccess: true, title: "Berhasil!", message: "Data Anda telah tersimpan.");
      }
    } catch (e) {
      if (mounted) _showResultDialog(isSuccess: false, title: "Gagal", message: "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAccessDenied) return _buildDeniedAccessUI();
    final category = widget.event.category.toLowerCase();

    return Column(
      children: [
        _buildHeader(), // GRADIENT HEADER ADA DI SINI
        Transform.translate(
          offset: const Offset(0, -80),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text("Registration Form", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                      const Text("Find Your Next Experience", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 30),
                      _buildLockedStatusChip(userStatus),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(child: buildInput("Nama Lengkap", nameController)),
                          const SizedBox(width: 15),
                          Expanded(child: buildInput(userStatus == "Mahasiswa" ? "Universitas" : "Sekolah", institutionController)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          if (userStatus == "Mahasiswa") ...[
                            Expanded(child: buildInput("Jurusan", majorController)),
                            const SizedBox(width: 15),
                          ],
                          Expanded(child: buildInput("Tahun / Angkatan", yearController)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: buildInput("Nomor WhatsApp", phoneController)),
                          const SizedBox(width: 15),
                          Expanded(child: (category == 'lomba') ? buildSubEventDropdown() : buildDivisionDropdown()),
                        ],
                      ),
                      const SizedBox(height: 25),
                      if (category == 'event') ...[
                        _buildFileSection("Curriculum Vitae", cvFile, _existingCvUrl, (f) => setState(() => cvFile = f), () => setState(() => _existingCvUrl = null)),
                        const SizedBox(height: 25),
                        _buildFileSection("Portfolio (Opsional)", portfolioFile, _existingPortfolioUrl, (f) => setState(() => portfolioFile = f), () => setState(() => _existingPortfolioUrl = null)),
                      ],
                      if (category == 'lomba') ...[
                        _buildFileSection("Bukti Transfer", paymentFile, null, (f) => setState(() => paymentFile = f), () {}),
                      ],
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== HEADER DENGAN GRADIENT 3 WARNA =====
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 120),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFFFE0), // Kuning Terang
            Color(0xFFFFF9C4), // Kuning Menengah
            Color(0xFFF0E68C), // Khaki (Kuning Tua)
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.event.name, 
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black), 
            textAlign: TextAlign.center
          ),
          const SizedBox(height: 10),
          const Text(
            "This Isn’t Just an Event. It’s the Experience\nEveryone Will Talk About.", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87, fontStyle: FontStyle.italic)
          ),
        ],
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: mainYellow, width: 2), borderRadius: BorderRadius.circular(8)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget buildDivisionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Divisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedDivision,
          items: divisions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.black)))).toList(),
          onChanged: (value) => setState(() => selectedDivision = value),
          validator: (v) => v == null ? "Wajib pilih divisi" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: mainYellow, width: 2), borderRadius: BorderRadius.circular(8)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget buildSubEventDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Cabang Lomba", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedSubEvent,
          items: subEvents.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.black)))).toList(),
          onChanged: (value) => setState(() => selectedSubEvent = value),
          validator: (v) => v == null ? "Wajib pilih cabang" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: mainYellow, width: 2), borderRadius: BorderRadius.circular(8)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget buildUploadBox({required String title, PlatformFile? file, String? existingUrl, required VoidCallback onPick, required VoidCallback onRemove}) {
    bool hasFile = file != null || (existingUrl != null && existingUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 10),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
          child: !hasFile
              ? Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, side: BorderSide(color: Colors.grey.shade300)),
                    onPressed: onPick,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text("Pilih File", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              : Stack(
                  children: [
                    Center(child: Text(file?.name ?? "File terunggah", style: const TextStyle(color: Colors.black))),
                    Positioned(right: 10, top: 10, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: onRemove)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainYellow, 
          foregroundColor: Colors.black, 
          padding: const EdgeInsets.symmetric(vertical: 20), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.black) 
            : const Text("Kirim Pendaftaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLockedStatusChip(String label) {
    return Chip(
      label: Text("Terdaftar sebagai: $label", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: mainYellow,
      avatar: const Icon(Icons.verified_user, color: Colors.black, size: 20),
    );
  }

  Widget _buildDeniedAccessUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 80, color: Colors.red),
          const Text("Akses Ditolak", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          const Text("Kategori ini hanya untuk Mahasiswa.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kembali")),
        ],
      ),
    );
  }

  Widget _buildFileSection(String title, PlatformFile? file, String? url, Function(PlatformFile?) onPick, VoidCallback onRem) {
    return buildUploadBox(title: title, file: file, existingUrl: url, onPick: () async {
      final f = await pickFile();
      if (f != null) onPick(f);
    }, onRemove: onRem);
  }
} 