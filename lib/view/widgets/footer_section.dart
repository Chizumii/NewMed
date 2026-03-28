import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/database_provider.dart'; // Pastikan path import ini benar

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

  // Fungsi untuk menangani proses subscribe
  Future<void> _handleSubscribe() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Panggil fungsi dari Provider
    final provider = context.read<DatabaseProvider>();
    String? error = await provider.subscribeNewsletter(email);

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        // SUKSES
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil berlangganan! Terima kasih."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // GAGAL
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
      color: const Color(0xFF1E1135), // Very dark purple/blue
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
                  "The Event",
                  style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _socialIcon(Icons.camera_alt_outlined),
                    const SizedBox(width: 15),
                    _socialIcon(Icons.facebook),
                    const SizedBox(width: 15),
                    _socialIcon(Icons.close), // Used for X/Twitter
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
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 15),
                Text("theevent@gmail.com",
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 2)),
                Text("Universitas Ciputra Citraland",
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 2)),
                Text("081133112345778890",
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 2)),
              ],
            ),
          ),

          // Column 3: Subscribe (YANG SUDAH DIUPDATE)
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Subscribe",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Text("Enter your email to get notified about newest event",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 0, 5, 0), // Padding disesuaikan untuk tombol
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: const TextStyle(fontSize: 12),
                      border: InputBorder.none,
                      // Tombol Kirim ada di sini
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: SizedBox(
                                width: 10, 
                                height: 10, 
                                child: CircularProgressIndicator(strokeWidth: 2)
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, size: 20, color: Color(0xFF1E1135)),
                              onPressed: _handleSubscribe, // Panggil fungsi saat diklik
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(icon, color: const Color(0xFF1E1135), size: 20),
    );
  }
}