from app import db
from datetime import datetime
import random
import string

class Medicine(db.Model):
    __tablename__ = 'medicines'
    
    id = db.Column(db.Integer, primary_key=True)
    store_id = db.Column(db.Integer, db.ForeignKey('medical_stores.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    manufacturer = db.Column(db.String(200))
    price = db.Column(db.Float, nullable=False)
    stock_quantity = db.Column(db.Integer, default=0)
    expiry_date = db.Column(db.Date)
    category = db.Column(db.String(100))
    requires_prescription = db.Column(db.Boolean, default=False)
    is_available = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    order_items = db.relationship('MedicineOrderItem', backref='medicine', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'store_id': self.store_id,
            'name': self.name,
            'description': self.description,
            'manufacturer': self.manufacturer,
            'price': self.price,
            'stock_quantity': self.stock_quantity,
            'expiry_date': self.expiry_date.isoformat() if self.expiry_date else None,
            'category': self.category,
            'requires_prescription': self.requires_prescription,
            'is_available': self.is_available
        }

class MedicineOrder(db.Model):
    __tablename__ = 'medicine_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    store_id = db.Column(db.Integer, db.ForeignKey('medical_stores.id'), nullable=True)
    current_store_id = db.Column(db.Integer, db.ForeignKey('medical_stores.id'), nullable=True)
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(30), default='pending')  # pending, confirmed, accepted, dispatched, out_for_delivery, delivered, completed, declined, cancelled
    total_amount = db.Column(db.Float, default=0.0)
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed
    delivery_address = db.Column(db.Text)
    delivery_type = db.Column(db.String(20), default='pickup')  # pickup, home_delivery
    delivery_otp = db.Column(db.String(6))  # OTP for delivery verification
    otp_verified = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text)
    offered_to_stores = db.Column(db.Text)  # JSON array of store IDs that have been offered
    current_offer_time = db.Column(db.DateTime)  # When current store received the offer
    timeout_minutes = db.Column(db.Integer, default=5)  # Minutes to accept before auto-reject
    
    # Relationships
    items = db.relationship('MedicineOrderItem', backref='order', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        # Get store name if store_id exists
        store_name = None
        if self.store_id:
            from app.models.user import MedicalStore
            store = MedicalStore.query.get(self.store_id)
            store_name = store.name if store else None
        
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'store_id': self.store_id,
            'store_name': store_name,
            'current_store_id': self.current_store_id,
            'order_date': self.order_date.isoformat() if self.order_date else None,
            'status': self.status,
            'total_amount': self.total_amount,
            'payment_status': self.payment_status,
            'delivery_address': self.delivery_address,
            'delivery_type': self.delivery_type,
            'delivery_otp': self.delivery_otp if self.otp_verified else None,
            'otp_verified': self.otp_verified,
            'notes': self.notes,
            'offered_to_stores': self.offered_to_stores,
            'current_offer_time': self.current_offer_time.isoformat() if self.current_offer_time else None,
            'timeout_minutes': self.timeout_minutes,
            'items': [item.to_dict() for item in self.items]
        }

class MedicineOrderItem(db.Model):
    __tablename__ = 'medicine_order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('medicine_orders.id'), nullable=False)
    medicine_id = db.Column(db.Integer, db.ForeignKey('medicines.id'), nullable=True)
    medicine_name = db.Column(db.String(200))
    quantity = db.Column(db.Integer, nullable=False)
    price = db.Column(db.Float, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'medicine_id': self.medicine_id,
            'medicine_name': self.medicine_name,
            'quantity': self.quantity,
            'price': self.price,
            'medicine': self.medicine.to_dict() if self.medicine else None
        }

class Prescription(db.Model):
    __tablename__ = 'prescriptions'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    appointment_id = db.Column(db.Integer, db.ForeignKey('appointments.id'), nullable=True)
    prescription_date = db.Column(db.DateTime, default=datetime.utcnow)
    medicines = db.Column(db.Text)  # JSON string of medicines with dosage
    instructions = db.Column(db.Text)
    
    # Relationships
    patient = db.relationship('Patient', backref='prescriptions', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'doctor_id': self.doctor_id,
            'appointment_id': self.appointment_id,
            'prescription_date': self.prescription_date.isoformat() if self.prescription_date else None,
            'medicines': self.medicines,
            'instructions': self.instructions
        }

class MedicineStoreOrder(db.Model):
    """Orders placed by medical stores to admin for inventory restocking"""
    __tablename__ = 'medicine_store_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    store_id = db.Column(db.Integer, db.ForeignKey('medical_stores.id'), nullable=False)
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(30), default='pending')  # pending, approved, rejected, processing, dispatched, delivered, completed
    delivery_status = db.Column(db.String(30))  # For tracking: processing, dispatched, out_for_delivery, delivered
    total_amount = db.Column(db.Float, default=0.0)
    order_type = db.Column(db.String(20), default='store_order')
    notes = db.Column(db.Text)
    admin_notes = db.Column(db.Text)  # Notes from admin
    expected_delivery_date = db.Column(db.Date)  # Expected delivery date
    
    # Relationships
    items = db.relationship('MedicineStoreOrderItem', backref='order', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        from app.models.user import MedicalStore
        store = MedicalStore.query.get(self.store_id) if self.store_id else None
        
        # Extract OTP from notes if present
        import re
        otp = None
        if self.notes:
            otp_match = re.search(r'OTP:\s*(\d{6})', self.notes)
            if otp_match:
                otp = otp_match.group(1)
        
        return {
            'id': self.id,
            'store_id': self.store_id,
            'store_name': store.name if store else None,
            'order_date': self.order_date.isoformat() if self.order_date else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'status': self.status,
            'delivery_status': self.delivery_status,
            'total_amount': self.total_amount,
            'order_type': self.order_type,
            'notes': self.notes,
            'admin_notes': self.admin_notes,
            'expected_delivery_date': self.expected_delivery_date.isoformat() if self.expected_delivery_date else None,
            'delivery_otp': otp,
            'items': [item.to_dict() for item in self.items]
        }

class MedicineStoreOrderItem(db.Model):
    """Individual items in store orders"""
    __tablename__ = 'medicine_store_order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('medicine_store_orders.id'), nullable=False)
    medicine_id = db.Column(db.Integer, nullable=False)
    medicine_name = db.Column(db.String(200))
    quantity = db.Column(db.Integer, nullable=False)
    price = db.Column(db.Float, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'medicine_id': self.medicine_id,
            'medicine_name': self.medicine_name,
            'quantity': self.quantity,
            'price': self.price
        }

class MedicineBill(db.Model):
    """Bills generated for medicine orders after OTP verification"""
    __tablename__ = 'medicine_bills'
    
    id = db.Column(db.Integer, primary_key=True)
    bill_number = db.Column(db.String(50), unique=True, nullable=False)
    order_id = db.Column(db.Integer, db.ForeignKey('medicine_orders.id'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    store_id = db.Column(db.Integer, db.ForeignKey('medical_stores.id'), nullable=False)
    bill_date = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Patient details (snapshot at time of purchase)
    patient_name = db.Column(db.String(200))
    patient_phone = db.Column(db.String(20))
    patient_address = db.Column(db.Text)
    
    # Store details (snapshot at time of purchase)
    store_name = db.Column(db.String(200))
    store_address = db.Column(db.Text)
    store_phone = db.Column(db.String(20))
    store_gstin = db.Column(db.String(50))
    
    # Bill details
    subtotal = db.Column(db.Float, default=0.0)
    tax_percentage = db.Column(db.Float, default=0.0)
    tax_amount = db.Column(db.Float, default=0.0)
    discount = db.Column(db.Float, default=0.0)
    total_amount = db.Column(db.Float, default=0.0)
    
    payment_method = db.Column(db.String(50))
    payment_status = db.Column(db.String(20), default='completed')
    
    delivery_type = db.Column(db.String(20))  # pickup, home_delivery
    delivery_address = db.Column(db.Text)
    
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    order = db.relationship('MedicineOrder', backref='bill', lazy=True)
    items = db.relationship('MedicineBillItem', backref='bill', lazy=True, cascade='all, delete-orphan')
    
    @staticmethod
    def generate_bill_number():
        """Generate unique bill number in format: BILL-YYYYMMDD-XXXX"""
        date_str = datetime.utcnow().strftime('%Y%m%d')
        random_str = ''.join(random.choices(string.digits, k=4))
        bill_number = f'BILL-{date_str}-{random_str}'
        
        # Check if exists, regenerate if needed
        while MedicineBill.query.filter_by(bill_number=bill_number).first():
            random_str = ''.join(random.choices(string.digits, k=4))
            bill_number = f'BILL-{date_str}-{random_str}'
        
        return bill_number
    
    def to_dict(self):
        return {
            'id': self.id,
            'bill_number': self.bill_number,
            'order_id': self.order_id,
            'patient_id': self.patient_id,
            'store_id': self.store_id,
            'bill_date': self.bill_date.isoformat() if self.bill_date else None,
            'patient_name': self.patient_name,
            'patient_phone': self.patient_phone,
            'patient_address': self.patient_address,
            'medical_store_name': self.store_name,  # Use medical_store_name for frontend consistency
            'store_name': self.store_name,  # Keep for backward compatibility
            'store_address': self.store_address,
            'store_phone': self.store_phone,
            'store_gstin': self.store_gstin,
            'subtotal': self.subtotal,
            'tax_percentage': self.tax_percentage,
            'tax_amount': self.tax_amount,
            'discount': self.discount,
            'total_amount': self.total_amount,
            'payment_method': self.payment_method,
            'payment_status': self.payment_status,
            'delivery_type': self.delivery_type,
            'delivery_address': self.delivery_address,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'items': [item.to_dict() for item in self.items]
        }

class MedicineBillItem(db.Model):
    """Individual items in a medicine bill"""
    __tablename__ = 'medicine_bill_items'
    
    id = db.Column(db.Integer, primary_key=True)
    bill_id = db.Column(db.Integer, db.ForeignKey('medicine_bills.id'), nullable=False)
    medicine_id = db.Column(db.Integer, nullable=True)
    medicine_name = db.Column(db.String(200), nullable=False)
    manufacturer = db.Column(db.String(200))
    quantity = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Float, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'bill_id': self.bill_id,
            'medicine_id': self.medicine_id,
            'medicine_name': self.medicine_name,
            'manufacturer': self.manufacturer,
            'quantity': self.quantity,
            'unit_price': self.unit_price,
            'total_price': self.total_price
        }
