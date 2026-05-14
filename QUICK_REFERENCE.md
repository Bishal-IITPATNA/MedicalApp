# Razorpay Integration - Quick Reference

## Files Changed/Created

### Backend
```
✅ backend/requirements.txt
   └─ Added: razorpay==1.3.0

✅ backend/app/models/payment.py
   └─ Added 4 new fields for Razorpay data

✅ backend/app/services/payment_service.py (NEW)
   └─ RazorpayService class with 5 methods

✅ backend/app/routes/payments.py
   └─ 2 new endpoints for order & verify

✅ backend/razorpay_test.py (NEW)
   └─ CLI testing utility for APIs

✅ .env.example
   └─ Template for Razorpay credentials
```

### Frontend
```
✅ .flutter_app/lib/screens/patient/medicine_payment_screen.dart (NEW)
   └─ UI for medicine payments (231 lines)

✅ .flutter_app/lib/screens/patient/lab_test_payment_screen.dart (NEW)
   └─ UI for lab payments (231 lines)

✅ .flutter_app/lib/utils/payment_helper.dart (NEW)
   └─ Payment utilities (117 lines)

✅ pubspec.yaml
   └─ Already has razorpay_flutter (no change needed)
```

### Documentation
```
✅ RAZORPAY_SETUP.md
   └─ Quick start & setup guide

✅ backend/docs/RAZORPAY_INTEGRATION.md
   └─ Detailed integration guide

✅ PAYMENT_INTEGRATION.md
   └─ Comprehensive reference

✅ PAYMENT_FLOW_GUIDE.md
   └─ Visual diagrams & flows

✅ IMPLEMENTATION_SUMMARY.md
   └─ Summary of all changes

✅ DEPLOYMENT_CHECKLIST.md
   └─ Step-by-step deployment guide

✅ This file: QUICK_REFERENCE.md
   └─ Quick lookup for common tasks
```

## Quick Start (3 Steps)

### 1️⃣ Setup Environment
```bash
cp .env.example .env
# Edit .env and add:
# RAZORPAY_KEY_ID=rzp_test_xxxxx
# RAZORPAY_KEY_SECRET=xxxxx
```

### 2️⃣ Install & Migrate
```bash
pip install -r backend/requirements.txt
cd backend
flask db migrate -m "Add Razorpay fields"
flask db upgrade
```

### 3️⃣ Test
```bash
python backend/razorpay_test.py --test-create-order
```

## API Endpoints

### Create Order
```
POST /api/payments/razorpay/create-order
Authorization: Bearer <token>

Request:
{
  "amount": 500,
  "related_type": "medicine_order|lab_order",
  "related_id": 123,
  "description": "Description"
}

Response:
{
  "success": true,
  "razorpay_order_id": "order_...",
  "razorpay_key": "rzp_test_...",
  "amount": 50000,
  "currency": "INR"
}
```

### Verify Payment
```
POST /api/payments/razorpay/verify
Authorization: Bearer <token>

Request:
{
  "razorpay_order_id": "order_...",
  "razorpay_payment_id": "pay_...",
  "razorpay_signature": "sig..."
}

Response:
{
  "success": true,
  "message": "Payment verified successfully"
}
```

## Flutter Usage

### Medicine Payment
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MedicinePaymentScreen(
      orderId: 123,
      amount: 500.00,
      orderDetails: 'Medicine Order #123',
    ),
  ),
);
```

### Lab Test Payment
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LabTestPaymentScreen(
      orderId: 456,
      amount: 1500.00,
      testName: 'Blood Test',
    ),
  ),
);
```

## Test Cards

| Purpose | Card Number | CVV | Expiry |
|---------|-------------|-----|--------|
| Success | 4111 1111 1111 1111 | Any | Future |
| Decline | 4000 0000 0000 0002 | Any | Future |

## Test UPI
- Success: `success@razorpay`
- Failure: `failed@razorpay`

## Common Commands

### Test API
```bash
# Test order creation
python backend/razorpay_test.py --test-create-order --amount 500

# Test payment history
python backend/razorpay_test.py --test-get-payments
```

### Database
```bash
# Run migrations
flask db upgrade

# Check payments
psql medicalapp -c "SELECT id, amount, payment_status FROM payments LIMIT 5;"
```

### Run Backend
```bash
cd backend
python application.py
```

### Run Frontend
```bash
cd .flutter_app
flutter run
```

## Environment Variables

```bash
# Required for payment processing
RAZORPAY_KEY_ID=rzp_test_xxxxx      # From Razorpay dashboard
RAZORPAY_KEY_SECRET=xxxxx           # From Razorpay dashboard

# Optional (for API testing)
API_BASE_URL=http://localhost:5000
TEST_AUTH_TOKEN=your_jwt_token
```

## Payment Flow Summary

```
1. User clicks "Pay"
   ↓
2. Backend creates Razorpay order
   ↓
3. Frontend opens Razorpay modal
   ↓
4. User completes payment
   ↓
5. Backend verifies signature
   ↓
6. Order marked as "paid"
   ↓
7. User gets confirmation
```

## Database Schema

### New Payment Fields
```sql
ALTER TABLE payments ADD razorpay_order_id VARCHAR(100);
ALTER TABLE payments ADD razorpay_payment_id VARCHAR(100);
ALTER TABLE payments ADD razorpay_signature VARCHAR(200);
ALTER TABLE payments ADD razorpay_receipt VARCHAR(100);
```

### Payment Status Values
- `pending` - Order created, awaiting payment
- `initiated` - Payment started in Razorpay
- `completed` - Payment successful
- `failed` - Payment failed/cancelled

## Key Classes & Methods

### Backend

**RazorpayService** (`app/services/payment_service.py`)
```python
service = RazorpayService()
service.create_order(amount, receipt, description)
service.verify_payment_signature(order_id, payment_id, signature)
service.fetch_payment(payment_id)
service.refund_payment(payment_id, amount)
```

**Payment Model** (`app/models/payment.py`)
- New fields: razorpay_order_id, razorpay_payment_id, razorpay_signature, razorpay_receipt
- Updated field: payment_status includes 'initiated'

### Frontend

**MedicinePaymentScreen** (`lib/screens/patient/medicine_payment_screen.dart`)
```dart
MedicinePaymentScreen(
  orderId: int,
  amount: double,
  orderDetails: String,
)
```

**LabTestPaymentScreen** (`lib/screens/patient/lab_test_payment_screen.dart`)
```dart
LabTestPaymentScreen(
  orderId: int,
  amount: double,
  testName: String,
)
```

**PaymentHelper** (`lib/utils/payment_helper.dart`)
- `formatAmount(amount)` - Format currency
- `getPaymentStatusColor(status)` - Get color for status
- `buildPaymentStatusWidget(status)` - Widget with badge

## Documentation Files

| File | Purpose |
|------|---------|
| RAZORPAY_SETUP.md | Quick start guide |
| PAYMENT_INTEGRATION.md | Comprehensive reference |
| PAYMENT_FLOW_GUIDE.md | Architecture & flow diagrams |
| IMPLEMENTATION_SUMMARY.md | Change summary |
| DEPLOYMENT_CHECKLIST.md | Step-by-step deployment |
| backend/docs/RAZORPAY_INTEGRATION.md | Detailed integration guide |

## Security Checklist

- ✅ API keys in environment variables (not hardcoded)
- ✅ Signature verification (HMAC-SHA256)
- ✅ User authorization check
- ✅ Order ownership validation
- ✅ Amount verification
- ✅ HTTPS for all endpoints
- ✅ Error handling doesn't expose secrets

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Service not configured" | Check .env has credentials |
| "Invalid signature" | Verify Razorpay keys match |
| "Order not found" | Check order ID is correct |
| "Unauthorized" | Verify JWT token |
| Payment modal won't open | Check Razorpay key is valid |

## Support Resources

- **Razorpay Docs**: https://razorpay.com/docs/
- **Flutter Plugin**: https://pub.dev/packages/razorpay_flutter
- **Razorpay Dashboard**: https://dashboard.razorpay.com
- **This Project Docs**: See documentation files above

## Version Info

- **Razorpay SDK**: 1.3.0 (Python)
- **Razorpay Flutter**: 1.3.7 (already in pubspec.yaml)
- **Flask**: 3.0.0+
- **Flutter**: 3.22.0+

---

**Last Updated**: May 2026  
**Quick Reference Version**: 1.0.0  
**Status**: ✅ Production Ready
