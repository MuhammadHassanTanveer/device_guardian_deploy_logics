# User App Implementation Guide for Camera Control

This guide explains how to implement camera disable functionality in your user app to receive commands from the admin app.

## Overview

The admin app sends Firebase Cloud Messaging (FCM) notifications to user devices with camera control commands. The user app needs to:

1. Listen for FCM notifications
2. Parse camera control commands
3. Disable/enable camera functionality based on commands
4. Update UI to reflect camera status

## FCM Notification Structure

The admin app sends notifications with the following structure:

### Camera Control Notification
```json
{
  "notification": {
    "title": "Camera Control",
    "body": "Camera has been disabled by admin" // or "enabled"
  },
  "data": {
    "command_type": "camera_control",
    "camera_disabled": "true", // or "false"
    "action": "disable_camera" // or "enable_camera"
  }
}
```

## Implementation Steps

### 1. Add Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^15.2.7
  flutter_local_notifications: ^19.3.0
  shared_preferences: ^2.5.3
  camera: ^0.10.5+5
```

### 2. Initialize Firebase Messaging

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    
    // Listen for messages
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
}
```

### 3. Handle Camera Control Commands

```dart
class CameraController {
  static bool _cameraDisabled = false;
  static CameraController? _cameraController;
  
  static bool get isCameraDisabled => _cameraDisabled;
  
  static Future<void> _handleMessage(RemoteMessage message) async {
    final data = message.data;
    
    if (data['command_type'] == 'camera_control') {
      final isDisabled = data['camera_disabled'] == 'true';
      await _updateCameraStatus(isDisabled);
      
      // Show notification to user
      await _showLocalNotification(
        'Camera Control',
        isDisabled ? 'Camera has been disabled by admin' : 'Camera has been enabled by admin',
      );
    }
  }
  
  static Future<void> _updateCameraStatus(bool disabled) async {
    _cameraDisabled = disabled;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camera_disabled', disabled);
    
    // Dispose camera if disabled
    if (disabled && _cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    
    // Notify UI to update
    // You can use a state management solution like Provider, Bloc, etc.
  }
  
  static Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'camera_control',
      'Camera Control',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(0, title, body, details);
  }
}
```

### 4. Initialize Camera with Status Check

```dart
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraDisabled = false;
  
  @override
  void initState() {
    super.initState();
    _checkCameraStatus();
  }
  
  Future<void> _checkCameraStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isDisabled = prefs.getBool('camera_disabled') ?? false;
    
    setState(() {
      _isCameraDisabled = isDisabled;
    });
    
    if (!isDisabled) {
      await _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isCameraDisabled) {
      return Scaffold(
        appBar: AppBar(title: Text('Camera')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 100,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Camera is disabled by admin',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Camera')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: CameraPreview(_cameraController!),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
  
  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        // Handle the captured image
        print('Picture taken: ${image.path}');
      } catch (e) {
        print('Error taking picture: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
```

### 5. Update Main App to Listen for Commands

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User App',
      home: CameraScreen(),
    );
  }
}
```

### 6. Add Camera Permissions

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Testing

1. **Admin App**: Click the camera disable/enable button for a registered device
2. **User App**: Should receive notification and camera should be disabled/enabled
3. **Database**: Check Firebase Realtime Database for `camera_disabled` field updates

## Database Schema

The admin app updates the following fields in Firebase Realtime Database:

```json
{
  "user_devices": {
    "device_id": {
      "imei_1": "device_imei_1",
      "imei_2": "device_imei_2", 
      "fcm_token": "device_fcm_token",
      "status": "lock" | "unlock",
      "camera_disabled": true | false
    }
  }
}
```

## Security Considerations

1. **Authentication**: Ensure only authorized admins can send camera control commands
2. **Validation**: Validate FCM tokens and device ownership
3. **Encryption**: Consider encrypting sensitive data in notifications
4. **Rate Limiting**: Implement rate limiting for camera control commands

## Troubleshooting

1. **FCM Not Received**: Check FCM token registration and Firebase configuration
2. **Camera Not Disabling**: Verify SharedPreferences implementation and state management
3. **Permission Issues**: Ensure camera permissions are properly requested
4. **Background Handling**: Test camera control when app is in background/foreground

## Additional Features

Consider implementing:

1. **Camera Status Indicator**: Show camera status in app header/navigation
2. **Admin Override**: Allow users to request camera re-enablement
3. **Audit Log**: Log all camera control commands
4. **Bulk Operations**: Support disabling camera for multiple devices
5. **Scheduled Control**: Schedule camera disable/enable at specific times

