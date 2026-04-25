from flask import Blueprint, request, jsonify
from app import db
from app.models.user import User, Patient, Doctor, Nurse, MedicalStore, LabStore
from app.models.appointment import Appointment
from app.models.medicine import MedicineOrder, MedicineOrderItem, Medicine, MedicineStoreOrder, MedicineStoreOrderItem
from app.models.lab import LabTestOrder
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func
import random
import string

bp = Blueprint('admin', __name__, url_prefix='/api/admin')

def check_admin(user_id):
    """Check if user is admin"""
    user = User.query.get(user_id)
    return user and user.role == 'admin'

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

@bp.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard():
    """Get high-level dashboard statistics"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    # Get statistics
    total_patients = Patient.query.count()
    total_doctors = Doctor.query.count()
    total_nurses = Nurse.query.count()
    total_medical_stores = MedicalStore.query.count()
    total_lab_stores = LabStore.query.count()
    total_appointments = Appointment.query.count()
    total_medicine_orders = MedicineOrder.query.count()
    total_lab_orders = LabTestOrder.query.count()
    
    # Count pending store orders
    total_pending_store_orders = MedicineStoreOrder.query.filter_by(status='pending').count()
    
    return jsonify({
        'total_patients': total_patients,
        'total_doctors': total_doctors,
        'total_nurses': total_nurses,
        'total_medical_stores': total_medical_stores,
        'total_lab_stores': total_lab_stores,
        'total_appointments': total_appointments,
        'total_medicine_orders': total_medicine_orders,
        'total_lab_orders': total_lab_orders,
        'total_pending_store_orders': total_pending_store_orders
    }), 200

@bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    """Get all users with filters and pagination"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    query = User.query
    
    # Filter by role
    if request.args.get('role'):
        query = query.filter_by(role=request.args.get('role'))
    
    # Order by created_at desc
    query = query.order_by(User.created_at.desc())
    
    # Paginate
    result = paginate_query(query)
    
    return jsonify({
        'users': [user.to_dict() for user in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/patients', methods=['GET'])
@jwt_required()
def get_patients():
    """Get all patients with filters and pagination"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    query = Patient.query
    
    # Filter by city
    if request.args.get('city'):
        query = query.filter(Patient.city.ilike(f"%{request.args.get('city')}%"))
    
    # Filter by state
    if request.args.get('state'):
        query = query.filter(Patient.state.ilike(f"%{request.args.get('state')}%"))
    
    # Order by id desc
    query = query.order_by(Patient.id.desc())
    
    # Paginate
    result = paginate_query(query)
    
    return jsonify({
        'patients': [patient.to_dict() for patient in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/doctors', methods=['GET'])
@jwt_required()
def get_doctors():
    """Get all doctors with filters and pagination"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
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
    
    # Order by id desc
    query = query.order_by(Doctor.id.desc())
    
    # Paginate
    result = paginate_query(query)
    
    return jsonify({
        'doctors': [doctor.to_dict() for doctor in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/analytics', methods=['GET'])
@jwt_required()
def analytics():
    """Get detailed analytics"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    # Location-based statistics
    patients_by_city = db.session.query(
        Patient.city, func.count(Patient.id)
    ).group_by(Patient.city).all()
    
    doctors_by_city = db.session.query(
        Doctor.city, func.count(Doctor.id)
    ).group_by(Doctor.city).all()
    
    return jsonify({
        'patients_by_city': [{'city': city, 'count': count} for city, count in patients_by_city],
        'doctors_by_city': [{'city': city, 'count': count} for city, count in doctors_by_city]
    }), 200

@bp.route('/check-order-timeouts', methods=['POST'])
@jwt_required()
def check_timeouts():
    """Manually trigger order timeout check"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    from app.utils.order_timeout import check_order_timeouts
    
    try:
        timeout_count = check_order_timeouts()
        return jsonify({
            'success': True,
            'message': f'Processed {timeout_count} timed out orders'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/medicine-catalog', methods=['GET', 'POST'])
@jwt_required()
def admin_medicine_catalog():
    """Get or add medicines to admin catalog that stores can order"""
    current_user_id = get_jwt_identity()
    
    # GET is allowed for medical stores to view catalog, POST requires admin
    if request.method == 'POST' and not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    if request.method == 'GET':
        # Get all medicines from all stores for the admin catalog
        # Get search parameters
        search_name = request.args.get('name', '').strip()
        search_category = request.args.get('category', '').strip()
        
        # Query all medicines with optional filters
        query = Medicine.query.order_by(Medicine.name, Medicine.manufacturer)
        
        if search_name:
            query = query.filter(Medicine.name.ilike(f'%{search_name}%'))
        if search_category:
            query = query.filter(Medicine.category.ilike(f'%{search_category}%'))
        
        medicines = query.all()
        
        # Create enhanced catalog with aggregated information
        catalog = []
        for med in medicines:
            med_dict = med.to_dict()
            # Add store information for context
            store = MedicalStore.query.get(med.store_id) if med.store_id else None
            if store:
                med_dict['store_name'] = store.name
                med_dict['store_city'] = store.city
            catalog.append(med_dict)
        
        return jsonify({
            'success': True,
            'data': {
                'medicines': catalog,
                'total': len(catalog)
            }
        }), 200
    
    # POST - Add new medicine to catalog
    else:
        data = request.get_json()
        
        # Create medicine in the first available medical store (admin managed)
        # In production, you might want a dedicated admin store
        admin_store = MedicalStore.query.first()
        if not admin_store:
            return jsonify({'error': 'No medical store available for admin medicines'}), 400
        
        medicine = Medicine(
            store_id=admin_store.id,
            name=data.get('name'),
            manufacturer=data.get('manufacturer'),
            category=data.get('category'),
            description=data.get('description'),
            price=data.get('price', 0.0),
            stock_quantity=data.get('stock_quantity', 0),
            requires_prescription=data.get('requires_prescription', False),
            is_available=True
        )
        
        try:
            db.session.add(medicine)
            db.session.commit()
            return jsonify({
                'success': True,
                'message': 'Medicine added to catalog successfully',
                'medicine': medicine.to_dict()
            }), 201
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Failed to add medicine: {str(e)}'}), 500

@bp.route('/medicines/<int:medicine_id>', methods=['PUT', 'DELETE'])
@jwt_required()
def manage_medicine(medicine_id):
    """Edit or delete a medicine in the catalog (admin only)"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    medicine = Medicine.query.get(medicine_id)
    if not medicine:
        return jsonify({'error': 'Medicine not found'}), 404
    
    if request.method == 'PUT':
        data = request.get_json()
        
        # Update medicine details
        if 'name' in data:
            medicine.name = data['name']
        if 'manufacturer' in data:
            medicine.manufacturer = data['manufacturer']
        if 'category' in data:
            medicine.category = data['category']
        if 'description' in data:
            medicine.description = data['description']
        if 'price' in data:
            medicine.price = data['price']
        if 'stock_quantity' in data:
            medicine.stock_quantity = data['stock_quantity']
        if 'requires_prescription' in data:
            medicine.requires_prescription = data['requires_prescription']
        if 'is_available' in data:
            medicine.is_available = data['is_available']
        
        try:
            db.session.commit()
            return jsonify({
                'success': True,
                'message': 'Medicine updated successfully',
                'medicine': medicine.to_dict()
            }), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Failed to update medicine: {str(e)}'}), 500
    
    elif request.method == 'DELETE':
        try:
            db.session.delete(medicine)
            db.session.commit()
            return jsonify({
                'success': True,
                'message': 'Medicine deleted successfully'
            }), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Failed to delete medicine: {str(e)}'}), 500

@bp.route('/home-delivery-orders', methods=['GET'])
@jwt_required()
def get_home_delivery_orders():
    """Get all home delivery orders for admin to manage"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    # Get all home delivery orders (pending assignment and in-progress)
    orders = MedicineOrder.query.filter(
        MedicineOrder.delivery_type == 'home_delivery'
    ).order_by(MedicineOrder.order_date.desc()).all()
    
    # Categorize orders
    pending_orders = [o for o in orders if o.store_id is None and o.status == 'pending']
    assigned_orders = [o for o in orders if o.store_id is not None and o.status not in ['completed', 'cancelled']]
    completed_orders = [o for o in orders if o.status in ['completed', 'cancelled']]
    
    return jsonify({
        'success': True,
        'pending_orders': [order.to_dict() for order in pending_orders],
        'assigned_orders': [order.to_dict() for order in assigned_orders],
        'completed_orders': [order.to_dict() for order in completed_orders],
        'total': len(orders)
    }), 200

@bp.route('/assign-order/<int:order_id>', methods=['POST'])
@jwt_required()
def assign_order_to_store(order_id):
    """Assign a home delivery order to a medical store"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    data = request.get_json()
    store_id = data.get('store_id')
    
    if not store_id:
        return jsonify({'error': 'Store ID is required'}), 400
    
    order = MedicineOrder.query.get(order_id)
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    store = MedicalStore.query.get(store_id)
    if not store:
        return jsonify({'error': 'Medical store not found'}), 404
    
    try:
        # Generate OTP for delivery verification
        delivery_otp = ''.join(random.choices(string.digits, k=6))
        
        # Assign order to store
        order.store_id = store_id
        order.status = 'confirmed'
        order.delivery_otp = delivery_otp
        order.otp_verified = False
        
        # Update order items with medicine_id from the store
        for item in order.items:
            medicine = db.session.query(Medicine).filter(
                Medicine.store_id == store_id,
                func.lower(Medicine.name) == func.lower(item.medicine_name)
            ).first()
            
            if medicine:
                item.medicine_id = medicine.id
        
        # Notify the store
        notification = Notification(
            user_id=store.user_id,
            patient_id=order.patient_id,
            title='New Home Delivery Order Assigned',
            message=f'Admin assigned home delivery order #{order.id}. Total: ₹{order.total_amount:.2f}. Verify OTP before dispatch.',
            notification_type='medicine_order',
            related_id=order.id
        )
        db.session.add(notification)
        
        # Notify patient with OTP
        patient = Patient.query.get(order.patient_id)
        if patient:
            patient_notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Order Assigned',
                message=f'Your order #{order.id} has been assigned to {store.name}. OTP: {delivery_otp}. Share this for delivery verification.',
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(patient_notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order assigned successfully',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders', methods=['GET'])
@jwt_required()
def get_store_orders():
    """Get all medicine orders placed by stores with pagination"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    # Get all store orders with optional status filter
    query = MedicineStoreOrder.query
    
    if request.args.get('status'):
        query = query.filter_by(status=request.args.get('status'))
    
    query = query.order_by(MedicineStoreOrder.created_at.desc())
    
    # Paginate
    result = paginate_query(query, per_page=10)
    
    # Enrich with store information
    enriched_orders = []
    for order in result['items']:
        order_dict = order.to_dict()
        store = MedicalStore.query.get(order.store_id)
        if store:
            order_dict['store_name'] = store.name
            order_dict['store_phone'] = store.phone
            order_dict['store_address'] = store.address
            order_dict['store_city'] = store.city
            order_dict['store_state'] = store.state
            order_dict['store_pincode'] = store.pincode
            order_dict['store_license'] = store.license_number
            # Get store owner email
            store_user = User.query.get(store.user_id)
            if store_user:
                order_dict['store_email'] = store_user.email
        enriched_orders.append(order_dict)
    
    return jsonify({
        'orders': enriched_orders,
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/store-orders/<int:order_id>/approve', methods=['POST'])
@jwt_required()
def approve_store_order(order_id):
    """Approve a store order and notify the store"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'pending':
        return jsonify({'error': 'Order is not pending'}), 400
    
    try:
        order.status = 'approved'
        
        # Notify the store
        store = MedicalStore.query.get(order.store_id)
        if store:
            notification = Notification(
                user_id=store.user_id,
                title='Order Approved',
                message=f'Your medicine order #{order.id} has been approved by admin. Total: ₹{order.total_amount:.2f}',
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order approved successfully',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders/<int:order_id>/reject', methods=['POST'])
@jwt_required()
def reject_store_order(order_id):
    """Reject a store order and notify the store"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'pending':
        return jsonify({'error': 'Order is not pending'}), 400
    
    try:
        data = request.get_json()
        reason = data.get('reason', 'No reason provided')
        
        order.status = 'rejected'
        order.notes = f"Rejected: {reason}"
        
        # Notify the store
        store = MedicalStore.query.get(order.store_id)
        if store:
            notification = Notification(
                user_id=store.user_id,
                title='Order Rejected',
                message=f'Your medicine order #{order.id} has been rejected. Reason: {reason}',
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order rejected successfully',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders/<int:order_id>/complete', methods=['POST'])
@jwt_required()
def complete_store_order(order_id):
    """Mark a store order as completed and add medicines to store inventory"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'approved':
        return jsonify({'error': 'Order must be approved first'}), 400
    
    try:
        order.status = 'completed'
        
        # Add medicines to store's inventory
        store = MedicalStore.query.get(order.store_id)
        if store:
            from app.models.medicine import MedicineStoreOrderItem, Medicine
            
            # Get all items in the order
            order_items = MedicineStoreOrderItem.query.filter_by(order_id=order.id).all()
            
            medicines_added = []
            for item in order_items:
                # Check if medicine already exists in store's inventory
                existing_medicine = Medicine.query.filter_by(
                    store_id=store.id,
                    name=item.medicine_name
                ).first()
                
                if existing_medicine:
                    # Update existing medicine stock
                    existing_medicine.stock_quantity += item.quantity
                    medicines_added.append(f"{item.medicine_name} (+{item.quantity})")
                else:
                    # Create new medicine entry in store's inventory
                    # Get medicine details from admin catalog if available
                    admin_medicine = None
                    if item.medicine_id:
                        admin_medicine = Medicine.query.get(item.medicine_id)
                    
                    new_medicine = Medicine(
                        store_id=store.id,
                        name=item.medicine_name,
                        price=item.price,
                        stock_quantity=item.quantity,
                        description=admin_medicine.description if admin_medicine else f"Ordered from admin catalog",
                        manufacturer=admin_medicine.manufacturer if admin_medicine else None,
                        category=admin_medicine.category if admin_medicine else 'General',
                        requires_prescription=admin_medicine.requires_prescription if admin_medicine else False,
                        expiry_date=admin_medicine.expiry_date if admin_medicine else None,
                        is_available=True
                    )
                    db.session.add(new_medicine)
                    medicines_added.append(f"{item.medicine_name} ({item.quantity})")
            
            # Notify the store
            medicines_summary = ', '.join(medicines_added) if medicines_added else 'No medicines'
            notification = Notification(
                user_id=store.user_id,
                title='Order Delivered - Inventory Updated',
                message=f'Your medicine order #{order.id} has been completed. Added to inventory: {medicines_summary}',
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order marked as completed and medicines added to inventory',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders/<int:order_id>/update-delivery-status', methods=['POST'])
@jwt_required()
def update_store_order_delivery_status(order_id):
    """Update delivery status for approved store orders"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'approved':
        return jsonify({'error': 'Order must be approved first'}), 400
    
    data = request.get_json()
    new_status = data.get('delivery_status')
    
    # Valid delivery statuses
    valid_statuses = ['processing', 'dispatched', 'out_for_delivery', 'delivered']
    
    if not new_status or new_status not in valid_statuses:
        return jsonify({'error': f'Invalid delivery status. Must be one of: {", ".join(valid_statuses)}'}), 400
    
    try:
        old_status = order.delivery_status
        order.delivery_status = new_status
        order.admin_notes = data.get('notes', order.admin_notes)
        
        # If delivered, mark order as completed and add medicines to inventory
        if new_status == 'delivered':
            order.status = 'completed'
            
            # Add medicines to store's inventory
            store = MedicalStore.query.get(order.store_id)
            if store:
                from app.models.medicine import MedicineStoreOrderItem, Medicine
                
                # Get all items in the order
                order_items = MedicineStoreOrderItem.query.filter_by(order_id=order.id).all()
                
                medicines_added = []
                for item in order_items:
                    # Check if medicine already exists in store's inventory
                    existing_medicine = Medicine.query.filter_by(
                        store_id=store.id,
                        name=item.medicine_name
                    ).first()
                    
                    if existing_medicine:
                        # Update existing medicine stock
                        existing_medicine.stock_quantity += item.quantity
                        medicines_added.append(f"{item.medicine_name} (+{item.quantity})")
                    else:
                        # Create new medicine entry in store's inventory
                        # Get medicine details from admin catalog if available
                        admin_medicine = None
                        if item.medicine_id:
                            admin_medicine = Medicine.query.get(item.medicine_id)
                        
                        new_medicine = Medicine(
                            store_id=store.id,
                            name=item.medicine_name,
                            price=item.price,
                            stock_quantity=item.quantity,
                            description=admin_medicine.description if admin_medicine else f"Ordered from admin catalog",
                            manufacturer=admin_medicine.manufacturer if admin_medicine else None,
                            category=admin_medicine.category if admin_medicine else 'General',
                            requires_prescription=admin_medicine.requires_prescription if admin_medicine else False,
                            expiry_date=admin_medicine.expiry_date if admin_medicine else None,
                            is_available=True
                        )
                        db.session.add(new_medicine)
                        medicines_added.append(f"{item.medicine_name} ({item.quantity})")
        
        db.session.commit()
        
        # Notify the store about delivery status update
        store = MedicalStore.query.get(order.store_id)
        if store:
            status_messages = {
                'processing': 'Your order is being processed',
                'dispatched': 'Your order has been dispatched',
                'out_for_delivery': 'Your order is out for delivery',
                'delivered': 'Your order has been delivered and added to inventory'
            }
            
            message = f'Order #{order.id}: {status_messages.get(new_status, "Status updated")}'
            if new_status == 'delivered' and 'medicines_added' in locals():
                medicines_summary = ', '.join(medicines_added) if medicines_added else 'No medicines'
                message += f'. Added: {medicines_summary}'
            
            notification = Notification(
                user_id=store.user_id,
                title='Order Delivery Update',
                message=message,
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Delivery status updated from {old_status or "None"} to {new_status}',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/patient-orders/<int:order_id>/notify-delivery', methods=['POST'])
@jwt_required()
def notify_patient_delivery(order_id):
    """Notify patient about delivery day for home delivery order"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.delivery_type != 'home_delivery':
        return jsonify({'error': 'This endpoint is only for home delivery orders'}), 400
    
    data = request.get_json()
    delivery_date = data.get('delivery_date')
    delivery_message = data.get('message', f'Your order #{order.id} will be delivered on {delivery_date}')
    
    if not delivery_date:
        return jsonify({'error': 'Delivery date is required'}), 400
    
    try:
        # Update order notes
        order.notes = f"{order.notes or ''}\nDelivery scheduled for: {delivery_date}".strip()
        
        # Notify patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Delivery Scheduled',
                message=delivery_message,
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Patient notified about delivery date',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/patient-orders/<int:order_id>/complete-delivery', methods=['POST'])
@jwt_required()
def complete_patient_delivery(order_id):
    """Complete patient home delivery order after verifying OTP"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.delivery_type != 'home_delivery':
        return jsonify({'error': 'This endpoint is only for home delivery orders'}), 400
    
    data = request.get_json()
    provided_otp = data.get('otp')
    
    if not provided_otp:
        return jsonify({'error': 'OTP is required'}), 400
    
    # Verify OTP
    if order.delivery_otp != provided_otp:
        return jsonify({'error': 'Invalid OTP'}), 400
    
    if order.otp_verified:
        return jsonify({'error': 'OTP already verified. Order already completed.'}), 400
    
    try:
        # Mark OTP as verified
        order.otp_verified = True
        order.status = 'delivered'
        
        # Deduct stock for home delivery orders
        for item in order.items:
            if item.medicine_id:
                medicine = Medicine.query.get(item.medicine_id)
                if medicine:
                    medicine.stock_quantity = max(0, medicine.stock_quantity - item.quantity)
        
        db.session.commit()
        
        # Notify patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Order Delivered',
                message=f'Your order #{order.id} has been successfully delivered. Thank you for your order!',
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        # Notify medical store
        if order.store_id:
            store = MedicalStore.query.get(order.store_id)
            if store:
                notification = Notification(
                    user_id=store.user_id,
                    title='Order Delivered',
                    message=f'Order #{order.id} has been successfully delivered to the patient.',
                    notification_type='order_update',
                    related_id=order.id
                )
                db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order delivered successfully. Stock deducted.',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders/<int:order_id>/notify-delivery', methods=['POST'])
@jwt_required()
def notify_store_delivery(order_id):
    """Notify medical store about delivery day for their order"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'approved':
        return jsonify({'error': 'Order must be approved first'}), 400
    
    data = request.get_json()
    delivery_date = data.get('delivery_date')
    delivery_message = data.get('message', f'Your order #{order.id} will be delivered on {delivery_date}')
    
    if not delivery_date:
        return jsonify({'error': 'Delivery date is required'}), 400
    
    try:
        # Parse and store expected delivery date
        from datetime import datetime
        try:
            order.expected_delivery_date = datetime.strptime(delivery_date, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        # Update admin notes
        order.admin_notes = f"{order.admin_notes or ''}\nDelivery scheduled for: {delivery_date}".strip()
        order.delivery_status = 'dispatched'
        
        # Notify store
        store = MedicalStore.query.get(order.store_id)
        if store:
            notification = Notification(
                user_id=store.user_id,
                title='Delivery Scheduled',
                message=delivery_message,
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Store notified about delivery date',
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/store-orders/<int:order_id>/complete-delivery', methods=['POST'])
@jwt_required()
def complete_store_delivery(order_id):
    """Complete medical store order delivery after verifying OTP"""
    current_user_id = get_jwt_identity()
    
    if not check_admin(current_user_id):
        return jsonify({'error': 'Unauthorized'}), 403
    
    order = MedicineStoreOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.status != 'approved':
        return jsonify({'error': 'Order must be approved first'}), 400
    
    data = request.get_json()
    provided_otp = data.get('otp')
    
    if not provided_otp:
        return jsonify({'error': 'OTP is required'}), 400
    
    # Extract OTP from notes (stored as "OTP: XXXXXX")
    import re
    otp_match = re.search(r'OTP:\s*(\d{6})', order.notes or '')
    
    if not otp_match:
        return jsonify({'error': 'OTP not found for this order'}), 400
    
    stored_otp = otp_match.group(1)
    
    # Verify OTP
    if stored_otp != provided_otp:
        return jsonify({'error': 'Invalid OTP'}), 400
    
    if order.status == 'completed':
        return jsonify({'error': 'Order already completed'}), 400
    
    try:
        # Mark order as completed
        order.status = 'completed'
        order.delivery_status = 'delivered'
        order.admin_notes = f"{order.admin_notes or ''}\nDelivery completed with OTP verification".strip()
        
        # Update store inventory - ADD ALL MEDICINES (existing and new)
        store = MedicalStore.query.get(order.store_id)
        medicines_added = []
        
        if store:
            for item in order.items:
                # Check if medicine already exists in store inventory by name
                existing_medicine = Medicine.query.filter_by(
                    store_id=store.id,
                    name=item.medicine_name
                ).first()
                
                if existing_medicine:
                    # Update existing medicine stock
                    existing_medicine.stock_quantity += item.quantity
                    medicines_added.append(f"{item.medicine_name} (+{item.quantity})")
                else:
                    # Create new medicine in store's inventory
                    # Get details from admin catalog if available
                    admin_medicine = None
                    if item.medicine_id:
                        admin_medicine = Medicine.query.get(item.medicine_id)
                    
                    new_medicine = Medicine(
                        store_id=store.id,
                        name=item.medicine_name,
                        price=item.price,
                        stock_quantity=item.quantity,
                        description=admin_medicine.description if admin_medicine else f"Ordered from admin catalog",
                        manufacturer=admin_medicine.manufacturer if admin_medicine else None,
                        category=admin_medicine.category if admin_medicine else 'General',
                        requires_prescription=admin_medicine.requires_prescription if admin_medicine else False,
                        expiry_date=admin_medicine.expiry_date if admin_medicine else None,
                        is_available=True
                    )
                    db.session.add(new_medicine)
                    medicines_added.append(f"{item.medicine_name} ({item.quantity})")
        
        db.session.commit()
        
        # Notify store with details
        if store:
            medicines_summary = ', '.join(medicines_added) if medicines_added else 'No medicines'
            notification = Notification(
                user_id=store.user_id,
                title='Order Delivered Successfully',
                message=f'Your order #{order.id} has been delivered and verified with OTP. Inventory updated: {medicines_summary}',
                notification_type='store_order_update',
                related_id=order.id
            )
            db.session.add(notification)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Order delivered successfully. {len(medicines_added)} medicines added to inventory.',
            'medicines_added': medicines_added,
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
