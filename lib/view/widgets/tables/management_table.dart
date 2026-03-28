import 'package:flutter/material.dart';
import '../../../model/custom_models.dart'; // Sesuaikan path model EventModel kamu
import '../custom_dialogs.dart';

class ManagementTable extends StatelessWidget {
  final List<EventModel> data; 
  final String type; 
  
  // Callback Functions
  final Function(EventModel) onEdit;
  final Function(EventModel) onCheckParticipants;
  final Function(String) onDelete; // Tambahan callback delete

  const ManagementTable({
    super.key, 
    required this.data, 
    required this.type, 
    required this.onEdit, 
    required this.onCheckParticipants,
    required this.onDelete, 
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40), 
          child: Text("Belum ada data event/lomba yang Anda buat.")
        )
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: data.map((item) => DataRow(cells: [
          // 1. Nama Event (Dibatasi lebarnya agar tidak merusak tabel)
          DataCell(
            SizedBox(
              width: 180, 
              child: Text(
                item.name, 
                style: const TextStyle(fontWeight: FontWeight.bold), 
                overflow: TextOverflow.ellipsis
              )
            )
          ),
          
          // 2. Kategori (Badge Warna)
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                // Warna beda untuk Lomba vs Event
                color: item.category.toLowerCase() == 'lomba' 
                    ? Colors.orange.shade100 
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                item.category.toUpperCase(), 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold,
                  color: item.category.toLowerCase() == 'lomba' 
                      ? Colors.orange.shade900 
                      : Colors.blue.shade900,
                )
              ),
            )
          ),

          // 3. Tanggal Event
          DataCell(Text(
            "${item.eventDate.day}/${item.eventDate.month}/${item.eventDate.year}"
          )),

          // 4. Aksi (Lihat Peserta, Edit, Hapus)
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol Lihat Peserta
              IconButton(
                tooltip: "Lihat Pendaftar",
                icon: const Icon(Icons.people, size: 20, color: Color(0xff143952)), 
                onPressed: () => onCheckParticipants(item)
              ),
              
              // Tombol Edit (FITUR UPDATE)
              IconButton(
                tooltip: "Edit Event",
                icon: const Icon(Icons.edit, size: 20, color: Colors.green), 
                onPressed: () => onEdit(item), // Memicu form dengan data awal
              ),

              // Tombol Hapus
              IconButton(
                tooltip: "Hapus",
                icon: const Icon(Icons.delete, size: 20, color: Colors.red), 
                onPressed: () => _confirmDelete(context, item.id),
              ),
            ],
          )),
        ])).toList(),
      ),
    );
  }

  // Dialog Konfirmasi Hapus
  void _confirmDelete(BuildContext context, String id) async {
    // PAKAI POP UP KONFIRMASI CUSTOM
    bool confirm = await showConfirmationDialog(
      context,
      title: "Hapus Kegiatan?",
      message: "Data akan dihapus permanen dan tidak bisa dikembalikan. Lanjutkan?",
      confirmLabel: "Hapus",
      isDestructive: true, // Merah
    );

    if (confirm) {
      onDelete(id); // Jalankan fungsi hapus
    }
  }
}