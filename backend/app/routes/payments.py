from flask import Blueprint, request, jsonify
from app import db
from app.models.payment import Payment
from app.models.medicine import MedicineOrder
from app.models.lab import LabTestOrder
from app.services.payment_service import RazorpayService
from flask_jwt_extended import jwt_required, get_jwt_identity
import uuid
import json

bp = Blueprint('payments', __name__, url_prefix='/api/payments')

# Initialize Razorpay service
try:
    razorpay_service = RazorpayService()
    razorpay_available = True
except:
    razorpay_available = False

@bp.route('/razorpay/create-order', methods=['POST'])
@jwt_required()
def create_razorpay_order():
    """Create a Razorpay order for medicine or lab test"""
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    if not razorpay_available:
        return jsonify({'error': 'Payment service not configured'}), 500
    
    # Validate required fields
    if not data.get('amount') or not data.get('related_type') or not data.get('related_id'):
        return jsonify({'error': 'Amount, related_type, and related_id are required'}), 400
    
    amount = float(data.get('amount'))
    related_type = data.get('related_type')  # 'medicine_order' or 'lab_order'
    related_id = data.get('related_id')
    description = data.get('description', f'{related_type} payment')
    
    # Validate related entity exists and belongs to user
    if related_type == 'medicine_order':
        from app.models.user import Patient
        order = MedicineOrder.query.get(related_id)
        if not order:
            return jsonify({'error': 'Medicine order not found'}), 404
        
        patient = Patient.query.get(order.patient_id)
        if not patient or patient.user_id != current_user_id:
            return jsonify({'error': 'Unauthorized access to order'}), 403
            
    elif related_type == 'lab_order':
        from app.models.user import Patient
        order = LabTestOrder.query.get(related_id)
        if not order:
            return jsonify({'error': 'Lab order not found'}), 404
        
        patient = Patient.query.get(order.patient_id)
        if not patient or patient.user_id != current_user_id:
            return jsonify({'error': 'Unauthorized access to order'}), 403
    else:
        return jsonify({'error': 'Invalid related_type'}), 400
    
    # Generate unique receipt
    receipt = f"{related_type}_{related_id}_{uuid.uuid4().hex[:8]}"
    
    # Create Razorpay order
    razorpay_result = razorpay_service.create_order(
        amount=amount,
        receipt=receipt,
        description=description,
        notes={
            'related_type': related_type,
            'related_id': str(related_id),
            'user_id': str(current_user_id)
        }
    )
    
    if not razorpay_result['success']:
        return jsonify({'error': razorpay_result['error']}), 500
    
    # Create payment record in database
    transaction_id = f"TXN{uuid.uuid4().hex[:12].upper()}"
    payment = Payment(
        user_id=current_user_id,
        amount=amount,
        payment_method='razorpay',
        payment_status='initiated',
        transaction_id=transaction_id,
        razorpay_order_id=razorpay_result['order_id'],
        razorpay_receipt=receipt,
        related_id=related_id,
        related_type=related_type
    )
    
    db.session.add(payment)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'razorpay_order_id': razorpay_result['order_id'],
        'amount': razorpay_result['amount'],
        'currency': razorpay_result['currency'],
        'razorpay_key': razorpay_service.key_id,  # Send key to frontend for Razorpay checkout
        'payment_id': payment.id,
        'description': description
    }), 201

@bp.route('/razorpay/verify', methods=['POST'])
@jwt_required()
def verify_razorpay_payment():
    """Verify Razorpay payment signature"""
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    if not razorpay_available:
        return jsonify({'error': 'Payment service not configured'}), 500
    
    # Validate required fields
    if not data.get('razorpay_order_id') or not data.get('razorpay_payment_id') or not data.get('razorpay_signature'):
        return jsonify({'error': 'Missing payment verification data'}), 400
    
    razorpay_order_id = data.get('razorpay_order_id')
    razorpay_payment_id = data.get('razorpay_payment_id')
    razorpay_signature = data.get('razorpay_signature')
    
    # Verify signature
    is_valid = razorpay_service.verify_payment_signature(
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature
    )
    
    if not is_valid:
        return jsonify({'error': 'Payment signature verification failed'}), 400
    
    # Find and update payment record
    payment = Payment.query.filter_by(
        razorpay_order_id=razorpay_order_id,
        user_id=current_user_id
    ).first()
    
    if not payment:
        return jsonify({'error': 'Payment record not found'}), 404
    
    # Fetch payment details from Razorpay to confirm
    payment_details = razorpay_service.fetch_payment(razorpay_payment_id)
    
    if not payment_details['success']:
        return jsonify({'error': 'Failed to verify payment with Razorpay'}), 500
    
    if payment_details['status'] != 'captured':
        return jsonify({'error': 'Payment not captured'}), 400
    
    # Update payment record
    payment.payment_status = 'completed'
    payment.razorpay_payment_id = razorpay_payment_id
    payment.razorpay_signature = razorpay_signature
    payment.gateway_response = json.dumps(payment_details)
    db.session.commit()
    
    # Update related order status
    if payment.related_type == 'medicine_order':
        order = MedicineOrder.query.get(payment.related_id)
        if order:
            order.payment_status = 'completed'
            db.session.commit()
            
            # Notify patient
            from app.models.notification import Notification
            from app.models.user import Patient
            patient = Patient.query.get(order.patient_id)
            if patient:
                notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Payment Successful',
                    message=f'Payment of ₹{payment.amount:.2f} received for medicine order #{order.id}',
                    notification_type='payment_update',
                    related_id=order.id
                )
                db.session.add(notification)
                db.session.commit()
    
    elif payment.related_type == 'lab_order':
        order = LabTestOrder.query.get(payment.related_id)
        if order:
            order.payment_status = 'completed'
            db.session.commit()
            
            # Notify patient
            from app.models.notification import Notification
            from app.models.user import Patient
            patient = Patient.query.get(order.patient_id)
            if patient:
                notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Payment Successful',
                    message=f'Payment of ₹{payment.amount:.2f} received for lab test order #{order.id}',
                    notification_type='payment_update',
                    related_id=order.id
                )
                db.session.add(notification)
                db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Payment verified successfully',
        'payment': payment.to_dict()
    }), 200

@bp.route('/', methods=['POST'])
@jwt_required()
def create_payment():
    """Create a new payment"""
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    # Generate transaction ID
    transaction_id = f"TXN{uuid.uuid4().hex[:12].upper()}"
    
    payment = Payment(
        user_id=current_user_id,
        amount=data['amount'],
        payment_method=data['payment_method'],
        transaction_id=transaction_id,
        related_id=data.get('related_id'),
        related_type=data.get('related_type')
    )
    
    db.session.add(payment)
    db.session.commit()
    
    # In production, integrate with actual payment gateway
    # For now, we'll mark as completed
    payment.payment_status = 'completed'
    db.session.commit()
    
    return jsonify({
        'message': 'Payment processed successfully',
        'payment': payment.to_dict()
    }), 201

@bp.route('/', methods=['GET'])
@jwt_required()
def get_payments():
    """Get user payment history"""
    current_user_id = get_jwt_identity()
    
    payments = Payment.query.filter_by(user_id=current_user_id).order_by(
        Payment.payment_date.desc()
    ).all()
    
    return jsonify({
        'payments': [payment.to_dict() for payment in payments]
    }), 200

@bp.route('/<int:payment_id>', methods=['GET'])
@jwt_required()
def get_payment(payment_id):
    """Get payment details"""
    current_user_id = get_jwt_identity()
    
    payment = Payment.query.filter_by(
        id=payment_id,
        user_id=current_user_id
    ).first()
    
    if not payment:
        return jsonify({'error': 'Payment not found'}), 404
    
    return jsonify(payment.to_dict()), 200
