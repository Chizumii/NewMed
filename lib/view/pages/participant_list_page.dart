import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../viewmodel/database_provider.dart';
import '../../../model/custom_models.dart';

class ParticipantListPage extends StatefulWidget {
  final EventModel event;

  const ParticipantListPage({super.key, required this.event});

  @override
  State<ParticipantListPage> createState() => _ParticipantListPageState();
}

class _ParticipantListPageState extends State<ParticipantListPage> {
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await context.read<DatabaseProvider>().fetchEventParticipants(
      widget.event.id,
    );
    setState(() {
      _participants = data;
      _isLoading = false;
    });
  }

  // Ganti seluruh fungsi _updateStatus dengan ini:
  Future<void> _updateStatus(String regId, String status) async {
    // 1. Panggil Database (Save ke Server)
    final success = await context
        .read<DatabaseProvider>()
        .updateParticipantStatus(regId, status);

    if (success) {
      // 2. Update Tampilan Lokal (Biar langsung berubah warnanya)
      setState(() {
        final index = _participants.indexWhere(
          (p) => p['id'].toString() == regId,
        );
        if (index != -1) {
          _participants[index]['status'] = status;
        }
      });

      // 3. Info ke User
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status disimpan: ${status.toUpperCase()}"),
            backgroundColor: status == 'accepted'
                ? Colors.green
                : (status == 'rejected' ? Colors.red : Colors.orange),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Peserta: ${widget.event.name}"),
        centerTitle: true,
        foregroundColor: Colors.white,
        // Membuat Background AppBar menjadi Gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff123C52), Color(0xff3F054F)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
          ? const Center(child: Text("Belum ada pendaftar."))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.topCenter, // Menjaga konten di tengah atas
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Center(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey[100],
                            ),
                            columnSpacing: 25,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Nama',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Jurusan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Angkatan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'No. WA',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'ID Line',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Instansi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Divisi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Dokumen',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Aksi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: _participants.map((p) {
                              final profile =
                                  p['profiles'] as Map<String, dynamic>? ?? {};
                              final regId = p['id'].toString();
                              final currentStatus =
                                  p['status']?.toString().toLowerCase() ??
                                  "pending";

                              return DataRow(
                                cells: [
                                  DataCell(Text(profile['full_name'] ?? "-")),
                                  DataCell(Text(profile['email'] ?? "-")),
                                  DataCell(Text(profile['major'] ?? "-")),
                                  DataCell(
                                    Text(
                                      profile['batch_year']?.toString() ?? "-",
                                    ),
                                  ),
                                  DataCell(
                                    Text(profile['phone_number'] ?? "-"),
                                  ),
                                  DataCell(Text(profile['line_id'] ?? "-")),
                                  DataCell(Text(profile['institution'] ?? "-")),
                                  DataCell(Text(p['chosen_division'] ?? "-")),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (p['cv_link'] != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.description,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: "Buka CV",
                                            onPressed: () =>
                                                _openLink(p['cv_link']),
                                          ),
                                        if (p['payment_proof_url'] != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.receipt_long,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: "Buka Bukti/Porto",
                                            onPressed: () => _openLink(
                                              p['payment_proof_url'],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        // LOGIKA WARNA STATUS
                                        color: currentStatus == 'accepted'
                                            ? Colors.green.shade100
                                            : (currentStatus == 'rejected'
                                                  ? Colors.red.shade100
                                                  : Colors.orange.shade100),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        currentStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          // LOGIKA WARNA TEKS
                                          color: currentStatus == 'accepted'
                                              ? Colors.green.shade900
                                              : (currentStatus == 'rejected'
                                                    ? Colors.red.shade900
                                                    : Colors.orange.shade900),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          tooltip: "Terima",
                                          onPressed: () =>
                                              _updateStatus(regId, "accepted"),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          tooltip: "Tolak",
                                          onPressed: () =>
                                              _updateStatus(regId, "rejected"),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.history,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                          tooltip: "Pending",
                                          onPressed: () =>
                                              _updateStatus(regId, "pending"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
