part of 'pages.dart';

class EventHeader extends StatefulWidget {
  final bool isLoggedIn;

  const EventHeader({super.key, required this.isLoggedIn});

  @override
  State<EventHeader> createState() => _EventHeaderState();
}

class _EventHeaderState extends State<EventHeader> {
  // 1. Controller untuk input search
  final TextEditingController _searchController = TextEditingController();

  // 2. Fungsi pencarian
  void _onSearch(String query) {
    context.read<DatabaseProvider>().searchEvents(query);
  }

  // --- FUNGSI CEK LOGIN (Hanya dipakai untuk Search Result nanti, kalau perlu) ---
  Future<void> _checkLoginAndProceed(BuildContext context, VoidCallback action) async {
    final provider = context.read<DatabaseProvider>();
    
    if (provider.isLoggedIn) {
      action();
    } else {
      bool confirm = await showConfirmationDialog(
        context,
        title: "Akses Terbatas",
        message: "Kamu harus login terlebih dahulu untuk melihat detail event ini.",
        confirmLabel: "Login",
        cancelLabel: "Batal",
      );

      if (confirm && context.mounted) {
        Navigator.pushNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseProvider>();
    final now = DateTime.now();

    // Filter event Upcoming (Yang pendaftarannya BELUM dibuka)
    final upcomingEvents = dbProvider.events.where((e) {
      return now.isBefore(e.openRegDate);
    }).toList();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3F054F), Color(0xFF291F51), Color(0xFF103D52)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== NAVBAR =====
            Padding(
              padding: const EdgeInsets.symmetric(),
              child: Navbar(isLoggedIn: widget.isLoggedIn, activePage: "Event"),
            ),

            const SizedBox(height: 20),

            // ===== TITLE + CARD (SEJAJAR) =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== LEFT TEXT =====
                SizedBox(
                  width: 450,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 60.0, top: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upcoming\nEvents",
                          style: TextStyle(
                            fontFamily: 'VisuletPro',
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 90,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "This Isn’t Just an Event. It’s \nthe Experience Everyone \nWill Talk About.",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'VisuletPro',
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // ===== RIGHT CARD (DATA UPCOMING) =====
                Expanded(
                  child: SizedBox(
                    height: 340,
                    child: upcomingEvents.isEmpty
                        ? const Center(
                            child: Text(
                              "No upcoming events",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(right: 40),
                            itemCount: upcomingEvents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 24),
                            itemBuilder: (context, index) {
                              final event = upcomingEvents[index];
                              
                              // --- UPDATE LOGIC DI SINI ---
                              return GestureDetector(
                                onTap: () {
                                  // KARENA INI LIST UPCOMING (BELUM BUKA),
                                  // KITA BLOKIR NAVIGASI DAN TAMPILKAN WARNING.
                                  
                                  String openDateStr = DateFormat('dd MMMM yyyy').format(event.openRegDate);

                                  showErrorDialog(
                                    context,
                                    title: "Coming Soon",
                                    message: "Pendaftaran event ini baru akan dibuka pada tanggal:\n\n$openDateStr",
                                  );
                                  
                                  // Return agar tidak lanjut navigasi
                                  return;
                                },
                                // AbsorbPointer mencegah UpcomingEventCard menerima klik langsung
                                child: AbsorbPointer(
                                  child: UpcomingEventCard(
                                    event: event,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ===== SEARCH BAR =====
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 180,
                vertical: 30,
              ),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFB763DD), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC83BB).withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF263238)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Color(0xFF263238)),
              decoration: const InputDecoration(
                hintText: "Search events by name...",
                hintStyle: TextStyle(color: Color(0xFF263238)),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _onSearch(_searchController.text),
            child: Icon(
              Icons.send,
              color: const Color(0xFF263238).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}