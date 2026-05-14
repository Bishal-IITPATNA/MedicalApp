#!/usr/bin/env python3
"""
Razorpay Payment Integration - API Testing Script

Usage:
    python razorpay_test.py --help
    python razorpay_test.py --test-create-order
    python razorpay_test.py --test-verify
"""

import requests
import json
import argparse
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
BASE_URL = os.getenv('API_BASE_URL', 'http://localhost:5000')
TEST_TOKEN = os.getenv('TEST_AUTH_TOKEN', '')  # Set this to your test JWT token

class RazorpayAPITester:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.token = token
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def test_create_order(self, amount=500, order_type='medicine_order', order_id=1):
        """Test creating a Razorpay order"""
        print("\n=== Test: Create Razorpay Order ===")
        print(f"URL: {self.base_url}/api/payments/razorpay/create-order")
        
        payload = {
            'amount': amount,
            'related_type': order_type,
            'related_id': order_id,
            'description': f'Test {order_type} Payment'
        }
        
        print(f"\nRequest Payload:\n{json.dumps(payload, indent=2)}")
        
        try:
            response = requests.post(
                f'{self.base_url}/api/payments/razorpay/create-order',
                headers=self.headers,
                json=payload,
                timeout=10
            )
            
            print(f"\nStatus Code: {response.status_code}")
            print(f"Response:\n{json.dumps(response.json(), indent=2)}")
            
            return response.json()
        except Exception as e:
            print(f"\nError: {str(e)}")
            return None
    
    def test_get_payments(self):
        """Test getting user payment history"""
        print("\n=== Test: Get Payments ===")
        print(f"URL: {self.base_url}/api/payments")
        
        try:
            response = requests.get(
                f'{self.base_url}/api/payments',
                headers=self.headers,
                timeout=10
            )
            
            print(f"\nStatus Code: {response.status_code}")
            print(f"Response:\n{json.dumps(response.json(), indent=2)}")
            
            return response.json()
        except Exception as e:
            print(f"\nError: {str(e)}")
            return None
    
    def test_verify_payment(self, order_id, payment_id, signature):
        """Test payment verification"""
        print("\n=== Test: Verify Payment ===")
        print(f"URL: {self.base_url}/api/payments/razorpay/verify")
        
        payload = {
            'razorpay_order_id': order_id,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        }
        
        print(f"\nRequest Payload:\n{json.dumps(payload, indent=2)}")
        
        try:
            response = requests.post(
                f'{self.base_url}/api/payments/razorpay/verify',
                headers=self.headers,
                json=payload,
                timeout=10
            )
            
            print(f"\nStatus Code: {response.status_code}")
            print(f"Response:\n{json.dumps(response.json(), indent=2)}")
            
            return response.json()
        except Exception as e:
            print(f"\nError: {str(e)}")
            return None

def main():
    parser = argparse.ArgumentParser(
        description='Razorpay Payment Integration API Tester'
    )
    parser.add_argument('--base-url', default=BASE_URL, help='API base URL')
    parser.add_argument('--token', default=TEST_TOKEN, help='JWT auth token')
    parser.add_argument('--test-create-order', action='store_true', help='Test order creation')
    parser.add_argument('--test-get-payments', action='store_true', help='Test get payments')
    parser.add_argument('--amount', type=float, default=500, help='Payment amount')
    parser.add_argument('--order-type', default='medicine_order', help='Order type')
    parser.add_argument('--order-id', type=int, default=1, help='Order ID')
    parser.add_argument('--razorpay-order-id', help='Razorpay order ID for verification')
    parser.add_argument('--razorpay-payment-id', help='Razorpay payment ID for verification')
    parser.add_argument('--signature', help='Payment signature for verification')
    
    args = parser.parse_args()
    
    # Validate token
    if not args.token:
        print("Error: JWT token required. Set TEST_AUTH_TOKEN or use --token flag")
        return
    
    tester = RazorpayAPITester(args.base_url, args.token)
    
    if args.test_create_order:
        tester.test_create_order(
            amount=args.amount,
            order_type=args.order_type,
            order_id=args.order_id
        )
    elif args.test_get_payments:
        tester.test_get_payments()
    elif args.razorpay_order_id and args.razorpay_payment_id and args.signature:
        tester.test_verify_payment(
            args.razorpay_order_id,
            args.razorpay_payment_id,
            args.signature
        )
    else:
        # Run all basic tests
        print("=== Running All Tests ===")
        tester.test_create_order()
        tester.test_get_payments()

if __name__ == '__main__':
    main()
