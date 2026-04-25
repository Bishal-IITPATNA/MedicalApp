from flask import Blueprint, request, jsonify
from app import db
from app.models.user import Patient, MedicalStore, LabStore
from app.models.appointment import Appointment
from app.models.medicine import MedicineOrder, MedicineOrderItem, Prescription, Medicine, MedicineBill
from app.models.lab import LabTestOrder, LabReport, LabTestBill, LabTest, LabTestOrderItem
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity

from datetime import datetime
import json
import random
import string
import random

bp = Blueprint('patient', __name__, url_prefix='/api/patient')

def paginate_query(query, page=1, per_page=20):
    """Helper function to paginate query results"""
    try:
        page = int(request.args.get('page', page))
        per_page = int(request.args.get('per_page', per_page))
        per_page = min(per_page, 100)  # Max 100 items per page
    except (ValueError, TypeError):
        page = 1
        per_page = 20
    
    paginated = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return {
        'items': paginated.items,
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
    """Get or update patient profile"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    if request.method == 'GET':
        return jsonify(patient.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            patient.name = data['name']
        if 'phone' in data:
            patient.phone = data['phone']
        if 'address' in data:
            patient.address = data['address']
        if 'city' in data:
            patient.city = data['city']
        if 'state' in data:
            patient.state = data['state']
        if 'pincode' in data:
            patient.pincode = data['pincode']
        if 'gender' in data:
            patient.gender = data['gender']
        if 'blood_group' in data:
            patient.blood_group = data['blood_group']
        if 'date_of_birth' in data:
            try:
                # Parse date from string (format: YYYY-MM-DD)
                patient.date_of_birth = datetime.strptime(data['date_of_birth'], '%Y-%m-%d').date()
            except ValueError:
                return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully',
            'profile': patient.to_dict()
        }), 200

@bp.route('/appointments', methods=['GET'])
@jwt_required()
def get_appointments():
    """Get patient appointments with pagination"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    query = Appointment.query.filter_by(patient_id=patient.id).order_by(Appointment.appointment_date.desc())
    
    # Paginate
    result = paginate_query(query, per_page=10)
    
    return jsonify({
        'success': True,
        'appointments': [apt.to_dict() for apt in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/prescriptions', methods=['GET'])
@jwt_required()
def get_prescriptions():
    """Get patient prescriptions with pagination"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    query = Prescription.query.filter_by(patient_id=patient.id).order_by(Prescription.prescription_date.desc())
    
    # Paginate
    result = paginate_query(query, per_page=10)
    
    return jsonify({
        'prescriptions': [p.to_dict() for p in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/prescriptions/<int:appointment_id>/medicines', methods=['GET'])
@jwt_required()
def get_prescribed_medicines(appointment_id):
    """Get medicines prescribed in a specific appointment"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    # Verify the appointment belongs to this patient
    appointment = Appointment.query.filter_by(id=appointment_id, patient_id=patient.id).first()
    if not appointment:
        return jsonify({'error': 'Appointment not found or does not belong to this patient'}), 404
    
    # Only allow access to prescriptions for confirmed and completed appointments
    if appointment.status not in ['confirmed', 'completed']:
        return jsonify({
            'error': 'Prescription is only available for confirmed or completed appointments',
            'appointment_status': appointment.status,
            'appointment_id': appointment_id
        }), 400
    
    # Get prescription for this appointment
    prescription = Prescription.query.filter_by(appointment_id=appointment_id, patient_id=patient.id).first()
    
    if not prescription:
        return jsonify({
            'success': True,
            'data': {
                'appointment_id': appointment_id,
                'prescription': None,
                'medicines': [],
                'message': 'No prescription found for this appointment'
            }
        }), 200
    
    # Parse medicines from prescription (stored as JSON string)
    prescribed_medicines = []
    try:
        if prescription.medicines:
            medicines_data = json.loads(prescription.medicines)
            if isinstance(medicines_data, list):
                prescribed_medicines = medicines_data
            else:
                # Handle single medicine or different format
                prescribed_medicines = [medicines_data]
    except (json.JSONDecodeError, TypeError):
        # If medicines is not valid JSON, treat as plain text
        prescribed_medicines = []
    
    # Get detailed information about each prescribed medicine
    detailed_medicines = []
    for med in prescribed_medicines:
        if isinstance(med, dict):
            # If medicine data includes medicine_id, get full details
            if 'medicine_id' in med:
                medicine = Medicine.query.get(med['medicine_id'])
                if medicine:
                    med_dict = medicine.to_dict()
                    # Extract quantity from dosage if possible, otherwise default to 1
                    dosage = med.get('dosage', '')
                    quantity = 1  # default
                    if dosage:
                        # Try to extract number from dosage like "1 tablet", "2 tablet"
                        import re
                        match = re.search(r'(\d+)', dosage)
                        if match:
                            quantity = int(match.group(1))
                    
                    med_dict.update({
                        'prescribed_quantity': med.get('quantity', quantity),
                        'prescribed_dosage': dosage,
                        'prescribed_frequency': med.get('frequency', ''),
                        'prescribed_duration': med.get('duration', '')
                    })
                    detailed_medicines.append(med_dict)
            elif 'name' in med:
                # If only name is provided, search by name
                medicine = Medicine.query.filter(Medicine.name.ilike(f"%{med['name']}%")).first()
                if medicine:
                    med_dict = medicine.to_dict()
                    # Extract quantity from dosage if possible, otherwise default to 1
                    dosage = med.get('dosage', '')
                    quantity = 1  # default
                    if dosage:
                        # Try to extract number from dosage like "1 tablet", "2 tablet"
                        import re
                        match = re.search(r'(\d+)', dosage)
                        if match:
                            quantity = int(match.group(1))
                    
                    med_dict.update({
                        'prescribed_quantity': med.get('quantity', quantity),
                        'prescribed_dosage': dosage,
                        'prescribed_frequency': med.get('frequency', ''),
                        'prescribed_duration': med.get('duration', '')
                    })
                    detailed_medicines.append(med_dict)
                else:
                    # Medicine not found in database
                    # Extract quantity from dosage if possible, otherwise default to 1
                    dosage = med.get('dosage', '')
                    quantity = 1  # default
                    if dosage:
                        # Try to extract number from dosage like "1 tablet", "2 tablet"
                        import re
                        match = re.search(r'(\d+)', dosage)
                        if match:
                            quantity = int(match.group(1))
                    
                    detailed_medicines.append({
                        'name': med.get('name', 'Unknown'),
                        'prescribed_quantity': med.get('quantity', quantity),
                        'prescribed_dosage': dosage,
                        'prescribed_frequency': med.get('frequency', ''),
                        'prescribed_duration': med.get('duration', ''),
                        'available': False,
                        'message': 'Medicine not available in our catalog'
                    })
        elif isinstance(med, str):
            # If medicine is just a string (medicine name)
            medicine = Medicine.query.filter(Medicine.name.ilike(f"%{med}%")).first()
            if medicine:
                med_dict = medicine.to_dict()
                med_dict.update({
                    'prescribed_quantity': 1,  # default for string medicine names
                    'prescribed_dosage': '',
                    'prescribed_frequency': '',
                    'prescribed_duration': ''
                })
                detailed_medicines.append(med_dict)
            else:
                detailed_medicines.append({
                    'name': med,
                    'prescribed_quantity': 1,
                    'available': False,
                    'message': 'Medicine not available in our catalog'
                })
    
    return jsonify({
        'success': True,
        'data': {
            'appointment_id': appointment_id,
            'prescription': prescription.to_dict(),
            'medicines': detailed_medicines,
            'instructions': prescription.instructions
        }
    }), 200

@bp.route('/medicine-orders', methods=['GET', 'POST'])
@jwt_required()
def medicine_orders():
    """Get patient medicine orders or create new order"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    if request.method == 'GET':
        query = MedicineOrder.query.filter_by(patient_id=patient.id).order_by(MedicineOrder.order_date.desc())
        
        # Paginate
        result = paginate_query(query, per_page=10)
        
        # Add bill information to each order
        orders_with_bills = []
        for order in result['items']:
            order_dict = order.to_dict()
            # Check if bill exists for this order
            from app.models.medicine import MedicineBill
            bill = MedicineBill.query.filter_by(order_id=order.id).first()
            order_dict['bill'] = bill.to_dict() if bill else None
            orders_with_bills.append(order_dict)
        
        return jsonify({
            'orders': orders_with_bills,
            'total': result['total'],
            'page': result['page'],
            'per_page': result['per_page'],
            'pages': result['pages'],
            'has_next': result['has_next'],
            'has_prev': result['has_prev']
        }), 200
    
    # POST - Create new medicine order
    data = request.get_json()
    
    # Validate required fields
    if not data.get('items') or len(data['items']) == 0:
        return jsonify({'error': 'Order must contain at least one item'}), 400
    
    try:
        # Calculate total amount
        total_amount = sum(item.get('price', 0) * item.get('quantity', 0) for item in data['items'])
        
        # Get selected store or use automatic routing
        selected_store_id = data.get('store_id')
        delivery_type = data.get('delivery_type', 'pickup')  # pickup or home_delivery
        delivery_address = data.get('delivery_address')
        
        if selected_store_id:
            # Patient selected a specific store
            selected_store = MedicalStore.query.get(selected_store_id)
            if not selected_store:
                return jsonify({'error': 'Selected medical store not found'}), 404
            
            # Create the medicine order with selected store
            # Generate OTP for all orders (both pickup and home delivery)
            delivery_otp = ''.join(random.choices(string.digits, k=6))
            
            order = MedicineOrder(
                patient_id=patient.id,
                store_id=selected_store.id,
                total_amount=total_amount,
                status='confirmed',
                delivery_type=delivery_type,
                delivery_address=delivery_address,
                delivery_otp=delivery_otp,
                otp_verified=False
            )
            
            db.session.add(order)
            db.session.flush()
            
            # Create order items and link to actual medicines
            for item_data in data['items']:
                medicine_name = item_data.get('medicine_name', '')
                quantity = item_data.get('quantity', 0)
                price = item_data.get('price', 0)
                
                # Find the medicine in the selected store
                from sqlalchemy import func
                medicine = Medicine.query.filter(
                    Medicine.store_id == selected_store.id,
                    func.lower(Medicine.name) == func.lower(medicine_name)
                ).first()
                
                order_item = MedicineOrderItem(
                    order_id=order.id,
                    medicine_id=medicine.id if medicine else None,
                    medicine_name=medicine_name,
                    quantity=quantity,
                    price=price
                )
                db.session.add(order_item)
            
            # Notify the selected store
            notification = Notification(
                user_id=selected_store.user_id,
                patient_id=patient.id,
                title='New Medicine Order',
                message=f'New {delivery_type.replace("_", " ")} order #{order.id} from {patient.name}. Total: ₹{total_amount:.2f}. Verify OTP before {"dispatch" if delivery_type == "home_delivery" else "handing over"}.',
                notification_type='medicine_order',
                related_id=order.id
            )
            db.session.add(notification)
            
            # Notify patient with OTP
            if delivery_type == 'home_delivery':
                otp_message = f'Your order #{order.id} OTP: {delivery_otp}. Share this with the medical store for delivery verification.'
            else:
                otp_message = f'Your order #{order.id} OTP: {delivery_otp}. Show this when collecting your order from the store.'
            
            patient_notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Order Confirmation',
                message=otp_message,
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(patient_notification)
            
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': 'Order placed successfully',
                'order': order.to_dict(),
                'otp': delivery_otp
            }), 201
        else:
            # Automatic routing
            if delivery_type == 'home_delivery':
                # Home delivery orders go to admin
                from app.models.user import User
                admin_user = User.query.filter_by(role='admin').first()
                
                if not admin_user:
                    return jsonify({'error': 'Admin not found'}), 400
                
                # Generate OTP for home delivery
                delivery_otp = ''.join(random.choices(string.digits, k=6))
                # Create the medicine order for admin to handle
                order = MedicineOrder(
                    patient_id=patient.id,
                    total_amount=total_amount,
                    status='pending',
                    delivery_type=delivery_type,
                    delivery_address=delivery_address or patient.address,
                    delivery_otp=delivery_otp,
                    otp_verified=False
                )
                db.session.add(order)
                db.session.flush()
                # Create order items (without medicine_id or store_id)
                for item_data in data['items']:
                    order_item = MedicineOrderItem(
                        order_id=order.id,
                        medicine_name=item_data.get('medicine_name', ''),
                        quantity=item_data.get('quantity', 0),
                        price=item_data.get('price', 0)
                    )
                    db.session.add(order_item)
                # Create notification for admin
                notification = Notification(
                    user_id=admin_user.id,
                    patient_id=patient.id,
                    title='New Home Delivery Order',
                    message=f'New home delivery order #{order.id} from {patient.name}. Total: ₹{total_amount:.2f}. Please assign to a medical store.',
                    notification_type='medicine_order',
                    related_id=order.id
                )
                db.session.add(notification)
                # Notify patient with OTP
                otp_message = f'Your home delivery order #{order.id} OTP: {delivery_otp}. Share this with the medical store for delivery verification.'
                patient_notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Order Confirmation',
                    message=otp_message,
                    notification_type='order_update',
                    related_id=order.id
                )
                db.session.add(patient_notification)
                db.session.commit()
                return jsonify({
                    'success': True,
                    'message': 'Order placed successfully.',
                    'order': order.to_dict(),
                    'otp': delivery_otp
                }), 201
            else:
                # Pickup orders - get first store alphabetically
                first_store = MedicalStore.query.order_by(MedicalStore.name).first()
                
                if not first_store:
                    return jsonify({'error': 'No medical stores available'}), 400
                
                # Create the medicine order with automatic routing
                order = MedicineOrder(
                    patient_id=patient.id,
                    total_amount=total_amount,
                    status='pending',
                    current_store_id=first_store.id,
                    offered_to_stores=json.dumps([first_store.id]),
                    current_offer_time=datetime.utcnow(),
                    timeout_minutes=5,
                    delivery_type=delivery_type,
                    delivery_address=delivery_address
                )
                
                db.session.add(order)
                db.session.flush()
                
                # Create order items (without medicine_id for automatic routing)
                for item_data in data['items']:
                    order_item = MedicineOrderItem(
                        order_id=order.id,
                        medicine_name=item_data.get('medicine_name', ''),
                        quantity=item_data.get('quantity', 0),
                        price=item_data.get('price', 0)
                    )
                    db.session.add(order_item)
                
                # Create notification for the first medical store
                notification = Notification(
                    user_id=first_store.user_id,
                    patient_id=patient.id,
                    title='New Medicine Order',
                    message=f'New pickup order #{order.id} from {patient.name}. Total: ₹{total_amount:.2f}. Please respond within 5 minutes.',
                    notification_type='medicine_order',
                    related_id=order.id
                )
                db.session.add(notification)
                
                db.session.commit()
                
                return jsonify({
                    'success': True,
                    'message': 'Order placed successfully',
                    'order': order.to_dict()
                }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/check-medicine-availability', methods=['POST'])
@jwt_required()
def check_medicine_availability():
    """Check which medical stores have all the requested medicines in stock"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    data = request.get_json()
    items = data.get('items', [])
    
    print(f"DEBUG: Checking availability for items: {items}")
    
    if not items:
        return jsonify({'error': 'No items provided'}), 400
    
    from app.models.medicine import Medicine
    from sqlalchemy import and_
    
    # Get all medical stores
    all_stores = MedicalStore.query.all()
    available_stores = []
    
    print(f"DEBUG: Total stores found: {len(all_stores)}")
    
    for store in all_stores:
        has_all_medicines = True
        store_medicines = []
        
        print(f"DEBUG: Checking store: {store.name} (ID: {store.id})")
        
        for item in items:
            medicine_name = item.get('medicine_name', '')
            required_quantity = item.get('quantity', 0)
            
            print(f"DEBUG: Looking for '{medicine_name}' (qty: {required_quantity}) in store {store.name}")
            
            # Find medicine in this store by case-insensitive exact name match
            # Using func.lower for case-insensitive comparison that works across databases
            from sqlalchemy import func
            medicine = Medicine.query.filter(
                and_(
                    Medicine.store_id == store.id,
                    func.lower(Medicine.name) == func.lower(medicine_name),
                    Medicine.stock_quantity >= required_quantity,
                    Medicine.is_available == True
                )
            ).first()
            
            print(f"DEBUG: Found medicine: {medicine.name if medicine else 'None'}")
            
            if medicine:
                store_medicines.append({
                    'name': medicine.name,
                    'available_quantity': medicine.stock_quantity,
                    'price': medicine.price
                })
            else:
                has_all_medicines = False
                break
        
        if has_all_medicines:
            print(f"DEBUG: Store {store.name} has all medicines, adding to available_stores")
            available_stores.append({
                'id': store.id,
                'name': store.name,
                'address': store.address,
                'city': store.city,
                'state': store.state,
                'phone': store.phone,
                'medicines': store_medicines
            })
        else:
            print(f"DEBUG: Store {store.name} does NOT have all medicines")
    
    print(f"DEBUG: Total available stores: {len(available_stores)}")
    
    # If no stores have all medicines available, offer home delivery option
    home_delivery_available = False
    unavailable_medicines = []
    
    if len(available_stores) == 0:
        print("DEBUG: No stores have all medicines, checking for home delivery option")
        home_delivery_available = True
        
        # Collect information about unavailable medicines for home delivery
        for item in items:
            medicine_name = item.get('medicine_name', '')
            required_quantity = item.get('quantity', 0)
            
            # Find any store that has this medicine (even if not all medicines)
            available_medicine = Medicine.query.filter(
                and_(
                    func.lower(Medicine.name) == func.lower(medicine_name),
                    Medicine.stock_quantity >= required_quantity,
                    Medicine.is_available == True
                )
            ).first()
            
            if available_medicine:
                unavailable_medicines.append({
                    'name': medicine_name,
                    'required_quantity': required_quantity,
                    'estimated_price': available_medicine.price,
                    'available_for_delivery': True
                })
            else:
                unavailable_medicines.append({
                    'name': medicine_name,
                    'required_quantity': required_quantity,
                    'estimated_price': 0,
                    'available_for_delivery': False,
                    'note': 'This medicine may need to be ordered specially'
                })
    
    print(f"DEBUG: Returning response with home_delivery_available: {home_delivery_available}")
    
    response = {
        'success': True,
        'available_stores': available_stores,
        'home_delivery_available': home_delivery_available
    }
    
    if home_delivery_available:
        response['home_delivery'] = {
            'available': True,
            'message': 'Medicines not available in nearby stores. We can deliver to your home.',
            'delivery_fee': 50.0,
            'estimated_delivery_time': '24-48 hours',
            'medicines': unavailable_medicines,
            'note': 'Admin will source medicines and arrange delivery to your address'
        }
    
    return jsonify(response), 200

@bp.route('/lab-orders', methods=['GET'])
@jwt_required()
def get_lab_orders():
    """Get patient lab test orders with pagination"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    query = LabTestOrder.query.filter_by(patient_id=patient.id).order_by(LabTestOrder.order_date.desc())
    
    # Paginate
    result = paginate_query(query, per_page=10)
    
    # Add bill information to each order
    from app.models.lab import LabTestBill
    orders_with_bills = []
    for order in result['items']:
        order_dict = order.to_dict()
        # Check if bill exists for this order
        bill = LabTestBill.query.filter_by(order_id=order.id).first()
        order_dict['bill'] = bill.to_dict() if bill else None
        orders_with_bills.append(order_dict)
    
    return jsonify({
        'orders': orders_with_bills,
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/lab-reports', methods=['GET'])
@jwt_required()
def get_lab_reports():
    """Get patient lab reports"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    reports = LabReport.query.filter_by(patient_id=patient.id).all()
    
    return jsonify({
        'reports': [report.to_dict() for report in reports]
    }), 200

@bp.route('/bills', methods=['GET'])
@jwt_required()
def get_bills():
    """Get all medicine bills for the patient (paginated)"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    query = MedicineBill.query.filter_by(patient_id=patient.id).order_by(MedicineBill.bill_date.desc())
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
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    bill = MedicineBill.query.filter_by(id=bill_id, patient_id=patient.id).first()
    
    if not bill:
        return jsonify({'error': 'Bill not found'}), 404
    
    return jsonify(bill.to_dict()), 200

@bp.route('/lab-bills', methods=['GET'])
@jwt_required()
def get_lab_bills():
    """Get all lab test bills for the patient (paginated)"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    query = LabTestBill.query.filter_by(patient_id=patient.id).order_by(LabTestBill.bill_date.desc())
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

@bp.route('/lab-bills/<int:bill_id>', methods=['GET'])
@jwt_required()
def get_lab_bill_detail(bill_id):
    """Get detailed lab test bill information"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    bill = LabTestBill.query.filter_by(id=bill_id, patient_id=patient.id).first()
    
    if not bill:
        return jsonify({'error': 'Bill not found'}), 404
    
    return jsonify(bill.to_dict()), 200

# Lab Test Endpoints

@bp.route('/lab-tests/search', methods=['GET'])
@jwt_required()
def search_lab_tests():
    """Search for available lab tests"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    # Get search parameters
    test_name = request.args.get('test_name', '').strip()
    category = request.args.get('category', '').strip()
    lab_id = request.args.get('lab_id')
    
    # Base query
    query = db.session.query(LabTest, LabStore).join(LabStore, LabTest.lab_id == LabStore.id).filter(
        LabTest.is_available == True
    )
    
    # Apply filters
    if test_name:
        query = query.filter(LabTest.name.ilike(f'%{test_name}%'))
    
    if category:
        query = query.filter(LabTest.category.ilike(f'%{category}%'))
    
    if lab_id:
        try:
            lab_id = int(lab_id)
            query = query.filter(LabTest.lab_id == lab_id)
        except ValueError:
            pass
    
    results = query.all()
    
    # Format response with lab details
    tests_with_labs = []
    for test, lab in results:
        test_dict = test.to_dict()
        test_dict['lab_info'] = {
            'id': lab.id,
            'name': lab.name,
            'address': lab.address,
            'city': lab.city,
            'state': lab.state,
            'pincode': lab.pincode,
            'phone': lab.phone
        }
        tests_with_labs.append(test_dict)
    
    return jsonify({
        'success': True,
        'tests': tests_with_labs,
        'total': len(tests_with_labs)
    }), 200

@bp.route('/lab-tests/book', methods=['POST'])
@jwt_required()
def book_lab_test():
    """Book lab tests"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['lab_id', 'test_ids', 'test_date']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    try:
        # Validate lab exists
        lab = LabStore.query.get(data['lab_id'])
        if not lab:
            return jsonify({'error': 'Lab not found'}), 404
        
        # Validate tests
        test_ids = data['test_ids']
        if not isinstance(test_ids, list) or len(test_ids) == 0:
            return jsonify({'error': 'test_ids must be a non-empty array'}), 400
        
        tests = LabTest.query.filter(
            LabTest.id.in_(test_ids),
            LabTest.lab_id == data['lab_id'],
            LabTest.is_available == True
        ).all()
        
        if len(tests) != len(test_ids):
            return jsonify({'error': 'One or more tests not found or unavailable'}), 404
        
        # Calculate total amount
        test_total = sum(test.price for test in tests)
        
        # Generate OTP for order verification
        otp = str(random.randint(100000, 999999))
        
        # Create order
        order = LabTestOrder(
            patient_id=patient.id,
            lab_id=data['lab_id'],
            test_date=datetime.strptime(data['test_date'], '%Y-%m-%d').date(),
            test_time=datetime.strptime(data.get('test_time', '09:00'), '%H:%M').time() if data.get('test_time') else None,
            collection_address=data.get('collection_address'),
            collection_otp=otp,
            total_amount=test_total,
            notes=data.get('notes', '')
        )
        
        db.session.add(order)
        db.session.flush()  # Get order ID
        
        # Create order items
        for test in tests:
            item = LabTestOrderItem(
                order_id=order.id,
                test_id=test.id,
                price=test.price
            )
            db.session.add(item)
        
        # Create notification for patient
        test_names = [test.name for test in tests]
        lab_details = f"Lab: {lab.name}\nAddress: {lab.address}, {lab.city}, {lab.state} - {lab.pincode}\nPhone: {lab.phone}"
        
        notification = Notification(
            user_id=patient.user_id,
            patient_id=patient.id,
            title='Lab Test Booking Confirmed',
            message=f'Your lab test booking (Order #{order.id}) has been confirmed.\n\nTests: {", ".join(test_names)}\n{lab_details}\n\nCollection OTP: {otp}\nPlease share this OTP with the lab technician during sample collection.',
            notification_type='lab_booking',
            related_id=order.id,
            related_type='lab_order'
        )
        db.session.add(notification)
        
        # Create notification for lab store
        lab_notification = Notification(
            user_id=lab.user_id,
            title='New Lab Test Booking',
            message=f'New lab test booking received (Order #{order.id})\n\nPatient: {patient.user.email}\nTests: {", ".join(test_names)}\nTest Date: {data["test_date"]}\nOTP: {otp}\n\nTotal Amount: ₹{test_total}',
            notification_type='new_lab_order',
            related_id=order.id,
            related_type='lab_order'
        )
        db.session.add(lab_notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Lab tests booked successfully',
            'order_id': order.id,
            'total_amount': test_total,
            'otp': otp,
            'lab_name': lab.name
        }), 201
        
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {str(e)}'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to book lab tests: {str(e)}'}), 500

@bp.route('/lab-stores', methods=['GET'])
@jwt_required()
def get_lab_stores():
    """Get available lab stores"""
    current_user_id = get_jwt_identity()
    patient = Patient.query.filter_by(user_id=current_user_id).first()
    
    if not patient:
        return jsonify({'error': 'Patient profile not found'}), 404
    
    labs = LabStore.query.all()
    
    return jsonify({
        'success': True,
        'labs': [lab.to_dict() for lab in labs]
    }), 200
