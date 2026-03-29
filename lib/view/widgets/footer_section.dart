// File: lib/view/widgets/footer_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/database_provider.dart';

class FooterSection extends StatefulWidget {
  const FooterSection({super.key});

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubscribe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<DatabaseProvider>();
    String? error = await provider.subscribeNewsletter(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil berlangganan!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // ===== UPDATE GRADIENT DI SINI =====
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFFFFE0), // Kuning sangat terang
            Color(0xFFFFF9C4), // Kuning menengah
            Color(0xFFF0E68C), // Khaki/Kuning tua
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      child: Wrap(
        spacing: 60,
        runSpacing: 40,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Column 1: Brand & Social
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "UCommittee",
                  style: TextStyle(
                      color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _socialIcon(Icons.camera_alt_outlined),
                    const SizedBox(width: 15),
                    _socialIcon(Icons.facebook),
                    const SizedBox(width: 15),
                    _socialIcon(Icons.close),
                  ],
                )
              ],
            ),
          ),

          // Column 2: Contact Us
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Contact Us",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 15),
                Text("UCommittee@gmail.com",
                    style: TextStyle(color: Colors.black54, fontSize: 12, height: 2)),
                Text("Universitas Ciputra Citraland",
                    style: TextStyle(color: Colors.black54, fontSize: 12, height: 2)),
                Text("09760738314",
                    style: TextStyle(color: Colors.black54, fontSize: 12, height: 2)),
              ],
            ),
          ),

          // Column 3: Subscribe
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Subscribe",
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Text("Enter your email to get notified about newest event",
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    // Menambah shadow agar input field terlihat jelas di atas kuning
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 0, 5, 0),
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, size: 20, color: Color(0xFFF0E68C)),
                              onPressed: _handleSubscribe,
                              tooltip: "Subscribe",
                            ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black, // Background icon diubah jadi hitam agar kontras
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}