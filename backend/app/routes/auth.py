from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User, Patient, Doctor, Nurse, MedicalStore, LabStore, Admin
from app.models.notification import Notification
from app.models.otp_verification import OTPVerification
from app.models.password_reset import PasswordResetOTP
from app.services.notification_service import NotificationService
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from datetime import datetime
import json

bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@bp.route('/register', methods=['POST'])
def register():
    """Initiate registration with OTP verification"""
    data = request.get_json()
    
    # Validate required fields
    if not data.get('email') or not data.get('password') or not data.get('role') or not data.get('name'):
        return jsonify({'error': 'Email, password, role, and name are required'}), 400
    
    # Check if user already exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 400
    
    # Check if there's already a pending OTP verification for this email
    existing_otp = OTPVerification.query.filter_by(email=data['email']).first()
    if existing_otp and not existing_otp.is_expired():
        return jsonify({'error': 'OTP already sent. Please check your email and phone.'}), 400
    
    # Clean up expired OTP records
    if existing_otp and existing_otp.is_expired():
        db.session.delete(existing_otp)
        db.session.commit()
    
    # Create temporary user object to hash password
    temp_user = User(email=data['email'], role=data['role'])
    temp_user.set_password(data['password'])
    
    # Store additional registration data
    additional_data = {
        'address': data.get('address', ''),
        'city': data.get('city', ''),
        'state': data.get('state', ''),
        'pincode': data.get('pincode', ''),
        'specialty': data.get('specialty', ''),
        'qualification': data.get('qualification', ''),
        'consultation_fee': data.get('consultation_fee', 0.0),
        'license_number': data.get('license_number', ''),
        'date_of_birth': data.get('date_of_birth', ''),
        'gender': data.get('gender', ''),
        'blood_group': data.get('blood_group', '')
    }
    
    # Create OTP verification record
    otp_verification = OTPVerification(
        email=data['email'],
        phone=data.get('phone', ''),
        name=data['name'],
        role=data['role'],
        password_hash=temp_user.password_hash,
        additional_data=json.dumps(additional_data)
    )
    
    db.session.add(otp_verification)
    db.session.commit()
    
    # Send OTP via email
    email_success, email_msg = NotificationService.send_registration_otp_email(
        data['email'], data['name'], otp_verification.email_otp
    )
    
    # Send OTP via SMS if phone number provided
    sms_success = True
    sms_msg = "No phone number provided"
    if data.get('phone'):
        sms_success, sms_msg = NotificationService.send_registration_otp_sms(
            data['phone'], data['name'], otp_verification.phone_otp
        )
    
    return jsonify({
        'success': True,
        'message': 'OTP sent successfully. Please verify to complete registration.',
        'verification_id': otp_verification.id,
        'email_sent': email_success,
        'sms_sent': sms_success if data.get('phone') else False,
        'phone_available': bool(data.get('phone')),
        'expires_in_minutes': 10
    }), 200

@bp.route('/check-roles', methods=['POST'])
def check_user_roles():
    """Check what roles are available for a user"""
    data = request.get_json()
    
    login_id = data.get('login_id')  # Can be email or mobile
    password = data.get('password')
    
    if not login_id or not password:
        return jsonify({'error': 'Email/Mobile and password are required'}), 400
    
    # Try to find user by email first, then by mobile through patient/doctor profiles
    user = None
    
    # Check if login_id is email format
    if '@' in login_id:
        user = User.query.filter_by(email=login_id).first()
    else:
        # Search by mobile number in Patient and Doctor tables
        from app.models.user import Patient, Doctor
        
        patient = Patient.query.filter_by(phone=login_id).first()
        if patient:
            user = patient.user
            
        if not user:
            doctor = Doctor.query.filter_by(phone=login_id).first()
            if doctor:
                user = doctor.user
    
    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    if not user.is_active:
        return jsonify({'error': 'Account is deactivated'}), 401
    
    # Check what roles the user has
    available_roles = [user.role]
    
    # Check if user can have multiple roles
    from app.models.user import Patient, Doctor
    
    # Check if user has patient profile
    patient = Patient.query.filter_by(user_id=user.id).first()
    if patient and 'patient' not in available_roles:
        available_roles.append('patient')
    
    # Check if user has doctor profile  
    doctor = Doctor.query.filter_by(user_id=user.id).first()
    if doctor and 'doctor' not in available_roles:
        available_roles.append('doctor')
    
    return jsonify({
        'success': True,
        'available_roles': available_roles,
        'user_id': user.id,
        'email': user.email
    }), 200

@bp.route('/login', methods=['POST'])
def login():
    """Login user with email/mobile and role selection"""
    data = request.get_json()
    
    login_id = data.get('login_id')  # Can be email or mobile
    password = data.get('password')
    selected_role = data.get('role', 'patient')  # Default to patient
    
    if not login_id or not password:
        return jsonify({'error': 'Email/Mobile and password are required'}), 400
    
    # Try to find user by email first, then by mobile through patient/doctor profiles
    user = None
    
    # Check if login_id is email format
    if '@' in login_id:
        user = User.query.filter_by(email=login_id).first()
    else:
        # Search by mobile number in Patient and Doctor tables
        from app.models.user import Patient, Doctor
        
        patient = Patient.query.filter_by(phone=login_id).first()
        if patient:
            user = patient.user
            
        if not user:
            doctor = Doctor.query.filter_by(phone=login_id).first()
            if doctor:
                user = doctor.user
    
    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    if not user.is_active:
        return jsonify({'error': 'Account is deactivated'}), 401
    
    # Check if user has the selected role
    user_roles = [user.role]
    
    # Check if user can have multiple roles
    from app.models.user import Patient, Doctor
    
    # Check if user has patient profile
    patient = Patient.query.filter_by(user_id=user.id).first()
    if patient and 'patient' not in user_roles:
        user_roles.append('patient')
    
    # Check if user has doctor profile  
    doctor = Doctor.query.filter_by(user_id=user.id).first()
    if doctor and 'doctor' not in user_roles:
        user_roles.append('doctor')
    
    if selected_role not in user_roles:
        return jsonify({'error': f'You do not have {selected_role} access'}), 403
    
    # Create tokens with string identity and include selected role
    additional_claims = {'role': selected_role}
    access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
    refresh_token = create_refresh_token(identity=str(user.id))
    
    # Get profile data based on selected role
    profile_data = None
    if selected_role == 'patient':
        patient_profile = Patient.query.filter_by(user_id=user.id).first()
        if patient_profile:
            profile_data = patient_profile.to_dict()
    elif selected_role == 'doctor':
        doctor_profile = Doctor.query.filter_by(user_id=user.id).first()
        if doctor_profile:
            profile_data = doctor_profile.to_dict()
    
    user_dict = user.to_dict()
    user_dict['selected_role'] = selected_role
    user_dict['available_roles'] = user_roles
    if profile_data:
        user_dict['profile'] = profile_data
    
    return jsonify({
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user_dict
    }), 200

@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token"""
    current_user_id = get_jwt_identity()
    access_token = create_access_token(identity=current_user_id)
    
    return jsonify({
        'access_token': access_token
    }), 200

@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current user details"""
    try:
        current_user_id = int(get_jwt_identity())  # Convert string back to int
        print(f"DEBUG: Current user ID from JWT: {current_user_id}")
        
        user = User.query.get(current_user_id)
        
        if not user:
            print(f"DEBUG: User not found for ID: {current_user_id}")
            return jsonify({'error': 'User not found'}), 404
        
        print(f"DEBUG: User found: {user.email}, role: {user.role}")
        
        # Get role-specific profile
        profile = None
        if user.role == 'patient':
            profile = Patient.query.filter_by(user_id=user.id).first()
            print(f"DEBUG: Patient profile: {profile.to_dict() if profile else None}")
        elif user.role == 'doctor':
            profile = Doctor.query.filter_by(user_id=user.id).first()
        elif user.role == 'nurse':
            profile = Nurse.query.filter_by(user_id=user.id).first()
        elif user.role == 'medical_store':
            profile = MedicalStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'lab_store':
            profile = LabStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'admin':
            profile = Admin.query.filter_by(user_id=user.id).first()
        
        response_data = {
            'user': user.to_dict(),
            'profile': profile.to_dict() if profile else None
        }
        print(f"DEBUG: Returning response: {response_data}")
        
        return jsonify(response_data), 200
    except Exception as e:
        print(f"ERROR in get_current_user: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change password for logged-in user"""
    try:
        current_user_id = int(get_jwt_identity())
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        if not current_password or not new_password:
            return jsonify({'error': 'Current password and new password are required'}), 400
        
        # Verify current password
        if not user.check_password(current_password):
            return jsonify({'error': 'Current password is incorrect'}), 401
        
        # Validate new password length
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters long'}), 400
        
        # Update password
        user.set_password(new_password)
        user.updated_at = datetime.utcnow()
        db.session.commit()
        
        # Get user profile for notification
        profile = None
        if user.role == 'patient':
            profile = Patient.query.filter_by(user_id=user.id).first()
        elif user.role == 'doctor':
            profile = Doctor.query.filter_by(user_id=user.id).first()
        elif user.role == 'nurse':
            profile = Nurse.query.filter_by(user_id=user.id).first()
        elif user.role == 'medical_store':
            profile = MedicalStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'lab_store':
            profile = LabStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'admin':
            profile = Admin.query.filter_by(user_id=user.id).first()
        
        # Create notification
        notification = Notification(
            user_id=user.id,
            title='Password Changed',
            message='Your password has been changed successfully.',
            notification_type='security'
        )
        
        # Add patient_id if user is a patient
        if user.role == 'patient' and profile:
            notification.patient_id = profile.id
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Password changed successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """Request password reset OTP"""
    try:
        data = request.get_json()
        email = data.get('email')
        
        if not email:
            return jsonify({'error': 'Email is required'}), 400
        
        user = User.query.filter_by(email=email).first()
        
        # Always return success to prevent email enumeration
        if not user:
            return jsonify({
                'success': True,
                'message': 'If the email exists, an OTP has been sent for password reset.'
            }), 200
        
        # Get user's phone number from profile
        phone = None
        profile = None
        if user.role == 'patient':
            profile = Patient.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        elif user.role == 'doctor':
            profile = Doctor.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        elif user.role == 'nurse':
            profile = Nurse.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        elif user.role == 'medical_store':
            profile = MedicalStore.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        elif user.role == 'lab_store':
            profile = LabStore.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        elif user.role == 'admin':
            profile = Admin.query.filter_by(user_id=user.id).first()
            phone = profile.phone if profile else None
        
        # Delete any existing password reset OTPs for this user
        PasswordResetOTP.query.filter_by(user_id=user.id).delete()
        
        # Create new password reset OTP
        reset_otp = PasswordResetOTP(
            user_id=user.id,
            email=user.email,
            phone=phone
        )
        db.session.add(reset_otp)
        db.session.commit()
        
        # Send OTP via email
        user_name = profile.name if profile else 'User'
        email_success, email_message = NotificationService.send_password_reset_otp_email(
            user.email,
            user_name,
            reset_otp.email_otp
        )
        
        # Send OTP via SMS if phone is available
        sms_success = False
        if phone:
            sms_success, sms_message = NotificationService.send_password_reset_otp_sms(
                phone,
                reset_otp.phone_otp
            )
        
        return jsonify({
            'success': True,
            'message': 'OTP sent successfully for password reset.',
            'reset_id': reset_otp.id,
            'email_sent': email_success,
            'sms_sent': sms_success,
            'phone_available': phone is not None,
            'expires_in_minutes': 10
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/verify-password-reset-otp', methods=['POST'])
def verify_password_reset_otp():
    """Verify OTP for password reset"""
    data = request.get_json()
    
    reset_id = data.get('reset_id')
    otp = data.get('otp')
    otp_type = data.get('type', 'email')  # 'email' or 'phone'
    
    if not reset_id or not otp:
        return jsonify({'error': 'Reset ID and OTP are required'}), 400
    
    # Find password reset OTP record
    reset_otp = PasswordResetOTP.query.get(reset_id)
    if not reset_otp:
        return jsonify({'error': 'Invalid reset ID'}), 404
    
    if reset_otp.is_expired():
        return jsonify({'error': 'OTP has expired. Please request a new one.'}), 400
    
    # Verify OTP
    if otp_type == 'email':
        success, message = reset_otp.verify_email_otp(otp)
    else:
        success, message = reset_otp.verify_phone_otp(otp)
    
    db.session.commit()
    
    if not success:
        return jsonify({'error': message}), 400
    
    # OTP verified successfully
    return jsonify({
        'success': True,
        'message': 'OTP verified successfully. You can now reset your password.',
        'reset_id': reset_otp.id
    }), 200

@bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password using verified OTP"""
    try:
        data = request.get_json()
        reset_id = data.get('reset_id')
        new_password = data.get('new_password')
        
        if not reset_id or not new_password:
            return jsonify({'error': 'Reset ID and new password are required'}), 400
        
        # Validate new password length
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters long'}), 400
        
        # Find password reset OTP record
        reset_otp = PasswordResetOTP.query.get(reset_id)
        if not reset_otp:
            return jsonify({'error': 'Invalid reset ID'}), 404
        
        if reset_otp.is_expired():
            return jsonify({'error': 'Reset session has expired. Please request a new OTP.'}), 400
        
        if not reset_otp.is_verified():
            return jsonify({'error': 'OTP not verified. Please verify OTP first.'}), 400
        
        # Get user
        user = User.query.get(reset_otp.user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Update password
        user.set_password(new_password)
        user.updated_at = datetime.utcnow()
        
        # Delete the password reset OTP record
        db.session.delete(reset_otp)
        db.session.commit()
        
        # Get user profile for notification
        profile = None
        if user.role == 'patient':
            profile = Patient.query.filter_by(user_id=user.id).first()
        elif user.role == 'doctor':
            profile = Doctor.query.filter_by(user_id=user.id).first()
        elif user.role == 'nurse':
            profile = Nurse.query.filter_by(user_id=user.id).first()
        elif user.role == 'medical_store':
            profile = MedicalStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'lab_store':
            profile = LabStore.query.filter_by(user_id=user.id).first()
        elif user.role == 'admin':
            profile = Admin.query.filter_by(user_id=user.id).first()
        
        # Create notification
        notification = Notification(
            user_id=user.id,
            title='Password Reset Successful',
            message='Your password has been reset successfully. If you did not make this change, please contact support immediately.',
            notification_type='security'
        )
        
        # Add patient_id if user is a patient
        if user.role == 'patient' and profile:
            notification.patient_id = profile.id
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Password reset successfully. You can now login with your new password.'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/resend-password-reset-otp', methods=['POST'])
def resend_password_reset_otp():
    """Resend OTP for password reset"""
    data = request.get_json()
    
    reset_id = data.get('reset_id')
    otp_type = data.get('type', 'both')  # 'email', 'phone', or 'both'
    
    if not reset_id:
        return jsonify({'error': 'Reset ID is required'}), 400
    
    # Find password reset OTP record
    reset_otp = PasswordResetOTP.query.get(reset_id)
    if not reset_otp:
        return jsonify({'error': 'Invalid reset ID'}), 404
    
    # Regenerate OTP
    reset_otp.regenerate_otp(otp_type)
    db.session.commit()
    
    # Get user and profile
    user = User.query.get(reset_otp.user_id)
    profile = None
    if user.role == 'patient':
        profile = Patient.query.filter_by(user_id=user.id).first()
    elif user.role == 'doctor':
        profile = Doctor.query.filter_by(user_id=user.id).first()
    elif user.role == 'nurse':
        profile = Nurse.query.filter_by(user_id=user.id).first()
    elif user.role == 'medical_store':
        profile = MedicalStore.query.filter_by(user_id=user.id).first()
    elif user.role == 'lab_store':
        profile = LabStore.query.filter_by(user_id=user.id).first()
    elif user.role == 'admin':
        profile = Admin.query.filter_by(user_id=user.id).first()
    
    user_name = profile.name if profile else 'User'
    
    # Send new OTP
    email_success = True
    sms_success = True
    
    if otp_type in ['email', 'both']:
        email_success, email_message = NotificationService.send_password_reset_otp_email(
            reset_otp.email,
            user_name,
            reset_otp.email_otp
        )
    
    if otp_type in ['phone', 'both'] and reset_otp.phone:
        sms_success, sms_message = NotificationService.send_password_reset_otp_sms(
            reset_otp.phone,
            reset_otp.phone_otp
        )
    
    return jsonify({
        'success': True,
        'message': 'OTP resent successfully',
        'email_sent': email_success,
        'sms_sent': sms_success,
        'expires_in_minutes': 10
    }), 200

@bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    """Verify OTP and complete registration"""
    data = request.get_json()
    
    verification_id = data.get('verification_id')
    otp = data.get('otp')
    otp_type = data.get('type', 'email')  # 'email' or 'phone'
    
    if not verification_id or not otp:
        return jsonify({'error': 'Verification ID and OTP are required'}), 400
    
    # Find OTP verification record
    otp_verification = OTPVerification.query.get(verification_id)
    if not otp_verification:
        return jsonify({'error': 'Invalid verification ID'}), 404
    
    if otp_verification.is_expired():
        return jsonify({'error': 'OTP has expired. Please request a new one.'}), 400
    
    # Verify OTP
    if otp_type == 'email':
        success, message = otp_verification.verify_email_otp(otp)
    else:
        success, message = otp_verification.verify_phone_otp(otp)
    
    if not success:
        db.session.commit()  # Save attempt count
        return jsonify({'error': message}), 400
    
    # OTP verified successfully - create user account
    try:
        # Create user
        user = User(
            email=otp_verification.email,
            role=otp_verification.role,
        )
        user.password_hash = otp_verification.password_hash
        db.session.add(user)
        db.session.flush()
        
        # Parse additional data
        additional_data = {}
        if otp_verification.additional_data:
            additional_data = json.loads(otp_verification.additional_data)
        
        # Helper function to parse date strings
        def parse_date(date_str):
            if not date_str:
                return None
            try:
                if isinstance(date_str, str):
                    from datetime import datetime
                    return datetime.strptime(date_str, '%Y-%m-%d').date()
                return date_str
            except:
                return None
        
        # Create role-specific profile
        profile = None
        if otp_verification.role == 'patient':
            profile = Patient(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or '',
                address=additional_data.get('address', ''),
                city=additional_data.get('city', ''),
                state=additional_data.get('state', ''),
                pincode=additional_data.get('pincode', ''),
                date_of_birth=parse_date(additional_data.get('date_of_birth')),
                gender=additional_data.get('gender', ''),
                blood_group=additional_data.get('blood_group', '')
            )
        elif otp_verification.role == 'doctor':
            profile = Doctor(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or '',
                specialty=additional_data.get('specialty', ''),
                qualification=additional_data.get('qualification', ''),
                consultation_fee=float(additional_data.get('consultation_fee', 0.0)),
                city=additional_data.get('city', ''),
                state=additional_data.get('state', '')
            )
        elif otp_verification.role == 'nurse':
            profile = Nurse(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or '',
                qualification=additional_data.get('qualification', ''),
                consultation_fee=float(additional_data.get('consultation_fee', 0.0)),
                city=additional_data.get('city', ''),
                state=additional_data.get('state', '')
            )
        elif otp_verification.role == 'medical_store':
            profile = MedicalStore(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or '',
                license_number=additional_data.get('license_number', ''),
                city=additional_data.get('city', ''),
                state=additional_data.get('state', '')
            )
        elif otp_verification.role == 'lab_store':
            profile = LabStore(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or '',
                license_number=additional_data.get('license_number', ''),
                city=additional_data.get('city', ''),
                state=additional_data.get('state', '')
            )
        elif otp_verification.role == 'admin':
            profile = Admin(
                user_id=user.id,
                name=otp_verification.name,
                phone=otp_verification.phone or ''
            )
        
        if profile:
            db.session.add(profile)
        
        # Clean up OTP verification record
        db.session.delete(otp_verification)
        
        db.session.commit()
        
        # Send welcome email
        NotificationService.send_account_created_notification(user.email, otp_verification.name)
        
        # Create tokens
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        return jsonify({
            'success': True,
            'message': 'Account created successfully!',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create account: {str(e)}'}), 500

@bp.route('/resend-otp', methods=['POST'])
def resend_otp():
    """Resend OTP for verification"""
    data = request.get_json()
    
    verification_id = data.get('verification_id')
    otp_type = data.get('type', 'both')  # 'email', 'phone', or 'both'
    
    if not verification_id:
        return jsonify({'error': 'Verification ID is required'}), 400
    
    # Find OTP verification record
    otp_verification = OTPVerification.query.get(verification_id)
    if not otp_verification:
        return jsonify({'error': 'Invalid verification ID'}), 404
    
    # Regenerate OTP
    otp_verification.regenerate_otp(otp_type)
    db.session.commit()
    
    # Send new OTP
    email_success = True
    sms_success = True
    
    if otp_type in ['email', 'both']:
        email_success, email_msg = NotificationService.send_registration_otp_email(
            otp_verification.email, otp_verification.name, otp_verification.email_otp
        )
    
    if otp_type in ['phone', 'both'] and otp_verification.phone:
        sms_success, sms_msg = NotificationService.send_registration_otp_sms(
            otp_verification.phone, otp_verification.name, otp_verification.phone_otp
        )
    
    return jsonify({
        'success': True,
        'message': 'OTP resent successfully',
        'email_sent': email_success if otp_type in ['email', 'both'] else False,
        'sms_sent': sms_success if otp_type in ['phone', 'both'] and otp_verification.phone else False,
        'expires_in_minutes': 10
    }), 200

@bp.route('/check-verification-status', methods=['POST'])
def check_verification_status():
    """Check the status of OTP verification"""
    data = request.get_json()
    
    verification_id = data.get('verification_id')
    
    if not verification_id:
        return jsonify({'error': 'Verification ID is required'}), 400
    
    otp_verification = OTPVerification.query.get(verification_id)
    if not otp_verification:
        return jsonify({'error': 'Invalid verification ID'}), 404
    
    return jsonify({
        'success': True,
        'data': otp_verification.to_dict(),
        'expired': otp_verification.is_expired(),
        'verified': otp_verification.is_verified()
    }), 200
