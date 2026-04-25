"""
Utility function to check and handle order timeouts
This should be called periodically (e.g., via a cron job or scheduler)
"""
from app import db
from app.models.medicine import MedicineOrder
from app.models.user import MedicalStore, Patient
from app.models.notification import Notification
from datetime import datetime, timedelta
import json


def check_order_timeouts():
    """
    Check all pending orders with current_store_id set
    If timeout has passed, route to next store or mark as unfulfilled
    """
    # Get all pending orders that have a current store assigned
    pending_orders = MedicineOrder.query.filter(
        MedicineOrder.status == 'pending',
        MedicineOrder.current_store_id.isnot(None),
        MedicineOrder.current_offer_time.isnot(None)
    ).all()
    
    timeout_count = 0
    
    for order in pending_orders:
        # Calculate timeout
        timeout_minutes = order.timeout_minutes or 5
        timeout_time = order.current_offer_time + timedelta(minutes=timeout_minutes)
        
        # Check if timeout has passed
        if datetime.utcnow() >= timeout_time:
            timeout_count += 1
            
            # Get list of stores already offered
            offered_stores = json.loads(order.offered_to_stores) if order.offered_to_stores else []
            
            # Get next store alphabetically that hasn't been offered yet
            next_store = MedicalStore.query.filter(
                MedicalStore.id.notin_(offered_stores)
            ).order_by(MedicalStore.name).first()
            
            if next_store:
                # Route to next store
                offered_stores.append(next_store.id)
                order.current_store_id = next_store.id
                order.offered_to_stores = json.dumps(offered_stores)
                order.current_offer_time = datetime.utcnow()
                
                # Notify the next store
                notification = Notification(
                    user_id=next_store.user_id,
                    patient_id=order.patient_id,
                    title='New Medicine Order',
                    message=f'New order #{order.id}. Total: ₹{order.total_amount:.2f}. Please respond within {timeout_minutes} minutes.',
                    notification_type='medicine_order',
                    related_id=order.id
                )
                db.session.add(notification)
                
                print(f"Order #{order.id} timeout - routed to {next_store.name}")
                
            else:
                # No more stores available
                order.status = 'no_stores_available'
                order.current_store_id = None
                order.current_offer_time = None
                
                # Notify patient that no stores are available
                patient = Patient.query.get(order.patient_id)
                if patient:
                    notification = Notification(
                        user_id=patient.user_id,
                        patient_id=patient.id,
                        title='Order Could Not Be Fulfilled',
                        message=f'Sorry, no medical stores are available to fulfill order #{order.id}',
                        notification_type='order_update',
                        related_id=order.id
                    )
                    db.session.add(notification)
                
                print(f"Order #{order.id} timeout - no more stores available")
    
    # Commit all changes
    if timeout_count > 0:
        db.session.commit()
        print(f"Processed {timeout_count} timed out orders")
    
    return timeout_count


def get_pending_orders_with_timeout():
    """
    Get all pending orders with their remaining timeout
    Useful for dashboard/monitoring
    """
    pending_orders = MedicineOrder.query.filter(
        MedicineOrder.status == 'pending',
        MedicineOrder.current_store_id.isnot(None),
        MedicineOrder.current_offer_time.isnot(None)
    ).all()
    
    orders_with_timeout = []
    
    for order in pending_orders:
        timeout_minutes = order.timeout_minutes or 5
        timeout_time = order.current_offer_time + timedelta(minutes=timeout_minutes)
        remaining_seconds = (timeout_time - datetime.utcnow()).total_seconds()
        
        orders_with_timeout.append({
            'order_id': order.id,
            'current_store_id': order.current_store_id,
            'timeout_time': timeout_time.isoformat(),
            'remaining_seconds': max(0, int(remaining_seconds)),
            'is_expired': remaining_seconds <= 0
        })
    
    return orders_with_timeout
