import 'package:newmed/view/pages/participant_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/custom_models.dart';
import '../../../viewmodel/database_provider.dart';
import '../../widgets/organizer_form.dart';
import '../../widgets/tables/management_table.dart';
import '../../widgets/organizer_navbar.dart'; // Pastikan import ini benar

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  // State untuk Tab Aktif
  String _activeTab = "Daftar Event";

  @override
  void initState() {
    super.initState();
    // Ambil data event milik organizer ini saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().fetchMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();
    final myEvents = provider.myEvents;
    final isLoading = provider.isLoading;

    // --- LOGIKA FILTERING BERDASARKAN TAB ---
    List<EventModel> filteredData = [];
    String currentCategoryFilter = '';

    if (_activeTab == "Daftar Event") {
      currentCategoryFilter = 'event';
    } else if (_activeTab == "Daftar Lomba") {
      currentCategoryFilter = 'lomba';
    } else if (_activeTab == "Daftar Pengmas") {
      currentCategoryFilter = 'pengmas';
    }

    // Filter list event berdasarkan kategori tab
    filteredData = myEvents
        .where((e) => e.category.toLowerCase() == currentCategoryFilter)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu sedikit biar rapi
      body: Column(
        children: [
          // 1. NAVBAR (Pengganti AppBar)
          OrganizerNavbar(
            activeTab: _activeTab,
            onTabChanged: (newTab) {
              setState(() {
                _activeTab = newTab;
              });
            },
          ),

          // 2. CONTENT AREA
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul Halaman sesuai Tab
                        Text(
                          "Kelola $_activeTab",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff123C52),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Daftar kegiatan yang telah Anda buat.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 20),

                        // TABLE CARD
                        Expanded(
                          child: Card(
                            elevation: 2, // Shadow tipis biar elegan
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ManagementTable(
                                data:
                                    filteredData, // Gunakan data yang sudah difilter
                                type: "Organizer",

                                // --- FITUR EDIT ---
                                onEdit: (event) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrganizerForm(
                                        category: event.category,
                                        initialData: event,
                                      ),
                                    ),
                                  );
                                },

                                // --- FITUR DELETE ---
                                onDelete: (id) async {
                                  await provider.deleteEvent(id);
                                  // Refresh otomatis ditangani provider, tapi kita bisa kasih notif
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Kegiatan berhasil dihapus",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },

                                // --- FITUR LIHAT PESERTA ---
                                onCheckParticipants: (event) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ParticipantListPage(event: event),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // TOMBOL TAMBAH (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Buka Form Baru sesuai kategori tab yang aktif
          String catToSend = 'Event'; // Default
          if (_activeTab == "Daftar Lomba") catToSend = 'Lomba';
          if (_activeTab == "Daftar Pengmas") catToSend = 'Pengmas';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizerForm(category: catToSend),
            ),
          );
        },
        backgroundColor: const Color(0xFFF0E68C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Buat ${currentCategoryFilter.isNotEmpty ? currentCategoryFilter[0].toUpperCase() + currentCategoryFilter.substring(1) : 'Kegiatan'}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
