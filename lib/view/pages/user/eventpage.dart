import 'package:newmed/view/widgets/organizer_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodel/database_provider.dart';
import 'package:newmed/view/widgets/pages.dart';
import 'package:newmed/view/widgets/footer_section.dart';

class Eventpage extends StatelessWidget {
  const Eventpage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen ke DatabaseProvider
    final dbProvider = context.watch<DatabaseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER (Dibiarkan di luar agar tetap Full Width)
            EventHeader(isLoggedIn: dbProvider.isLoggedIn),

            // 2. KONTEN TENGAH (Diberi Padding Horizontal)
            Padding(
              // Atur jarak kiri-kanan di sini (misal: 24 atau 30)
              padding: const EdgeInsets.symmetric(horizontal: 120),
              child: Column(
                children: [
                  const LastChanceEventsSection(),
                  const RecentEventsSection(),
                  const AllEventsSection(),
                ],
              ),
            ),

            // 3. FOOTER (Dibiarkan di luar agar tetap Full Width)
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}
