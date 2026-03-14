# Database Queries and Management Guide

## Database Connection

### Access Database (Development)
```bash
cd backend
source venv/bin/activate
python -c "from app import create_app, db; app = create_app(); app.app_context().push(); print('Database connected')"
```

### SQLite Command Line
```bash
sqlite3 instance/medical_app.db
```

### Database Schema Information
```sql
-- List all tables
.tables

-- Show table structure
.schema users
.schema patients
.schema doctors
.schema appointments

-- Show all table schemas
.schema
```

## User Management Queries

### View All Users
```sql
SELECT 
    u.id, 
    u.email, 
    u.role, 
    u.created_at, 
    u.is_active,
    CASE 
        WHEN u.role = 'patient' THEN p.name
        WHEN u.role = 'doctor' THEN d.name
        WHEN u.role = 'medical_store' THEN ms.name
        WHEN u.role = 'lab_store' THEN ls.name
        ELSE 'N/A'
    END as name
FROM users u
LEFT JOIN patients p ON u.id = p.user_id
LEFT JOIN doctors d ON u.id = d.user_id
LEFT JOIN medical_stores ms ON u.id = ms.user_id
LEFT JOIN lab_stores ls ON u.id = ls.user_id
ORDER BY u.created_at DESC;
```

### Find User by Email or Phone
```sql
-- By email
SELECT * FROM users WHERE email = 'user@example.com';

-- By phone (search in patient and doctor tables)
SELECT u.*, p.phone as patient_phone 
FROM users u 
JOIN patients p ON u.id = p.user_id 
WHERE p.phone = '1234567890'
UNION
SELECT u.*, d.phone as doctor_phone 
FROM users u 
JOIN doctors d ON u.id = d.user_id 
WHERE d.phone = '1234567890';
```

### User Role Statistics
```sql
SELECT 
    role,
    COUNT(*) as user_count,
    COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_users
FROM users 
GROUP BY role
ORDER BY user_count DESC;
```

### Recent Registrations
```sql
SELECT 
    u.email, 
    u.role, 
    u.created_at,
    CASE 
        WHEN u.role = 'patient' THEN p.name
        WHEN u.role = 'doctor' THEN d.name
    END as name
FROM users u
LEFT JOIN patients p ON u.id = p.user_id
LEFT JOIN doctors d ON u.id = d.user_id
WHERE u.created_at >= datetime('now', '-7 days')
ORDER BY u.created_at DESC;
```

## Patient Management Queries

### Patient Details with Medical History
```sql
SELECT 
    p.*,
    u.email,
    u.created_at as registration_date,
    COUNT(DISTINCT a.id) as total_appointments,
    COUNT(DISTINCT mo.id) as total_medicine_orders,
    COUNT(DISTINCT lto.id) as total_lab_orders
FROM patients p
JOIN users u ON p.user_id = u.id
LEFT JOIN appointments a ON p.id = a.patient_id
LEFT JOIN medicine_orders mo ON p.id = mo.patient_id
LEFT JOIN lab_test_orders lto ON p.id = lto.patient_id
WHERE p.id = ?  -- Replace with patient ID
GROUP BY p.id;
```

### Patients by Age Group
```sql
SELECT 
    CASE 
        WHEN (julianday('now') - julianday(date_of_birth))/365 < 18 THEN 'Under 18'
        WHEN (julianday('now') - julianday(date_of_birth))/365 BETWEEN 18 AND 35 THEN '18-35'
        WHEN (julianday('now') - julianday(date_of_birth))/365 BETWEEN 36 AND 60 THEN '36-60'
        ELSE 'Over 60'
    END as age_group,
    COUNT(*) as patient_count
FROM patients 
WHERE date_of_birth IS NOT NULL
GROUP BY age_group;
```

## Doctor Management Queries

### Doctor Statistics
```sql
SELECT 
    d.*,
    u.email,
    COUNT(DISTINCT a.id) as total_appointments,
    COUNT(DISTINCT c.id) as total_chambers,
    AVG(a.consultation_fee) as avg_consultation_fee
FROM doctors d
JOIN users u ON d.user_id = u.id
LEFT JOIN appointments a ON d.id = a.doctor_id
LEFT JOIN chambers c ON d.id = c.doctor_id
GROUP BY d.id
ORDER BY total_appointments DESC;
```

### Doctors by Specialization
```sql
SELECT 
    specialization,
    COUNT(*) as doctor_count,
    AVG(consultation_fee) as avg_fee,
    MIN(consultation_fee) as min_fee,
    MAX(consultation_fee) as max_fee
FROM doctors 
GROUP BY specialization
ORDER BY doctor_count DESC;
```

## Appointment Queries

### Today's Appointments
```sql
SELECT 
    a.*,
    p.name as patient_name,
    p.phone as patient_phone,
    d.name as doctor_name,
    c.name as chamber_name,
    c.address as chamber_address
FROM appointments a
JOIN patients p ON a.patient_id = p.id
JOIN doctors d ON a.doctor_id = d.id
JOIN chambers c ON a.chamber_id = c.id
WHERE date(a.appointment_date) = date('now')
ORDER BY a.appointment_time;
```

### Appointment Statistics by Status
```sql
SELECT 
    status,
    COUNT(*) as appointment_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments) as percentage
FROM appointments 
GROUP BY status
ORDER BY appointment_count DESC;
```

### Monthly Appointment Trends
```sql
SELECT 
    strftime('%Y-%m', appointment_date) as month,
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled
FROM appointments 
WHERE appointment_date >= date('now', '-12 months')
GROUP BY month
ORDER BY month;
```

## Medicine Order Queries

### Recent Medicine Orders
```sql
SELECT 
    mo.*,
    p.name as patient_name,
    ms.name as store_name,
    COUNT(moi.id) as total_items
FROM medicine_orders mo
JOIN patients p ON mo.patient_id = p.id
JOIN medical_stores ms ON mo.store_id = ms.id
LEFT JOIN medicine_order_items moi ON mo.id = moi.order_id
WHERE mo.created_at >= datetime('now', '-7 days')
GROUP BY mo.id
ORDER BY mo.created_at DESC;
```

### Revenue by Medical Store
```sql
SELECT 
    ms.name as store_name,
    COUNT(mo.id) as total_orders,
    SUM(mo.total_amount) as total_revenue,
    AVG(mo.total_amount) as avg_order_value,
    COUNT(CASE WHEN mo.status = 'delivered' THEN 1 END) as delivered_orders
FROM medical_stores ms
LEFT JOIN medicine_orders mo ON ms.id = mo.store_id
GROUP BY ms.id
ORDER BY total_revenue DESC;
```

### Top Selling Medicines
```sql
SELECT 
    m.name as medicine_name,
    m.category,
    SUM(moi.quantity) as total_quantity_sold,
    COUNT(DISTINCT moi.order_id) as total_orders,
    SUM(moi.quantity * moi.price) as total_revenue
FROM medicines m
JOIN medicine_order_items moi ON m.id = moi.medicine_id
JOIN medicine_orders mo ON moi.order_id = mo.id
WHERE mo.status = 'delivered'
GROUP BY m.id
ORDER BY total_quantity_sold DESC
LIMIT 10;
```

## Lab Test Queries

### Lab Test Orders Summary
```sql
SELECT 
    lto.*,
    p.name as patient_name,
    ls.name as lab_name,
    COUNT(ltoi.id) as total_tests
FROM lab_test_orders lto
JOIN patients p ON lto.patient_id = p.id
JOIN lab_stores ls ON lto.lab_id = ls.id
LEFT JOIN lab_test_order_items ltoi ON lto.id = ltoi.order_id
GROUP BY lto.id
ORDER BY lto.created_at DESC;
```

### Popular Lab Tests
```sql
SELECT 
    lt.name as test_name,
    lt.category,
    COUNT(ltoi.id) as times_ordered,
    AVG(ltoi.price) as avg_price,
    ls.name as lab_name
FROM lab_tests lt
JOIN lab_test_order_items ltoi ON lt.id = ltoi.test_id
JOIN lab_test_orders lto ON ltoi.order_id = lto.id
JOIN lab_stores ls ON lt.lab_id = ls.id
GROUP BY lt.id
ORDER BY times_ordered DESC
LIMIT 10;
```

## Notification Queries

### Unread Notifications by User
```sql
SELECT 
    u.email,
    u.role,
    COUNT(n.id) as unread_count,
    MIN(n.created_at) as oldest_unread
FROM users u
JOIN notifications n ON u.id = n.user_id
WHERE n.is_read = 0
GROUP BY u.id
ORDER BY unread_count DESC;
```

### Notification Types Statistics
```sql
SELECT 
    notification_type,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN is_read = 1 THEN 1 END) as read_count,
    COUNT(CASE WHEN is_read = 0 THEN 1 END) as unread_count,
    (COUNT(CASE WHEN is_read = 1 THEN 1 END) * 100.0 / COUNT(*)) as read_percentage
FROM notifications 
GROUP BY notification_type
ORDER BY total_notifications DESC;
```

## System Analytics Queries

### Daily Active Users (Last 30 Days)
```sql
SELECT 
    date(created_at) as date,
    COUNT(DISTINCT user_id) as active_users
FROM notifications 
WHERE created_at >= datetime('now', '-30 days')
GROUP BY date(created_at)
ORDER BY date;
```

### Revenue Summary
```sql
SELECT 
    'Medicine Orders' as revenue_source,
    SUM(total_amount) as total_revenue,
    COUNT(*) as total_orders,
    AVG(total_amount) as avg_order_value
FROM medicine_orders 
WHERE status = 'delivered'
UNION ALL
SELECT 
    'Lab Tests' as revenue_source,
    SUM(total_amount) as total_revenue,
    COUNT(*) as total_orders,
    AVG(total_amount) as avg_order_value
FROM lab_test_orders 
WHERE status = 'completed';
```

## Database Maintenance

### Clean Up Old Notifications (Older than 90 days)
```sql
DELETE FROM notifications 
WHERE is_read = 1 
AND created_at < datetime('now', '-90 days');
```

### Update User Last Active
```sql
-- Create trigger to update last_active on login
CREATE TRIGGER update_last_active 
AFTER INSERT ON notifications 
FOR EACH ROW
BEGIN
    UPDATE users 
    SET updated_at = datetime('now') 
    WHERE id = NEW.user_id;
END;
```

### Index Creation for Performance
```sql
-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_medicine_orders_status ON medicine_orders(status);
CREATE INDEX IF NOT EXISTS idx_lab_orders_status ON lab_test_orders(status);
```

### Database Backup
```bash
# SQLite backup
sqlite3 instance/medical_app.db ".backup backup_$(date +%Y%m%d_%H%M%S).db"

# Export to SQL
sqlite3 instance/medical_app.db ".dump" > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Database Restore
```bash
# Restore from backup
cp backup_20251228_120000.db instance/medical_app.db

# Restore from SQL dump
sqlite3 instance/medical_app.db < backup_20251228_120000.sql
```

## Troubleshooting

### Check Database Integrity
```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

### View Database Size
```sql
SELECT 
    name as table_name,
    COUNT(*) as row_count
FROM sqlite_master 
CROSS JOIN pragma_table_info(sqlite_master.name) 
WHERE type='table' 
GROUP BY name;
```

### Lock Information
```sql
PRAGMA locking_mode;
PRAGMA journal_mode;
```

### Performance Analysis
```sql
-- Enable query plan analysis
EXPLAIN QUERY PLAN 
SELECT * FROM appointments 
WHERE appointment_date = '2025-12-28';
```

## Migration Commands

```bash
# Initialize migrations
flask db init

# Create new migration
flask db migrate -m "Add new field to users table"

# Apply migrations
flask db upgrade

# Revert migration
flask db downgrade

# View migration history
flask db history

# View current revision
flask db current
```
