from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Patient, Doctor
from app.models.lab import LabTest, LabTestOrder, LabTestOrderItem
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

bp = Blueprint('doctor_lab_tests', __name__, url_prefix='/api/doctor/lab-tests')

@bp.route('/recommend', methods=['POST'])
@jwt_required()
def recommend_lab_tests():
    """Recommend lab tests to a patient (doctor only)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user is a doctor
        doctor = Doctor.query.filter_by(user_id=current_user_id).first()
        
        if not doctor:
            return jsonify({'error': 'Only doctors can recommend lab tests'}), 403
        
        data = request.get_json()
        
        patient_id = data.get('patient_id')
        test_ids = data.get('test_ids', [])  # List of test IDs
        lab_id = data.get('lab_id')
        notes = data.get('notes', '')
        
        if not patient_id or not test_ids or not lab_id:
            return jsonify({'error': 'Patient ID, test IDs, and lab ID are required'}), 400
        
        # Verify patient exists
        patient = Patient.query.get(patient_id)
        if not patient:
            return jsonify({'error': 'Patient not found'}), 404
        
        # Create lab test order
        order = LabTestOrder(
            patient_id=patient_id,
            lab_id=lab_id,
            status='recommended',  # Special status for doctor recommendations
            notes=f'Recommended by Dr. {doctor.name}. {notes}'
        )
        
        db.session.add(order)
        db.session.flush()  # Get order ID
        
        # Add test items and calculate total
        total_amount = 0.0
        test_names = []
        
        for test_id in test_ids:
            test = LabTest.query.get(test_id)
            if test:
                order_item = LabTestOrderItem(
                    order_id=order.id,
                    test_id=test_id,
                    price=test.price
                )
                db.session.add(order_item)
                total_amount += test.price
                test_names.append(test.name)
        
        order.total_amount = total_amount
        db.session.commit()
        
        # Create notification for patient
        test_list = ', '.join(test_names[:3])
        if len(test_names) > 3:
            test_list += f' and {len(test_names) - 3} more'
        
        notification = Notification(
            user_id=patient.user_id,
            patient_id=patient.id,
            title='Lab Tests Recommended',
            message=f'Dr. {doctor.name} has recommended lab tests for you: {test_list}',
            notification_type='lab_test',
            related_id=order.id,
            related_type='lab_order'
        )
        
        db.session.add(notification)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Lab tests recommended successfully',
            'order': order.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to recommend lab tests: {str(e)}'}), 500

@bp.route('/available', methods=['GET'])
@jwt_required()
def get_available_tests():
    """Get all available lab tests"""
    try:
        lab_id = request.args.get('lab_id')
        
        if lab_id:
            tests = LabTest.query.filter_by(lab_id=lab_id, is_available=True).all()
        else:
            tests = LabTest.query.filter_by(is_available=True).all()
        
        return jsonify({
            'success': True,
            'tests': [test.to_dict() for test in tests]
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to fetch lab tests: {str(e)}'}), 500
