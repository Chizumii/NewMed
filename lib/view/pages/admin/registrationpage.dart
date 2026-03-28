// File: lib/view/pages/admin/registrationpage.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodel/database_provider.dart';
import '../../widgets/pages.dart';
import '../../widgets/registrationformcard.dart'; // Pastikan import ini benar
import '../../../model/custom_models.dart'; // Gunakan EventData dari sini
import '../../widgets/footer_section.dart';

class RegistrationPage extends StatelessWidget {
  // UBAH DARI EventModel KE EventData
  final EventModel event; 

  const RegistrationPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    // Gunakan DatabaseProvider untuk cek status login di Navbar
    final dbProvider = context.watch<DatabaseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // NAVBAR
            Navbar(
              isLoggedIn: dbProvider.isLoggedIn,
              activePage: "Event",
            ),


            // FORM (Sekarang tidak akan error karena tipe datanya sudah sama)
            Padding(
              padding: const EdgeInsets.symmetric(),
              child: RegistrationFormCard(event: event),
            ),

            const SizedBox(height: 40),

            // FOOTER
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}