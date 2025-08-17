# Google Sign-In Test Instructions

## Setup Complete ✅

The following configuration has been successfully added:
1. **GoogleService-Info.plist** - Added to iOS Runner folder
2. **google-services.json** - Added to Android app folder  
3. **Debug logging** - Added to track sign-in process
4. **Pod dependencies** - Updated with `pod install`

## Test Steps

1. **Open the app** - The app should now be running on the iPhone 16 simulator

2. **Navigate to Profile Tab** - Tap the Profile icon (rightmost tab)

3. **Look for SNS Banner** - You should see a banner saying "SNS 계정 연동해서 데이터 안전하게 보관하기"

4. **Tap the Banner** - This will navigate to the social login screen

5. **Test Google Sign-In**:
   - Tap the "구글 계정으로 계속하기" button
   - The Google Sign-In dialog should appear
   - Sign in with your Google account
   - Check the console logs for debug output

## Debug Output to Monitor

The following debug messages will appear in the console:
- `Starting Google Sign In process...`
- `Cleared previous Google session`
- `Triggering Google Sign In dialog...`
- `Google user signed in: [email]`
- `Getting Google authentication tokens...`
- `Access token received: true/false`
- `ID token received: true/false`
- `Signing in with Supabase using Google tokens...`
- `Successfully signed in with Supabase`

## Troubleshooting

If the app crashes when tapping the Google button:
1. Check the console for error messages
2. Ensure GoogleService-Info.plist is in the ios/Runner folder
3. Verify the bundle ID matches: `space.cordelia273.kanjiStudyApp`

## Current Status

- ✅ GoogleService-Info.plist configured
- ✅ google-services.json configured
- ✅ iOS URL schemes configured
- ✅ Debug logging added
- ✅ App running successfully

The app is now ready to test Google Sign-In functionality!