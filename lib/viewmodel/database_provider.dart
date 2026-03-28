import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/custom_models.dart';

class DatabaseProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserProfile? _currentUser;

  // List Global (Untuk User Biasa melihat semua event)
  // List Global
  List<EventModel> _events = [];

  // List Khusus Dashboard
  List<EventModel> _myEvents = [];

  List<UserProfile> _allUsers = [];
  bool _isLoading = false;

  // --- BAGIAN INI YANG PERLU DIPERBAIKI ---

  List<EventModel> _filteredEvents = [];
  String _searchQuery = "";

  // 1. TAMBAHKAN GETTER INI (Supaya error merah hilang)
  String get searchQuery => _searchQuery;
  List<EventModel> get filteredEvents => _filteredEvents;

  // Getter events yang sudah ada (tetap biarkan)
  List<EventModel> get events {
    if (_searchQuery.isNotEmpty) return _filteredEvents;
    
    // Jika filter "All", return semua
    if (_selectedDivisionFilter == "All") return _events;

    // Filter Logic: Cocokkan Category, Divisi, atau SubEvent
    return _events.where((e) {
      bool catMatch = e.category.toLowerCase() == _selectedDivisionFilter.toLowerCase();
      bool divMatch = e.divisions.any((d) => d.toLowerCase() == _selectedDivisionFilter.toLowerCase());
      bool subMatch = e.subEvents.any((s) => s.toLowerCase() == _selectedDivisionFilter.toLowerCase());
      return catMatch || divMatch || subMatch;
    }).toList();
  }

  // Fungsi ambil list divisi unik untuk Chip Filter
  List<String> getAvailableDivisions() {
    Set<String> divisions = {"All"};
    for (var event in _events) {
      if(event.category.isNotEmpty) divisions.add(_toTitleCase(event.category)); 
      for(var div in event.divisions) if(div.isNotEmpty) divisions.add(_toTitleCase(div));
      for(var sub in event.subEvents) if(sub.isNotEmpty) divisions.add(_toTitleCase(sub));
    }
    return divisions.toList();
  }

  void setDivisionFilter(String filter) {
    _selectedDivisionFilter = filter;
    notifyListeners();
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.trim()[0].toUpperCase() + text.trim().substring(1).toLowerCase();
  }

  // Getter lainnya (tetap biarkan)
  UserProfile? get currentUser => _currentUser;
  List<EventModel> get myEvents => _myEvents;
  List<UserProfile> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String _selectedDivisionFilter = "All";
  String get selectedDivisionFilter => _selectedDivisionFilter;
  
  Future<String?> checkTimeConflict(DateTime newEventDate) async {
    if (_currentUser == null) return null;

    try {
      // Ambil status pendaftaran DAN judul event
      final response = await _supabase
          .from('registrations')
          .select('status, events(title, event_date)') 
          .eq('user_id', _currentUser!.id);

      final joinedEvents = List<Map<String, dynamic>>.from(response);

      for (var reg in joinedEvents) {
        if (reg['events'] == null) continue;
        
        // Ambil status, default ke pending jika null
        final status = reg['status']?.toString().toLowerCase() ?? 'pending';

        // LOGIKA KUNCI:
        // Jika statusnya 'rejected', anggap TIDAK ADA konflik (User bebas daftar lagi)
        if (status == 'rejected') continue;

        // Jika status 'accepted' atau 'pending', cek tanggalnya
        final eventData = reg['events'] as Map<String, dynamic>;
        if (eventData['event_date'] != null) {
          DateTime joinedDate = DateTime.parse(eventData['event_date']);
          
          // Cek kesamaan Tanggal (Tahun, Bulan, Hari)
          if (joinedDate.year == newEventDate.year && 
              joinedDate.month == newEventDate.month && 
              joinedDate.day == newEventDate.day) {
            
            // Return NAMA EVENT yang bentrok
            return eventData['title']?.toString() ?? "Event Lain"; 
          }
        }
      }
      return null; // Tidak ada konflik
    } catch (e) {
      print("Error check conflict: $e");
      return null; 
    }
  }
  // ================== AUTH SECTION ==================

  Future<void> loadUser() async {
    // Mulai loading agar UI tahu sedang mengambil data awal
    _setLoading(true);

    try {
      // 1. AMBIL DATA EVENT (Wajib untuk semua, baik Guest maupun User)
      await fetchAllEvents();

      // 2. CEK SESI LOGIN
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // Jika User Login: Ambil Profile & Event Pribadi (Organizer)
        await _fetchProfile(user.id);
      } else {
        // Jika Guest: Stop loading (karena fetchAllEvents sudah selesai)
        _setLoading(false);
      }
    } catch (e) {
      print("Error loading initial data: $e");
      _setLoading(false);
    }
  }

  void searchEvents(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      // Jika search bar dikosongkan, reset hasil filter
      _filteredEvents = [];
    } else {
      // Filter event berdasarkan nama ATAU kategori
      _filteredEvents = _events.where((event) {
        final name = event.name.toLowerCase();
        final category = event.category.toLowerCase();
        return name.contains(_searchQuery) || category.contains(_searchQuery);
      }).toList();
    }

    // Beritahu UI untuk update tampilan
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchProfile(response.user!.id);
        _setLoading(false);
        return null;
      }
      return "Login gagal";
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<String?> register(
    String email,
    String password,
    String name,
    String role,
    String institution,
  ) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'role': role.toLowerCase(),
          'institution': institution,
          'avatar_url': '',
          'cv_url': '',
          'portfolio_url': '',
        });

        await _fetchProfile(response.user!.id);
        _setLoading(false);
        return null;
      }
      return "Register gagal";
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // lib/viewmodel/database_provider.dart

  Future<void> logout() async {
    try {
      // 1. Keluar dari sesi di Supabase (Sisi Server)
      await _supabase.auth.signOut();
    } catch (e) {
      print("Supabase signout error: $e");
    } finally {
      // 2. Bersihkan data lokal di memori secara INSTAN (Sisi Client)
      // Walaupun Supabase error (misal: koneksi), user tetap harus 'logout' dari UI
      _currentUser = null;
      _allUsers = [];
      _myEvents = [];

      // 3. Beritahu Navbar & UI lainnya untuk langsung berubah
      notifyListeners();
      print("Logout lokal berhasil");
    }
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _currentUser = UserProfile.fromJson(data);
      notifyListeners();

      fetchAllEvents();
      // Jika organizer, ambil event miliknya sendiri juga
      if (_currentUser?.role == 'organizer' || _currentUser?.role == 'admin') {
        fetchMyEvents();
      }
      if (_currentUser?.role == 'admin') fetchAllUsers();
    } catch (e) {
      print("Error fetch profile: $e");
    }
  }

  // ================== GENERAL FILE UPLOAD ==================

  Future<String?> uploadFile(Uint8List bytes, String ext, String folder) async {
    if (_currentUser == null) return null;
    try {
      final fileName =
          '${_currentUser!.id}/${folder}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('documents')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('documents').getPublicUrl(fileName);
    } catch (e) {
      print("Error upload file $folder: $e");
      return null;
    }
  }

  // ================== PROFILE UPDATE SECTION ==================

  Future<String?> updateProfileDataComplete({
    required String fullName,
    required String institution,
    required String major,
    required String batch,
    required String phone,
    required String lineId,

    Uint8List? cvBytes,
    String? cvName,
    Uint8List? portfolioBytes,
    String? portfolioName,
  }) async {
    if (_currentUser == null) return "User belum login";

    try {
      _setLoading(true);
      final userId = _currentUser!.id;

      String? cvUrl;
      String? pfUrl;

      if (cvBytes != null && cvName != null) {
        final ext = cvName.split('.').last;
        cvUrl = await uploadFile(cvBytes, ext, 'cv');
      }

      if (portfolioBytes != null && portfolioName != null) {
        final ext = portfolioName.split('.').last;
        pfUrl = await uploadFile(portfolioBytes, ext, 'portfolio');
      }

      final Map<String, dynamic> updates = {
        'full_name': fullName,
        'institution': institution,
        'major': major,
        'batch_year': batch,
        'phone_number': phone,
        'line_id': lineId,
      };

      if (cvUrl != null) updates['cv_url'] = cvUrl;
      if (pfUrl != null) updates['portfolio_url'] = pfUrl;

      await _supabase.from('profiles').update(updates).eq('id', userId);

      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        institution: institution,
        major: major,
        batch: batch,
        phone: phone,
        lineId: lineId,
        cvUrl: cvUrl ?? _currentUser!.cvUrl,
        portfolioUrl: pfUrl ?? _currentUser!.portfolioUrl,
      );

      notifyListeners();
      return null;
    } catch (e) {
      return "Gagal update: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadProfilePicture(
    Uint8List imageBytes,
    String fileExt,
  ) async {
    if (_currentUser == null) return "User belum login";
    try {
      _setLoading(true);
      final userId = _currentUser!.id;
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);
      _currentUser = _currentUser!.copyWith(avatarUrl: imageUrl);

      notifyListeners();
      return null;
    } catch (e) {
      return "Gagal upload: $e";
    } finally {
      _setLoading(false);
    }
  }

  // ================== EVENT & ADMIN SECTIONS ==================

  // 1. Fetch SEMUA Event (Untuk Halaman Utama User)
  Future<void> fetchAllEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select('*'); 
      
      var loadedEvents = (response as List).map((e) => EventModel.fromJson(e)).toList();

      // --- [BARU] SORTING SISA KUOTA TERBANYAK DI ATAS ---
      loadedEvents.sort((a, b) {
        return b.remainingQuota.compareTo(a.remainingQuota);
      });

      _events = loadedEvents;
      notifyListeners();
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  // 2. Fetch EVENT SAYA (Untuk Dashboard Organizer - 1 Akun 1 Dashboard)
  Future<void> fetchMyEvents() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('created_by', _currentUser!.id) // Filter by User ID
          .order('created_at', ascending: false);

      _myEvents = (response as List)
          .map((e) => EventModel.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching my events: $e");
    }
  }

  Future<String?> uploadEventPoster(
    Uint8List imageBytes,
    String fileExt,
  ) async {
    if (_currentUser == null) return null;
    try {
      _setLoading(true);
      final fileName =
          'poster_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage
          .from('posters')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final imageUrl = _supabase.storage.from('posters').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print("Error upload poster: $e");
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 3. CREATE EVENT
  Future<String?> addEvent({
    required String title,
    required String category,
    required DateTime? startReg,
    required DateTime? endReg,
    required DateTime? eventDate,
    required String description,
    String? posterUrl,
    List<String>? divisions,
    String? whatsapp,
    String? lineId,
    String? location,
    String? fee,
    DateTime? tmDate,
    DateTime? prelimDate,
    String? terms,
    String? waGroupLink,
    String? bankAccount,
    List<String>? subEvents,
    required int maxParticipants,
  }) async {
    if (_currentUser == null) return "User belum login";
    try {
      _setLoading(true);

      await _supabase.from('events').insert({
        'title': title,
        'category': category.toLowerCase(),
        'description': description,
        'organization_name': _currentUser!.fullName,
        'start_reg_date': startReg?.toIso8601String(),
        'end_reg_date': endReg?.toIso8601String(),
        'event_date': eventDate?.toIso8601String(),
        'tm_date': tmDate?.toIso8601String(),
        'prelim_date': prelimDate?.toIso8601String(),
        'poster_url': posterUrl ?? 'https://via.placeholder.com/400x600',
        'created_by': _currentUser!.id,
        'created_at': DateTime.now().toIso8601String(),
        'contact_whatsapp': whatsapp ?? '-',
        'contact_line': lineId ?? '-',
        'whatsapp_group_link': waGroupLink ?? '-',
        'location': location ?? '-',
        'terms_and_conditions': terms ?? '-',
        'bank_account_info': bankAccount ?? '-',
        'registration_fee': fee ?? '0',
        'divisions': divisions ?? [],
        'sub_events': subEvents ?? [],
        'max_participants': maxParticipants,
        'current_participants': 0,
      });

      await fetchAllEvents();
      await fetchMyEvents(); // Refresh dashboard organizer juga
      return null;
    } catch (e) {
      return "Gagal membuat event: $e";
    } finally {
      _setLoading(false);
    }
  }

  // 4. UPDATE EVENT (Fitur Edit)
  Future<String?> updateEvent({
    required String eventId,
    required String title,
    required String category,
    required DateTime? startReg,
    required DateTime? endReg,
    required DateTime? eventDate,
    required String description,
    String? posterUrl,
    List<String>? divisions,
    List<String>? subEvents,
    String? whatsapp,
    String? lineId,
    String? waGroupLink,
    String? bankAccount,
    String? fee,
    String? location,
    String? terms,
    DateTime? tmDate,
    DateTime? prelimDate,
    int? maxParticipants,
  }) async {
    try {
      _setLoading(true);

      final Map<String, dynamic> updates = {
        'title': title,
        'category': category.toLowerCase(),
        'description': description,
        'start_reg_date': startReg?.toIso8601String(),
        'end_reg_date': endReg?.toIso8601String(),
        'event_date': eventDate?.toIso8601String(),
        'tm_date': tmDate?.toIso8601String(),
        'prelim_date': prelimDate?.toIso8601String(),
        'contact_whatsapp': whatsapp ?? '-',
        'contact_line': lineId ?? '-',
        'whatsapp_group_link': waGroupLink ?? '-',
        'location': location ?? '-',
        'terms_and_conditions': terms ?? '-',
        'bank_account_info': bankAccount ?? '-',
        'registration_fee': fee ?? '0',
        'divisions': divisions ?? [],
        'sub_events': subEvents ?? [],
        'max_participants': maxParticipants ?? 0,
      };

      if (posterUrl != null) {
        updates['poster_url'] = posterUrl;
      }

      await _supabase.from('events').update(updates).eq('id', eventId);

      await fetchAllEvents();
      await fetchMyEvents(); // Refresh dashboard
      return null;
    } catch (e) {
      return "Gagal update: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);

      // Update local lists
      _events.removeWhere((e) => e.id == eventId);
      _myEvents.removeWhere((e) => e.id == eventId);

      notifyListeners();
    } catch (e) {
      print("Error delete event: $e");
    }
  }

  // lib/viewmodel/database_provider.dart

 Future<List<Map<String, dynamic>>> fetchEventParticipants(String eventId) async {
    try {
      final response = await _supabase
          .from('registrations')
          .select('''
          id,                 
          registration_date,
          chosen_division, 
          status,
          cv_link,             
          payment_proof_url,
          profiles (
            email,
            full_name,
            institution,
            phone_number,
            line_id,
            major,
            batch_year
          )
        ''')
          .eq('event_id', eventId)
          .order('registration_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // ... error handling
      return [];
    }
  }

 Future<bool> registerToEvent(
    String eventId,
    String division,
    String? cvLink,
    String? proofLink,
  ) async {
    if (_currentUser == null) return false;
    try {
      // 1. Simpan Data Pendaftaran Baru
      // (Trigger di Database akan OTOMATIS mengupdate current_participants di tabel events)
      await _supabase.from('registrations').insert({
        'user_id': _currentUser!.id,
        'event_id': eventId,
        'status': 'pending', 
        'registration_date': DateTime.now().toIso8601String(),
        'chosen_division': division,
        'payment_proof_url': proofLink,
        'cv_link': cvLink,
      });

      // 2. Refresh data lokal agar UI aplikasi langsung update sisa kuota terbaru
      await fetchAllEvents(); 

      return true;
    } catch (e) {
      log("Error registering detail: $e");
      return false;
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at');
      _allUsers = (response as List)
          .map((e) => UserProfile.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      log("Error fetching users: $e");
    }
  }

  // lib/viewmodel/database_provider.dart

  Future<void> updateUserRole(String targetUserId, String newRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Update di Database Supabase
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', targetUserId);

      // 2. Update list lokal (allUsers) agar UI berubah seketika
      int index = _allUsers.indexWhere((u) => u.id == targetUserId);
      if (index != -1) {
        _allUsers[index] = UserProfile(
          id: _allUsers[index].id,
          fullName: _allUsers[index].fullName,
          email: _allUsers[index].email,
          role: newRole, // Role baru
          avatarUrl: _allUsers[index].avatarUrl,
          institution: _allUsers[index].institution,
          major: _allUsers[index].major,
          batch: _allUsers[index].batch,
          phone: _allUsers[index].phone,
          lineId: _allUsers[index].lineId,
        );
      }

      print("Role berhasil diubah menjadi $newRole");
    } catch (e) {
      print("Error updating role: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateParticipantStatus(
    String registrationId,
    String newStatus,
  ) async {
    try {
      await _supabase
          .from('registrations')
          .update({'status': newStatus})
          .eq('id', registrationId);
      return true;
    } catch (e) {
      print("Error updating status: $e");
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<String?> subscribeNewsletter(String email) async {
    try {
      // Validasi sederhana
      if (!email.contains('@') || !email.contains('.')) {
        return "Format email tidak valid";
      }

      await _supabase.from('subscribers').insert({'email': email});
      return null; // Berhasil
    } catch (e) {
      // Cek jika error karena duplikat (email sudah ada)
      if (e.toString().contains('duplicate key')) {
        return "Email ini sudah berlangganan.";
      }
      return "Gagal berlangganan: $e";
    }
  }
 Future<List<Map<String, dynamic>>> fetchMyRegistrations() async {
    if (_currentUser == null) return [];

    try {
      final response = await _supabase
          .from('registrations')
          .select('''
            id,
            status,
            events (
              id,
              title,
              event_date,
              whatsapp_group_link,
              poster_url,
              category
            )
          ''')
          .eq('user_id', _currentUser!.id)
          // --- PERBAIKAN DI SINI ---
          // Ganti 'created_at' menjadi 'registration_date'
          .order('registration_date', ascending: false); 
          // -------------------------

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching my registrations: $e");
      return []; // Return list kosong jika error agar UI tidak crash
    }
  }
}
