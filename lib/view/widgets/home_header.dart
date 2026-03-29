part of 'pages.dart';

class HomeHeader extends StatefulWidget {
  final bool isLoggedIn;
  const HomeHeader({super.key, required this.isLoggedIn});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  // 1. Controller untuk menangkap teks input
  final TextEditingController _searchController = TextEditingController();

  // 2. Fungsi pencarian yang dipanggil saat teks berubah
  void _onSearch(String query) {
    // Memanggil provider untuk memfilter list event
    context.read<DatabaseProvider>().searchEvents(query);
  }

  @override
  void dispose() {
    _searchController.dispose(); // Bersihkan controller saat widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFFE0), Color(0xFFFFF9C4), Color(0xFFF0E68C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Navbar(isLoggedIn: widget.isLoggedIn, activePage: "Home"),
          const SizedBox(height: 80),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 140),
            child: const Text(
              "Find Your Next Experience",
              style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontFamily: 'VisuletPro',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 140),
            child: const Text(
              "Discover & Promote\nUpcoming Events",
              style: TextStyle(
                color: Colors.black,
                fontSize: 75,
                fontWeight: FontWeight.w900,
                fontFamily: 'VisuletPro',
                height: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 180,
              vertical: 50,
            ), // Atur angka sesuai keinginan
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF0E68C).withOpacity(0.6), // Shadow oren muda
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
        border: GradientBoxBorder(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0E68C), Color(0xFFFFF9C4)], // Border oren
          ),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF263238)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              // FUNGSI UTAMA: onChanged memicu pencarian real-time
              onChanged: _onSearch,

              style: const TextStyle(color: Color(0xFF263238)),
              decoration: const InputDecoration(
                hintText: "Search events by name or category...",
                hintStyle: TextStyle(color: Color(0xFF263238)),
                border: InputBorder.none,
              ),
            ),
          ),
          // Tombol kirim opsional (tetap bisa diklik, tapi search sudah otomatis)
          GestureDetector(
            onTap: () => _onSearch(_searchController.text),
            child: Icon(
              Icons.send,
              color: const Color(0xFF263238).withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
