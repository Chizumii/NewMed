import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/database_provider.dart'; // Pastikan path ini benar sesuai struktur folder Anda
import 'custom_dialogs.dart'; // Sesuaikan path jika perlu '../custom_dialogs.dart'

class OrganizerNavbar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChanged;

  const OrganizerNavbar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.read<DatabaseProvider>();
    final user = dbProvider.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff123C52), Color(0xff3F054F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Logo / Judul Dashboard
          const Text(
            "Organizer Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 40),

          // --- MENU NAVIGASI ---

          // Tab Filter Event
          _navItem(
            label: "Daftar Event",
            isActive: activeTab == "Daftar Event",
            onTap: () => onTabChanged("Daftar Event"),
          ),
          _navItem(
            label: "Daftar Lomba",
            isActive: activeTab == "Daftar Lomba",
            onTap: () => onTabChanged("Daftar Lomba"),
          ),
          _navItem(
            label: "Daftar Pengmas",
            isActive: activeTab == "Daftar Pengmas",
            onTap: () => onTabChanged("Daftar Pengmas"),
          ),

          const Spacer(),

          // --- PROFIL & LOGOUT ---
          PopupMenuButton<String>(
            // TARO DI SINI:
            onSelected: (value) async {
              if (value == 'home') {
                // Navigasi ke halaman home
                Navigator.pushNamed(context, '/home');
                // ...
              } else if (value == 'logout') {
                bool confirm = await showConfirmationDialog(
                  context,
                  title: "Keluar Dashboard",
                  message:
                      "Yakin ingin keluar? Pekerjaan yang belum disimpan mungkin hilang.",
                  confirmLabel: "Logout",
                  isDestructive: true,
                );

                if (confirm) {
                  await dbProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                }
              }
              // ...
            },
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Update bagian ini juga agar item 'home' bisa di-klik
              const PopupMenuItem<String>(
                value: 'home',
                enabled: true, // Pastikan true agar bisa diklik
                child: Row(
                  children: [
                    Icon(Icons.home, color: Colors.grey, size: 20),
                    SizedBox(width: 12),
                    Text("Back to Home Page"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk Item Navigasi
  Widget _navItem({
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
