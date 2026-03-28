import 'package:newmed/view/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/database_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Layout Responsif: Jika layar lebar (Desktop/Web), bagi 2 kolom
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                const Expanded(flex: 5, child: LeftSideHero()),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: SignInForm(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Layout Mobile: Satu kolom tengah
            return const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: SignInForm(),
              ),
            );
          }
        },
      ),
    );
  }
}

// Widget Desain Sisi Kiri
class LeftSideHero extends StatelessWidget {
  const LeftSideHero({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF57C00), Color(0xFFE65100)], // Gradien oren
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Find Your Next\nExperience",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 24,
                fontStyle: FontStyle.italic,
                fontFamily: 'Georgia',
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Discover\n&\nPromote\nUpcoming\nEvents",
              style: TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                height: 1.1,
                fontFamily: 'Arial',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Form Login dengan Logika Baru
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Sign in",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Please login to continue to your account.",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 40),

        // Input Email
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: "Email",
            labelStyle: const TextStyle(color: Color(0xFFE65100)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE65100), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Input Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Tombol Login
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: () async {
              // 1. Ambil input
              final email = _emailController.text.trim();
              final password = _passwordController.text;

              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Email and Password cannot be empty"),
                  ),
                );
                return;
              }

              // 2. Proses Login
              String? error = await provider.login(email, password);

              if (error == null) {
                // SUKSES
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Welcome back!"), backgroundColor: Colors.green),
                  );
                }
              } else {
                // GAGAL -> PAKAI POP UP ERROR
                if (mounted) {
                  showErrorDialog(
                    context,
                    title: "Gagal Masuk",
                    message: error, // Pesan error dari provider (misal: "Password salah")
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Sign In",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 40),

        // Link ke Register Page
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Need an account? ",
                style: TextStyle(color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {
                  // Arahkan ke halaman Register jika belum punya akun
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text(
                  "Create one",
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
