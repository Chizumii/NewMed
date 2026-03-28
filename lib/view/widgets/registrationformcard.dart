import 'dart:io';
import 'package:newmed/model/custom_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
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

  String? selectedDivision; // Untuk Event/Pengmas
  String? selectedSubEvent; // Untuk Lomba
  List<String> divisions = [];
  List<String> subEvents = [];

  String userStatus = "Mahasiswa";
  bool isAccessDenied = false; // Flag untuk blokir akses

  PlatformFile? cvFile;
  PlatformFile? portfolioFile;
  PlatformFile? paymentFile;

  String? _existingCvUrl;
  String? _existingPortfolioUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final provider = context.read<DatabaseProvider>();
    final user = provider.currentUser;
    final category = widget.event.category.toLowerCase();

    // 1. CEK VALIDASI AKSES ROLE
    if (user != null) {
      String userRole = user.role.toLowerCase();

      // Siswa tidak boleh ikut Event atau Pengmas
      if (userRole == "siswa" &&
          (category == "event" || category == "pengmas")) {
        isAccessDenied = true;
      }

      // Set status default berdasarkan profile database
      userStatus = (userRole == "siswa") ? "Siswa" : "Mahasiswa";
    }

    // 2. SETUP DATA DARI DATABASE (Divisi atau Sub Event)
    if (category == 'lomba') {
      subEvents = List.from(widget.event.subEvents);
    } else {
      divisions = List.from(widget.event.divisions);
      if (divisions.isEmpty) divisions = ["General Participant"];
    }

    // 3. AUTO-FILL DATA
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

  // --- FUNGSI POP-UP DIALOG HASIL ---
  Future<void> _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User harus tekan tombol untuk menutup
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. ICON (Centang Hijau / Silang Merah)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    size: 60,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. JUDUL
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSuccess
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. PESAN
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // 4. TOMBOL (Selesai / Coba Lagi)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Tutup Dialog

                      if (isSuccess) {
                        Navigator.pop(
                            context); // Jika Sukses, Tutup Form & Balik ke Halaman Event
                      }
                      // Jika Gagal, hanya tutup dialog agar user bisa edit form
                    },
                    child: Text(
                      isSuccess ? "Selesai" : "Coba Lagi",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI SUBMIT FORM ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final category = widget.event.category.toLowerCase();

    // Validasi Dokumen (Manual)
    if (category == 'event' &&
        (cvFile == null &&
            (_existingCvUrl == null || _existingCvUrl!.isEmpty))) {
      _showResultDialog(
        isSuccess: false,
        title: "Dokumen Kurang",
        message: "CV wajib dilampirkan untuk kategori Event.",
      );
      return;
    }

    if (category == 'lomba' && paymentFile == null) {
      _showResultDialog(
        isSuccess: false,
        title: "Dokumen Kurang",
        message: "Bukti pembayaran wajib diunggah.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DatabaseProvider>();
      String? finalCvUrl;
      String? finalPfUrl;
      String? finalPaymentUrl;

      // Upload File
      if (category == 'event') {
        finalCvUrl = cvFile != null
            ? await provider.uploadFile(
                cvFile!.bytes!,
                cvFile!.extension!,
                "cv",
              )
            : _existingCvUrl;
        finalPfUrl = portfolioFile != null
            ? await provider.uploadFile(
                portfolioFile!.bytes!,
                portfolioFile!.extension!,
                "portfolio",
              )
            : _existingPortfolioUrl;
      }

      if (category == 'lomba' && paymentFile != null) {
        finalPaymentUrl = await provider.uploadFile(
          paymentFile!.bytes!,
          paymentFile!.extension!,
          "payment",
        );
      }

      // Simpan ke Database
      final success = await provider.registerToEvent(
        widget.event.id,
        (category == 'lomba')
            ? (selectedSubEvent ?? "Umum")
            : (selectedDivision ?? "Umum"),
        finalCvUrl,
        finalPaymentUrl ?? finalPfUrl,
      );

      if (success) {
        if (mounted) {
          // TAMPILKAN DIALOG SUKSES
          await _showResultDialog(
            isSuccess: true,
            title: "Pendaftaran Berhasil!",
            message:
                "Data Anda telah tersimpan. Silakan tunggu informasi selanjutnya.",
          );
        }
      } else {
        throw "Gagal menyimpan data ke database";
      }
    } catch (e) {
      if (mounted) {
        // TAMPILKAN DIALOG GAGAL
        await _showResultDialog(
          isSuccess: false,
          title: "Pendaftaran Gagal",
          message:
              "Terjadi kesalahan: $e.\nSilakan periksa koneksi dan coba lagi.",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAccessDenied) {
      return _buildDeniedAccessUI();
    }

    final category = widget.event.category.toLowerCase();

    return Column(
      children: [
        _buildHeader(),
        Transform.translate(
          offset: const Offset(0, -80),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Registration Form",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'VisuletPro',
                          color: Color(0xff143952),
                        ),
                      ),
                      Text(
                        "This Isn’t Just an Event. It’s the Experience\nEveryone Will Talk About.",
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'VisuletPro',
                          color: Color(0xff143952),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Status dikunci berdasarkan role asli di database
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildLockedStatusChip(userStatus)],
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: buildInput("Nama Lengkap", nameController),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: buildInput(
                              userStatus == "Mahasiswa"
                                  ? "Universitas"
                                  : "Sekolah",
                              institutionController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          if (userStatus == "Mahasiswa") ...[
                            Expanded(
                              child: buildInput("Jurusan", majorController),
                            ),
                            const SizedBox(width: 15),
                          ],
                          Expanded(
                            child: buildInput(
                              "Tahun / Angkatan",
                              yearController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: buildInput(
                              "Nomor WhatsApp",
                              phoneController,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Dropdown Dinamis: Sub Event (Lomba) atau Divisi (Event/Pengmas)
                          Expanded(
                            child: (category == 'lomba')
                                ? buildSubEventDropdown()
                                : buildDivisionDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      if (category == 'event') ...[
                        _buildFileSection(
                          "Curriculum Vitae",
                          cvFile,
                          _existingCvUrl,
                          (f) => setState(() => cvFile = f),
                          () => setState(() => _existingCvUrl = null),
                        ),
                        const SizedBox(height: 25),
                        _buildFileSection(
                          "Portfolio Opsional",
                          portfolioFile,
                          _existingPortfolioUrl,
                          (f) => setState(() => portfolioFile = f),
                          () => setState(() => _existingPortfolioUrl = null),
                        ),
                      ],

                      if (category == 'lomba') ...[
                        _buildFileSection(
                          "Bukti Transfer Pendaftaran",
                          paymentFile,
                          null,
                          (f) => setState(() => paymentFile = f),
                          () {},
                        ),
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

  // UI untuk Siswa yang mencoba masuk ke Event/Pengmas
  Widget _buildDeniedAccessUI() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            "Akses Terbatas",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Maaf, pendaftaran Event dan Pengmas hanya terbuka untuk Mahasiswa. Siswa hanya diperbolehkan mengikuti kategori Lomba.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kembali ke Beranda"),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedStatusChip(String label) {
    return Chip(
      label: Text("Terdaftar sebagai: $label"),
      backgroundColor: const Color(0xff3F054F),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      avatar: const Icon(Icons.verified, color: Colors.white, size: 18),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff123C52), Color(0xff3F054F)],
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.event.name,
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Find Your Next Experience",
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontFamily: 'VisuletPro',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSubEventDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pilih Cabang Lomba",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffA0025B),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: selectedSubEvent,
          items: subEvents
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) => setState(() => selectedSubEvent = value),
          validator: (v) => v == null ? "Wajib pilih cabang" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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
        const Text(
          "Pilih Divisi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffA0025B),
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: selectedDivision,
          items: divisions
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (value) => setState(() => selectedDivision = value),
          validator: (v) => v == null ? "Wajib pilih divisi" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSection(
    String title,
    PlatformFile? file,
    String? existingUrl,
    Function(PlatformFile?) onPick,
    VoidCallback onRem,
  ) {
    return buildUploadBox(
      title: title,
      file: file,
      existingUrl: existingUrl,
      onPick: () async {
        final f = await pickFile();
        if (f != null) onPick(f);
      },
      onRemove: onRem,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff3F054F),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: _isLoading ? null : _submitForm,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Kirim Pendaftaran",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffA0025B),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: (v) => v == null || v.isEmpty ? "Wajib diisi" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget buildUploadBox({
    required String title,
    PlatformFile? file,
    String? existingUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    bool hasFile =
        file != null || (existingUrl != null && existingUrl.isNotEmpty);
    bool isImage = false;
    if (file != null) {
      isImage =
          ["jpg", "jpeg", "png"].contains(file.extension?.toLowerCase());
    } else if (existingUrl != null) {
      isImage = existingUrl.contains('.jpg') ||
          existingUrl.contains('.jpeg') ||
          existingUrl.contains('.png');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffA0025B),
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: !hasFile
                  ? Center(
                      child: ElevatedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Pilih File"),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isImage
                          ? (file != null
                              ? (kIsWeb
                                  ? Image.memory(
                                      file.bytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(file.path!),
                                      fit: BoxFit.cover,
                                    ))
                              : Image.network(
                                  existingUrl!,
                                  fit: BoxFit.cover,
                                ))
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.description,
                                    size: 50,
                                    color: Colors.blue,
                                  ),
                                  Text(file?.name ?? "Dokumen"),
                                ],
                              ),
                            ),
                    ),
            ),
            if (hasFile)
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: onRemove,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}