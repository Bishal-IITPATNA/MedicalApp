from app import db
from datetime import datetime

class Appointment(db.Model):
    __tablename__ = 'appointments'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=True)
    nurse_id = db.Column(db.Integer, db.ForeignKey('nurses.id'), nullable=True)
    
    appointment_date = db.Column(db.Date, nullable=False)
    appointment_time = db.Column(db.Time, nullable=False)
    status = db.Column(db.String(20), default='pending')  # pending, confirmed, completed, cancelled
    appointment_type = db.Column(db.String(20))  # doctor, nurse
    
    # Details
    symptoms = db.Column(db.Text)
    diagnosis = db.Column(db.Text)
    notes = db.Column(db.Text)
    
    # Timing
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Payment
    consultation_fee = db.Column(db.Float)
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed
    
    def to_dict(self):
        # Get doctor details if doctor_id exists
        doctor_info = None
        if self.doctor_id:
            from app.models.user import Doctor
            doctor = Doctor.query.get(self.doctor_id)
            if doctor:
                doctor_info = {
                    'id': doctor.id,
                    'name': doctor.name,
                    'specialty': doctor.specialty,
                    'qualification': doctor.qualification,
                    'experience_years': doctor.experience_years,
                    'phone': doctor.phone,
                    'email': doctor.user.email if doctor.user else None,
                    'address': doctor.address,
                    'consultation_fee': doctor.consultation_fee,
                    'rating': doctor.rating
                }
        
        # Get nurse details if nurse_id exists
        nurse_info = None
        if self.nurse_id:
            from app.models.user import Nurse
            nurse = Nurse.query.get(self.nurse_id)
            if nurse:
                nurse_info = {
                    'id': nurse.id,
                    'name': nurse.name,
                    'qualification': nurse.qualification,
                    'experience_years': nurse.experience_years,
                    'phone': nurse.phone,
                    'email': nurse.user.email if nurse.user else None,
                    'address': nurse.address,
                    'consultation_fee': nurse.consultation_fee,
                    'rating': nurse.rating
                }
        
        # Get prescriptions for this appointment
        prescriptions_info = []
        from app.models.medicine import Prescription
        prescriptions = Prescription.query.filter_by(appointment_id=self.id).all()
        for prescription in prescriptions:
            prescriptions_info.append(prescription.to_dict())
        
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'doctor_id': self.doctor_id,
            'nurse_id': self.nurse_id,
            'doctor': doctor_info,
            'nurse': nurse_info,
            'appointment_date': self.appointment_date.isoformat() if self.appointment_date else None,
            'appointment_time': self.appointment_time.isoformat() if self.appointment_time else None,
            'status': self.status,
            'appointment_type': self.appointment_type,
            'symptoms': self.symptoms,
            'diagnosis': self.diagnosis,
            'notes': self.notes,
            'consultation_fee': self.consultation_fee,
            'payment_status': self.payment_status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'prescriptions': prescriptions_info
        }
