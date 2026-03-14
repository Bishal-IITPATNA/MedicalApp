# Team Workflow & Collaboration Guide

Best practices for effective team collaboration on the Medical App project.

## 🔄 Git Workflow

### Branch Strategy

```
main (production-ready)
  ↓
develop (integration branch)
  ↓
feature/team-x-feature-name (your work)
```

**Branch Types:**
- `main` - Production code, always stable
- `develop` - Integration branch for all features
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Critical production fixes

### Creating Feature Branch

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/patient-prescription-view

# Work on your feature
# ... make changes ...

# Commit regularly
git add .
git commit -m "Add prescription view screen

- Created prescription list component
- Added API integration
- Implemented medicine display with dosage"

# Push to remote
git push origin feature/patient-prescription-view
```

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Build/tool changes

**Examples:**

```
feat: Add medicine cart functionality

- Implemented shopping cart for medicines
- Added prescription validation
- Auto-calculate quantities based on prescription

Closes #123
```

```
fix: Correct profile value population in lab store

- Changed response parsing to extract data field
- Fixed null reference in profile screen
- Added error handling for missing data

Fixes #456
```

## 🔍 Code Review Process

### 1. Creating Pull Request

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Refactoring

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] No breaking changes

## Screenshots (if UI changes)
[Add screenshots]

## Related Issues
Closes #issue_number
```

### 2. Review Checklist

**For Reviewers:**
- [ ] Code follows project style guidelines
- [ ] Changes are well-documented
- [ ] No unnecessary code duplication
- [ ] Error handling is appropriate
- [ ] Tests are included and passing
- [ ] No security vulnerabilities
- [ ] Performance considerations addressed

**Comment Etiquette:**
```
✅ Good: "Consider extracting this logic into a separate method for reusability"
❌ Bad: "This code is terrible"

✅ Good: "This could cause a memory leak. Try disposing the controller in the dispose() method"
❌ Bad: "You forgot to dispose"

✅ Good: "Nice solution! Just a suggestion: we could use FutureBuilder here to simplify the code"
❌ Bad: "Why didn't you use FutureBuilder?"
```

### 3. Responding to Feedback

```markdown
### Code Review Discussion

**Reviewer:** Consider adding error handling here
**Author:** Good catch! Added try-catch block in commit abc123

**Reviewer:** Can this be simplified using a switch statement?
**Author:** You're right, refactored in commit def456

**Reviewer:** This might cause performance issues with large lists
**Author:** Implemented pagination to address this. See commit ghi789
```

### 4. Merging

```bash
# After approval, update with latest develop
git checkout feature/your-feature
git merge develop

# Resolve any conflicts
# ... fix conflicts ...
git add .
git commit -m "Merge develop into feature branch"

# Push updated branch
git push origin feature/your-feature

# Merge via GitHub PR interface (or command line)
```

## 👥 Daily Standup Format

**Time:** 15 minutes, every morning

**Format:**
Each team member answers:

1. **What I did yesterday:**
   - Completed appointment booking UI
   - Fixed bugs in medicine cart
   
2. **What I'm doing today:**
   - Implement prescription writing screen
   - Code review for Team B's PR
   
3. **Blockers:**
   - Waiting for backend API endpoint from Team C
   - Need design mockups for new feature

**Example:**
```
Team Member A (Backend - Auth):
Yesterday: Implemented password reset API endpoint
Today: Adding email verification for new registrations
Blockers: Need clarification on email service provider

Team Member B (Frontend - Patient):
Yesterday: Completed medicine cart UI and logic
Today: Testing prescription validation flow
Blockers: Backend prescription endpoint returning 500 error

Team Member C (Backend - Medicine):
Yesterday: Fixed order routing to admin
Today: Investigating prescription endpoint bug (Team B blocker)
Blockers: None
```

## 📋 Sprint Planning

### 2-Week Sprint Cycle

**Week 1:**
```
Monday: Sprint Planning
- Review backlog
- Assign stories
- Define sprint goals

Tuesday-Thursday: Development
- Daily standups
- Code reviews
- Pair programming (if needed)

Friday: Mid-sprint Check
- Progress review
- Blocker resolution
- Adjust if needed
```

**Week 2:**
```
Monday-Wednesday: Development
- Complete features
- Code reviews
- Integration testing

Thursday: Testing & Bug Fixes
- QA testing
- Fix critical bugs
- Documentation updates

Friday: Sprint Review & Retro
- Demo completed features
- Retrospective
- Plan next sprint
```

### Story Point Estimation

**Fibonacci Scale:** 1, 2, 3, 5, 8, 13

- **1 point:** Simple text change, minor fix (1-2 hours)
- **2 points:** Small feature, simple screen (2-4 hours)
- **3 points:** Medium feature, API integration (4-6 hours)
- **5 points:** Complex feature, multiple screens (1-2 days)
- **8 points:** Large feature, backend+frontend (2-3 days)
- **13 points:** Epic, requires breakdown

## 🧪 Testing Strategy

### Test Pyramid

```
        /\
       /UI\        ← Few (E2E tests)
      /────\
     /  API \      ← Some (Integration tests)
    /────────\
   /   Unit   \    ← Many (Unit tests)
  /────────────\
```

### Backend Testing

**Unit Tests:**
```python
# tests/test_auth.py
def test_user_registration(client):
    response = client.post('/api/auth/register', json={
        'email': 'test@test.com',
        'password': 'password123',
        'role': 'patient'
    })
    assert response.status_code == 201
    assert response.json['success'] == True

def test_duplicate_email_registration(client):
    # Register once
    client.post('/api/auth/register', json={...})
    
    # Try again with same email
    response = client.post('/api/auth/register', json={...})
    assert response.status_code == 400
    assert 'already registered' in response.json['error']
```

**Running Tests:**
```bash
# Backend
cd backend
pytest tests/

# With coverage
pytest --cov=app tests/

# Specific test
pytest tests/test_auth.py::test_user_registration
```

### Frontend Testing

**Widget Tests:**
```dart
// test/screens/auth/login_screen_test.dart
testWidgets('Login form validates empty fields', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  
  // Tap login without entering anything
  await tester.tap(find.text('Login'));
  await tester.pump();
  
  // Should show error messages
  expect(find.text('Email is required'), findsOneWidget);
  expect(find.text('Password is required'), findsOneWidget);
});
```

**Running Tests:**
```bash
# Frontend
cd frontend
flutter test

# With coverage
flutter test --coverage

# Specific test
flutter test test/screens/auth/login_screen_test.dart
```

## 🐛 Bug Reporting & Tracking

### Bug Report Template

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Go to login screen
2. Enter email: test@test.com
3. Enter password: pass123
4. Click login
5. See error

## Expected Behavior
Should navigate to patient dashboard

## Actual Behavior
Shows "Network error" message

## Environment
- OS: macOS 14.0
- Browser: N/A
- App Version: 1.0.0
- Backend: Running on localhost:5000

## Screenshots
[Add screenshots if applicable]

## Severity
- [ ] Critical (app crashes, data loss)
- [x] High (feature broken, workaround exists)
- [ ] Medium (minor feature issue)
- [ ] Low (cosmetic issue)

## Additional Context
Error occurs only when backend is not running
```

### Bug Priority

| Priority | Description | Response Time |
|----------|-------------|---------------|
| P0 | Critical - App unusable | Immediate |
| P1 | High - Major feature broken | Within 24 hours |
| P2 | Medium - Minor feature issue | Within 3 days |
| P3 | Low - Cosmetic issue | Next sprint |

## 💬 Communication Channels

### Slack/Teams Channels

```
#general              - General discussion
#backend-dev          - Backend questions
#frontend-dev         - Frontend questions
#code-reviews         - PR notifications
#bugs                 - Bug reports
#deployment           - Deployment updates
#random               - Off-topic
```

### When to Use What

**Slack:**
- Quick questions
- Informal discussion
- Status updates
- Urgent issues

**GitHub Issues:**
- Feature requests
- Bug reports
- Documentation needs
- Long-term planning

**Email:**
- Formal communication
- Weekly summaries
- Stakeholder updates

**Video Call:**
- Complex discussions
- Pair programming
- Architecture decisions
- Sprint planning

## 📚 Documentation Standards

### Code Comments

**When to Comment:**
```dart
// ✅ Good: Explains WHY
// Using debounce to prevent excessive API calls during typing
final debouncer = Debouncer(milliseconds: 500);

// ❌ Bad: States the obvious
// Set loading to true
setState(() => _isLoading = true);
```

**Complex Logic:**
```python
def calculate_available_slots(doctor_id, date):
    """
    Calculate available appointment slots for a doctor on given date.
    
    Algorithm:
    1. Get doctor's schedule for the day
    2. Generate time slots based on slot_duration
    3. Exclude already booked slots
    4. Return available slots
    
    Args:
        doctor_id: ID of the doctor
        date: Date to check availability
        
    Returns:
        List of available time strings (e.g., ["09:00", "09:30"])
    """
    # Implementation...
```

### README Updates

**When features change:**
1. Update main README.md
2. Update relevant docs in docs/ folder
3. Add to CHANGELOG.md

## 🎯 Definition of Done

Feature is "Done" when:

- [ ] Code written and committed
- [ ] Unit tests added and passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Integration tested
- [ ] No critical bugs
- [ ] Merged to develop branch
- [ ] Deployed to staging (if applicable)

## 🚀 Deployment Process

### Staging Deployment

```bash
# After merge to develop
git checkout develop
git pull origin develop

# Backend
cd backend
git push staging develop

# Frontend
cd frontend
flutter build web
# Deploy to staging server
```

### Production Deployment

```bash
# After thorough testing
git checkout main
git merge develop
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags

# Deploy to production
# ... deployment steps ...
```

## 📊 Metrics & KPIs

**Track Weekly:**
- PRs merged
- Bugs fixed
- Code coverage %
- Sprint velocity
- Customer issues

**Review Monthly:**
- Feature completion rate
- Code quality trends
- Team velocity trends
- Technical debt

---

**Next:** See [Coding Standards](./coding-standards.md) for code quality guidelines.
