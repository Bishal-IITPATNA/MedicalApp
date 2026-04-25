from flask import Blueprint, request, jsonify
from app import db
from app.models.payment import Payment
from flask_jwt_extended import jwt_required, get_jwt_identity
import uuid

bp = Blueprint('payments', __name__, url_prefix='/api/payments')

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
