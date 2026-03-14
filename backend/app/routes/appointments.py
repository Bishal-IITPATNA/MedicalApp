from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Patient, Doctor, Nurse
from app.models.appointment import Appointment
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

bp = Blueprint('appointments', __name__, url_prefix='/api/appointments')

@bp.route('/', methods=['POST'])
@jwt_required()
def create_appointment():
    """Book a new appointment"""
    try:
        current_user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=current_user_id).first()
        
        if not patient:
            return jsonify({'error': 'Patient profile not found'}), 404
        
        data = request.get_json()
        
        # Parse appointment date and time
        appointment_date = datetime.strptime(data['appointment_date'], '%Y-%m-%d').date()
        
        # Parse appointment time - handle both 12-hour and 24-hour formats
        time_str = data['appointment_time']
        appointment_time = None
        
        try:
            # Try 24-hour format first (HH:MM)
            appointment_time = datetime.strptime(time_str, '%H:%M').time()
        except ValueError:
            try:
                # Try 12-hour format (h:MM AM/PM)
                appointment_time = datetime.strptime(time_str, '%I:%M %p').time()
            except ValueError:
                return jsonify({'error': f'Invalid time format: {time_str}. Use HH:MM or h:MM AM/PM'}), 400
        
        doctor_id = data.get('doctor_id')
        nurse_id = data.get('nurse_id')
        
        # Check for duplicate booking - same patient, same doctor/nurse, same date and time
        if doctor_id:
            duplicate = Appointment.query.filter_by(
                patient_id=patient.id,
                doctor_id=doctor_id,
                appointment_date=appointment_date,
                appointment_time=appointment_time
            ).filter(Appointment.status != 'cancelled').first()
            
            if duplicate:
                return jsonify({
                    'error': 'You already have an appointment with this doctor at this time'
                }), 400
        
        if nurse_id:
            duplicate = Appointment.query.filter_by(
                patient_id=patient.id,
                nurse_id=nurse_id,
                appointment_date=appointment_date,
                appointment_time=appointment_time
            ).filter(Appointment.status != 'cancelled').first()
            
            if duplicate:
                return jsonify({
                    'error': 'You already have an appointment with this nurse at this time'
                }), 400
        
        # Check for conflicting appointments - same patient, different doctor/nurse, same date and time
        conflicting = Appointment.query.filter_by(
            patient_id=patient.id,
            appointment_date=appointment_date,
            appointment_time=appointment_time
        ).filter(Appointment.status != 'cancelled').first()
        
        if conflicting:
            if conflicting.doctor_id and conflicting.doctor_id != doctor_id:
                doctor = Doctor.query.get(conflicting.doctor_id)
                doctor_name = doctor.name if doctor else 'another doctor'
                return jsonify({
                    'error': f'You already have an appointment with {doctor_name} at this time'
                }), 400
            elif conflicting.nurse_id and conflicting.nurse_id != nurse_id:
                nurse = Nurse.query.get(conflicting.nurse_id)
                nurse_name = nurse.name if nurse else 'a nurse'
                return jsonify({
                    'error': f'You already have an appointment with {nurse_name} at this time'
                }), 400
        
        appointment = Appointment(
            patient_id=patient.id,
            doctor_id=doctor_id,
            nurse_id=nurse_id,
            appointment_date=appointment_date,
            appointment_time=appointment_time,
            appointment_type=data['appointment_type'],
            symptoms=data.get('symptoms'),
            consultation_fee=data.get('consultation_fee', 0.0)
        )
        
        db.session.add(appointment)
        db.session.commit()
        
        # Create notification for doctor/nurse about new booking
        if doctor_id:
            doctor = Doctor.query.get(doctor_id)
            if doctor:
                notification = Notification(
                    user_id=doctor.user_id,
                    patient_id=patient.id,
                    title='New Appointment Request',
                    message=f'New appointment request from {patient.name} on {appointment_date.strftime("%B %d, %Y")} at {appointment_time.strftime("%I:%M %p")}',
                    notification_type='appointment',
                    related_id=appointment.id,
                    related_type='appointment'
                )
                db.session.add(notification)
        
        if nurse_id:
            nurse = Nurse.query.get(nurse_id)
            if nurse:
                notification = Notification(
                    user_id=nurse.user_id,
                    patient_id=patient.id,
                    title='New Appointment Request',
                    message=f'New appointment request from {patient.name} on {appointment_date.strftime("%B %d, %Y")} at {appointment_time.strftime("%I:%M %p")}',
                    notification_type='appointment',
                    related_id=appointment.id,
                    related_type='appointment'
                )
                db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Appointment booked successfully',
            'data': {'appointment_id': appointment.id},
            'appointment': appointment.to_dict()
        }), 201
        
    except KeyError as e:
        return jsonify({'error': f'Missing required field: {str(e)}'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to book appointment: {str(e)}'}), 500

@bp.route('/<int:appointment_id>', methods=['GET', 'PUT', 'DELETE'])
@jwt_required()
def appointment_detail(appointment_id):
    """Get, update, or cancel an appointment"""
    current_user_id = get_jwt_identity()
    
    appointment = Appointment.query.get(appointment_id)
    
    if not appointment:
        return jsonify({'error': 'Appointment not found'}), 404
    
    if request.method == 'GET':
        return jsonify(appointment.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        if 'status' in data:
            appointment.status = data['status']
        if 'appointment_date' in data:
            appointment.appointment_date = datetime.strptime(data['appointment_date'], '%Y-%m-%d').date()
        if 'appointment_time' in data:
            appointment.appointment_time = datetime.strptime(data['appointment_time'], '%H:%M').time()
        if 'notes' in data:
            appointment.notes = data['notes']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Appointment updated successfully',
            'appointment': appointment.to_dict()
        }), 200
    
    elif request.method == 'DELETE':
        appointment.status = 'cancelled'
        db.session.commit()
        
        return jsonify({
            'message': 'Appointment cancelled successfully'
        }), 200

@bp.route('/<int:appointment_id>/confirm', methods=['POST'])
@jwt_required()
def confirm_appointment(appointment_id):
    """Confirm an appointment (doctor/nurse only)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor or nurse
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        nurse = Nurse.query.filter_by(user_id=current_user_id).first()
        
        if not doctor and not nurse:
            return jsonify({'error': 'Only doctors and nurses can confirm appointments'}), 403
        
        appointment = Appointment.query.get(appointment_id)
        
        if not appointment:
            return jsonify({'error': 'Appointment not found'}), 404
        
        # Verify this appointment belongs to the doctor/nurse
        if doctor and appointment.doctor_id != doctor.id:
            return jsonify({'error': 'You can only confirm your own appointments'}), 403
        if nurse and appointment.nurse_id != nurse.id:
            return jsonify({'error': 'You can only confirm your own appointments'}), 403
        
        # Update appointment status
        appointment.status = 'confirmed'
        db.session.commit()
        
        # Get patient details for notification
        patient = Patient.query.get(appointment.patient_id)
        
        # Create notification for patient
        provider_name = doctor.name if doctor else nurse.name
        provider_type = 'Dr.' if doctor else 'Nurse'
        
        notification = Notification(
            user_id=patient.user_id,
            patient_id=patient.id,
            title='Appointment Confirmed',
            message=f'Your appointment with {provider_type} {provider_name} on {appointment.appointment_date.strftime("%B %d, %Y")} at {appointment.appointment_time.strftime("%I:%M %p")} has been confirmed.',
            notification_type='appointment',
            related_id=appointment.id,
            related_type='appointment'
        )
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Appointment confirmed successfully',
            'appointment': appointment.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to confirm appointment: {str(e)}'}), 500

@bp.route('/<int:appointment_id>/reject', methods=['POST'])
@jwt_required()
def reject_appointment(appointment_id):
    """Reject/Cancel an appointment (doctor/nurse only)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor or nurse
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        nurse = Nurse.query.filter_by(user_id=current_user_id).first()
        
        if not doctor and not nurse:
            return jsonify({'error': 'Only doctors and nurses can reject appointments'}), 403
        
        appointment = Appointment.query.get(appointment_id)
        
        if not appointment:
            return jsonify({'error': 'Appointment not found'}), 404
        
        # Verify this appointment belongs to the doctor/nurse
        if doctor and appointment.doctor_id != doctor.id:
            return jsonify({'error': 'You can only reject your own appointments'}), 403
        if nurse and appointment.nurse_id != nurse.id:
            return jsonify({'error': 'You can only reject your own appointments'}), 403
        
        # Get reason from request body (optional)
        data = request.get_json() or {}
        reason = data.get('reason', 'No reason provided')
        
        # Update appointment status
        appointment.status = 'cancelled'
        appointment.notes = f'Cancelled by provider. Reason: {reason}'
        db.session.commit()
        
        # Get patient details for notification
        patient = Patient.query.get(appointment.patient_id)
        
        # Create notification for patient
        provider_name = doctor.name if doctor else nurse.name
        provider_type = 'Dr.' if doctor else 'Nurse'
        
        notification = Notification(
            user_id=patient.user_id,
            patient_id=patient.id,
            title='Appointment Cancelled',
            message=f'Your appointment with {provider_type} {provider_name} on {appointment.appointment_date.strftime("%B %d, %Y")} at {appointment.appointment_time.strftime("%I:%M %p")} has been cancelled. Reason: {reason}',
            notification_type='appointment',
            related_id=appointment.id,
            related_type='appointment'
        )
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Appointment cancelled successfully',
            'appointment': appointment.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to cancel appointment: {str(e)}'}), 500
