import 'package:newmed/model/custom_models.dart';
import 'package:newmed/view/pages/admin/registrationpage.dart';
import 'package:newmed/view/pages/user/eventDetailPage.dart';
import 'package:newmed/view/pages/registerpage.dart'; // Pastikan import ini ada untuk Quick Apply
import 'package:newmed/viewmodel/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'custom_dialogs.dart'; 

class EventCard extends StatefulWidget {
  final EventModel event;
  final String tag;
  final Color tagColor;

  const EventCard({
    super.key,
    required this.event,
    required this.tag,
    required this.tagColor,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isHovered = false;

  // Logic Status
  bool get isComingSoon => DateTime.now().isBefore(widget.event.openRegDate);
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(widget.event.openRegDate) &&
        now.isBefore(widget.event.closeRegDate);
  }
  bool get isClosed => DateTime.now().isAfter(widget.event.closeRegDate);

  Duration get remainingTime => widget.event.closeRegDate.difference(DateTime.now());

  String get countdownText {
    if (remainingTime.isNegative) return "Closed";
    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;
    return "$days days | $hours hours left";
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  // Fungsi Cek Login
  Future<void> _checkLoginAndProceed(BuildContext context, VoidCallback action) async {
    final provider = context.read<DatabaseProvider>();
    
    if (provider.isLoggedIn) {
      action();
    } else {
      bool confirm = await showConfirmationDialog(
        context,
        title: "Akses Terbatas",
        message: "Kamu harus login terlebih dahulu untuk mengakses fitur ini.",
        confirmLabel: "Login Sekarang",
        cancelLabel: "Nanti Saja",
        isDestructive: false, 
      );

      if (confirm && context.mounted) {
        Navigator.pushNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: const Text("Coming Soon"),
               content: Text("Event ini baru akan dibuka pada tanggal ${_formatDate(widget.event.openRegDate)}."),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(ctx),
                   child: const Text("OK"),
                 )
               ],
             ),
           );
           return; 
        }

        _checkLoginAndProceed(context, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: widget.event),
            ),
          );
        });
      },
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= IMAGE SECTION =================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    widget.event.posterUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),

                // APPLY BUTTON (Top Right)
                if (isOpen)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: GestureDetector(
                        onTap: () {
                          _checkLoginAndProceed(context, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegistrationPage(event: widget.event),
                              ),
                            );
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isHovered ? const Color(0xff3F054F) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Apply Now",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isHovered ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // COUNTDOWN (Bottom Left)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          countdownText,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ================= CONTENT SECTION =================
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Supaya tanggal di kanan
                    children: [
                      _statusChip(),
                      Text(
                        _formatDate(widget.event.closeRegDate),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    widget.event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description Stub
                  Text(
                    widget.event.description.isNotEmpty 
                        ? widget.event.description 
                        : "No description available.",
                    maxLines: 1, // Kurangi jadi 1 baris agar muat
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  
                  const SizedBox(height: 12),

                  // --- INFO TAMBAHAN: LOKASI & KUOTA ---
                  Row(
                    children: [
                      // Lokasi
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // [BARU] Indikator Kuota (Peserta)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_outline, size: 14, color: widget.event.remainingQuota > 0 ? Colors.blueGrey : Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              // Tampilan: "12/100"
                              "${widget.event.currentParticipants}/${widget.event.maxParticipants}",
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold,
                                color: widget.event.remainingQuota > 0 ? Colors.blueGrey : Colors.red
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    if (isComingSoon) return _chip("Coming Soon", Colors.orange);
    if (isClosed) return _chip("Closed", Colors.red);
    return _chip(widget.tag, widget.tagColor);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}