import 'dart:async'; // Diperlukan untuk Timer
import 'package:newmed/model/custom_models.dart';
import 'package:newmed/view/pages/admin/registrationpage.dart';
import 'package:newmed/view/widgets/custom_dialogs.dart';
import 'package:newmed/view/widgets/pages.dart';
import 'package:newmed/viewmodel/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newmed/view/widgets/footer_section.dart';

const Color titleColor = Color(0xFF0F2A44);
const Color subColor = Color(0xFF334155);

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Timer? _timer;
  late Duration _diff;
  
  // [BARU] Controller untuk input email notifikasi
  final TextEditingController _notifyEmailCtrl = TextEditingController();
  bool _isNotifying = false; // Loading state untuk tombol notify

  @override
  void initState() {
    super.initState();
    _calculateTime();
    // Jalankan timer setiap 1 detik untuk menggerakkan detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTime();
        });
      }
    });
  }

  void _calculateTime() {
    final now = DateTime.now();
    // Menghitung selisih waktu ke hari-H pelaksanaan event
    _diff = widget.event.eventDate.difference(now);
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _notifyEmailCtrl.dispose(); // [BARU] Dispose controller
    super.dispose();
  }

  // [BARU] Fungsi Handle Notify
  Future<void> _handleNotify() async {
    final email = _notifyEmailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak boleh kosong"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isNotifying = true);

    // Panggil fungsi subscribe dari Provider
    final provider = context.read<DatabaseProvider>();
    String? error = await provider.subscribeNewsletter(email);

    if (mounted) {
      setState(() => _isNotifying = false);

      if (error == null) {
        // SUKSES
        _notifyEmailCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil! Kami akan mengirimkan notifikasi ke email Anda."),
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
    final isLoggedIn = context.select<DatabaseProvider, bool>(
      (p) => p.isLoggedIn,
    );
    final isExpired = _diff.isNegative;

    final isLomba = widget.event.category.toLowerCase() == 'lomba';
    final isEvent = widget.event.category.toLowerCase() == 'event';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // ===== BACKGROUND IMAGE & OVERLAY =====
            SizedBox(
              width: double.infinity,
              height: 1800,
              child: Image.network(
                widget.event.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) =>
                    Container(color: Colors.grey[200]),
              ),
            ),
            Container(
              width: double.infinity,
              height: 1800,
              color: Colors.white.withOpacity(0.90),
            ),

            // ===== PAGE CONTENT =====
            Column(
              children: [
                Navbar(isLoggedIn: isLoggedIn, activePage: "Event"),

                // ================= HERO SECTION =================
                SizedBox(
                  height: 600,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCategoryTag(),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.event.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- COUNTDOWN SECTION ---
                        if (!isExpired) ...[
                          const Text(
                            "Started in",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _count(_diff.inDays, 'days'),
                              _spacer(),
                              _count(_diff.inHours % 24, 'hours'),
                              _spacer(),
                              _count(_diff.inMinutes % 60, 'minutes'),
                              _spacer(),
                              _count(_diff.inSeconds % 60, 'seconds'),
                            ],
                          ),
                        ] else
                          const Text(
                            "EVENT ENDED",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),

                        const SizedBox(height: 60),
                        
                        // [BARU] Widget Notify Input yang sudah tersambung
                        _buildNotifyInput(),
                      ],
                    ),
                  ),
                ),

                // ================= CONTENT DETAIL =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 150,
                    vertical: 100,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: POSTER
                      _buildPoster(),
                      const SizedBox(width: 80),

                      // RIGHT: INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.event.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: subColor,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 40),

                            _buildInfoGrid(isLomba, isEvent),

                            const SizedBox(height: 50),

                            _buildApplyButton(isLoggedIn),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const FooterSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _spacer() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      ":",
      style: TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: titleColor,
      ),
    ),
  );

  Widget _count(int v, String l) => Column(
    children: [
      Text(
        v.toString().padLeft(2, '0'),
        style: const TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      ),
      Text(
        l,
        style: const TextStyle(color: subColor, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _buildCategoryTag() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: const Color(0xFFF0E68C).withOpacity(0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFF0E68C)),
    ),
    child: Text(
      widget.event.category.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFF0E68C),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildPoster() => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Image.network(
      widget.event.posterUrl,
      width: 380,
      height: 620,
      fit: BoxFit.cover,
    ),
  );

  Widget _buildInfoGrid(bool isLomba, bool isEvent) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Event Detail",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow("Organization", widget.event.organization),
            _detailRow("Whatsapp Number", widget.event.whatsapp),
            _detailRow("ID line", widget.event.lineId),
            _detailRow("Location", widget.event.location),
            _detailRow(
              "Close Entry",
              DateFormat('dd MMM yyyy').format(widget.event.closeRegDate),
            ),
            _detailRow(
              "The Day",
              DateFormat('dd MMM yyyy').format(widget.event.eventDate),
            ),
            _detailRow(
              "Sisa Kuota",
              "${widget.event.remainingQuota} seats",
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLomba ? "Competition Branches" : "Open Divisions",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final list = isLomba
                    ? widget.event.subEvents
                    : widget.event.divisions;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: list
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "${e.key + 1}. ${e.value}",
                            style: const TextStyle(
                              color: subColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: subColor,
            ),
          ),
        ),
        const Text(": "),
        Expanded(
          child: Text(value, style: const TextStyle(color: subColor)),
        ),
      ],
    ),
  );

  Widget _buildApplyButton(bool isLoggedIn) {
    final bool isClosed = DateTime.now().isAfter(widget.event.closeRegDate);
    final bool isFull = widget.event.remainingQuota <= 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: (isClosed || isFull)
              ? Colors.grey
              : const Color(0xFFFfd700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () async {
          if (isClosed) return;
          if (isFull) {
            await showErrorDialog(
              context,
              title: "Kuota Penuh",
              message: "Maaf, kuota peserta sudah habis.",
            );
            return;
          }

          if (!isLoggedIn) {
             // Opsional: Tambahkan logika redirect ke login
            return;
          }

          final provider = context.read<DatabaseProvider>();
          String? conflictingEventName = await provider.checkTimeConflict(
            widget.event.eventDate,
          );

          if (conflictingEventName != null) {
            await showErrorDialog(
              context,
              title: "Jadwal Bentrok!",
              message: "Kamu telah terdaftar di \"$conflictingEventName\".",
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrationPage(event: widget.event),
            ),
          );
        },
        child: Text(
          isClosed
              ? "Registration Closed"
              : (isFull ? "Quota Full" : "Apply Now !"),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // [BARU] Widget Notify Input dengan Logika Database
  Widget _buildNotifyInput() => SizedBox(
    width: 620,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _notifyEmailCtrl, // Hubungkan controller
            decoration: InputDecoration(
              hintText: "Enter your email",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
        const SizedBox(width: 18),
        ElevatedButton(
          onPressed: _isNotifying ? null : _handleNotify, // Panggil fungsi saat diklik
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0E68C),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            shape: const StadiumBorder(),
          ),
          child: _isNotifying 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text("Notify", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}