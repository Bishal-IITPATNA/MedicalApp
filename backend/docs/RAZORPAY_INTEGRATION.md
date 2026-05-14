# Razorpay Payment Integration Guide

## Overview
The Medical App now supports payment processing through Razorpay for both medicine orders and lab test orders.

## Backend Setup

### 1. Install Razorpay SDK
The Razorpay SDK is already added to `requirements.txt`:
```
razorpay==1.3.0
```

Install with:
```bash
pip install -r requirements.txt
```

### 2. Environment Variables
Add your Razorpay credentials to `.env` file:
```env
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

Get these credentials from:
- Dashboard: https://dashboard.razorpay.com
- Settings → API Keys → Live/Test Keys

### 3. Database Migrations
New payment fields have been added to the `Payment` model:
- `razorpay_order_id`: Razorpay order ID
- `razorpay_payment_id`: Razorpay payment ID
- `razorpay_signature`: Payment signature for verification
- `razorpay_receipt`: Receipt ID for the order

Run migration:
```bash
flask db migrate -m "Add Razorpay payment fields"
flask db upgrade
```

## API Endpoints

### 1. Create Razorpay Order
**POST** `/api/payments/razorpay/create-order`

Request:
```json
{
  "amount": 500,
  "related_type": "medicine_order",
  "related_id": 123,
  "description": "Medicine Order Payment"
}
```

Response:
```json
{
  "success": true,
  "razorpay_order_id": "order_1234567890",
  "amount": 50000,
  "currency": "INR",
  "razorpay_key": "rzp_live_xxxxx",
  "payment_id": 1,
  "description": "Medicine Order Payment"
}
```

### 2. Verify Payment
**POST** `/api/payments/razorpay/verify`

Request:
```json
{
  "razorpay_order_id": "order_1234567890",
  "razorpay_payment_id": "pay_1234567890",
  "razorpay_signature": "signature_hash"
}
```

Response:
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "payment": { ... }
}
```

## Frontend Setup

### 1. Razorpay Package
The package is already in `pubspec.yaml`:
```yaml
razorpay_flutter: ^1.3.7
```

### 2. Android Configuration
Add to `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.razorpay:checkout:1.6.33'
}
```

### 3. iOS Configuration
Add to `ios/Podfile`:
```ruby
pod 'Razorpay', '~> 23.1.0'
```

## Usage

### For Medicine Orders
```dart
import 'package:medical_app/screens/patient/medicine_payment_screen.dart';

// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MedicinePaymentScreen(
      orderId: medicineOrderId,
      amount: totalAmount,
      orderDetails: 'Medicine Order #$medicineOrderId',
    ),
  ),
);
```

### For Lab Test Orders
```dart
import 'package:medical_app/screens/patient/lab_test_payment_screen.dart';

// Navigate to payment screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LabTestPaymentScreen(
      orderId: labOrderId,
      amount: totalAmount,
      testName: 'Blood Test',
    ),
  ),
);
```

## Payment Flow

1. **Order Creation**: User creates a medicine/lab order
2. **Payment Initiation**: Click "Pay" button to go to payment screen
3. **Create Order**: Backend creates Razorpay order
4. **Checkout**: Frontend opens Razorpay checkout modal
5. **Payment**: User completes payment via Razorpay
6. **Verification**: Frontend verifies signature on backend
7. **Confirmation**: Order status updated to "paid"

## Testing

### Test Cards (Razorpay Test Mode)
- **Success**: Card Number: 4111 1111 1111 1111
- **CVV**: Any 3 digits
- **Expiry**: Any future date

### Test UPI IDs
- Success: `success@razorpay`
- Failed: `failed@razorpay`

## Error Handling

The implementation includes:
- Signature verification for security
- Order ownership validation
- Payment status tracking
- Automatic notification on payment success
- Error recovery and retry mechanisms

## Security Considerations

1. **Signature Verification**: All payments verified using Razorpay signature
2. **Order Validation**: Backend confirms order belongs to user
3. **Amount Verification**: Amount matches order total before processing
4. **HTTPS Only**: All API calls use secure connections

## Troubleshooting

### Payment Fails with "Invalid signature"
- Verify `RAZORPAY_KEY_SECRET` is correct
- Check order ID, payment ID are correct
- Ensure payment was successfully processed on Razorpay

### "Payment service not configured"
- Verify environment variables are set
- Check Razorpay credentials in `.env`
- Restart the application

### Order Not Found
- Verify order belongs to logged-in user
- Check order ID is for medicine or lab order
- Ensure order exists before payment

## Support
For Razorpay API issues, visit: https://razorpay.com/docs/api/
