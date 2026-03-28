// File: lib/view/widgets/recentsEventSection.dart
part of 'pages.dart';

class RecentEventsSection extends StatelessWidget {
  const RecentEventsSection({super.key});

  bool _isRecent(EventModel event) {
    // Logic: Event opened registration within the last 7 days
    final now = DateTime.now();
    final diffDays = now.difference(event.openRegDate).inDays;
    return diffDays >= 0 && diffDays <= 7;
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari Provider
    final dbProvider = context.watch<DatabaseProvider>();
    final recentEvents = dbProvider.events.where(_isRecent).toList();

    if (recentEvents.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Recent Events",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF143952),
              ),
            ),
          ),
          
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // Atur jarak kiri-kanan di sini
            child: Container(
              width: 110,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF143952),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "This isn't Just an Event, It's the Experience\n"
              "Everyone Will Talk About.",
              style: TextStyle(color: Color(0xFF143952), height: 1.5),
            ),
          ),

          const SizedBox(height: 50),

          SizedBox(
            height: 430,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 30),
              itemBuilder: (context, index) {
                return EventCard(
                  event: recentEvents[index],
                  tag: "Just Now",
                  tagColor: Colors.blue,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
