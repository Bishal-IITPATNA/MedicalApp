# Delivery Charges Implementation Guide

## Overview
This document describes the delivery charges feature added to the medicine order system. Delivery charges are calculated based on the total order amount (including GST) and are transparently displayed to users.

## Delivery Charges Formula

### Calculation Rules
The delivery charges are calculated based on the total order amount (subtotal + GST):

```
if total_amount_with_gst < Rs 500:
    delivery_charges = Rs 50 (flat)
else:
    delivery_charges = 10% of total_amount_with_gst
```

### Example Calculations

**Example 1: Order Total < Rs 500**
- Subtotal: Rs 300
- GST (5%): Rs 15
- Total with GST: Rs 315 (< 500)
- Delivery Charges: **Rs 50** (flat)
- Final Total: Rs 365

**Example 2: Order Total ≥ Rs 500**
- Subtotal: Rs 1000
- GST (5%): Rs 50
- Total with GST: Rs 1050 (≥ 500)
- Delivery Charges: **10% of 1050 = Rs 105**
- Final Total: Rs 1155

## Implementation Details

### 1. Backend Changes

#### Medicine Model (`backend/app/models/medicine.py`)
- **MedicineOrder**: Added fields
  - `subtotal_amount` (Float): Sum of medicine prices before GST
  - `gst_amount` (Float): 5% tax on subtotal
  - `delivery_charges` (Float): Calculated delivery charges
  - `total_amount` (Float): Final amount including all charges

- **MedicineBill**: Added field
  - `delivery_charges` (Float): Delivery charges from the order

#### Helper Function (`backend/app/routes/patient.py`)
```python
def calculate_delivery_charges(total_with_gst):
    """
    Calculate delivery charges based on total amount (inclusive of GST)
    Rules:
    - If total < Rs 500: flat Rs 50
    - If total >= Rs 500: 10% of total
    """
    if total_with_gst < 500:
        return 50.0
    else:
        return round(total_with_gst * 0.10, 2)
```

#### Order Creation Endpoint (`/api/patient/medicine-orders` POST)
Updated to:
1. Calculate subtotal from medicine items
2. Calculate GST as 5% of subtotal
3. Calculate delivery charges using the formula
4. Store all values in the MedicineOrder record
5. Return breakdown to frontend

**Request**: No changes to request format
**Response**: Enhanced with breakdown details
```json
{
  "success": true,
  "message": "Order placed successfully",
  "order": {
    "id": 1,
    "subtotal_amount": 300,
    "gst_amount": 15,
    "delivery_charges": 50,
    "total_amount": 365,
    ...
  },
  "breakdown": {
    "subtotal": 300,
    "gst": 15,
    "delivery_charges": 50,
    "total": 365
  }
}
```

#### Bill Generation Endpoint (`/api/medical-store/orders/<id>/verify-otp` POST)
Updated to:
1. Extract pre-calculated subtotal, GST, and delivery charges from order
2. Use these values in the bill (instead of recalculating)
3. Generate bill total including delivery charges

### 2. Database Migration

File: `backend/migrations/versions/add_delivery_charges_to_medicine_orders.py`

Adds columns:
- `medicine_order.subtotal_amount` (Float, default 0.0)
- `medicine_order.gst_amount` (Float, default 0.0)
- `medicine_order.delivery_charges` (Float, default 0.0)
- `medicine_bill.delivery_charges` (Float, default 0.0)

### 3. Frontend Changes

#### Medicine Payment Screen (`medicine_payment_screen.dart`)
Enhanced to display price breakdown:
- Subtotal amount
- GST (5%)
- Delivery Charges
- **Total Amount**

Price breakdown is displayed in a dedicated card section with clear labels and values.

## API Endpoints Summary

### GET `/api/patient/medicine-orders`
Returns list of orders with delivery charges included in each order object.

### POST `/api/patient/medicine-orders`
Creates new medicine order with delivery charges calculated.
- Subtotal calculated from items
- GST calculated as 5% of subtotal
- Delivery charges calculated based on formula
- All values stored in database

**Response includes**:
```json
{
  "breakdown": {
    "subtotal": <number>,
    "gst": <number>,
    "delivery_charges": <number>,
    "total": <number>
  }
}
```

### POST `/api/payments/razorpay/create-order`
Payment amount now automatically reflects total_amount (with delivery charges).

### POST `/api/medical-store/orders/<id>/verify-otp`
Bill generation now includes:
- Subtotal from order
- GST from order
- Delivery charges from order
- Correctly calculated total

## Deployment Steps

1. **Create Database Migration**
   ```bash
   flask db upgrade
   ```

2. **Verify Models**
   - Check MedicineOrder model has all new fields
   - Check MedicineBill model has delivery_charges field

3. **Test Order Creation**
   - Create test order with items
   - Verify subtotal, GST, delivery charges calculated correctly
   - Verify response includes breakdown

4. **Test Bill Generation**
   - Verify OTP submission generates bill with delivery charges
   - Verify total_amount matches order total

5. **Test Payment Flow**
   - Verify payment amount includes delivery charges
   - Verify payment status updated correctly

## Edge Cases Handled

1. **Zero-price orders**: delivery_charges calculated as Rs 50
2. **Rounding**: All amounts rounded to 2 decimal places
3. **Order with single low-cost item**: delivery_charges = Rs 50
4. **Large orders**: delivery_charges = 10% of total

## Backward Compatibility

- Existing orders without delivery charges will have `delivery_charges = null` or default to 0
- All new orders created after migration will have proper delivery charges
- Payment endpoints work with both old and new order formats

## Testing Scenarios

### Scenario 1: Small Order
- Add 1 medicine: Rs 200
- Expected subtotal: Rs 200
- Expected GST: Rs 10
- Expected delivery: Rs 50 (flat, total is 210 < 500)
- Expected total: Rs 260

### Scenario 2: Medium Order  
- Add medicines totaling: Rs 400
- Expected subtotal: Rs 400
- Expected GST: Rs 20
- Expected delivery: Rs 50 (flat, total is 420 < 500)
- Expected total: Rs 470

### Scenario 3: Large Order
- Add medicines totaling: Rs 1000
- Expected subtotal: Rs 1000
- Expected GST: Rs 50
- Expected delivery: Rs 105 (10% of 1050, total is 1050 ≥ 500)
- Expected total: Rs 1155

## Future Enhancements

1. **Dynamic delivery charges by location**: Different rates for different areas
2. **Promo codes**: Apply discount to delivery charges
3. **Free delivery**: Threshold-based free delivery
4. **Express delivery**: Premium option with higher charges
5. **Delivery partner tracking**: Real-time tracking with delivery confirmation

## Support & Troubleshooting

### Issue: Delivery charges not showing
- **Check**: Migration has been run
- **Check**: MedicineOrder model has all fields
- **Verify**: Order creation endpoint is calculating charges

### Issue: Incorrect delivery charges
- **Verify**: calculate_delivery_charges() function logic
- **Check**: Subtotal calculation includes all items
- **Check**: GST calculation is 5% of subtotal

### Issue: Bill total mismatch
- **Verify**: Bill uses order's pre-calculated values
- **Check**: delivery_charges is included in bill total

---

**Version**: 1.0
**Last Updated**: December 2024
**Status**: Production Ready
