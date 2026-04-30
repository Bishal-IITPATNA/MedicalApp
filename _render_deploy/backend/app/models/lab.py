from app import db
from datetime import datetime
import random
import string

class LabTest(db.Model):
    __tablename__ = 'lab_tests'
    
    id = db.Column(db.Integer, primary_key=True)
    lab_id = db.Column(db.Integer, db.ForeignKey('lab_stores.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    price = db.Column(db.Float, nullable=False)
    category = db.Column(db.String(100))
    preparation_required = db.Column(db.Text)  # Instructions for test preparation
    sample_type = db.Column(db.String(50))  # blood, urine, etc.
    report_delivery_time = db.Column(db.String(50))  # "24 hours", "48 hours", etc.
    is_available = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    order_items = db.relationship('LabTestOrderItem', backref='test', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'lab_id': self.lab_id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'category': self.category,
            'preparation_required': self.preparation_required,
            'sample_type': self.sample_type,
            'report_delivery_time': self.report_delivery_time,
            'is_available': self.is_available
        }

class LabTestOrder(db.Model):
    __tablename__ = 'lab_test_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    lab_id = db.Column(db.Integer, db.ForeignKey('lab_stores.id'), nullable=False)
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    test_date = db.Column(db.Date)
    test_time = db.Column(db.Time)
    status = db.Column(db.String(20), default='pending')  # pending, accepted, declined, sample_collected, completed, cancelled
    total_amount = db.Column(db.Float, default=0.0)
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed
    collection_address = db.Column(db.Text)
    collection_otp = db.Column(db.String(6))  # OTP for sample collection verification
    otp_verified = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text)

    # Optional prescription uploaded by the patient when booking the test.
    # Stored as a base64 data URL.
    prescription_image = db.Column(db.Text, nullable=True)
    prescription_filename = db.Column(db.String(255), nullable=True)
    prescription_uploaded_at = db.Column(db.DateTime, nullable=True)
    
    # Relationships
    items = db.relationship('LabTestOrderItem', backref='order', lazy=True, cascade='all, delete-orphan')
    reports = db.relationship('LabReport', backref='order', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'lab_id': self.lab_id,
            'order_date': self.order_date.isoformat() if self.order_date else None,
            'test_date': self.test_date.isoformat() if self.test_date else None,
            'test_time': self.test_time.isoformat() if self.test_time else None,
            'status': self.status,
            'total_amount': self.total_amount,
            'payment_status': self.payment_status,
            'collection_address': self.collection_address,
            'collection_otp': self.collection_otp if self.otp_verified else None,
            'otp_verified': self.otp_verified,
            'notes': self.notes,
            'has_prescription': bool(self.prescription_image),
            'prescription_filename': self.prescription_filename,
            'prescription_uploaded_at': self.prescription_uploaded_at.isoformat() if self.prescription_uploaded_at else None,
            'items': [item.to_dict() for item in self.items]
        }

class LabTestOrderItem(db.Model):
    __tablename__ = 'lab_test_order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('lab_test_orders.id'), nullable=False)
    test_id = db.Column(db.Integer, db.ForeignKey('lab_tests.id'), nullable=False)
    price = db.Column(db.Float, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'test_id': self.test_id,
            'price': self.price,
            'test': self.test.to_dict() if self.test else None
        }

class LabReport(db.Model):
    __tablename__ = 'lab_reports'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('lab_test_orders.id'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    report_date = db.Column(db.DateTime, default=datetime.utcnow)
    report_file_url = db.Column(db.String(500))  # URL to uploaded report file
    findings = db.Column(db.Text)
    remarks = db.Column(db.Text)
    
    # Relationships
    patient = db.relationship('Patient', backref='lab_reports', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'patient_id': self.patient_id,
            'report_date': self.report_date.isoformat() if self.report_date else None,
            'report_file_url': self.report_file_url,
            'findings': self.findings,
            'remarks': self.remarks
        }

class LabTestBill(db.Model):
    """Bills generated for lab test orders after OTP verification"""
    __tablename__ = 'lab_test_bills'
    
    id = db.Column(db.Integer, primary_key=True)
    bill_number = db.Column(db.String(50), unique=True, nullable=False)
    order_id = db.Column(db.Integer, db.ForeignKey('lab_test_orders.id'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    lab_id = db.Column(db.Integer, db.ForeignKey('lab_stores.id'), nullable=False)
    bill_date = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Patient details (snapshot at time of purchase)
    patient_name = db.Column(db.String(200))
    patient_phone = db.Column(db.String(20))
    patient_address = db.Column(db.Text)
    
    # Lab details (snapshot at time of purchase)
    lab_name = db.Column(db.String(200))
    lab_address = db.Column(db.Text)
    lab_phone = db.Column(db.String(20))
    lab_registration = db.Column(db.String(50))
    
    # Bill details
    subtotal = db.Column(db.Float, default=0.0)
    tax_percentage = db.Column(db.Float, default=0.0)
    tax_amount = db.Column(db.Float, default=0.0)
    discount = db.Column(db.Float, default=0.0)
    total_amount = db.Column(db.Float, default=0.0)
    
    payment_method = db.Column(db.String(50))
    payment_status = db.Column(db.String(20), default='completed')
    
    collection_address = db.Column(db.Text)
    test_date = db.Column(db.Date)
    test_time = db.Column(db.Time)
    
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    order = db.relationship('LabTestOrder', backref='bill', lazy=True)
    items = db.relationship('LabTestBillItem', backref='bill', lazy=True, cascade='all, delete-orphan')
    
    @staticmethod
    def generate_bill_number():
        """Generate unique bill number in format: LAB-YYYYMMDD-XXXX"""
        date_str = datetime.utcnow().strftime('%Y%m%d')
        random_str = ''.join(random.choices(string.digits, k=4))
        bill_number = f'LAB-{date_str}-{random_str}'
        
        # Check if exists, regenerate if needed
        while LabTestBill.query.filter_by(bill_number=bill_number).first():
            random_str = ''.join(random.choices(string.digits, k=4))
            bill_number = f'LAB-{date_str}-{random_str}'
        
        return bill_number
    
    def to_dict(self):
        return {
            'id': self.id,
            'bill_number': self.bill_number,
            'order_id': self.order_id,
            'patient_id': self.patient_id,
            'lab_id': self.lab_id,
            'bill_date': self.bill_date.isoformat() if self.bill_date else None,
            'patient_name': self.patient_name,
            'patient_phone': self.patient_phone,
            'patient_address': self.patient_address,
            'lab_name': self.lab_name,
            'lab_address': self.lab_address,
            'lab_phone': self.lab_phone,
            'lab_registration': self.lab_registration,
            'subtotal': self.subtotal,
            'tax_percentage': self.tax_percentage,
            'tax_amount': self.tax_amount,
            'discount': self.discount,
            'total_amount': self.total_amount,
            'payment_method': self.payment_method,
            'payment_status': self.payment_status,
            'collection_address': self.collection_address,
            'test_date': self.test_date.isoformat() if self.test_date else None,
            'test_time': self.test_time.isoformat() if self.test_time else None,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'items': [item.to_dict() for item in self.items]
        }

class LabTestBillItem(db.Model):
    """Individual items in a lab test bill"""
    __tablename__ = 'lab_test_bill_items'
    
    id = db.Column(db.Integer, primary_key=True)
    bill_id = db.Column(db.Integer, db.ForeignKey('lab_test_bills.id'), nullable=False)
    test_id = db.Column(db.Integer, nullable=True)
    test_name = db.Column(db.String(200), nullable=False)
    category = db.Column(db.String(100))
    price = db.Column(db.Float, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'bill_id': self.bill_id,
            'test_id': self.test_id,
            'test_name': self.test_name,
            'category': self.category,
            'price': self.price
        }
