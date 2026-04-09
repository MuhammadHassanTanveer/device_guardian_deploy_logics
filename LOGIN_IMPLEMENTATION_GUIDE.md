# Login System Implementation Guide

## Overview
This document describes the login system implementation in the Device Guardian Admin application.

## Components Created

### 1. LoginProvider (`lib/providers/login_provider.dart`)
A provider class that manages authentication state and operations.

**Public Variables:**
- `isLoading` (bool): Indicates when an API call is in progress
- `errorMessage` (String?): Stores error messages from failed login attempts

**Public Functions:**
- `login(String email, String password)`: Authenticates user and stores credentials
- `checkLoginStatus()`: Checks if user is logged in
- `logout()`: Clears stored credentials
- `clearError()`: Clears error messages

**Data Storage:**
After successful login, the following data is stored in SharedPreferences:
- `auth_token`: Authentication token from API response
- `user_id`: User ID from API response  
- `is_logged_in`: Boolean flag indicating login status

### 2. LoginScreen (`lib/screens/login_screen.dart`)
A beautiful login screen following your app's design patterns.

**Features:**
- Uses your `CustomTextFieldWidget` for email and password inputs
- Follows your gradient background design pattern
- Displays loading indicator during API call
- Shows toast messages for success/error feedback
- Form validation for email and password

**Validators:**
- Email: Required and must be valid format
- Password: Required and minimum 6 characters

### 3. Updated SplashScreen (`lib/screens/splash_screen.dart`)
**Flow:**
1. Shows splash screen for 3 seconds
2. Checks login status from SharedPreferences
3. Navigates to HomeScreen if logged in
4. Navigates to LoginScreen if not logged in

### 4. Updated HomeScreen
Added logout button with confirmation dialog.

## How to Use

### API Configuration ✅
The API endpoint is already configured to:
```
https://locker.deploylogics.com/api/login_user_api
```

The login request sends:
```json
{
  "email": "user@example.com",
  "password": "userpassword"
}
```

### Integrate Your API
The `login()` function in `lib/providers/login_provider.dart` is already configured with your endpoint:

```dart
final response = await http.post(
  Uri.parse('https://locker.deploylogics.com/api/login_user_api'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);
```

**Expected API Response Format:**
```json
{
  "token": "your_auth_token_here",
  "userId": "user_id_123",
  "message": "Login successful"
}
```

### Access Stored Data
To access stored credentials anywhere in your app:

```dart
// Get SharedPreferences instance
final prefs = await SharedPreferences.getInstance();

// Retrieve stored data
String? token = prefs.getString('auth_token');
String? userId = prefs.getString('user_id');
bool? isLoggedIn = prefs.getBool('is_logged_in');
```

### Use in API Calls
Example of using the token in authenticated API requests:

```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');

final response = await http.get(
  Uri.parse('YOUR_API_ENDPOINT/data'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

## Application Flow

1. **App Launch** → `main.dart` → `SplashScreen`
2. **SplashScreen** → Checks login status
3. If **Not Logged In** → `LoginScreen`
4. If **Logged In** → `HomeScreen`
5. **After Login** → Stores token & user_id → `HomeScreen`
6. **Logout** → Clears SharedPreferences → `LoginScreen`

## Testing

### Test Credentials (for development)
Until you integrate your real API, you can modify the login function to use mock credentials:

```dart
// In login_provider.dart, temporarily replace the API call with:
await Future.delayed(const Duration(seconds: 2)); // Simulate API delay

// Mock credentials check
if (email == 'admin@test.com' && password == 'password123') {
  // Success - store mock data
  final token = "mock_token_123";
  final userId = "mock_user_123";
  // ... rest of the code
} else {
  errorMessage = 'Invalid credentials';
  isLoading = false;
  notifyListeners();
  return false;
}
```

## Customization

### Change Session Duration
Currently, the session persists until logout. To add session timeout:

```dart
// Store timestamp when logging in
await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);

// Check session expiry (e.g., 24 hours)
Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final loginTime = prefs.getInt('login_timestamp') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  final sessionDuration = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  
  if (isLoggedIn && (now - loginTime) < sessionDuration) {
    return true;
  }
  return false;
}
```

### Add Remember Me Feature
```dart
// Store remember me preference
await prefs.setBool('remember_me', rememberMeValue);

// Check on splash
if (!rememberMe) {
  // Don't auto-login
}
```

## Dependencies Used
- `provider`: State management
- `shared_preferences`: Local data storage
- `http`: API calls
- `fluttertoast`: Toast notifications

All dependencies are already in your `pubspec.yaml`.

## Notes
- All variables and functions are public for easy access
- Code follows your existing patterns (CustomTextFieldWidget, styles, dimensions)
- Uses your gradient theme and design system
- Simple and readable implementation
- Toast messages for user feedback
- Proper error handling

