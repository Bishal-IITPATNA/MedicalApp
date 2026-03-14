# State Management Guide

Guide to managing state in the Medical App Flutter frontend.

## 🎯 State Management Approach

This app uses **StatefulWidget** with **FutureBuilder** and **setState** for state management.

**Why this approach?**
- Simple and built-in to Flutter
- No external dependencies
- Easy to understand for beginners
- Sufficient for medium-sized apps

## 📊 Types of State

### 1. Local State (Widget-Level)

**What:** State that only one widget cares about

**Examples:**
- Form field values
- Is loading indicator shown?
- Selected tab index
- Is dropdown expanded?

**Implementation:**
```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Local state
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword 
                ? Icons.visibility 
                : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        if (_isLoading)
          CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _handleLogin,
            child: Text('Login'),
          ),
      ],
    );
  }
}
```

### 2. App State (Cross-Widget)

**What:** State shared across multiple widgets

**Examples:**
- User authentication status
- User profile data
- Shopping cart items
- Notification count

**Implementation Methods:**

#### Method A: Passing via Constructor

```dart
// Parent widget holds state
class PatientDashboard extends StatefulWidget {
  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  Map<String, dynamic>? _userData;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final data = await authService.getUserData();
    setState(() {
      _userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WelcomeCard(userData: _userData), // Pass to child
        AppointmentsList(
          appointments: _appointments,
          onRefresh: _loadAppointments,
        ),
      ],
    );
  }
}

// Child widget receives state
class WelcomeCard extends StatelessWidget {
  final Map<String, dynamic>? userData;

  WelcomeCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return CircularProgressIndicator();
    }
    
    return Card(
      child: Text('Welcome, ${userData!['name']}!'),
    );
  }
}
```

#### Method B: Using Services (Singleton Pattern)

```dart
// Singleton service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Map<String, dynamic>? _cachedUserData;

  Future<Map<String, dynamic>?> getUserData() async {
    if (_cachedUserData != null) {
      return _cachedUserData;
    }

    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      _cachedUserData = json.decode(userData);
      return _cachedUserData;
    }
    return null;
  }

  void clearCache() {
    _cachedUserData = null;
  }
}

// Usage in any widget
class AnyScreen extends StatefulWidget {
  @override
  _AnyScreenState createState() => _AnyScreenState();
}

class _AnyScreenState extends State<AnyScreen> {
  final _authService = AuthService(); // Same instance everywhere

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('Hello, ${snapshot.data!['name']}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## 🔄 Async State Handling

### FutureBuilder Pattern

**Use when:** Fetching data from API once

```dart
class ProfileScreen extends StatelessWidget {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.get('/api/patient/profile'),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    // Rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Success state
        if (snapshot.hasData) {
          final profile = snapshot.data!['data'];
          return _buildProfileContent(profile);
        }

        // No data state
        return Center(child: Text('No data available'));
      },
    );
  }
}
```

### StatefulWidget with Manual Loading

**Use when:** Need more control over loading state

```dart
class AppointmentsScreen extends StatefulWidget {
  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService _apiService = ApiService();
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('/api/patient/appointments');
      
      if (response['success']) {
        setState(() {
          _appointments = (response['data'] as List)
              .map((json) => Appointment.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          return AppointmentCard(appointment: _appointments[index]);
        },
      ),
    );
  }
}
```

## 🛒 Complex State Example: Shopping Cart

```dart
class CartItem {
  final int medicineId;
  final String medicineName;
  final double price;
  int quantity;

  CartItem({
    required this.medicineId,
    required this.medicineName,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  
  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  // Add item
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.medicineId == item.medicineId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
  }

  // Remove item
  void removeItem(int medicineId) {
    _items.removeWhere((item) => item.medicineId == medicineId);
  }

  // Update quantity
  void updateQuantity(int medicineId, int quantity) {
    final item = _items.firstWhere(
      (item) => item.medicineId == medicineId,
    );
    item.quantity = quantity;
  }

  // Clear cart
  void clear() {
    _items.clear();
  }
}

// Usage in screen
class BuyMedicineScreen extends StatefulWidget {
  @override
  _BuyMedicineScreenState createState() => _BuyMedicineScreenState();
}

class _BuyMedicineScreenState extends State<BuyMedicineScreen> {
  final CartManager _cart = CartManager();

  void _addToCart(Medicine medicine) {
    setState(() {
      _cart.addItem(CartItem(
        medicineId: medicine.id,
        medicineName: medicine.name,
        price: medicine.price,
        quantity: 1,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medicine.name} added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Medicine'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                ),
              ),
              if (_cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cart.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildMedicineList(),
    );
  }
}
```

## 📝 Form State Management

```dart
class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedRole;
  DateTime? _selectedDob;

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': _selectedRole,
        'dob': _selectedDob?.toIso8601String(),
      };

      final response = await apiService.post(
        '/api/auth/register',
        formData,
      );

      if (response['success']) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(response['error']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(labelText: 'Role'),
            items: ['patient', 'doctor', 'nurse'].map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a role';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
```

## 🔔 Notification State

```dart
class NotificationManager {
  static final NotificationManager _instance = 
      NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final StreamController<int> _unreadCountController = 
      StreamController<int>.broadcast();

  Stream<int> get unreadCountStream => _unreadCountController.stream;
  int _unreadCount = 0;

  void setUnreadCount(int count) {
    _unreadCount = count;
    _unreadCountController.add(count);
  }

  void incrementUnread() {
    _unreadCount++;
    _unreadCountController.add(_unreadCount);
  }

  void markAllAsRead() {
    _unreadCount = 0;
    _unreadCountController.add(0);
  }

  void dispose() {
    _unreadCountController.close();
  }
}

// Usage
class DashboardAppBar extends StatelessWidget {
  final NotificationManager _notificationManager = NotificationManager();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Dashboard'),
      actions: [
        StreamBuilder<int>(
          stream: _notificationManager.unreadCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/notifications',
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

## 🎯 Best Practices

### 1. Keep State Close to Where It's Used

```dart
// ✅ Good: Local state in widget
class ExpandableCard extends StatefulWidget {
  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false; // Only this widget cares

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Title'),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            Text('Details here'),
          ],
        ],
      ),
    );
  }
}
```

### 2. Minimize setState Rebuilds

```dart
// ❌ Bad: Rebuilds entire screen
setState(() {
  _someValue = newValue;
});

// ✅ Good: Extract to separate StatefulWidget
class MyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveWidget(),      // Won't rebuild
        ChangingWidget(),       // Only this rebuilds
      ],
    );
  }
}

class ChangingWidget extends StatefulWidget {
  @override
  _ChangingWidgetState createState() => _ChangingWidgetState();
}

class _ChangingWidgetState extends State<ChangingWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Text('$_counter'); // Only this rebuilds on setState
  }
}
```

### 3. Clean Up Resources

```dart
@override
void dispose() {
  // Dispose controllers
  _emailController.dispose();
  _passwordController.dispose();
  
  // Cancel subscriptions
  _subscription?.cancel();
  
  // Close streams
  _streamController.close();
  
  super.dispose();
}
```

### 4. Handle Null Safety

```dart
// Use null-aware operators
final name = userData?['name'] ?? 'Unknown';

// Safe navigation
final email = response['data']?['user']?['email'];

// Null check before use
if (userData != null) {
  Text(userData['name']);
}
```

## 📚 Summary

State management in this app:
- **Local state**: `setState()` in StatefulWidget
- **Async data**: `FutureBuilder` and `StreamBuilder`
- **Shared state**: Singleton services
- **Forms**: `Form` widget with `GlobalKey`
- **Navigation**: Pass data via constructors or named routes

This approach is simple, effective, and doesn't require additional packages. For larger apps, consider using Provider, Riverpod, or BLoC.

---

**Next:** Read [API Integration Guide](./api-integration.md) for backend communication.
