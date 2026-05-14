# Razorpay Payment Integration - Implementation Guide

## Quick Start

### Step 1: Setup Environment Variables
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your Razorpay credentials:
   ```env
   RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
   RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx
   ```

### Step 2: Install Backend Dependencies
```bash
pip install -r backend/requirements.txt
```

### Step 3: Database Migration
```bash
cd backend
flask db migrate -m "Add Razorpay payment fields"
flask db upgrade
```

### Step 4: Frontend Setup
Razorpay package is already in `pubspec.yaml`. Just install:
```bash
cd .flutter_app
flutter pub get
```

## File Changes Summary

### Backend Changes

#### 1. **requirements.txt**
- Added: `razorpay==1.3.0`

#### 2. **app/models/payment.py**
- New fields:
  - `razorpay_order_id`: Store Razorpay order ID
  - `razorpay_payment_id`: Store Razorpay payment ID  
  - `razorpay_signature`: Store payment signature
  - `razorpay_receipt`: Store receipt ID
- Updated payment_status values: 'pending', 'initiated', 'completed', 'failed'

#### 3. **app/services/payment_service.py** (NEW)
- `RazorpayService` class for payment gateway integration
- Methods:
  - `create_order()`: Create Razorpay order
  - `verify_payment_signature()`: Verify payment authenticity
  - `fetch_payment()`: Get payment details
  - `capture_payment()`: Capture authorized payments
  - `refund_payment()`: Process refunds

#### 4. **app/routes/payments.py**
- New endpoints:
  - `POST /api/payments/razorpay/create-order`: Initialize payment
  - `POST /api/payments/razorpay/verify`: Verify and complete payment
- Updated endpoints to work with Razorpay

### Frontend Changes

#### 1. **pubspec.yaml**
- Already includes: `razorpay_flutter: ^1.3.7`
- No changes needed

#### 2. **lib/screens/patient/medicine_payment_screen.dart** (NEW)
- Medicine order payment UI
- Razorpay checkout integration
- Payment success/failure handling

#### 3. **lib/screens/patient/lab_test_payment_screen.dart** (NEW)
- Lab test order payment UI
- Similar to medicine payment screen
- Lab-specific metadata

#### 4. **lib/utils/payment_helper.dart** (NEW)
- Helper utilities for payment UI
- Status formatting and colors
- Reusable payment widgets

## API Endpoints

### Create Order
```
POST /api/payments/razorpay/create-order
Authorization: Bearer <token>

{
  "amount": 500,
  "related_type": "medicine_order|lab_order",
  "related_id": 123,
  "description": "Order description"
}
```

**Response (201)**:
```json
{
  "success": true,
  "razorpay_order_id": "order_...",
  "amount": 50000,
  "currency": "INR",
  "razorpay_key": "rzp_test_...",
  "payment_id": 1,
  "description": "Order description"
}
```

### Verify Payment
```
POST /api/payments/razorpay/verify
Authorization: Bearer <token>

{
  "razorpay_order_id": "order_...",
  "razorpay_payment_id": "pay_...",
  "razorpay_signature": "signature_hash"
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "payment": { ... }
}
```

## Integration Points

### Medicine Orders
1. After creating order, show "Pay" button
2. Button triggers `MedicinePaymentScreen`
3. On success, order status updates to `payment_status='completed'`

### Lab Test Orders
1. After booking test, show "Pay" button
2. Button triggers `LabTestPaymentScreen`
3. On success, order status updates to `payment_status='completed'`

## Database Schema Changes

### Payment Table Updates
```sql
ALTER TABLE payments ADD COLUMN razorpay_order_id VARCHAR(100);
ALTER TABLE payments ADD COLUMN razorpay_payment_id VARCHAR(100);
ALTER TABLE payments ADD COLUMN razorpay_signature VARCHAR(200);
ALTER TABLE payments ADD COLUMN razorpay_receipt VARCHAR(100);
CREATE UNIQUE INDEX idx_razorpay_order_id ON payments(razorpay_order_id);
```

## Testing

### Test Credentials
Use these for development:
- Key ID: `rzp_test_xxxxxxxxxxxxx`
- Key Secret: `xxxxxxxxxxxxxxxxxxxxx`

### Test Cards
- **Success**: 4111 1111 1111 1111 (any future expiry, any CVV)
- **Decline**: 4000 0000 0000 0002

### Test UPI
- Success: `success@razorpay`
- Failure: `failed@razorpay`

## Security

1. **Server-side Verification**: All payment signatures verified on backend
2. **User Validation**: Orders checked to belong to logged-in user
3. **Amount Verification**: Payment amount must match order total
4. **Encrypted Storage**: Razorpay keys stored in environment variables
5. **HTTPS Only**: All API calls use secure connections

## Error Handling

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Payment service not configured" | Razorpay credentials missing | Set `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` |
| "Invalid signature" | Signature mismatch | Verify credentials are correct |
| "Order not found" | Order doesn't exist | Check order ID is valid |
| "Unauthorized" | Order belongs to different user | Verify user permission |

## Monitoring & Logs

### Backend Logs
```python
# Enable debug logs
app.config['DEBUG'] = True

# Check payment service initialization
from app.services.payment_service import RazorpayService
service = RazorpayService()  # Will raise error if credentials missing
```

### Transaction History
Access all payments through:
- Admin dashboard: `/api/admin/payments`
- User history: `GET /api/payments`
- Individual payment: `GET /api/payments/<id>`

## Deployment Checklist

- [ ] Set production Razorpay keys in `.env`
- [ ] Run database migrations
- [ ] Install all dependencies
- [ ] Test payment flow with test account
- [ ] Verify notification emails
- [ ] Enable HTTPS
- [ ] Set up payment webhook (optional)
- [ ] Document API keys location
- [ ] Setup monitoring/alerts

## Support & Resources

- **Razorpay Docs**: https://razorpay.com/docs/
- **Flutter Plugin**: https://pub.dev/packages/razorpay_flutter
- **Dashboard**: https://dashboard.razorpay.com
