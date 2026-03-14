from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Patient, Doctor
from app.models.appointment import Appointment
from app.models.medicine import Prescription, MedicineOrder
from app.models.lab import LabTestOrder, LabReport
from flask_jwt_extended import jwt_required, get_jwt_identity
import json

bp = Blueprint('patient_history', __name__, url_prefix='/api/patient-history')

@bp.route('/<int:patient_id>', methods=['GET'])
@jwt_required()
def get_patient_history(patient_id):
    """Get complete medical history for a patient (doctor only)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        
        if not doctor:
            return jsonify({'error': 'Only doctors can view patient history'}), 403
        
        # Get patient details
        patient = Patient.query.get(patient_id)
        
        if not patient:
            return jsonify({'error': 'Patient not found'}), 404
        
        # Get all appointments for this patient
        appointments = Appointment.query.filter_by(patient_id=patient_id).order_by(
            Appointment.appointment_date.desc()
        ).all()
        
        appointments_list = []
        for apt in appointments:
            apt_dict = apt.to_dict()
            if apt.doctor_id:
                doc = Doctor.query.get(apt.doctor_id)
                if doc:
                    apt_dict['doctor_name'] = doc.name
                    apt_dict['doctor_specialty'] = doc.specialty
            appointments_list.append(apt_dict)
        
        # Get all prescriptions
        prescriptions = Prescription.query.filter_by(patient_id=patient_id).order_by(
            Prescription.prescription_date.desc()
        ).all()
        
        prescriptions_list = []
        for presc in prescriptions:
            presc_dict = presc.to_dict()
            doc = Doctor.query.get(presc.doctor_id)
            if doc:
                presc_dict['doctor_name'] = doc.name
            # Parse medicines JSON
            if presc.medicines:
                try:
                    presc_dict['medicines_list'] = json.loads(presc.medicines)
                except:
                    presc_dict['medicines_list'] = []
            prescriptions_list.append(presc_dict)
        
        # Get all medicine orders
        medicine_orders = MedicineOrder.query.filter_by(patient_id=patient_id).order_by(
            MedicineOrder.order_date.desc()
        ).all()
        
        # Get all lab test orders
        lab_orders = LabTestOrder.query.filter_by(patient_id=patient_id).order_by(
            LabTestOrder.order_date.desc()
        ).all()
        
        # Get all lab reports
        lab_reports = LabReport.query.filter_by(patient_id=patient_id).order_by(
            LabReport.report_date.desc()
        ).all()
        
        return jsonify({
            'success': True,
            'patient': patient.to_dict(),
            'appointments': appointments_list,
            'prescriptions': prescriptions_list,
            'medicine_orders': [order.to_dict() for order in medicine_orders],
            'lab_orders': [order.to_dict() for order in lab_orders],
            'lab_reports': [report.to_dict() for report in lab_reports]
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to fetch patient history: {str(e)}'}), 500
