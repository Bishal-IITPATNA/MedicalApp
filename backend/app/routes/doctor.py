from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Doctor
from app.models.appointment import Appointment
from app.models.medicine import Prescription
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

bp = Blueprint('doctor', __name__, url_prefix='/api/doctor')

def paginate_query(query, page=1, per_page=20, max_per_page=100):
    """Helper function to paginate a SQLAlchemy query"""
    try:
        page = int(request.args.get('page', page))
        per_page = min(int(request.args.get('per_page', per_page)), max_per_page)
    except (ValueError, TypeError):
        page = 1
        per_page = 20
    
    if page < 1:
        page = 1
    if per_page < 1:
        per_page = 20
    
    paginated = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return {
        'items': [item.to_dict() for item in paginated.items],
        'total': paginated.total,
        'page': paginated.page,
        'per_page': paginated.per_page,
        'pages': paginated.pages,
        'has_next': paginated.has_next,
        'has_prev': paginated.has_prev
    }

@bp.route('/profile', methods=['GET', 'PUT'])
@jwt_required()
def profile():
    """Get or update doctor profile"""
    current_user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=current_user_id).first()
    
    if not doctor:
        return jsonify({'error': 'Doctor profile not found'}), 404
    
    if request.method == 'GET':
        return jsonify(doctor.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            doctor.name = data['name']
        if 'phone' in data:
            doctor.phone = data['phone']
        if 'address' in data:
            doctor.address = data['address']
        if 'city' in data:
            doctor.city = data['city']
        if 'state' in data:
            doctor.state = data['state']
        if 'pincode' in data:
            doctor.pincode = data['pincode']
        if 'specialty' in data:
            doctor.specialty = data['specialty']
        if 'qualification' in data:
            doctor.qualification = data['qualification']
        if 'experience_years' in data:
            doctor.experience_years = data['experience_years']
        if 'consultation_fee' in data:
            doctor.consultation_fee = data['consultation_fee']
        
        # Sync profile address to chambers when address fields are updated
        address_fields_updated = any(field in data for field in ['address', 'city', 'state', 'pincode', 'consultation_fee'])
        
        if address_fields_updated and 'chambers' not in data:
            import json
            chambers = []
            if doctor.available_days:
                try:
                    chambers = json.loads(doctor.available_days) if isinstance(doctor.available_days, str) else doctor.available_days
                except:
                    chambers = []
            
            # Create primary chamber from profile data
            primary_chamber = {
                'name': f'{doctor.name} - Primary Chamber',
                'address': doctor.address,
                'city': doctor.city,
                'state': doctor.state,
                'pincode': doctor.pincode,
                'consultation_fee': doctor.consultation_fee,
                'available_from': doctor.available_from.strftime('%I:%M %p') if doctor.available_from else '09:00 AM',
                'available_to': doctor.available_to.strftime('%I:%M %p') if doctor.available_to else '05:00 PM',
                'available_days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
            }
            
            # Update first chamber or create new one
            if chambers:
                chambers[0] = primary_chamber
            else:
                chambers = [primary_chamber]
            
            # Save updated chambers
            doctor.available_days = json.dumps(chambers)
        
        # Handle chambers data (JSON string containing array of chambers)
        if 'chambers' in data:
            # Store the JSON string directly in available_days field
            doctor.available_days = data['chambers']
            
            # Extract first chamber's data for backward compatibility
            import json
            try:
                chambers_list = json.loads(data['chambers']) if isinstance(data['chambers'], str) else data['chambers']
                if chambers_list and len(chambers_list) > 0:
                    first_chamber = chambers_list[0]
                    doctor.consultation_fee = first_chamber.get('consultation_fee', 0.0)
                    doctor.address = first_chamber.get('address', '')
                    doctor.city = first_chamber.get('city', '')
                    doctor.state = first_chamber.get('state', '')
                    doctor.pincode = first_chamber.get('pincode', '')
                    
                    # Convert time strings to time objects
                    if 'available_from' in first_chamber:
                        try:
                            from datetime import datetime
                            # Handle both "HH:MM AM/PM" and "HH:MM" formats
                            time_str = first_chamber['available_from']
                            try:
                                # Try 12-hour format first
                                doctor.available_from = datetime.strptime(time_str, '%I:%M %p').time()
                            except:
                                # Fall back to 24-hour format
                                doctor.available_from = datetime.strptime(time_str, '%H:%M').time()
                        except:
                            pass
                    
                    if 'available_to' in first_chamber:
                        try:
                            from datetime import datetime
                            time_str = first_chamber['available_to']
                            try:
                                doctor.available_to = datetime.strptime(time_str, '%I:%M %p').time()
                            except:
                                doctor.available_to = datetime.strptime(time_str, '%H:%M').time()
                        except:
                            pass
            except:
                pass
        
        # Legacy support: time field updates
        if 'available_from' in data:
            doctor.available_from = datetime.strptime(data['available_from'], '%H:%M').time()
        if 'available_to' in data:
            doctor.available_to = datetime.strptime(data['available_to'], '%H:%M').time()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully',
            'profile': doctor.to_dict()
        }), 200

@bp.route('/appointments', methods=['GET'])
@jwt_required()
def get_appointments():
    """Get doctor's appointments (paginated)"""
    current_user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=current_user_id).first()
    
    if not doctor:
        return jsonify({'error': 'Doctor profile not found'}), 404
    
    query = Appointment.query.filter_by(doctor_id=doctor.id).order_by(Appointment.appointment_date.desc())
    result = paginate_query(query, page=1, per_page=10)
    
    return jsonify({
        'appointments': result['items'],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/appointments/<int:appointment_id>', methods=['PUT'])
@jwt_required()
def update_appointment(appointment_id):
    """Update appointment details"""
    current_user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=current_user_id).first()
    
    if not doctor:
        return jsonify({'error': 'Doctor profile not found'}), 404
    
    appointment = Appointment.query.filter_by(id=appointment_id, doctor_id=doctor.id).first()
    
    if not appointment:
        return jsonify({'error': 'Appointment not found'}), 404
    
    data = request.get_json()
    
    if 'status' in data:
        appointment.status = data['status']
    if 'diagnosis' in data:
        appointment.diagnosis = data['diagnosis']
    if 'notes' in data:
        appointment.notes = data['notes']
    
    db.session.commit()
    
    return jsonify({
        'message': 'Appointment updated successfully',
        'appointment': appointment.to_dict()
    }), 200

@bp.route('/prescriptions', methods=['POST'])
@jwt_required()
def create_prescription():
    """Create a prescription for a patient"""
    current_user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=current_user_id).first()
    
    if not doctor:
        return jsonify({'error': 'Doctor profile not found'}), 404
    
    data = request.get_json()
    
    prescription = Prescription(
        patient_id=data['patient_id'],
        doctor_id=doctor.id,
        appointment_id=data.get('appointment_id'),
        medicines=data.get('medicines'),
        instructions=data.get('instructions')
    )
    
    db.session.add(prescription)
    db.session.commit()
    
    return jsonify({
        'message': 'Prescription created successfully',
        'prescription': prescription.to_dict()
    }), 201

@bp.route('/chambers', methods=['GET', 'PUT'])
@jwt_required()
def manage_chambers():
    """Get or update doctor's chambers"""
    current_user_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(user_id=current_user_id).first()
    
    if not doctor:
        return jsonify({'error': 'Doctor profile not found'}), 404
    
    if request.method == 'GET':
        # Return chambers data
        import json
        chambers = []
        if doctor.available_days:
            try:
                chambers = json.loads(doctor.available_days) if isinstance(doctor.available_days, str) else doctor.available_days
            except:
                chambers = []
        
        return jsonify({
            'success': True,
            'chambers': chambers
        }), 200
    
    elif request.method == 'PUT':
        # Update chambers data
        data = request.get_json()
        import json
        
        if 'chambers' in data:
            chambers_data = data['chambers']
            # Store as JSON string
            doctor.available_days = json.dumps(chambers_data) if isinstance(chambers_data, list) else chambers_data
            
            # Sync first chamber to profile fields for consistency
            if chambers_data and len(chambers_data) > 0:
                first_chamber = chambers_data[0]
                doctor.address = first_chamber.get('address', doctor.address)
                doctor.city = first_chamber.get('city', doctor.city)
                doctor.state = first_chamber.get('state', doctor.state)
                doctor.pincode = first_chamber.get('pincode', doctor.pincode)
                doctor.consultation_fee = first_chamber.get('consultation_fee', doctor.consultation_fee)
                
                # Parse time strings
                if 'available_from' in first_chamber:
                    try:
                        time_str = first_chamber['available_from']
                        try:
                            doctor.available_from = datetime.strptime(time_str, '%I:%M %p').time()
                        except:
                            doctor.available_from = datetime.strptime(time_str, '%H:%M').time()
                    except:
                        pass
                
                if 'available_to' in first_chamber:
                    try:
                        time_str = first_chamber['available_to']
                        try:
                            doctor.available_to = datetime.strptime(time_str, '%I:%M %p').time()
                        except:
                            doctor.available_to = datetime.strptime(time_str, '%H:%M').time()
                    except:
                        pass
            
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': 'Chambers updated successfully',
                'chambers': chambers_data
            }), 200
        
        return jsonify({'error': 'No chambers data provided'}), 400

@bp.route('/search', methods=['GET'])
def search_doctors():
    """Search doctors by location, specialty, or name (paginated)"""
    query = Doctor.query
    
    # Filter by city
    if request.args.get('city'):
        query = query.filter(Doctor.city.ilike(f"%{request.args.get('city')}%"))
    
    # Filter by state
    if request.args.get('state'):
        query = query.filter(Doctor.state.ilike(f"%{request.args.get('state')}%"))
    
    # Filter by specialty
    if request.args.get('specialty'):
        query = query.filter(Doctor.specialty.ilike(f"%{request.args.get('specialty')}%"))
    
    # Filter by name
    if request.args.get('name'):
        query = query.filter(Doctor.name.ilike(f"%{request.args.get('name')}%"))
    
    query = query.order_by(Doctor.id.desc())
    result = paginate_query(query, page=1, per_page=20)
    
    return jsonify({
        'doctors': result['items'],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200
