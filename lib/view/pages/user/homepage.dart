import 'package:newmed/viewmodel/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider// import 'loginpage.dart';
// import 'profilepage.dart'; 
import 'package:newmed/view/widgets/pages.dart';
import 'package:newmed/view/widgets/footer_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {
    // 1. Listen to the AuthViewModel
    // 'watch' means if the login state changes, this widget rebuilds immediately
    final dbProvider = context.watch<DatabaseProvider>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 2. Pass the isLoggedIn state to the Header Section
            HomeHeader(isLoggedIn: dbProvider.isLoggedIn),

            // Featured Events Section
            const FeaturedEventsSection(),

            // Footer Section
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}


