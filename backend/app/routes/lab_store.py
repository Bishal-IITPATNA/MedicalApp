from flask import Blueprint, request, jsonify
from app import db
from app.models.user import LabStore, Patient
from app.models.lab import LabTest, LabTestOrder, LabTestOrderItem, LabReport, LabTestBill, LabTestBillItem
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func
import random
from datetime import datetime

bp = Blueprint('lab_store', __name__, url_prefix='/api/lab-store')

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
    """Get or update lab store profile"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    if request.method == 'GET':
        return jsonify(lab.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            lab.name = data['name']
        if 'phone' in data:
            lab.phone = data['phone']
        if 'address' in data:
            lab.address = data['address']
        if 'city' in data:
            lab.city = data['city']
        if 'state' in data:
            lab.state = data['state']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Profile updated successfully',
            'profile': lab.to_dict()
        }), 200

@bp.route('/tests', methods=['GET', 'POST'])
@jwt_required()
def tests():
    """Get all lab tests or add new test"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    if request.method == 'GET':
        query = LabTest.query.filter_by(lab_id=lab.id).order_by(LabTest.id.desc())
        result = paginate_query(query, page=1, per_page=50)
        
        return jsonify({
            'tests': result['items'],
            'total': result['total'],
            'page': result['page'],
            'per_page': result['per_page'],
            'pages': result['pages'],
            'has_next': result['has_next'],
            'has_prev': result['has_prev']
        }), 200
    
    elif request.method == 'POST':
        data = request.get_json()
        
        lab_test = LabTest(
            lab_id=lab.id,
            name=data['name'],
            description=data.get('description'),
            price=data['price'],
            category=data.get('category'),
            preparation_required=data.get('preparation_required'),
            sample_type=data.get('sample_type'),
            report_delivery_time=data.get('report_delivery_time')
        )
        
        db.session.add(lab_test)
        db.session.commit()
        
        return jsonify({
            'message': 'Lab test added successfully',
            'test': lab_test.to_dict()
        }), 201

@bp.route('/tests/<int:test_id>', methods=['GET', 'PUT', 'DELETE'])
@jwt_required()
def test_detail(test_id):
    """Get, update, or delete a lab test"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    lab_test = LabTest.query.filter_by(id=test_id, lab_id=lab.id).first()
    
    if not lab_test:
        return jsonify({'error': 'Lab test not found'}), 404
    
    if request.method == 'GET':
        return jsonify(lab_test.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        if 'name' in data:
            lab_test.name = data['name']
        if 'description' in data:
            lab_test.description = data['description']
        if 'price' in data:
            lab_test.price = data['price']
        if 'is_available' in data:
            lab_test.is_available = data['is_available']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Lab test updated successfully',
            'test': lab_test.to_dict()
        }), 200
    
    elif request.method == 'DELETE':
        db.session.delete(lab_test)
        db.session.commit()
        
        return jsonify({
            'message': 'Lab test deleted successfully'
        }), 200

@bp.route('/orders', methods=['GET'])
@jwt_required()
def get_orders():
    """Get all lab test orders (paginated)"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    query = LabTestOrder.query.filter_by(lab_id=lab.id).order_by(LabTestOrder.order_date.desc())
    
    # Get the paginated results but work with model objects
    try:
        page = int(request.args.get('page', 1))
        per_page = min(int(request.args.get('per_page', 10)), 100)
    except (ValueError, TypeError):
        page = 1
        per_page = 10
    
    if page < 1:
        page = 1
    if per_page < 1:
        per_page = 10
    
    paginated = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Add bill information to each order
    from app.models.lab import LabTestBill
    orders_with_bills = []
    for order in paginated.items:
        order_dict = order.to_dict()
        # Check if bill exists for this order
        bill = LabTestBill.query.filter_by(order_id=order.id).first()
        order_dict['bill'] = bill.to_dict() if bill else None
        orders_with_bills.append(order_dict)
    
    return jsonify({
        'orders': orders_with_bills,
        'total': paginated.total,
        'page': paginated.page,
        'per_page': paginated.per_page,
        'pages': paginated.pages,
        'has_next': paginated.has_next,
        'has_prev': paginated.has_prev
    }), 200

@bp.route('/orders/<int:order_id>', methods=['PUT'])
@jwt_required()
def update_order(order_id):
    """Accept, decline, or update order status"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    order = LabTestOrder.query.filter_by(id=order_id, lab_id=lab.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    data = request.get_json()
    
    if 'status' in data:
        new_status = data['status']
        order.status = new_status
        
        # Generate OTP when order is accepted
        if new_status == 'accepted' and not order.collection_otp:
            order.collection_otp = ''.join([str(random.randint(0, 9)) for _ in range(6)])
            
            # Notify patient with OTP
            patient = Patient.query.get(order.patient_id)
            if patient:
                notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Lab Test Order Accepted',
                    message=f'Your lab test order #{order.id} has been accepted by {lab.name}. Collection OTP: {order.collection_otp}',
                    notification_type='lab_order_update',
                    related_id=order.id
                )
                db.session.add(notification)
    
    db.session.commit()
    
    return jsonify({
        'message': 'Order updated successfully',
        'order': order.to_dict()
    }), 200

@bp.route('/orders/<int:order_id>/verify-otp', methods=['POST'])
@jwt_required()
def verify_otp_and_collect_sample(order_id):
    """Verify OTP, collect sample, and generate bill"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    order = LabTestOrder.query.filter_by(id=order_id, lab_id=lab.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.otp_verified:
        return jsonify({'error': 'OTP already verified'}), 400
    
    data = request.get_json()
    entered_otp = data.get('otp', '')
    
    if entered_otp != order.collection_otp:
        return jsonify({'error': 'Invalid OTP'}), 400
    
    try:
        # Mark OTP as verified
        order.otp_verified = True
        order.status = 'sample_collected'
        
        # Generate bill
        patient = Patient.query.get(order.patient_id)
        if not patient:
            raise Exception('Patient not found')
        
        # Calculate bill amounts
        subtotal = order.total_amount
        tax_percentage = 5.0  # 5% GST
        tax_amount = round(subtotal * tax_percentage / 100, 2)
        discount = 0.0
        total_amount = round(subtotal + tax_amount - discount, 2)
        
        # Create bill
        bill = LabTestBill(
            bill_number=LabTestBill.generate_bill_number(),
            order_id=order.id,
            patient_id=patient.id,
            lab_id=lab.id,
            patient_name=patient.name,
            patient_phone=patient.phone,
            patient_address=patient.address or '',
            lab_name=lab.name,
            lab_address=lab.address or '',
            lab_phone=lab.phone or '',
            lab_registration=getattr(lab, 'registration_number', 'N/A'),
            subtotal=subtotal,
            tax_percentage=tax_percentage,
            tax_amount=tax_amount,
            discount=discount,
            total_amount=total_amount,
            payment_method=order.payment_status,
            payment_status='completed',
            collection_address=order.collection_address,
            test_date=order.test_date,
            test_time=order.test_time,
            notes=order.notes
        )
        db.session.add(bill)
        db.session.flush()  # Get bill.id
        
        # Create bill items
        for order_item in order.items:
            test = LabTest.query.get(order_item.test_id) if order_item.test_id else None
            bill_item = LabTestBillItem(
                bill_id=bill.id,
                test_id=order_item.test_id,
                test_name=test.name if test else 'Unknown Test',
                category=test.category if test else '',
                price=order_item.price
            )
            db.session.add(bill_item)
        
        # Notify patient
        if patient:
            message = f'Sample collected for order #{order.id} at {lab.name}. Bill #{bill.bill_number} generated.'
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Sample Collected - Bill Generated',
                message=message,
                notification_type='lab_order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Sample collected successfully. Bill generated.',
            'order': order.to_dict(),
            'bill': bill.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/reports', methods=['POST'])
@jwt_required()
def create_report():
    """Upload lab report for an order"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    data = request.get_json()
    
    order = LabTestOrder.query.filter_by(id=data['order_id'], lab_id=lab.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    report = LabReport(
        order_id=order.id,
        patient_id=order.patient_id,
        report_file_url=data.get('report_file_url'),
        findings=data.get('findings'),
        remarks=data.get('remarks')
    )
    
    db.session.add(report)
    
    # Update order status
    order.status = 'completed'
    
    db.session.commit()
    
    return jsonify({
        'message': 'Report uploaded successfully',
        'report': report.to_dict()
    }), 201

@bp.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard():
    """Get dashboard statistics"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    # Total tests done
    total_tests = db.session.query(func.count(LabTestOrderItem.id)).join(
        LabTestOrder
    ).filter(
        LabTestOrder.lab_id == lab.id,
        LabTestOrder.status == 'completed'
    ).scalar() or 0
    
    # Total patients served
    total_patients = db.session.query(func.count(func.distinct(LabTestOrder.patient_id))).filter(
        LabTestOrder.lab_id == lab.id,
        LabTestOrder.status == 'completed'
    ).scalar() or 0
    
    # Total revenue
    total_revenue = db.session.query(func.sum(LabTestOrder.total_amount)).filter(
        LabTestOrder.lab_id == lab.id,
        LabTestOrder.payment_status == 'completed'
    ).scalar() or 0
    
    return jsonify({
        'total_tests_done': total_tests,
        'total_patients_served': total_patients,
        'total_revenue': total_revenue
    }), 200

@bp.route('/bills', methods=['GET'])
@jwt_required()
def get_bills():
    """Get all bills for the lab store (paginated)"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    query = LabTestBill.query.filter_by(lab_id=lab.id).order_by(LabTestBill.bill_date.desc())
    result = paginate_query(query, page=1, per_page=20)
    
    return jsonify({
        'bills': result['items'],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/bills/<int:bill_id>', methods=['GET'])
@jwt_required()
def get_bill_detail(bill_id):
    """Get detailed bill information"""
    current_user_id = get_jwt_identity()
    lab = LabStore.query.filter_by(user_id=current_user_id).first()
    
    if not lab:
        return jsonify({'error': 'Lab store profile not found'}), 404
    
    bill = LabTestBill.query.filter_by(id=bill_id, lab_id=lab.id).first()
    
    if not bill:
        return jsonify({'error': 'Bill not found'}), 404
    
    return jsonify(bill.to_dict()), 200

@bp.route('/search', methods=['GET'])
def search_tests():
    """Search lab tests across all labs (paginated)"""
    query = LabTest.query.filter_by(is_available=True)
    
    # Filter by name
    if request.args.get('name'):
        query = query.filter(LabTest.name.ilike(f"%{request.args.get('name')}%"))
    
    # Filter by category
    if request.args.get('category'):
        query = query.filter(LabTest.category.ilike(f"%{request.args.get('category')}%"))
    
    # Filter by city
    if request.args.get('city'):
        query = query.join(LabStore).filter(LabStore.city.ilike(f"%{request.args.get('city')}%"))
    
    query = query.order_by(LabTest.id.desc())
    result = paginate_query(query, page=1, per_page=50)
    
    return jsonify({
        'tests': result['items'],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200
