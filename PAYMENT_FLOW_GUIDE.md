# Razorpay Payment Integration - Visual Guide

## Payment Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER (Flutter App)                        │
│                                                                   │
│  1. Browse medicines/tests                                      │
│  2. Add to cart                                                 │
│  3. Review order                                                │
│  4. Click "Pay Now" button                                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Flask Backend API                               │
│                                                                   │
│  Endpoint: POST /api/payments/razorpay/create-order             │
│  - Validate user (JWT token)                                    │
│  - Verify order ownership                                       │
│  - Calculate amount                                             │
│  - Call RazorpayService.create_order()                          │
│  - Return: order_id, razorpay_key, amount                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Razorpay Service                               │
│                                                                   │
│  - Initialize Razorpay client (API Key + Secret)                │
│  - Create order with amount, receipt, notes                     │
│  - Return Razorpay order ID                                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Razorpay API                                  │
│                   (razorpay.com)                                 │
│                                                                   │
│  - Create order in Razorpay system                              │
│  - Store amount, currency, receipt info                         │
│  - Return unique order ID                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼ (Return to App)
┌─────────────────────────────────────────────────────────────────┐
│                  Flutter App (UI)                                │
│                                                                   │
│  - Receive razorpay_order_id, razorpay_key, amount              │
│  - Initialize Razorpay SDK                                      │
│  - Open Razorpay Checkout Modal                                 │
│  - Display payment options (Cards, UPI, etc.)                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   User Payment Page                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Razorpay Checkout                                     │    │
│  │  ───────────────────────────────────────────────────   │    │
│  │  Amount: ₹500.00                                       │    │
│  │  Order ID: order_1234567890                            │    │
│  │                                                         │    │
│  │  [Payment Methods]                                     │    │
│  │  ☐ Credit Card    ☐ UPI    ☐ Wallet                   │    │
│  │  ☐ Net Banking    ☐ EMI                                │    │
│  │                                                         │    │
│  │  [Pay ₹500] or [Cancel]                               │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  5. User selects payment method & enters details                │
└────────────────────────┬────────────────────────────────────────┘
                         │
           ┌─────────────┴─────────────┐
           │                           │
           ▼                           ▼
     [SUCCESS]                    [FAILURE]
           │                           │
           ▼                           ▼
    Payment Authorized          Show Error
    Return to App               Message
                                  │
                                  ▼
                             [Retry Payment]
                                  │
                          ┌───────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Flask Backend API                              │
│                                                                   │
│  Endpoint: POST /api/payments/razorpay/verify                   │
│  - Receive: razorpay_order_id, payment_id, signature            │
│  - Call RazorpayService.verify_payment_signature()              │
│  - Verify HMAC-SHA256 signature                                 │
│  - Verify amount matches                                        │
│  - Update Payment status = "completed"                          │
│  - Update Order status = "paid"                                 │
│  - Send success notification                                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Flutter App (Success)                          │
│                                                                   │
│  - Show: "Payment Successful!"                                  │
│  - Display: Order confirmation                                  │
│  - Navigate: To order details                                   │
│  - Notify: User via in-app + email                              │
└─────────────────────────────────────────────────────────────────┘
```

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                       FRONTEND LAYER                            │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Flutter App                                            │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ MedicinePaymentScreen                              │ │  │
│  │  │ - Display medicine order details                   │ │  │
│  │  │ - Amount: ₹X.XX                                    │ │  │
│  │  │ - [Pay Now] Button                                 │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  │  ┌────────▼───────────────────────────────────────────┐ │  │
│  │  │ LabTestPaymentScreen                               │ │  │
│  │  │ - Display lab test order details                   │ │  │
│  │  │ - Amount: ₹Y.YY                                    │ │  │
│  │  │ - [Pay Now] Button                                 │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  │  ┌────────▼───────────────────────────────────────────┐ │  │
│  │  │ Razorpay Checkout Modal (SDK)                      │ │  │
│  │  │ - Payment method selection                         │ │  │
│  │  │ - Card/UPI entry                                   │ │  │
│  │  │ - OTP verification                                 │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  └────────────┼───────────────────────────────────────────┘  │
│               │                                                │
└───────────────┼────────────────────────────────────────────────┘
                │ HTTP/HTTPS
        ┌───────▼────────┐
        │  API Requests  │
        └────────────────┘
                │
┌───────────────▼────────────────────────────────────────────────┐
│                    BACKEND LAYER                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ Flask Application (Python)                              │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ payments.py Routes                                 │ │  │
│  │  │ POST /api/payments/razorpay/create-order          │ │  │
│  │  │ POST /api/payments/razorpay/verify                │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  │  ┌────────▼───────────────────────────────────────────┐ │  │
│  │  │ RazorpayService (payment_service.py)              │ │  │
│  │  │ - create_order(amount, receipt, notes)            │ │  │
│  │  │ - verify_payment_signature(order_id, pay_id, sig) │ │  │
│  │  │ - fetch_payment(payment_id)                        │ │  │
│  │  │ - capture_payment(payment_id, amount)             │ │  │
│  │  │ - refund_payment(payment_id, amount, notes)       │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  │  ┌────────▼───────────────────────────────────────────┐ │  │
│  │  │ Payment Model (SQLAlchemy ORM)                     │ │  │
│  │  │ - id, user_id, amount, payment_status             │ │  │
│  │  │ - razorpay_order_id, payment_id                   │ │  │
│  │  │ - razorpay_signature, razorpay_receipt            │ │  │
│  │  └────────┬───────────────────────────────────────────┘ │  │
│  └────────────┼───────────────────────────────────────────┘  │
│               │                                                │
└───────────────┼────────────────────────────────────────────────┘
                │ Database
        ┌───────▼────────┐
        │ PostgreSQL DB  │
        │ payments table │
        └────────────────┘
                │
                ▼ (Also)
┌────────────────────────────────────────────────────────────────┐
│               RAZORPAY GATEWAY LAYER                           │
│                                                                │
│  Razorpay API                                                  │
│  └─ Authenticate with API Key & Secret                        │
│  └─ Create orders                                              │
│  └─ Verify payments                                            │
│  └─ Process refunds                                            │
│  └─ Fetch transaction details                                  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Class Diagram

```
┌─────────────────────────────┐
│      User (JWT)             │
├─────────────────────────────┤
│ - id                        │
│ - email                     │
│ - role                      │
│ - payments (relationship)   │
└─────────────────────────────┘
            │
            │ has many
            │
┌─────────────────────────────┐
│     Payment                 │
├─────────────────────────────┤
│ - id                        │
│ - user_id (FK)              │
│ - amount                    │
│ - payment_status            │
│ - related_type              │
│ - related_id                │
│ - razorpay_order_id         │
│ - razorpay_payment_id       │
│ - razorpay_signature        │
│ - razorpay_receipt          │
│ - created_at                │
│ - updated_at                │
└─────────────────────────────┘
            │
            │ polymorphic relation
            ├──────────────┬───────────────┐
            │              │               │
            ▼              ▼               ▼
┌──────────────────┐ ┌──────────────────┐
│ MedicineOrder    │ │ LabTestOrder     │
├──────────────────┤ ├──────────────────┤
│ - id             │ │ - id             │
│ - patient_id     │ │ - patient_id     │
│ - items[]        │ │ - test_type      │
│ - delivery_type  │ │ - payment_status │
│ - delivery_otp   │ │ - appointment_date│
│ - payment_status │ │ - delivery_addr  │
└──────────────────┘ └──────────────────┘
```

## Data Flow Sequence

```
Medicine Order Payment Flow:
─────────────────────────────

User              Frontend         Backend         Razorpay
 │                   │                │               │
 │  Click "Pay"      │                │               │
 ├──────────────────►│                │               │
 │                   │ POST create-order              │
 │                   ├──────────────►│                │
 │                   │                │ create_order()│
 │                   │                ├──────────────►│
 │                   │                │◄──────────────┤
 │                   │                │ order_id      │
 │                   │◄────────────────┤               │
 │                   │ razorpay_key    │               │
 │ Open Checkout    │                │               │
 │◄───────────────────┤                │               │
 │                   │  Open Modal                    │
 │ Select payment    │                │               │
 │ method & confirm  │                │               │
 │                   │                │               │
 │ Complete payment  ├──────────────►Razorpay SDK    │
 ├──────────────────►│                │  ┌───────────┤
 │                   │                │  │ Process   │
 │ Payment complete  │                │  │ payment   │
 │◄────────────────────┤                │  │           │
 │ payment_id, sig    │ POST verify    │  └───────────┤
 │                   ├──────────────►│                │
 │                   │                │ verify_sig()  │
 │                   │                ├──────────────►│
 │                   │                │◄──────────────┤
 │                   │                │ Valid         │
 │                   │ Success        │                │
 │                   │◄────────────────┤                │
 │ Show success      │                │                │
 │◄────────────────────┤                │                │
 │ Order updated     │                │                │
```

## Payment Status State Machine

```
                    ┌──────────┐
                    │  PENDING │
                    │(no order)│
                    └────┬─────┘
                         │
                    Create Order
                         │
                         ▼
                    ┌──────────┐
                    │INITIATED │
                    │(awaiting)│
                    └────┬─────┘
                         │
           ┌─────────────┴──────────────┐
           │                            │
      User Pays                   Timeout (optional)
           │                            │
           ▼                            ▼
    ┌──────────┐                  ┌──────────┐
    │ COMPLETED│                  │  FAILED  │
    │  (paid)  │                  │ (expired)│
    └──────────┘                  └──────────┘
         │                              │
    Order ships                    Show retry
    Notification sent              option


Request/Response Cycle:

1. Create Order Request
   ↓
   Backend validates user
   ↓
   Backend calls Razorpay
   ↓
   Razorpay creates order (status: created)
   ↓
   Return order_id to frontend
   ↓
   
2. User completes payment
   ↓
   Razorpay processes payment
   ↓
   Razorpay returns payment_id & signature
   ↓
   
3. Verify Payment Request
   ↓
   Backend verifies signature
   ↓
   Backend verifies amount
   ↓
   Backend updates Payment model
   ↓
   Backend sends notification
   ↓
   Return success to frontend
```

## Error Handling Flow

```
Payment Request
      │
      ▼
┌──────────────┐
│  Validate    │
│ Credentials  │
└──┬───────┬──┘
   │ OK    │ Error
   │       └─► "Service not configured"
   ▼
┌──────────────┐
│  Verify User │
│ Authorization│
└──┬───────┬──┘
   │ OK    │ Error
   │       └─► "Unauthorized"
   ▼
┌──────────────┐
│  Verify Order│
│  Ownership   │
└──┬───────┬──┘
   │ OK    │ Error
   │       └─► "Order not found"
   ▼
┌──────────────┐
│Create Order  │
│  in Razorpay │
└──┬───────┬──┘
   │ OK    │ Error
   │       └─► Show retry
   ▼
┌──────────────┐
│  User Pays   │
│   (Frontend) │
└──┬───────┬──┘
   │ OK    │ Failed/Cancelled
   │       └─► Show error, allow retry
   ▼
┌──────────────┐
│ Verify Sig   │
│  (Backend)   │
└──┬───────┬──┘
   │ OK    │ Invalid
   │       └─► "Payment tampered"
   ▼
┌──────────────┐
│ Update DB    │
│   & Notify   │
└──┬───────┬──┘
   │ OK    │ Error
   │       └─► Log error, retry
   ▼
Success!
```

---

**Generated**: May 2026  
**Version**: 1.0.0
