class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? institution;
  final String? avatarUrl;
  final String? cvUrl;
  final String? portfolioUrl;

  // --- Data Tambahan ---
  final String? major;
  final String? batch;
  final String? phone;
  final String? lineId; // <--- TAMBAHAN: Line ID

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.institution,
    this.avatarUrl,
    this.cvUrl,
    this.portfolioUrl,
    this.major,
    this.batch,
    this.phone,
    this.lineId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'No Name',
      role: json['role'] ?? 'mahasiswa',
      institution: json['institution'],
      avatarUrl: json['avatar_url'],
      cvUrl: json['cv_url'],
      portfolioUrl: json['portfolio_url'],

      // Mapping ke Nama Kolom Database yang BENAR
      major: json['major'],
      batch: json['batch_year'], // Sesuai DB: batch_year
      phone: json['phone_number'], // Sesuai DB: phone_number
      lineId: json['line_id'], // Sesuai DB: line_id
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? role,
    String? institution,
    String? avatarUrl,
    String? cvUrl,
    String? portfolioUrl,
    String? major,
    String? batch,
    String? phone,
    String? lineId,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      institution: institution ?? this.institution,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      major: major ?? this.major,
      batch: batch ?? this.batch,
      phone: phone ?? this.phone,
      lineId: lineId ?? this.lineId,
    );
  }
}

class EventModel {
  final String id;
  final String name;
  final String description;
  final String organization;
  final String category;
  final String posterUrl;

  final DateTime eventDate;
  final DateTime openRegDate;
  final DateTime closeRegDate;

  // --- Field Baru ---
  final DateTime? tmDate; // Khusus Lomba
  final DateTime? prelimDate; // Khusus Lomba
  final String terms; // S&K
  final String waGroupLink; // Link Group WA (Event)
  final String bankAccount; // No Rekening (Lomba)
  final List<String> subEvents; // Jenis Lomba (Lomba)

  // Data Lama
  final List<String> benefits;
  final List<String> divisions; // Divisi (Event/Pengmas)
  final String whatsapp;
  final String instagram;
  final String lineId;
  final String location;
  final String fee;
  final int maxParticipants;
  final int currentParticipants;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.organization,
    required this.category,
    required this.posterUrl,
    required this.eventDate,
    required this.openRegDate,
    required this.closeRegDate,
    this.tmDate,
    this.prelimDate,
    this.terms = '-',
    this.waGroupLink = '-',
    this.bankAccount = '-',
    this.subEvents = const [],
    this.benefits = const [],
    this.divisions = const [],
    this.whatsapp = '-',
    this.instagram = '-',
    this.lineId = '-',
    this.location = '-',
    this.fee = '-',
    this.maxParticipants = 0,
    this.currentParticipants = 0,
  });
  int get remainingQuota => maxParticipants - currentParticipants;
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      organization: json['organization_name'] ?? 'Organizer',
      category: json['category'] ?? 'event',
      posterUrl: json['poster_url'] ?? 'https://via.placeholder.com/400x600',

      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'])
          : DateTime.now(),
      openRegDate: json['start_reg_date'] != null
          ? DateTime.parse(json['start_reg_date'])
          : DateTime.now(),
      closeRegDate: json['end_reg_date'] != null
          ? DateTime.parse(json['end_reg_date'])
          : DateTime.now(),

      // --- Mapping Field Baru ---
      tmDate: json['tm_date'] != null ? DateTime.parse(json['tm_date']) : null,
      prelimDate: json['prelim_date'] != null
          ? DateTime.parse(json['prelim_date'])
          : null,
      terms: json['terms_and_conditions'] ?? '-',
      waGroupLink: json['whatsapp_group_link'] ?? '-',
      bankAccount: json['bank_account_info'] ?? '-',
      subEvents: json['sub_events'] != null
          ? List<String>.from(json['sub_events'])
          : [],

      // Mapping Lama
      divisions: json['divisions'] != null
          ? List<String>.from(json['divisions'])
          : [],
      benefits: [],
      whatsapp: json['contact_whatsapp']?.toString() ?? '-',
      lineId: json['contact_line']?.toString() ?? '-',

      location: json['location']?.toString() ?? '-',
      // This specifically fixes the "int is not subtype of String" error for fees
      fee: json['registration_fee']?.toString() ?? 'Free',
      maxParticipants: json['max_participants'] ?? 0,
      currentParticipants: json['current_participants'] ?? 0,
    );
  }
}
