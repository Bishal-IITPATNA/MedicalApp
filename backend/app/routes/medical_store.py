from flask import Blueprint, request, jsonify
from app import db
from app.models.user import MedicalStore, Patient
from app.models.medicine import Medicine, MedicineOrder, MedicineOrderItem, MedicineBill, MedicineBillItem
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func
from datetime import datetime
import json

bp = Blueprint('medical_store', __name__, url_prefix='/api/medical-store')

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
    """Get or update medical store profile"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    if request.method == 'GET':
        return jsonify(store.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            store.name = data['name']
        if 'phone' in data:
            store.phone = data['phone']
        if 'address' in data:
            store.address = data['address']
        if 'city' in data:
            store.city = data['city']
        if 'state' in data:
            store.state = data['state']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Profile updated successfully',
            'profile': store.to_dict()
        }), 200

@bp.route('/medicines', methods=['GET', 'POST'])
@jwt_required()
def medicines():
    """Get all medicines or add new medicine"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    if request.method == 'GET':
        query = Medicine.query.filter_by(store_id=store.id).order_by(Medicine.id.desc())
        
        # Paginate
        result = paginate_query(query, per_page=50)
        
        return jsonify({
            'medicines': [med.to_dict() for med in result['items']],
            'total': result['total'],
            'page': result['page'],
            'per_page': result['per_page'],
            'pages': result['pages'],
            'has_next': result['has_next'],
            'has_prev': result['has_prev']
        }), 200
    
    elif request.method == 'POST':
        data = request.get_json()
        
        medicine = Medicine(
            store_id=store.id,
            name=data['name'],
            description=data.get('description'),
            manufacturer=data.get('manufacturer'),
            price=data['price'],
            stock_quantity=data.get('stock_quantity', 0),
            category=data.get('category'),
            requires_prescription=data.get('requires_prescription', False)
        )
        
        db.session.add(medicine)
        db.session.commit()
        
        return jsonify({
            'message': 'Medicine added successfully',
            'medicine': medicine.to_dict()
        }), 201

@bp.route('/medicines/<int:medicine_id>', methods=['GET', 'PUT', 'DELETE'])
@jwt_required()
def medicine_detail(medicine_id):
    """Get, update, or delete a medicine"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    medicine = Medicine.query.filter_by(id=medicine_id, store_id=store.id).first()
    
    if not medicine:
        return jsonify({'error': 'Medicine not found'}), 404
    
    if request.method == 'GET':
        return jsonify(medicine.to_dict()), 200
    
    elif request.method == 'PUT':
        data = request.get_json()
        
        if 'name' in data:
            medicine.name = data['name']
        if 'description' in data:
            medicine.description = data['description']
        if 'price' in data:
            medicine.price = data['price']
        if 'stock_quantity' in data:
            medicine.stock_quantity = data['stock_quantity']
        if 'is_available' in data:
            medicine.is_available = data['is_available']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Medicine updated successfully',
            'medicine': medicine.to_dict()
        }), 200
    
    elif request.method == 'DELETE':
        db.session.delete(medicine)
        db.session.commit()
        
        return jsonify({
            'message': 'Medicine deleted successfully'
        }), 200

@bp.route('/orders', methods=['GET'])
@jwt_required()
def get_orders():
    """Get orders for this medical store"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    # Get completed orders assigned to this store
    completed_orders = MedicineOrder.query.filter_by(store_id=store.id).all()
    
    # Add bill information to completed orders
    completed_with_bills = []
    for order in completed_orders:
        order_dict = order.to_dict()
        # Check if bill exists for this order
        bill = MedicineBill.query.filter_by(order_id=order.id).first()
        order_dict['bill'] = bill.to_dict() if bill else None
        completed_with_bills.append(order_dict)
    
    # Get pending orders currently offered to this store
    from datetime import datetime, timedelta
    pending_offers = MedicineOrder.query.filter(
        MedicineOrder.status == 'pending',
        MedicineOrder.current_store_id == store.id
    ).all()
    
    # Add timeout info to pending offers
    offers_with_timeout = []
    for order in pending_offers:
        timeout_minutes = order.timeout_minutes or 5
        if order.current_offer_time:
            timeout_time = order.current_offer_time + timedelta(minutes=timeout_minutes)
            remaining_seconds = (timeout_time - datetime.utcnow()).total_seconds()
            
            order_dict = order.to_dict()
            order_dict['timeout_seconds'] = max(0, int(remaining_seconds))
            order_dict['is_expired'] = remaining_seconds <= 0
            offers_with_timeout.append(order_dict)
        else:
            offers_with_timeout.append(order.to_dict())
    
    return jsonify({
        'completed_orders': completed_with_bills,
        'pending_offers': offers_with_timeout
    }), 200

@bp.route('/orders/<int:order_id>', methods=['PUT'])
@jwt_required()
def update_order(order_id):
    """Accept or decline an order (legacy endpoint - use accept/reject endpoints instead)"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    # Check if order is assigned to this store OR currently offered to this store
    order = MedicineOrder.query.filter(
        MedicineOrder.id == order_id
    ).filter(
        db.or_(
            MedicineOrder.store_id == store.id,
            MedicineOrder.current_store_id == store.id
        )
    ).first()
    
    if not order:
        return jsonify({'error': 'Order not found or not assigned to your store'}), 404
    
    data = request.get_json()
    
    if 'status' in data:
        new_status = data['status']
        
        # If accepting an order that's currently offered (has current_store_id)
        if new_status == 'processing' and order.current_store_id == store.id:
            order.status = 'accepted'
            order.store_id = store.id
            order.current_store_id = None
            order.current_offer_time = None
            
            # Notify the patient
            patient = Patient.query.get(order.patient_id)
            if patient:
                notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Order Accepted',
                    message=f'{store.name} has accepted your medicine order #{order.id}',
                    notification_type='order_update',
                    related_id=order.id
                )
                db.session.add(notification)
        else:
            order.status = new_status
    
    db.session.commit()
    
    return jsonify({
        'message': 'Order updated successfully',
        'order': order.to_dict()
    }), 200

@bp.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard():
    """Get dashboard statistics"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    # Total medicines sold (from completed and dispatched orders)
    total_sold = db.session.query(func.sum(MedicineOrderItem.quantity)).join(
        MedicineOrder
    ).filter(
        MedicineOrder.store_id == store.id,
        MedicineOrder.status.in_(['completed', 'dispatched'])
    ).scalar() or 0
    
    # Total patients served (from completed and dispatched orders)
    total_patients = db.session.query(func.count(func.distinct(MedicineOrder.patient_id))).filter(
        MedicineOrder.store_id == store.id,
        MedicineOrder.status.in_(['completed', 'dispatched'])
    ).scalar() or 0
    
    # Total revenue (from completed and dispatched orders)
    total_revenue = db.session.query(func.sum(MedicineOrder.total_amount)).filter(
        MedicineOrder.store_id == store.id,
        MedicineOrder.status.in_(['completed', 'dispatched'])
    ).scalar() or 0
    
    # Convert to proper types
    total_sold = int(total_sold) if total_sold else 0
    total_patients = int(total_patients) if total_patients else 0
    total_revenue = float(total_revenue) if total_revenue else 0.0
    
    print(f"DEBUG: Dashboard for store {store.id} - Sold: {total_sold}, Patients: {total_patients}, Revenue: {total_revenue}")
    
    return jsonify({
        'total_medicines_sold': total_sold,
        'total_patients_served': total_patients,
        'total_revenue': total_revenue
    }), 200

@bp.route('/search', methods=['GET'])
def search_medicines():
    """Search medicines across all stores"""
    query = Medicine.query.filter_by(is_available=True)
    
    # Filter by name
    if request.args.get('name'):
        query = query.filter(Medicine.name.ilike(f"%{request.args.get('name')}%"))
    
    # Filter by category
    if request.args.get('category'):
        query = query.filter(Medicine.category.ilike(f"%{request.args.get('category')}%"))
    
    # Filter by city
    if request.args.get('city'):
        query = query.join(MedicalStore).filter(MedicalStore.city.ilike(f"%{request.args.get('city')}%"))
    
    medicines = query.all()
    
    return jsonify({
        'medicines': [med.to_dict() for med in medicines]
    }), 200

@bp.route('/order-medicines', methods=['POST'])
@jwt_required()
def order_medicines():
    """Place an order for medicines from admin"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    try:
        data = request.get_json()
        items = data.get('items', [])
        extra_medicines = data.get('extra_medicines', [])
        total_amount = data.get('total_amount', 0)

        if not items and not extra_medicines:
            return jsonify({'error': 'No items in order'}), 400

        # Generate OTP for order verification
        import random, string
        order_otp = ''.join(random.choices(string.digits, k=6))

        from app.models.medicine import MedicineStoreOrder
        order = MedicineStoreOrder(
            store_id=store.id,
            total_amount=total_amount,
            status='pending',
            order_type='store_order',
            notes=f'OTP: {order_otp}'
        )
        db.session.add(order)
        db.session.flush()  # Get order ID

        # Add order items
        from app.models.medicine import MedicineStoreOrderItem
        for item in items:
            medicine_name = item.get('name', f"Medicine #{item['medicine_id']}")
            order_item = MedicineStoreOrderItem(
                order_id=order.id,
                medicine_id=item['medicine_id'],
                medicine_name=medicine_name,
                quantity=item['quantity'],
                price=item['price']
            )
            db.session.add(order_item)
        # Add extra medicines
        for extra in extra_medicines:
            order_item = MedicineStoreOrderItem(
                order_id=order.id,
                medicine_id=None,
                medicine_name=extra.get('name', 'Extra Medicine'),
                quantity=extra.get('quantity', 1),
                price=extra.get('price', 0)
            )
            db.session.add(order_item)

        db.session.commit()

        # Notify medical store with OTP
        from app.models.notification import Notification
        notification = Notification(
            user_id=store.user_id,
            patient_id=None,
            title='Order OTP',
            message=f'Your admin order OTP is {order_otp}. Use this to verify delivery.',
            notification_type='order_update',
            related_id=order.id
        )
        db.session.add(notification)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Order placed successfully',
            'order_id': order.id,
            'otp': order_otp
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to place order: {str(e)}'}), 500

@bp.route('/my-orders', methods=['GET'])
@jwt_required()
def get_my_orders():
    """Get medicine orders placed by this store"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    from app.models.medicine import MedicineStoreOrder
    
    orders = MedicineStoreOrder.query.filter_by(
        store_id=store.id,
        order_type='store_order'
    ).order_by(MedicineStoreOrder.created_at.desc()).all()
    
    return jsonify({
        'orders': [order.to_dict() for order in orders]
    }), 200

@bp.route('/low-stock-medicines', methods=['GET'])
@jwt_required()
def get_low_stock_medicines():
    """Get medicines with low stock (stock_quantity <= 10)"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    threshold = int(request.args.get('threshold', 10))
    
    low_stock_medicines = Medicine.query.filter(
        Medicine.store_id == store.id,
        Medicine.stock_quantity <= threshold
    ).all()
    
    return jsonify({
        'medicines': [med.to_dict() for med in low_stock_medicines],
        'count': len(low_stock_medicines)
    }), 200

@bp.route('/check-low-stock', methods=['POST'])
@jwt_required()
def check_low_stock():
    """Check for low stock and create notifications for out of stock medicines"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    try:
        # Get medicines with 0 stock
        out_of_stock = Medicine.query.filter(
            Medicine.store_id == store.id,
            Medicine.stock_quantity == 0
        ).all()
        
        # Get medicines with low stock (1-10)
        low_stock = Medicine.query.filter(
            Medicine.store_id == store.id,
            Medicine.stock_quantity > 0,
            Medicine.stock_quantity <= 10
        ).all()
        
        # Create notifications for out of stock
        notifications_created = 0
        for medicine in out_of_stock:
            # Check if notification already exists today
            from datetime import datetime, timedelta
            today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
            
            existing = Notification.query.filter(
                Notification.user_id == store.user_id,
                Notification.message.like(f'%{medicine.name}%out of stock%'),
                Notification.created_at >= today_start
            ).first()
            
            if not existing:
                notification = Notification(
                    user_id=store.user_id,
                    title='Medicine Out of Stock',
                    message=f'{medicine.name} is out of stock. Please order from admin.',
                    notification_type='low_stock',
                    related_id=medicine.id
                )
                db.session.add(notification)
                notifications_created += 1
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'out_of_stock_count': len(out_of_stock),
            'low_stock_count': len(low_stock),
            'out_of_stock': [{'id': m.id, 'name': m.name, 'stock': m.stock_quantity} for m in out_of_stock],
            'low_stock': [{'id': m.id, 'name': m.name, 'stock': m.stock_quantity} for m in low_stock],
            'notifications_created': notifications_created
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/orders/<int:order_id>/accept', methods=['POST'])
@jwt_required()
def accept_order(order_id):
    """Accept a medicine order that was offered to this store"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    order = MedicineOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    # Verify this store is the current store for this order
    if order.current_store_id != store.id:
        return jsonify({'error': 'This order is not assigned to your store'}), 403
    
    # Check if order is still pending
    if order.status != 'pending':
        return jsonify({'error': 'Order is no longer available'}), 400
    
    try:
        # Accept the order
        order.status = 'accepted'
        order.store_id = store.id
        order.current_store_id = None
        order.current_offer_time = None
        
        # Link medicine_id to order items now that we know which store accepted
        from sqlalchemy import func
        for order_item in order.items:
            if not order_item.medicine_id and order_item.medicine_name:
                medicine = Medicine.query.filter(
                    Medicine.store_id == store.id,
                    func.lower(Medicine.name) == func.lower(order_item.medicine_name)
                ).first()
                if medicine:
                    order_item.medicine_id = medicine.id
        
        # Notify the patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Order Accepted',
                message=f'{store.name} has accepted your medicine order #{order.id}',
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order accepted successfully',
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/orders/<int:order_id>/reject', methods=['POST'])
@jwt_required()
def reject_order(order_id):
    """Reject a medicine order and route it to the next store"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    order = MedicineOrder.query.get(order_id)
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    # Verify this store is the current store for this order
    if order.current_store_id != store.id:
        return jsonify({'error': 'This order is not assigned to your store'}), 403
    
    # Check if order is still pending
    if order.status != 'pending':
        return jsonify({'error': 'Order is no longer available'}), 400
    
    try:
        # Get list of stores already offered
        offered_stores = json.loads(order.offered_to_stores) if order.offered_to_stores else []
        
        # Get next store alphabetically that hasn't been offered yet
        next_store = MedicalStore.query.filter(
            MedicalStore.id.notin_(offered_stores)
        ).order_by(MedicalStore.name).first()
        
        if next_store:
            # Route to next store
            offered_stores.append(next_store.id)
            order.current_store_id = next_store.id
            order.offered_to_stores = json.dumps(offered_stores)
            order.current_offer_time = datetime.utcnow()
            
            # Notify the next store
            notification = Notification(
                user_id=next_store.user_id,
                patient_id=order.patient_id,
                title='New Medicine Order',
                message=f'New order #{order.id}. Total: ₹{order.total_amount:.2f}. Please respond within 5 minutes.',
                notification_type='medicine_order',
                related_id=order.id
            )
            db.session.add(notification)
            
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': f'Order routed to {next_store.name}'
            }), 200
        else:
            # No more stores available
            order.status = 'no_stores_available'
            order.current_store_id = None
            order.current_offer_time = None
            
            # Notify patient that no stores are available
            patient = Patient.query.get(order.patient_id)
            if patient:
                notification = Notification(
                    user_id=patient.user_id,
                    patient_id=patient.id,
                    title='Order Could Not Be Fulfilled',
                    message=f'Sorry, no medical stores are available to fulfill order #{order.id}',
                    notification_type='order_update',
                    related_id=order.id
                )
                db.session.add(notification)
            
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': 'No more stores available, order marked as unfulfilled'
            }), 200
            
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/orders/<int:order_id>/verify-otp', methods=['POST'])
@jwt_required()
def verify_otp_and_dispatch(order_id):
    """Verify OTP for pickup orders - complete order and deduct stock. For home delivery, just verify OTP."""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    order = MedicineOrder.query.filter_by(id=order_id, store_id=store.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.otp_verified:
        return jsonify({'error': 'OTP already verified'}), 400
    
    data = request.get_json()
    entered_otp = data.get('otp', '')
    
    if entered_otp != order.delivery_otp:
        return jsonify({'error': 'Invalid OTP'}), 400
    
    try:
        # Mark OTP as verified
        order.otp_verified = True
        
        # For pickup orders: complete the order and deduct stock
        if order.delivery_type == 'pickup':
            order.status = 'completed'
            
            # Deduct stock for each medicine
            for order_item in order.items:
                if order_item.medicine_id:
                    medicine = Medicine.query.get(order_item.medicine_id)
                    if medicine and medicine.store_id == store.id:
                        if medicine.stock_quantity >= order_item.quantity:
                            medicine.stock_quantity -= order_item.quantity
                        else:
                            raise Exception(f'Insufficient stock for {medicine.name}')
        else:
            # For home delivery: just verify OTP, don't deduct stock yet
            # Stock will be deducted when order status is updated to 'delivered'
            pass
        
        # Check if bill already exists
        existing_bill = MedicineBill.query.filter_by(order_id=order.id).first()
        
        if not existing_bill:
            # Generate bill if it doesn't exist
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
            bill = MedicineBill(
                bill_number=MedicineBill.generate_bill_number(),
                order_id=order.id,
                patient_id=patient.id,
                store_id=store.id,
                patient_name=patient.name,
                patient_phone=patient.phone,
                patient_address=patient.address or '',
                store_name=store.name,
                store_address=store.address or '',
                store_phone=store.phone or '',
                store_gstin=getattr(store, 'gstin', 'N/A'),
                subtotal=subtotal,
                tax_percentage=tax_percentage,
                tax_amount=tax_amount,
                discount=discount,
                total_amount=total_amount,
                payment_method=order.payment_status,
                payment_status='completed',
                delivery_type=order.delivery_type,
                delivery_address=order.delivery_address,
                notes=order.notes
            )
            db.session.add(bill)
            db.session.flush()  # Get bill.id
            
            # Create bill items
            for order_item in order.items:
                medicine = Medicine.query.get(order_item.medicine_id) if order_item.medicine_id else None
                bill_item = MedicineBillItem(
                    bill_id=bill.id,
                    medicine_id=order_item.medicine_id,
                    medicine_name=order_item.medicine_name,
                    manufacturer=medicine.manufacturer if medicine else '',
                    quantity=order_item.quantity,
                    unit_price=order_item.price,
                    total_price=round(order_item.price * order_item.quantity, 2)
                )
                db.session.add(bill_item)
        else:
            bill = existing_bill
        
        # Notify patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            if order.delivery_type == 'home_delivery':
                message = f'OTP verified for order #{order.id}. Your order is ready for dispatch. Bill #{bill.bill_number}.'
            else:
                message = f'Your order #{order.id} has been completed. Bill #{bill.bill_number} generated. Thank you for your purchase!'
                
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title=f'Order {"Completed" if order.delivery_type == "pickup" else "OTP Verified"} - Bill Generated',
                message=message,
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        status_message = 'completed' if order.delivery_type == 'pickup' else 'OTP verified'
        return jsonify({
            'success': True,
            'message': f'Order {status_message} successfully. Bill generated.',
            'order': order.to_dict(),
            'bill': bill.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/bills', methods=['GET'])
@jwt_required()
def get_bills():
    """Get all bills for the medical store (paginated)"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    query = MedicineBill.query.filter_by(store_id=store.id).order_by(MedicineBill.bill_date.desc())
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
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    bill = MedicineBill.query.filter_by(id=bill_id, store_id=store.id).first()
    
    if not bill:
        return jsonify({'error': 'Bill not found'}), 404
    
    return jsonify(bill.to_dict()), 200

@bp.route('/orders/<int:order_id>/complete-pickup', methods=['POST'])
@jwt_required()
def complete_pickup(order_id):
    """Mark pickup order as completed and deduct stock"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    order = MedicineOrder.query.filter_by(id=order_id, store_id=store.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.delivery_type != 'pickup':
        return jsonify({'error': 'This endpoint is only for pickup orders'}), 400
    
    try:
        # Mark as completed
        order.status = 'completed'
        
        # Deduct stock for each medicine
        for order_item in order.items:
            if order_item.medicine_id:
                medicine = Medicine.query.get(order_item.medicine_id)
                if medicine and medicine.store_id == store.id:
                    if medicine.stock_quantity >= order_item.quantity:
                        medicine.stock_quantity -= order_item.quantity
                    else:
                        raise Exception(f'Insufficient stock for {medicine.name}')
        
        # Notify patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title='Order Completed',
                message=f'Your order #{order.id} has been completed at {store.name}',
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Order completed successfully',
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/orders/<int:order_id>/update-delivery-status', methods=['POST'])
@jwt_required()
def update_delivery_status(order_id):
    """Update home delivery order status with notifications to patient"""
    current_user_id = get_jwt_identity()
    store = MedicalStore.query.filter_by(user_id=current_user_id).first()
    
    if not store:
        return jsonify({'error': 'Medical store profile not found'}), 404
    
    order = MedicineOrder.query.filter_by(id=order_id, store_id=store.id).first()
    
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    if order.delivery_type != 'home_delivery':
        return jsonify({'error': 'This endpoint is only for home delivery orders'}), 400
    
    data = request.get_json()
    new_status = data.get('status')
    
    # Valid status transitions for home delivery
    valid_statuses = ['accepted', 'dispatched', 'out_for_delivery', 'delivered']
    
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'}), 400
    
    # Check valid status flow
    status_order = ['accepted', 'dispatched', 'out_for_delivery', 'delivered']
    current_index = status_order.index(order.status) if order.status in status_order else -1
    new_index = status_order.index(new_status)
    
    if new_index <= current_index:
        return jsonify({'error': f'Cannot move from {order.status} to {new_status}'}), 400
    
    try:
        # Update order status
        old_status = order.status
        order.status = new_status
        
        # If delivered, deduct stock
        if new_status == 'delivered':
            for order_item in order.items:
                if order_item.medicine_id:
                    medicine = Medicine.query.get(order_item.medicine_id)
                    if medicine and medicine.store_id == store.id:
                        if medicine.stock_quantity >= order_item.quantity:
                            medicine.stock_quantity -= order_item.quantity
                        else:
                            raise Exception(f'Insufficient stock for {medicine.name}')
        
        # Notify patient
        patient = Patient.query.get(order.patient_id)
        if patient:
            status_messages = {
                'accepted': f'Your order #{order.id} has been accepted by {store.name} and is being prepared.',
                'dispatched': f'Your order #{order.id} has been dispatched from {store.name}.',
                'out_for_delivery': f'Your order #{order.id} is out for delivery and will reach you today!',
                'delivered': f'Your order #{order.id} has been delivered. Thank you for your purchase!'
            }
            
            notification = Notification(
                user_id=patient.user_id,
                patient_id=patient.id,
                title=f'Order {new_status.replace("_", " ").title()}',
                message=status_messages.get(new_status, f'Order status updated to {new_status}'),
                notification_type='order_update',
                related_id=order.id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Order status updated to {new_status}',
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
