# Common Issues & Troubleshooting

Quick solutions to frequently encountered problems.

## 🔧 Backend Issues

### Issue 1: "No module named 'flask'"

**Error:**
```
ModuleNotFoundError: No module named 'flask'
```

**Cause:** Virtual environment not activated or packages not installed

**Solution:**
```bash
# Activate virtual environment
cd backend
source venv/bin/activate  # macOS/Linux
# OR
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
```

---

### Issue 2: "Database is locked"

**Error:**
```
sqlite3.OperationalError: database is locked
```

**Cause:** SQLite database accessed by multiple processes or tools

**Solution:**
```bash
# Close any DB browser tools
# Kill any running Flask processes
ps aux | grep flask
kill -9 <process_id>

# Restart server
flask run
```

---

### Issue 3: "Port 5000 already in use"

**Error:**
```
OSError: [Errno 48] Address already in use
```

**Cause:** Another process using port 5000

**Solution:**
```bash
# Find process using port 5000
lsof -i :5000

# Kill the process
kill -9 <PID>

# OR use different port
flask run --port 5001
```

---

### Issue 4: "Token has expired"

**Error:**
```
{
  "msg": "Token has expired"
}
```

**Cause:** JWT access token expired (after 24 hours)

**Solution:**
- Frontend should automatically refresh token
- If manual testing, login again to get new token
- Check JWT_ACCESS_TOKEN_EXPIRES in config.py

---

### Issue 5: "Migration conflicts"

**Error:**
```
alembic.util.exc.CommandError: Target database is not up to date.
```

**Cause:** Database migration out of sync

**Solution:**
```bash
# Check current migration
flask db current

# Downgrade to previous version
flask db downgrade

# OR reset migrations (CAUTION: deletes data)
rm -rf migrations/
rm medical_app.db
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

---

### Issue 6: "CORS error"

**Error:**
```
Access to fetch at 'http://localhost:5000' from origin 'http://localhost:8080' 
has been blocked by CORS policy
```

**Cause:** Flask-CORS not configured properly

**Solution:**
```python
# In app/__init__.py
from flask_cors import CORS

def create_app():
    app = Flask(__name__)
    CORS(app, origins=['http://localhost:8080', 'http://localhost:3000'])
    return app
```

---

## 📱 Frontend Issues

### Issue 1: "Unable to load asset"

**Error:**
```
Unable to load asset: assets/images/logo.png
```

**Cause:** Asset not declared in pubspec.yaml

**Solution:**
```yaml
# In pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

Then:
```bash
flutter pub get
flutter clean
flutter run
```

---

### Issue 2: "Connection refused"

**Error:**
```
SocketException: Connection refused (OS Error: Connection refused, errno = 61), 
address = localhost, port = 5000
```

**Cause:** Backend not running or wrong baseUrl

**Solution:**
1. Check backend is running:
```bash
cd backend
flask run
# Should show: Running on http://127.0.0.1:5000
```

2. Verify baseUrl in api_service.dart:
```dart
static const String baseUrl = 'http://localhost:5000';
```

3. If testing on physical device:
```dart
// Use your computer's IP address
static const String baseUrl = 'http://192.168.1.100:5000';
```

---

### Issue 3: "Type error in fromJson"

**Error:**
```
type 'Null' is not a subtype of type 'String'
```

**Cause:** API response field is null but model expects non-null

**Solution:**
```dart
// Make field nullable
class User {
  final String? address;  // Add ? for nullable
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      address: json['address'],  // Can be null now
    );
  }
}

// OR provide default value
class User {
  final String address;
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      address: json['address'] ?? '',  // Default to empty string
    );
  }
}
```

---

### Issue 4: "setState called after dispose"

**Error:**
```
setState() called after dispose()
```

**Cause:** Async operation completes after widget disposed

**Solution:**
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  Future<void> _loadData() async {
    final data = await apiService.get('/api/data');
    
    // Check if widget still mounted
    if (!mounted) return;
    
    setState(() {
      _data = data;
    });
  }
  
  @override
  void dispose() {
    // Cancel any ongoing operations
    super.dispose();
  }
}
```

---

### Issue 5: "Hot reload not working"

**Symptoms:** Changes not appearing after pressing 'r'

**Solutions:**

1. **Hot restart instead:** Press 'R' (capital R)

2. **Clean and rebuild:**
```bash
flutter clean
flutter pub get
flutter run
```

3. **Check for errors:** Look for compilation errors in console

4. **Restart IDE:** Sometimes VS Code needs restart

---

### Issue 6: "Gradle build failed" (Android)

**Error:**
```
FAILURE: Build failed with an exception.
```

**Solution:**
```bash
cd android
./gradlew clean

cd ..
flutter clean
flutter pub get
flutter run
```

---

## 🔐 Authentication Issues

### Issue 1: "Invalid token"

**Error:**
```
{
  "error": "Invalid token"
}
```

**Solutions:**
1. Check token in secure storage:
```dart
final token = await storage.read(key: 'access_token');
print('Token: $token');  // Should not be null
```

2. Login again to get fresh token

3. Check JWT_SECRET_KEY matches in backend .env

---

### Issue 2: "Token not being sent"

**Symptom:** All API calls return 401

**Solution:**
```dart
// In api_service.dart, verify token is added
Future<Map<String, dynamic>> get(String endpoint) async {
  final token = await _authService.getAccessToken();
  
  print('Token: ${token != null ? "Present" : "Missing"}');  // Debug
  
  final response = await http.get(
    Uri.parse('$baseUrl$endpoint'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
}
```

---

## 🗄️ Database Issues

### Issue 1: "Table doesn't exist"

**Error:**
```
sqlite3.OperationalError: no such table: user
```

**Cause:** Migrations not applied

**Solution:**
```bash
flask db upgrade
```

---

### Issue 2: "Column doesn't exist"

**Error:**
```
sqlite3.OperationalError: no such column: user.phone
```

**Cause:** Model changed but migration not created

**Solution:**
```bash
# Create new migration
flask db migrate -m "Add phone column to user"

# Apply migration
flask db upgrade
```

---

### Issue 3: "Foreign key constraint failed"

**Error:**
```
sqlite3.IntegrityError: FOREIGN KEY constraint failed
```

**Cause:** Trying to reference non-existent record

**Solution:**
```python
# Check if related record exists before creating
patient = Patient.query.get(patient_id)
if not patient:
    return {'error': 'Patient not found'}, 404

# Then create appointment
appointment = Appointment(patient_id=patient_id, ...)
```

---

## 🌐 Network Issues

### Issue 1: "Network timeout"

**Error:**
```
TimeoutException after 30 seconds
```

**Solution:**
```dart
// Increase timeout
final response = await http.get(
  Uri.parse(url),
  headers: headers,
).timeout(
  Duration(seconds: 60),  // Increase from default 30s
  onTimeout: () {
    throw Exception('Request timed out');
  },
);
```

---

### Issue 2: "SSL certificate error"

**Error:**
```
HandshakeException: Handshake error in client
```

**Solution (Development Only):**
```dart
// ONLY for development/testing with self-signed certs
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// In main.dart
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}
```

---

## 💾 Data Issues

### Issue 1: "Response parsing error"

**Error:**
```
FormatException: Unexpected character
```

**Cause:** Backend returning HTML instead of JSON (usually error page)

**Solution:**
```dart
Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
  try {
    final data = json.decode(response.body);
    return data;
  } catch (e) {
    print('Response body: ${response.body}');  // Debug
    return {
      'success': false,
      'error': 'Invalid response format',
    };
  }
}
```

---

### Issue 2: "Null values in response"

**Symptom:** Screen shows blank where data should be

**Solution:**
```dart
// Add null safety
final name = userData?['name'] ?? 'Unknown';
final email = userData?['email'] ?? 'No email';

// OR check before use
if (userData != null && userData['name'] != null) {
  Text(userData['name']);
}
```

---

## 🔍 Debugging Tips

### Enable Debug Logging

**Backend:**
```python
# In app/__init__.py
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# In your route
logger.debug(f"Request data: {request.get_json()}")
logger.debug(f"User ID: {get_jwt_identity()}")
```

**Frontend:**
```dart
// Add print statements
print('API Request: $endpoint');
print('Request data: $data');
print('Response: ${response.body}');

// Use debugPrint for long output
debugPrint('Long response: ${response.body}');
```

### Use Breakpoints

**VS Code:**
1. Click left of line number to add breakpoint
2. Run in debug mode (F5)
3. Inspect variables when execution pauses

### Network Inspection

**Use curl to test API directly:**
```bash
# Test login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"pass123"}'

# Test with auth
curl http://localhost:5000/api/patient/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📞 Getting Help

**Before asking:**
1. Check this guide
2. Search error message online
3. Check official docs (Flutter/Flask)
4. Try debugging steps above

**When asking:**
1. Describe what you're trying to do
2. Show the error message (full stack trace)
3. Show your code
4. Describe what you've tried

**Where to ask:**
- Team Slack/Teams channel
- GitHub Issues (for bugs)
- Stack Overflow (general questions)

---

**Next:** See [Deployment Guide](./deployment.md) for production setup.
