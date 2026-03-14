from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Patient, Doctor
from app.models.medicine import Prescription
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import json

bp = Blueprint('prescriptions', __name__, url_prefix='/api/prescriptions')

@bp.route('/', methods=['POST'])
@jwt_required()
def create_prescription():
    """Create a new prescription (doctor only)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        
        if not doctor:
            return jsonify({'error': 'Only doctors can create prescriptions'}), 403
        
        data = request.get_json()
        
        patient_id = data.get('patient_id')
        appointment_id = data.get('appointment_id')
        medicines = data.get('medicines', [])  # List of medicine objects
        instructions = data.get('instructions', '')
        
        if not patient_id:
            return jsonify({'error': 'Patient ID is required'}), 400
        
        # Verify patient exists
        patient = Patient.query.get(patient_id)
        if not patient:
            return jsonify({'error': 'Patient not found'}), 404
        
        # Create prescription
        prescription = Prescription(
            patient_id=patient_id,
            doctor_id=doctor.id,
            appointment_id=appointment_id,
            medicines=json.dumps(medicines),
            instructions=instructions
        )
        
        db.session.add(prescription)
        db.session.commit()
        
        # Create notification for patient
        medicine_names = ', '.join([m.get('name', '') for m in medicines[:3]])
        if len(medicines) > 3:
            medicine_names += f' and {len(medicines) - 3} more'
        
        notification = Notification(
            user_id=patient.user_id,
            patient_id=patient.id,
            title='New Prescription',
            message=f'Dr. {doctor.name} has prescribed medicines for you: {medicine_names}',
            notification_type='prescription',
            related_id=prescription.id,
            related_type='prescription'
        )
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Prescription created successfully',
            'prescription': prescription.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create prescription: {str(e)}'}), 500

@bp.route('/patient/<int:patient_id>', methods=['GET'])
@jwt_required()
def get_patient_prescriptions(patient_id):
    """Get all prescriptions for a patient"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor or the patient themselves
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        patient = Patient.query.filter_by(user_id=current_user_id).first()
        
        if not doctor and (not patient or patient.id != patient_id):
            return jsonify({'error': 'Unauthorized access'}), 403
        
        prescriptions = Prescription.query.filter_by(patient_id=patient_id).order_by(
            Prescription.prescription_date.desc()
        ).all()
        
        # Get doctor details for each prescription
        prescription_list = []
        for presc in prescriptions:
            presc_dict = presc.to_dict()
            doc = Doctor.query.get(presc.doctor_id)
            if doc:
                presc_dict['doctor_name'] = doc.name
                presc_dict['doctor_specialty'] = doc.specialty
            prescription_list.append(presc_dict)
        
        return jsonify({
            'success': True,
            'prescriptions': prescription_list
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to fetch prescriptions: {str(e)}'}), 500
