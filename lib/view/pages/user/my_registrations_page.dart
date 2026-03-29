import 'package:newmed/view/widgets/footer_section.dart';
import 'package:newmed/view/widgets/pages.dart'; // Untuk Navbar
import 'package:newmed/viewmodel/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MyRegistrationsPage extends StatefulWidget {
  const MyRegistrationsPage({super.key});

  @override
  State<MyRegistrationsPage> createState() => _MyRegistrationsPageState();
}

class _MyRegistrationsPageState extends State<MyRegistrationsPage> {
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final data = await context.read<DatabaseProvider>().fetchMyRegistrations();
    if (mounted) {
      setState(() {
        _registrations = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty || url == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link grup belum tersedia.")),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuka link.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<DatabaseProvider, bool>(
      (p) => p.isLoggedIn,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. NAVBAR
            Navbar(isLoggedIn: isLoggedIn, activePage: "Profile"),

            // 2. HEADER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFFFFFE0),
                    Color(0xFFFFF9C4),
                    Color(0xFFF0E68C),
                  ],
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    "Riwayat Pendaftaran",
                    style: TextStyle(
                      fontFamily: 'VisuletPro',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Pantau status penerimaan event, lomba, dan pengmas kamu di sini.",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),

            // 3. CONTENT LIST
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _registrations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _registrations.length,
                        itemBuilder: (context, index) {
                          return _buildRegistrationCard(_registrations[index]);
                        },
                      ),
              ),
            ),

            // 4. FOOTER
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            "Belum ada riwayat pendaftaran.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> data) {
    // Parsing Data
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final event = data['events'] as Map<String, dynamic>? ?? {};
    final title = event['title'] ?? 'Unknown Event';
    final groupLink = event['whatsapp_group_link'];
    final eventDateStr = event['event_date'];
    DateTime? eventDate = eventDateStr != null
        ? DateTime.tryParse(eventDateStr)
        : null;

    // Tentukan Warna & Teks Status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'accepted') {
      statusColor = Colors.green;
      statusText = "DITERIMA";
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = "DITOLAK";
      statusIcon = Icons.cancel;
    } else {
      // DEFAULT: PENDING
      statusColor = Colors.orange;
      statusText = "PENDING";
      statusIcon = Icons.access_time_filled;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN KIRI: Judul & Info ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Event
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143952),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tanggal Event
                  if (eventDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('dd MMMM yyyy').format(eventDate),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 15),

                  // --- LOGIKA PESAN STATUS (Left Side) ---

                  // 1. Jika Diterima
                  if (status == 'accepted') ...[
                    const Text(
                      "Selamat! Silakan bergabung ke grup peserta:",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchURL(groupLink),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366), // Warna WA
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Join WhatsApp Group",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Jika Ditolak
                  ] else if (status == 'rejected') ...[
                    const Text(
                      "Mohon maaf, Anda belum lolos seleksi untuk kegiatan ini.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    // 3. Jika Pending (TAMBAHAN BARU)
                  ] else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_empty,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            "Pendaftaran sedang ditinjau oleh panitia.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 20),

            // --- BAGIAN KANAN: Status Chip ---
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
