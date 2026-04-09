# Debug Steps for Token Issue

## What I Changed:

### 1. Login Provider (`lib/providers/login_provider.dart`)
- Added debug logging to see the **actual login API response**
- Improved token extraction to support multiple field names:
  - `token`
  - `access_token`
  - `data.token`
  - `data.access_token`
- Improved user_id extraction to support:
  - `userId`, `user_id`, `data.user_id`, `id`
- Added logging to confirm what's stored in SharedPreferences

### 2. Customer Provider (`lib/providers/customer_provider.dart`)
- Enhanced debug logging to show:
  - What user_id is retrieved from SharedPreferences
  - What auth_token is retrieved from SharedPreferences
  - The exact Authorization header being sent

## Next Steps:

### Step 1: Login and Check Console Output

When you login, you'll now see in the console:
```
flutter: Login API Response: {...}
flutter: Extracted token: Token present (XX chars) OR Token MISSING
flutter: Extracted user_id: XX
flutter: Stored in SharedPreferences - auth_token: YES/NO, user_id: XX
```

### Step 2: Navigate to Customer List and Check Console

When fetching customers, you'll see:
```
flutter: === Fetch Customers Debug ===
flutter: Retrieved user_id from SharedPreferences: XX
flutter: Retrieved auth_token from SharedPreferences: Token present (XX chars) OR Token MISSING
flutter: Customer API URL: http://100.113.207.78:8001/api/get_user_devices_api?user_id=XX
flutter: Authorization header: Bearer XXXXX
```

## Common Issues and Solutions:

### Issue 1: "Token MISSING" in Login Response
**Solution:** Your API returns the token in a different field. Check the login response and update line 29-30 in `login_provider.dart`:
```dart
final token = data['YOUR_TOKEN_FIELD'] ?? '';
final userId = data['YOUR_USER_ID_FIELD'] ?? '';
```

### Issue 2: Token stored but empty when retrieved
**Solution:** Token might be empty string. Check the Login API Response log.

### Issue 3: Server says "Authorization token missing" but token is sent
**Possible causes:**
1. Server expects different header format (e.g., just token without "Bearer")
2. Server expects token in a different header (e.g., "X-Auth-Token")
3. Token format is invalid

**To test without Bearer prefix:**
In `customer_provider.dart` line 433, try:
```dart
'Authorization': authToken,  // Without "Bearer"
```

Or with custom header:
```dart
'X-Auth-Token': authToken,
'Authorization': 'Bearer $authToken',  // Send both to test
```

## Manual Testing in Terminal:

After login, you can test the API directly using curl:

```bash
# Get the token from the console log, then test:
curl -X GET "http://100.113.207.78:8001/api/get_user_devices_api?user_id=8" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

If this works, the issue is in how the app is sending the token.
If this fails with 401, the issue is server-side or token format.

## Quick Fix if Login API Returns Nested Token:

If your login API returns something like:
```json
{
  "status": true,
  "data": {
    "token": "abc123",
    "user_id": 8
  }
}
```

The current code should handle this. But if it's even more nested, update login_provider.dart accordingly.

