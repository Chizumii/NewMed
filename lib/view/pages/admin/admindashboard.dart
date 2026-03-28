import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodel/database_provider.dart';
import '../../../model/custom_models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String activeTab = "Monitor Konten";

  @override
  void initState() {
    super.initState();
    // Fetch data user saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();
    final allEvents = provider.events;
    final allUsers = provider.allUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Admin Control Center"),
        backgroundColor: const Color(0xff123C52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => provider.logout(),
            
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                _sideItem("Monitor Konten", Icons.dashboard),
                _sideItem("Manajemen Role", Icons.people),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: activeTab == "Monitor Konten"
                  ? _buildMonitorTable(allEvents, provider)
                  : _buildRoleTable(allUsers, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(String t, IconData i) => ListTile(
    leading: Icon(
      i,
      color: activeTab == t ? const Color(0xff123C52) : Colors.grey,
    ),
    title: Text(
      t,
      style: TextStyle(
        fontWeight: activeTab == t ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    onTap: () => setState(() => activeTab = t),
  );

  Widget _buildMonitorTable(
    List<EventModel> events,
    DatabaseProvider provider,
  ) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nama Proker')),
            DataColumn(label: Text('Organizer')),
            DataColumn(label: Text('Tipe')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: events
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(Text(item.organization)),
                    DataCell(Text(item.category)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => provider.deleteEvent(item.id),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRoleTable(List<UserProfile> users, DatabaseProvider provider) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role Saat Ini')),
            DataColumn(label: Text('Ubah Role')),
          ],
          rows: users
              .map(
                (user) => DataRow(
                  cells: [
                    DataCell(Text(user.fullName)),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.role)),
                    DataCell(
                      provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<String>(
                              value:
                                  [
                                    'admin',
                                    'organizer',
                                    'mahasiswa',
                                    'siswa',
                                  ].contains(user.role)
                                  ? user.role
                                  : 'mahasiswa',
                              underline:
                                  const SizedBox(), // Hilangkan garis bawah agar lebih bersih
                              items:
                                  [
                                    'admin',
                                    'organizer',
                                    'mahasiswa',
                                    'siswa',
                                  ].map((String v) {
                                    return DropdownMenuItem<String>(
                                      value: v,
                                      child: Text(
                                        v,
                                        style: TextStyle(
                                          color: v == 'admin'
                                              ? Colors.red
                                              : (v == 'organizer'
                                                    ? Colors.blue
                                                    : Colors.black),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (newRole) async {
                                if (newRole != null && newRole != user.role) {
                                  // Tambahkan konfirmasi sederhana
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Konfirmasi Perubahan"),
                                      content: Text(
                                        "Ubah role ${user.fullName} menjadi $newRole?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text("Ya, Ubah"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    provider.updateUserRole(user.id, newRole);
                                  }
                                }
                              },
                            ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
