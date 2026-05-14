# Razorpay Payment Integration - Deployment Checklist

## Pre-Deployment (Development Setup)

### 1. Environment Configuration
- [ ] Copy `.env.example` to `.env`
- [ ] Get Razorpay Test credentials from https://dashboard.razorpay.com/settings/api-keys
- [ ] Add `RAZORPAY_KEY_ID=rzp_test_xxxxx` to `.env`
- [ ] Add `RAZORPAY_KEY_SECRET=xxxxx` to `.env`
- [ ] Verify `.env` is in `.gitignore` (never commit credentials)

### 2. Backend Setup
- [ ] `pip install -r backend/requirements.txt` (installs razorpay==1.3.0)
- [ ] Run migrations:
  ```bash
  cd backend
  flask db migrate -m "Add Razorpay payment fields"
  flask db upgrade
  ```
- [ ] Verify migrations completed successfully
- [ ] Start backend: `python application.py`
- [ ] Check for errors in logs

### 3. Frontend Setup
- [ ] `cd .flutter_app && flutter pub get`
- [ ] Verify no build errors
- [ ] Check iOS/Android specific Razorpay setup (if needed)
- [ ] Run app: `flutter run`

### 4. Testing (Development)

#### 4.1 API Testing
- [ ] Test order creation endpoint
  ```bash
  python backend/razorpay_test.py --test-create-order --amount 500
  ```
- [ ] Response should include `razorpay_order_id`, `razorpay_key`, `amount`
- [ ] Get payment history
  ```bash
  python backend/razorpay_test.py --test-get-payments
  ```

#### 4.2 UI Testing
- [ ] Open medicine purchase screen
- [ ] Click "Pay Now" button
- [ ] Verify Razorpay modal opens
- [ ] Test with test card: `4111 1111 1111 1111`
- [ ] Complete payment in modal
- [ ] Verify success screen appears
- [ ] Check order status updated to "paid"
- [ ] Verify notification received

#### 4.3 Lab Test Payment Testing
- [ ] Book a lab test
- [ ] Click "Pay Now" button
- [ ] Verify payment screen opens with test details
- [ ] Complete test payment
- [ ] Verify success confirmation

#### 4.4 Error Handling Testing
- [ ] Test declined card: `4000 0000 0000 0002`
- [ ] Verify error message displays
- [ ] Test cancel payment in modal
- [ ] Verify app handles cancellation
- [ ] Test network error scenarios
- [ ] Verify retry mechanism works

## Staging Deployment

### 5. Staging Environment Setup
- [ ] Deploy backend to staging server
- [ ] Update staging `.env` with test Razorpay credentials
- [ ] Run database migrations on staging
- [ ] Deploy Flutter app to staging (TestFlight/Google Play Console)
- [ ] Update API endpoints in Flutter if needed

### 6. Staging Testing
- [ ] Complete end-to-end payment flow
- [ ] Test all payment methods:
  - [ ] Credit Card
  - [ ] Debit Card
  - [ ] UPI (use test UPI: success@razorpay)
  - [ ] Net Banking
  - [ ] Wallet
- [ ] Test error scenarios
- [ ] Monitor backend logs for issues
- [ ] Check notification emails

### 7. Staging Validation
- [ ] Verify payment data in database
  ```sql
  SELECT * FROM payments ORDER BY created_at DESC LIMIT 5;
  ```
- [ ] Check Razorpay dashboard for transactions
- [ ] Verify all payment fields stored correctly
- [ ] Confirm signature verification working
- [ ] Test refund functionality

## Production Deployment

### 8. Production Environment Preparation
- [ ] Get production Razorpay credentials
- [ ] Create backup of production database
- [ ] Plan deployment during low-traffic time
- [ ] Notify support team of deployment

### 9. Production Environment Configuration
- [ ] Update `.env` with production Razorpay credentials:
  - `RAZORPAY_KEY_ID=rzp_live_xxxxx`
  - `RAZORPAY_KEY_SECRET=xxxxx`
- [ ] Verify environment variables in production
- [ ] Set up error monitoring (Sentry/similar)
- [ ] Configure payment notification emails

### 10. Production Database Migrations
- [ ] Backup production database:
  ```bash
  pg_dump medicalapp > medicalapp_backup_$(date +%Y%m%d).sql
  ```
- [ ] Run migrations:
  ```bash
  flask db upgrade
  ```
- [ ] Verify migrations successful
- [ ] Test payment queries work

### 11. Production Backend Deployment
- [ ] Deploy updated backend code
- [ ] Verify all services started:
  ```bash
  systemctl status medical-app-backend
  curl https://api.medicalapp.com/health
  ```
- [ ] Check backend logs for errors
- [ ] Test API endpoints accessible
- [ ] Verify HTTPS certificates valid

### 12. Production Frontend Deployment
- [ ] Build production Flutter release:
  ```bash
  flutter build apk --release  # Android
  flutter build ios --release  # iOS
  ```
- [ ] Submit to Google Play Store / App Store
- [ ] Wait for app store approval (Google: 2-4 hours, Apple: 1-3 days)
- [ ] Monitor app crash reports

### 13. Production Testing & Validation
- [ ] Download production app from app stores
- [ ] Test complete payment flow with live credentials
- [ ] Test with real payment methods (use small amount)
- [ ] Verify payment appears in Razorpay dashboard
- [ ] Confirm order status updates correctly
- [ ] Check notification emails sent
- [ ] Verify database entries correct

### 14. Post-Deployment Monitoring

#### 14.1 First Hour
- [ ] Monitor backend error logs
- [ ] Track payment success rate
- [ ] Check for API timeouts
- [ ] Monitor database performance
- [ ] Be on-call for issues

#### 14.2 First Day
- [ ] Review all payment transactions
- [ ] Check user feedback/complaints
- [ ] Verify notifications working
- [ ] Monitor system performance
- [ ] Document any issues

#### 14.3 First Week
- [ ] Analyze payment conversion rates
- [ ] Review failed payment reasons
- [ ] Check user success feedback
- [ ] Document lessons learned
- [ ] Plan improvements

## Rollback Plan (If Issues Occur)

### Immediate Actions
- [ ] Stop processing new payments
- [ ] Notify users via in-app banner
- [ ] Create backup of current state
- [ ] Document error details

### Rollback Steps
1. [ ] Revert payment endpoints to old version (if compatible)
2. [ ] Restore previous `.env` (disable Razorpay)
3. [ ] Restart backend services
4. [ ] Redeploy previous Flutter version
5. [ ] Notify users of temporary maintenance

### Post-Rollback
- [ ] Investigate root cause
- [ ] Fix issue in development
- [ ] Re-test thoroughly in staging
- [ ] Plan second deployment

## Documentation & Communication

### 15. Documentation Updates
- [ ] Update API documentation with new endpoints
- [ ] Document payment status meanings
- [ ] Create user FAQ for payment issues
- [ ] Document support procedures for payment issues
- [ ] Update deployment runbook

### 16. Team Communication
- [ ] Brief support team on Razorpay integration
- [ ] Share testing procedures
- [ ] Provide Razorpay dashboard access
- [ ] Schedule support training session
- [ ] Create incident response plan

### 17. User Communication
- [ ] Email users about new payment feature
- [ ] Update app store descriptions
- [ ] Create in-app announcement
- [ ] Post about new feature on social media

## Security Verification

### 18. Security Checklist
- [ ] API keys never logged or exposed
- [ ] Signature verification working correctly
- [ ] HTTPS enforced for all payment endpoints
- [ ] User authorization validated
- [ ] Order ownership verified before payment
- [ ] Amount verification preventing tampering
- [ ] Rate limiting enabled on payment endpoints
- [ ] Database credentials secured
- [ ] SSL/TLS certificates valid
- [ ] CORS properly configured

## Maintenance & Operations

### 19. Ongoing Maintenance
- [ ] Daily: Monitor payment success rate
- [ ] Daily: Check error logs
- [ ] Weekly: Review payment trends
- [ ] Monthly: Reconcile with Razorpay dashboard
- [ ] Monthly: Review failed transactions
- [ ] Quarterly: Security audit

### 20. Performance Optimization
- [ ] Monitor payment API response times
- [ ] Check database query performance
- [ ] Optimize Razorpay API calls
- [ ] Cache frequently accessed data
- [ ] Monitor network throughput

## Compliance & Auditing

### 21. Compliance Checklist
- [ ] Ensure PCI-DSS compliance (handled by Razorpay)
- [ ] Validate data protection compliance
- [ ] Document payment processing policies
- [ ] Setup audit logging for payments
- [ ] Review transaction data retention policies

### 22. Support & Escalation
- [ ] Setup payment issue escalation process
- [ ] Train support on payment troubleshooting
- [ ] Create knowledge base articles
- [ ] Document common issues & solutions
- [ ] Setup payment issue alerts

## Success Criteria

✅ All payments process without errors  
✅ Users receive confirmations and notifications  
✅ Order status updates correctly after payment  
✅ Signature verification prevents fraud  
✅ Database entries accurate and complete  
✅ No payment timeouts or failures  
✅ Support team confident troubleshooting  
✅ Zero critical issues in first week  

---

**Version**: 1.0.0  
**Last Updated**: May 2026  
**Status**: Ready for Deployment
