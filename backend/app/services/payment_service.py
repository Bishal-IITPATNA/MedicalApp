import razorpay
import json
import hmac
import hashlib
import os
from dotenv import load_dotenv

load_dotenv()

class RazorpayService:
    """Service for handling Razorpay payment gateway integration"""
    
    def __init__(self):
        self.key_id = os.getenv('RAZORPAY_KEY_ID', '')
        self.key_secret = os.getenv('RAZORPAY_KEY_SECRET', '')
        
        if not self.key_id or not self.key_secret:
            raise ValueError("Razorpay credentials not configured in environment variables")
        
        self.client = razorpay.Client(auth=(self.key_id, self.key_secret))
    
    def create_order(self, amount, receipt, description='', notes=None):
        """
        Create a Razorpay order
        
        Args:
            amount: Amount in smallest currency unit (paise for INR, e.g., 50000 for ₹500)
            receipt: Unique receipt ID
            description: Order description
            notes: Dict of additional notes
            
        Returns:
            Order dict with order_id, amount, etc.
        """
        try:
            order_data = {
                'amount': int(amount * 100),  # Convert to paise
                'currency': 'INR',
                'receipt': receipt,
                'description': description
            }
            
            if notes:
                order_data['notes'] = notes
            
            order = self.client.order.create(data=order_data)
            return {
                'success': True,
                'order_id': order['id'],
                'amount': order['amount'],
                'currency': order['currency'],
                'receipt': order['receipt'],
                'status': order['status']
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def verify_payment_signature(self, razorpay_order_id, razorpay_payment_id, razorpay_signature):
        """
        Verify the payment signature from Razorpay callback
        
        Args:
            razorpay_order_id: Order ID from Razorpay
            razorpay_payment_id: Payment ID from Razorpay
            razorpay_signature: Signature from Razorpay callback
            
        Returns:
            True if signature is valid, False otherwise
        """
        try:
            body = f'{razorpay_order_id}|{razorpay_payment_id}'
            expected_signature = hmac.new(
                self.key_secret.encode(),
                body.encode(),
                hashlib.sha256
            ).hexdigest()
            
            return expected_signature == razorpay_signature
        except Exception as e:
            print(f"Signature verification error: {str(e)}")
            return False
    
    def fetch_payment(self, payment_id):
        """
        Fetch payment details from Razorpay
        
        Args:
            payment_id: Razorpay payment ID
            
        Returns:
            Payment details dict
        """
        try:
            payment = self.client.payment.fetch(payment_id)
            return {
                'success': True,
                'payment_id': payment['id'],
                'order_id': payment['order_id'],
                'amount': payment['amount'],
                'currency': payment['currency'],
                'status': payment['status'],
                'method': payment['method'],
                'description': payment.get('description', ''),
                'notes': payment.get('notes', {})
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def capture_payment(self, payment_id, amount):
        """
        Capture a payment (for authorized payments)
        
        Args:
            payment_id: Razorpay payment ID
            amount: Amount to capture in paise
            
        Returns:
            Capture result dict
        """
        try:
            payment = self.client.payment.capture(payment_id, int(amount * 100))
            return {
                'success': True,
                'payment_id': payment['id'],
                'status': payment['status'],
                'amount': payment['amount']
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def refund_payment(self, payment_id, amount=None, notes=None):
        """
        Refund a payment (full or partial)
        
        Args:
            payment_id: Razorpay payment ID
            amount: Amount to refund in rupees (None for full refund)
            notes: Refund notes
            
        Returns:
            Refund result dict
        """
        try:
            refund_data = {}
            if amount:
                refund_data['amount'] = int(amount * 100)  # Convert to paise
            if notes:
                refund_data['notes'] = notes
            
            refund = self.client.payment.refund(payment_id, refund_data) if refund_data else self.client.payment.refund(payment_id)
            
            return {
                'success': True,
                'refund_id': refund['id'],
                'payment_id': refund['payment_id'],
                'amount': refund['amount'],
                'status': refund['status']
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
