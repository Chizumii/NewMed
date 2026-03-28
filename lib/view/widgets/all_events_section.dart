part of 'pages.dart';

class AllEventsSection extends StatelessWidget {
  const AllEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data dari Provider
    final dbProvider = context.watch<DatabaseProvider>();

    // 2. Ambil data events (Provider sudah menangani sorting kuota & filtering)
    final List<EventModel> displayEvents = dbProvider.events;

    // 3. Ambil data untuk Filter Chips
    final List<String> divisions = dbProvider.getAvailableDivisions();
    final String selectedFilter = dbProvider.selectedDivisionFilter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- JUDUL ---
          const Text(
            "All Events",
            style: TextStyle(
              fontFamily: 'VisuletPro',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF143952),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(), 
            child: Container(
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF143952),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(),
            child: Text(
              "This Isn’t Just an Event. It’s the Experience\n"
              "Everyone Will Talk About.",
              style: TextStyle(
                color: Color(0xFF143952),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- [BARU] FITUR FILTER DIVISI (CHIPS) ---
          if (divisions.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: divisions.map((div) {
                  final isSelected = div == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(div),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        // Jika di-klik, set filter. Jika di-unselect, set ke "All"
                        context.read<DatabaseProvider>().setDivisionFilter(
                          selected ? div : "All"
                        );
                      },
                      // Styling Chip
                      selectedColor: const Color(0xFF3F054F),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // --- LOGIKA ISI KONTEN ---
          if (displayEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  "Tidak ada event yang sesuai filter.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Scroll ikut parent
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.75, 
              ),
              itemCount: displayEvents.length,
              itemBuilder: (context, index) {
                final event = displayEvents[index];
                
                // EventCard otomatis menampilkan data yang sudah difilter & disortir
                return EventCard(
                  event: event,
                  tag: "Open Now", 
                  tagColor: Colors.green, 
                );
              },
            ),
        ],
      ),
    );
  }
}