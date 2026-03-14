class Appointment {
  final int id;
  final int patientId;
  final int? doctorId;
  final int? nurseId;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String appointmentType;
  final String? symptoms;
  final String? diagnosis;
  final String? notes;
  final double? consultationFee;
  final String paymentStatus;
  final String? createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    this.doctorId,
    this.nurseId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.appointmentType,
    this.symptoms,
    this.diagnosis,
    this.notes,
    this.consultationFee,
    required this.paymentStatus,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      nurseId: json['nurse_id'],
      appointmentDate: json['appointment_date'],
      appointmentTime: json['appointment_time'],
      status: json['status'],
      appointmentType: json['appointment_type'],
      symptoms: json['symptoms'],
      diagnosis: json['diagnosis'],
      notes: json['notes'],
      consultationFee: json['consultation_fee']?.toDouble(),
      paymentStatus: json['payment_status'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'nurse_id': nurseId,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'appointment_type': appointmentType,
      'symptoms': symptoms,
      'consultation_fee': consultationFee,
    };
  }
}
