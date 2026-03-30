// File: lib/view/widgets/navbar.dart
part of 'pages.dart';

class Navbar extends StatelessWidget {
  final bool isLoggedIn;
  final String activePage;

  const Navbar({super.key, required this.isLoggedIn, this.activePage = "Home"});

  // Widget pembantu untuk Link Navigasi dengan efek Hover
  Widget _navLink(
    BuildContext context,
    String text,
    bool isActive,
    VoidCallback onTap,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      // Warna teks hitam, berubah ungu saat hover
                      color: isHovered ? const Color(0xFFB763DD) : Colors.black,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indikator garis bawah
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isActive ? 24 : 0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI DIALOG KONFIRMASI LOGOUT ---
  void _showLogoutDialog(BuildContext context, DatabaseProvider dbProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar akun?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                dbProvider.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("Ya, Keluar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dbProvider = context.watch<DatabaseProvider>();
    final user = dbProvider.currentUser;
    final bool isDesktop = width > 800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
      // ===== UPDATE WARNA GRADASI DI SINI =====
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
      child: Row(
        children: [
          Image.asset('assets/Image/logo.svg', height: 45),
          const Spacer(),

          if (isDesktop) ...[
            _navLink(context, "Home", activePage == "Home", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
            }),
            _navLink(context, "Event", activePage == "Event", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const Eventpage()));
            }),
          ],

          const SizedBox(width: 25),

          if (isLoggedIn)
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              tooltip: "Account Menu",
              onSelected: (value) {
                if (value == 'organize') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerDashboard()));
                } else if (value == 'admin') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                } else if (value == 'history') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRegistrationsPage()));
                } else if (value == 'profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                } else if (value == 'logout') {
                  _showLogoutDialog(context, dbProvider);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (user?.role == 'organizer')
                  const PopupMenuItem<String>(
                    value: 'organize',
                    child: _PopupItem(icon: Icons.event_note, text: 'Organize Events'),
                  ),
                if (user?.role == 'admin')
                  const PopupMenuItem<String>(
                    value: 'admin',
                    child: _PopupItem(icon: Icons.admin_panel_settings, text: 'Manage Admin'),
                  ),
                const PopupMenuItem<String>(
                  value: 'history',
                  child: _PopupItem(icon: Icons.history, text: 'My Registrations'),
                ),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: _PopupItem(icon: Icons.person, text: 'Manage Profile'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: _PopupItem(
                    icon: Icons.logout, 
                    text: 'Logout', 
                    textColor: Colors.red, 
                    iconColor: Colors.red
                  ),
                ),
              ],
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : const NetworkImage("https://cdn-icons-png.freepik.com/512/6522/6522516.png"),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user?.email ?? "User",
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black),
                  ],
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Log In", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// Widget internal untuk item menu popup
class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color iconColor;

  const _PopupItem({
    required this.icon,
    required this.text,
    this.textColor = Colors.black87,
    this.iconColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: textColor, fontSize: 14)),
      ],
    );
  }
}