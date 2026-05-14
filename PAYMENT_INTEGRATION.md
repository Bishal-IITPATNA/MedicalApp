# Medical App - Razorpay Payment Integration

## Overview

The Medical App now supports **Razorpay** payment gateway for:
- 💊 **Medicine Orders** - Home delivery medicine purchases
- 🔬 **Lab Test Orders** - Medical test bookings

Users can pay using:
- 💳 Credit/Debit Cards
- 📱 UPI (Google Pay, PhonePe, Paytm)
- 🏦 Net Banking
- 💰 Wallets

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  MedicinePaymentScreen / LabTestPaymentScreen   │  │
│  │  (User selects payment method)                   │  │
│  └──────────────┬───────────────────────────────────┘  │
└─────────────────┼────────────────────────────────────────┘
                  │
        ┌─────────▼──────────┐
        │  API Backend       │
        │  POST /api/        │
        │  payments/razorpay │
        │  /create-order     │
        └─────────┬──────────┘
                  │
        ┌─────────▼──────────────────┐
        │    Razorpay Service        │
        │  - create_order()          │
        │  - verify_signature()      │
        │  - fetch_payment()         │
        └─────────┬──────────────────┘
                  │
        ┌─────────▼──────────────────┐
        │  Razorpay Gateway API      │
        │  (razorpay.com)            │
        └────────────────────────────┘
```

## Key Features

### 1. Secure Payment Processing
- ✅ Server-side signature verification
- ✅ User ownership validation
- ✅ Amount verification
- ✅ HTTPS encryption
- ✅ Environment-based credentials

### 2. Multiple Payment Methods
- Cards (Credit/Debit)
- UPI
- Net Banking
- Wallets
- EMI options

### 3. Order Tracking
- Order creation → Payment initiated → Payment completed → Order fulfilled
- Real-time status updates
- Notification on payment success/failure

### 4. Error Handling
- Automatic retry on payment failure
- Clear error messages
- Transaction logs
- Fallback mechanisms

## Installation

### Prerequisites
- Python 3.8+
- Flutter 3.22.0+
- Active Razorpay account

### Backend Setup

1. **Install Dependencies**
```bash
cd backend
pip install -r requirements.txt
```

2. **Configure Environment**
```bash
# Create .env file with Razorpay credentials
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=xxxxx
```

3. **Run Migrations**
```bash
flask db migrate -m "Add Razorpay payment fields"
flask db upgrade
```

4. **Start Backend**
```bash
python application.py
```

### Frontend Setup

1. **Install Dependencies**
```bash
cd .flutter_app
flutter pub get
```

2. **Run App**
```bash
flutter run
```

## Configuration

### Razorpay Credentials

Get credentials from: https://dashboard.razorpay.com/settings/api-keys

```env
# .env file
RAZORPAY_KEY_ID=rzp_test_xxxxx        # Test/Live Key ID
RAZORPAY_KEY_SECRET=xxxxxxxx          # Test/Live Key Secret
```

### Environment Variables
```bash
# Development
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=test_secret

# Production
RAZORPAY_KEY_ID=rzp_live_xxxxx
RAZORPAY_KEY_SECRET=live_secret
```

## API Usage

### Create Payment Order

```bash
curl -X POST http://localhost:5000/api/payments/razorpay/create-order \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 500,
    "related_type": "medicine_order",
    "related_id": 123,
    "description": "Medicine Order Payment"
  }'
```

**Response:**
```json
{
  "success": true,
  "razorpay_order_id": "order_1234567890",
  "razorpay_key": "rzp_test_xxxxx",
  "amount": 50000,
  "currency": "INR"
}
```

### Verify Payment

```bash
curl -X POST http://localhost:5000/api/payments/razorpay/verify \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "razorpay_order_id": "order_1234567890",
    "razorpay_payment_id": "pay_1234567890",
    "razorpay_signature": "signature_hash"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "payment": {
    "id": 1,
    "amount": 500,
    "payment_status": "completed",
    "razorpay_payment_id": "pay_1234567890"
  }
}
```

## Flutter Integration

### Medicine Payment Example

```dart
import 'screens/patient/medicine_payment_screen.dart';

// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MedicinePaymentScreen(
      orderId: 123,
      amount: 500.00,
      orderDetails: 'Medicine Order #123',
    ),
  ),
).then((result) {
  if (result == true) {
    // Payment successful
    showSuccessDialog();
  }
});
```

### Lab Test Payment Example

```dart
import 'screens/patient/lab_test_payment_screen.dart';

// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LabTestPaymentScreen(
      orderId: 456,
      amount: 1500.00,
      testName: 'Complete Blood Count',
    ),
  ),
).then((result) {
  if (result == true) {
    // Payment successful
    showSuccessDialog();
  }
});
```

## Testing

### Test Cards

| Card Type | Number | CVV | Expiry |
|-----------|--------|-----|--------|
| Success | 4111 1111 1111 1111 | Any 3 digits | Any future date |
| Decline | 4000 0000 0000 0002 | Any 3 digits | Any future date |

### Test UPI

- Success: `success@razorpay`
- Failure: `failed@razorpay`

### Manual Testing

```bash
# Test order creation
python backend/razorpay_test.py --test-create-order --amount 500

# Test payment history
python backend/razorpay_test.py --test-get-payments

# Test payment verification
python backend/razorpay_test.py --razorpay-order-id order_123 \
  --razorpay-payment-id pay_456 --signature sig_789
```

## Payment Flow

```
User Places Order
    ↓
Click "Pay" Button
    ↓
Create Razorpay Order (Backend)
    ↓
Open Razorpay Checkout (Frontend)
    ↓
User Selects Payment Method
    ↓
User Completes Payment
    ↓
Razorpay Returns Payment ID & Signature
    ↓
Verify Signature (Backend)
    ↓
Update Order Status = "Paid"
    ↓
Send Confirmation Notification
    ↓
Order Fulfillment Begins
```

## Database Schema

### Payments Table (New Fields)

```sql
-- New columns in payments table
razorpay_order_id VARCHAR(100) UNIQUE
razorpay_payment_id VARCHAR(100)
razorpay_signature VARCHAR(200)
razorpay_receipt VARCHAR(100)

-- Updated status values
payment_status IN ('pending', 'initiated', 'completed', 'failed')
```

## Security Considerations

### ✅ Implemented Security Measures

1. **Signature Verification**
   - All payments verified using HMAC-SHA256
   - Prevents payment tampering

2. **User Authorization**
   - Orders validated to belong to logged-in user
   - Prevents unauthorized access

3. **Amount Verification**
   - Payment amount must match order total
   - Prevents amount manipulation

4. **Encrypted Credentials**
   - API keys stored in environment variables
   - Never hardcoded or logged

5. **HTTPS Only**
   - All API calls use secure connections
   - Prevents man-in-the-middle attacks

### 🔐 Best Practices

- Keep `RAZORPAY_KEY_SECRET` confidential
- Rotate credentials regularly
- Monitor payment logs for suspicious activity
- Use test credentials for development

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Payment service not configured | Missing credentials | Check `.env` file |
| Invalid signature | Tampering detected | Verify Razorpay keys |
| Order not found | Order doesn't exist | Check order ID |
| Unauthorized | User permission denied | Verify user ownership |
| Payment failed | User cancelled/bank declined | Show retry option |

## Monitoring & Debugging

### Backend Logs
```python
# Enable debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Check Razorpay service
from app.services.payment_service import RazorpayService
service = RazorpayService()
print(f"Service initialized: {service.key_id}")
```

### View Transactions
- Razorpay Dashboard: https://dashboard.razorpay.com
- API: `GET /api/payments`
- Admin Panel: `/admin/payments`

## Troubleshooting

### Issue: "Payment service not configured"

**Cause:** Environment variables not set

**Solution:**
```bash
# Check .env file exists
ls -la .env

# Verify credentials
echo $RAZORPAY_KEY_ID
echo $RAZORPAY_KEY_SECRET

# Reload environment
source .env
```

### Issue: "Invalid signature" error

**Cause:** Razorpay keys mismatch

**Solution:**
1. Verify keys from Razorpay dashboard
2. Ensure correct key (Test vs Live)
3. Restart backend application

### Issue: Payment stuck on "Processing"

**Cause:** Order ID mismatch or network issue

**Solution:**
1. Check internet connection
2. Verify order exists in database
3. Contact Razorpay support with transaction ID

## Deployment

### Production Checklist

- [ ] Switch to Live credentials in `.env`
- [ ] Test payment flow with live account
- [ ] Setup payment notifications
- [ ] Enable HTTPS on backend
- [ ] Configure CORS for production domain
- [ ] Setup error monitoring (Sentry)
- [ ] Schedule regular backups
- [ ] Document payment procedures
- [ ] Train support team

### Deployment Steps

```bash
# 1. Update credentials
export RAZORPAY_KEY_ID=rzp_live_xxxxx
export RAZORPAY_KEY_SECRET=xxxxx

# 2. Run migrations
flask db upgrade

# 3. Restart services
systemctl restart medical-app-backend

# 4. Verify payment endpoint
curl https://api.medicalapp.com/api/payments

# 5. Monitor logs
tail -f /var/log/medical-app/payments.log
```

## Support & Resources

- **Documentation**: See `RAZORPAY_SETUP.md`
- **Razorpay Docs**: https://razorpay.com/docs/
- **Flutter Plugin**: https://pub.dev/packages/razorpay_flutter
- **API Tests**: `backend/razorpay_test.py`

## Changes Summary

### Backend Files
- ✅ `requirements.txt` - Added razorpay package
- ✅ `app/models/payment.py` - Added Razorpay fields
- ✅ `app/services/payment_service.py` - New payment service
- ✅ `app/routes/payments.py` - Updated payment endpoints
- ✅ `backend/razorpay_test.py` - Testing utility

### Frontend Files
- ✅ `lib/screens/patient/medicine_payment_screen.dart` - Medicine payment UI
- ✅ `lib/screens/patient/lab_test_payment_screen.dart` - Lab test payment UI
- ✅ `lib/utils/payment_helper.dart` - Payment utilities

### Configuration Files
- ✅ `.env.example` - Environment template
- ✅ `RAZORPAY_SETUP.md` - Setup guide
- ✅ `backend/docs/RAZORPAY_INTEGRATION.md` - Integration docs

## License

This payment integration is part of the Medical App project.

---

**Last Updated:** May 2026  
**Version:** 1.0.0
