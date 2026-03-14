class User {
  final int id;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

class Patient {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      bloodGroup: json['blood_group'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
    };
  }
}

class Doctor {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? specialty;
  final String? qualification;
  final int? experienceYears;
  final double consultationFee;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double rating;
  final String? availableDays;
  final String? availableFrom;
  final String? availableTo;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.specialty,
    this.qualification,
    this.experienceYears,
    required this.consultationFee,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.rating,
    this.availableDays,
    this.availableFrom,
    this.availableTo,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      specialty: json['specialty'],
      qualification: json['qualification'],
      experienceYears: json['experience_years'],
      consultationFee: (json['consultation_fee'] ?? 0.0).toDouble(),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      availableDays: json['available_days'],
      availableFrom: json['available_from'],
      availableTo: json['available_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'specialty': specialty,
      'qualification': qualification,
      'experience_years': experienceYears,
      'consultation_fee': consultationFee,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'rating': rating,
      'available_days': availableDays,
      'available_from': availableFrom,
      'available_to': availableTo,
    };
  }
}

class Nurse {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? qualification;
  final int? experienceYears;
  final double consultationFee;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double rating;

  Nurse({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.qualification,
    this.experienceYears,
    required this.consultationFee,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.rating,
  });

  factory Nurse.fromJson(Map<String, dynamic> json) {
    return Nurse(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      qualification: json['qualification'],
      experienceYears: json['experience_years'],
      consultationFee: (json['consultation_fee'] ?? 0.0).toDouble(),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
