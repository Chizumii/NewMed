import 'package:flutter/material.dart';

// 1. DIALOG KONFIRMASI (Ada tombol YA dan BATAL)
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Ya, Lanjutkan",
  String cancelLabel = "Batal",
  bool isDestructive = false, // Jika true, tombol jadi Merah (Bahaya)
}) async {
  return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(cancelLabel),
            ),
            
            // Tombol Konfirmasi
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : const Color(0xFF3F054F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false; // Default return false jika dialog ditutup paksa
}

// 2. DIALOG ERROR / INFORMASI (Hanya tombol OK / TUTUP)
Future<void> showErrorDialog(
  BuildContext context, {
  required String message,
  String title = "Terjadi Kesalahan",
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Merah untuk menandakan error
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Tutup"),
          ),
        ),
      ],
    ),
  );
}