from app import db
from datetime import datetime

class Payment(db.Model):
    __tablename__ = 'payments'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    payment_method = db.Column(db.String(50))  # gpay, phonepe, credit_card, debit_card
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed, failed
    transaction_id = db.Column(db.String(200), unique=True)
    
    # Related entity
    related_id = db.Column(db.Integer)  # ID of related appointment, order, etc.
    related_type = db.Column(db.String(50))  # appointment, medicine_order, lab_order
    
    payment_date = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Additional payment gateway details
    gateway_response = db.Column(db.Text)  # JSON string of gateway response
    
    # Relationships
    user = db.relationship('User', backref='payments', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'amount': self.amount,
            'payment_method': self.payment_method,
            'payment_status': self.payment_status,
            'transaction_id': self.transaction_id,
            'related_id': self.related_id,
            'related_type': self.related_type,
            'payment_date': self.payment_date.isoformat() if self.payment_date else None
        }
