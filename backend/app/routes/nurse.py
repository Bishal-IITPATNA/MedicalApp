from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Nurse
from app.models.appointment import Appointment
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

bp = Blueprint('nurse', __name__, url_prefix='/api/nurse')

@bp.route('/profile', methods=['GET', 'PUT'])
@jwt_required()
def profile():
    """Get or update nurse profile"""
    current_user_id = get_jwt_identity()
    nurse = Nurse.query.filter_by(user_id=current_user_id).first()
    
    if not nurse:
        return jsonify({'error': 'Nurse profile not found'}), 404
    
    if request.method == 'GET':
        return jsonify(nurse.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            nurse.name = data['name']
        if 'phone' in data:
            nurse.phone = data['phone']
        if 'qualification' in data:
            nurse.qualification = data['qualification']
        if 'experience_years' in data:
            nurse.experience_years = data['experience_years']
        if 'consultation_fee' in data:
            nurse.consultation_fee = data['consultation_fee']
        if 'address' in data:
            nurse.address = data['address']
        if 'city' in data:
            nurse.city = data['city']
        if 'state' in data:
            nurse.state = data['state']
        
        # Handle time slots data (JSON string containing array of time slots)
        if 'time_slots' in data:
            # Store the JSON string directly in available_days field
            nurse.available_days = data['time_slots']
            
            # Extract first time slot's data for backward compatibility
            import json
            try:
                time_slots_list = json.loads(data['time_slots']) if isinstance(data['time_slots'], str) else data['time_slots']
                if time_slots_list and len(time_slots_list) > 0:
                    first_slot = time_slots_list[0]
                    
                    # Convert time strings to time objects
                    if 'available_from' in first_slot:
                        try:
                            from datetime import datetime
                            time_str = first_slot['available_from']
                            try:
                                # Try 12-hour format first
                                nurse.available_from = datetime.strptime(time_str, '%I:%M %p').time()
                            except:
                                # Fall back to 24-hour format
                                nurse.available_from = datetime.strptime(time_str, '%H:%M').time()
                        except:
                            pass
                    
                    if 'available_to' in first_slot:
                        try:
                            from datetime import datetime
                            time_str = first_slot['available_to']
                            try:
                                nurse.available_to = datetime.strptime(time_str, '%I:%M %p').time()
                            except:
                                nurse.available_to = datetime.strptime(time_str, '%H:%M').time()
                        except:
                            pass
            except:
                pass
        
        # Legacy support: individual field updates
        if 'available_days' in data:
            nurse.available_days = data['available_days']
        if 'available_from' in data:
            nurse.available_from = datetime.strptime(data['available_from'], '%H:%M').time()
        if 'available_to' in data:
            nurse.available_to = datetime.strptime(data['available_to'], '%H:%M').time()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully',
            'profile': nurse.to_dict()
        }), 200

@bp.route('/appointments', methods=['GET'])
@jwt_required()
def get_appointments():
    """Get nurse's appointments"""
    current_user_id = get_jwt_identity()
    nurse = Nurse.query.filter_by(user_id=current_user_id).first()
    
    if not nurse:
        return jsonify({'error': 'Nurse profile not found'}), 404
    
    appointments = Appointment.query.filter_by(nurse_id=nurse.id).all()
    
    return jsonify({
        'appointments': [apt.to_dict() for apt in appointments]
    }), 200

@bp.route('/appointments/<int:appointment_id>', methods=['PUT'])
@jwt_required()
def update_appointment(appointment_id):
    """Accept, decline, or update appointment"""
    current_user_id = get_jwt_identity()
    nurse = Nurse.query.filter_by(user_id=current_user_id).first()
    
    if not nurse:
        return jsonify({'error': 'Nurse profile not found'}), 404
    
    appointment = Appointment.query.filter_by(id=appointment_id, nurse_id=nurse.id).first()
    
    if not appointment:
        return jsonify({'error': 'Appointment not found'}), 404
    
    data = request.get_json()
    
    if 'status' in data:
        appointment.status = data['status']
    if 'notes' in data:
        appointment.notes = data['notes']
    if 'appointment_date' in data:
        appointment.appointment_date = datetime.strptime(data['appointment_date'], '%Y-%m-%d').date()
    if 'appointment_time' in data:
        appointment.appointment_time = datetime.strptime(data['appointment_time'], '%H:%M').time()
    
    db.session.commit()
    
    return jsonify({
        'message': 'Appointment updated successfully',
        'appointment': appointment.to_dict()
    }), 200

@bp.route('/search', methods=['GET'])
def search_nurses():
    """Search nurses by location or name"""
    query = Nurse.query
    
    # Filter by city
    if request.args.get('city'):
        query = query.filter(Nurse.city.ilike(f"%{request.args.get('city')}%"))
    
    # Filter by state
    if request.args.get('state'):
        query = query.filter(Nurse.state.ilike(f"%{request.args.get('state')}%"))
    
    # Filter by name
    if request.args.get('name'):
        query = query.filter(Nurse.name.ilike(f"%{request.args.get('name')}%"))
    
    nurses = query.all()
    
    return jsonify({
        'nurses': [nurse.to_dict() for nurse in nurses]
    }), 200
