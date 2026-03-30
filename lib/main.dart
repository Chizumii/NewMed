// File: lib/main.dart

import 'package:newmed/view/pages/registerpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodel/database_provider.dart';
import 'view/pages/loginpage.dart';
import 'view/pages/admin/admindashboard.dart';
import 'view/pages/admin/organizerdashboard.dart';
import 'view/pages/user/homepage.dart';
import 'view/pages/user/profilepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- KONEKSI SUPABASE (Dari data yang kamu kirim) ---
  await Supabase.initialize(
    url: 'https://olatrbvaqigmjqlebpky.supabase.co',
    // Pastikan Key ini benar "anon public" key.
    // Biasanya key Supabase diawali dengan "ey..." (JWT).
    // Jika nanti error "JWT invalid", cek ulang di Dashboard Supabase > Project Settings > API.
    anonKey: 'sb_publishable_W14CZBiJmBv8dukm-n1a2A_x1B941-G',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inisialisasi DatabaseProvider (Otak Aplikasi)
        ChangeNotifierProvider(create: (_) => DatabaseProvider()..loadUser()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UCommittee',
        theme: ThemeData(
          primaryColor: const Color(0xFFF0E68C),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFFF0E68C),
            primary: const Color(0xFFF0E68C),
            secondary: Color(0xFFF0E68C),
          ),
        ),
        // Wrapper Pintar untuk cek status Login & Role
        home: const AuthCheckWrapper(),
        routes: {
          '/home': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/admin': (context) => const AdminDashboard(),
          '/organizer': (context) => const OrganizerDashboard(),
          '/profile': (context) => const ProfilePage(),
          "/register": (context) => const RegisterPage(),
        },
      ),
    );
  }
}

// Widget untuk mengecek status login & role saat aplikasi dibuka
class AuthCheckWrapper extends StatelessWidget {
  const AuthCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan data dari DatabaseProvider
    final provider = context.watch<DatabaseProvider>();

    // 1. Jika sedang loading (cek token/koneksi)
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Jika BELUM Login -> Ke Login Page
    if (!provider.isLoggedIn) {
      return const HomePage();
    }

    // 3. Jika SUDAH Login -> Cek Role untuk arahkan ke dashboard yang benar
    final role = provider.currentUser?.role;

    if (role == 'admin') {
      return const HomePage();
    } else if (role == 'organizer') {
      return const HomePage();
    } else {
      // Mahasiswa / Siswa ke Home
      return const HomePage();
    }
  }
}
