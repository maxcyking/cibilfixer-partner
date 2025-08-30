# Firestore Setup for CibilFixer Partner App

## Required Collections and Documents

### 1. Users Collection (`users`)

Each user document should have the following structure:

```json
{
  "email": "user@example.com",
  "role": "partner", // or "sales representative"
  "isActive": true,
  "kycStatus": "completed", // or "pending"
  "createdAt": "2024-08-28T10:00:00Z",
  "updatedAt": "2024-08-28T10:00:00Z",
  "profile": {
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890"
  }
}
```

### 2. Firestore Security Rules

Make sure your Firestore rules allow authenticated users to read their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Add other collection rules as needed
  }
}
```

## Setup Steps

1. **Go to Firebase Console**
2. **Select your project: `future-capital-91977`**
3. **Go to Firestore Database**
4. **Create the `users` collection**
5. **Add a test user document with the structure above**
6. **Update security rules if needed**

## Test User Creation

For testing, create a user with:
- **Authentication**: Email/Password in Firebase Auth
- **Firestore Document**: In `users` collection with user's UID as document ID

Example:
- Email: `test@cibilfixer.com`
- Password: `TestPassword123!`
- Document ID: `[Firebase Auth UID]`
- Document data: Use the JSON structure above