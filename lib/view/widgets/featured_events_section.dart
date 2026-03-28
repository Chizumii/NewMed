// File: lib/view/widgets/featured_events_section.dart
part of 'pages.dart';

class FeaturedEventsSection extends StatelessWidget {
  const FeaturedEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA DARI DATABASE
    final dbProvider = context.watch<DatabaseProvider>();
    final now = DateTime.now();

    // 2. FILTER: Event yang SEDANG BUKA pendaftaran (Open)
    final featuredEvents = dbProvider.events.where((e) {
      // Logic: Sekarang harus setelah Buka DAN sebelum Tutup
      return now.isAfter(e.openRegDate) && now.isBefore(e.closeRegDate);
    }).toList();

    // Hide section if no events match (Optional, or keep "No active events")
    // if (featuredEvents.isEmpty) return const SizedBox(); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Featured Events",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "This isn't Just an Event, It's the Experience\n"
            "Everyone Will Talk About.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 50),

          // ===== EVENT CARD (DATA ASLI) =====
          if (featuredEvents.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "No active events currently.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Wrap(
              spacing: 30,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: featuredEvents.map((event) {
                return EventCard(
                  event: event,
                  tag: "Open Now",
                  tagColor: Colors.pink,
                );
              }).toList(),
            ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}