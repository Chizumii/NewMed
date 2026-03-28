// File: lib/view/widgets/lastChanceEventSection.dart
part of 'pages.dart';

class LastChanceEventsSection extends StatelessWidget {
  const LastChanceEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseProvider>();
    final now = DateTime.now();

    final lastChanceEvents = dbProvider.events
        .where((event) {
          // Logic: 
          // 1. Event has started (now is after openReg)
          // 2. Event has NOT ended (now is before closeReg)
          // 3. Closing within 7 days
          
          final difference = event.closeRegDate.difference(now);
          
          // No need for '!' or '!= null' checks because fields are non-nullable
          return now.isAfter(event.openRegDate) &&
                 now.isBefore(event.closeRegDate) &&
                 difference.inDays >= 0 &&
                 difference.inDays <= 7;
        })
        .toList()
        // Sort by which one closes soonest
        ..sort((a, b) => a.closeRegDate.compareTo(b.closeRegDate));

    // Hide section if empty
    if (lastChanceEvents.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Last Chance Events",
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
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF143952),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "This Isn’t Just an Event. It’s the Experience\n"
              "Everyone Will Talk About.",
              style: TextStyle(
                color: Color(0xFF143952),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 45),

          SizedBox(
            height: 420,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: lastChanceEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 30),
              itemBuilder: (context, index) {
                return EventCard(
                  event: lastChanceEvents[index],
                  tag: "Closing Soon",
                  tagColor: const Color(0xffA0025B),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}