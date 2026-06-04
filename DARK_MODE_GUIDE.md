# Dark Mode Implementation Guide

## Setup Complete ✅

### Files Created/Updated:
- ✅ `lib/main.dart` - Updated to use AppTheme
- ✅ `lib/services/app_theme.dart` - Complete light & dark theme configuration

## How to Use AppTheme in Pages

### Method 1: Using Theme.of(context) - RECOMMENDED
```dart
// Text color
Text(
  'Hello',
  style: TextStyle(
    color: Theme.of(context).textTheme.bodyLarge!.color,
  ),
)

// Background
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
  child: ...,
)

// Primary color
Icon(Icons.home, color: Theme.of(context).primaryColor)
```

### Method 2: Using AppTheme Helpers
```dart
import 'package:quick_parcel/services/app_theme.dart';

// Get text color
Text(
  'Hello',
  style: TextStyle(color: AppTheme.getTextColor(context)),
)

// Get background color
Container(
  color: AppTheme.getBackgroundColor(context),
)

// Get border color
Border.all(color: AppTheme.getBorderColor(context))
```

### Method 3: Brightness Check
```dart
bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

Color color = isDarkMode 
  ? AppTheme.darkPrimary 
  : AppTheme.lightPrimary;
```

## Pages to Update

### Priority 1 - Main Pages:
- [ ] `lib/coustomer/homepage.dart`
- [ ] `lib/coustomer/login.dart`
- [ ] `lib/coustomer/signUp.dart`
- [ ] `lib/coustomer/sendPackage.dart`
- [ ] `lib/coustomer/find_driver.dart`
- [ ] `lib/coustomer/billing_page.dart`
- [ ] `lib/coustomer/my_packages.dart`
- [ ] `lib/coustomer/profile.dart`
- [ ] `lib/coustomer/live_tracking.dart`

### Priority 2 - Driver Pages:
- [ ] All driver app pages

## Color Mapping

### Light Mode:
- Primary: #0D7D8F (Teal)
- Secondary: #00BCD4 (Cyan)
- Background: #FAFAFA (Light Gray)
- Surface: #FFFFFF (White)
- Text: #1A1A1A (Dark Gray)
- Text Secondary: #6C6C6C (Medium Gray)
- Border: #E0E0E0 (Light Gray)

### Dark Mode:
- Primary: #00BCD4 (Cyan)
- Secondary: #26C6DA (Light Cyan)
- Background: #121212 (Very Dark)
- Surface: #1E1E1E (Dark Gray)
- Text: #FFFFFF (White)
- Text Secondary: #B0B0B0 (Light Gray)
- Border: #333333 (Dark Border)

## Common Patterns to Replace

### Old (Hardcoded) → New (Theme-aware)

```dart
// ❌ Old
Container(
  color: Color(0xFF0D7D8F),
  child: Text('Hello', style: TextStyle(color: Colors.white)),
)

// ✅ New
Container(
  color: Theme.of(context).primaryColor,
  child: Text(
    'Hello',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  ),
)
```

### TextField Example:
```dart
// ✅ Already configured in AppTheme!
// Just use TextField without custom InputDecoration
TextField(
  decoration: InputDecoration(
    hintText: 'Enter text',
    prefixIcon: Icon(Icons.email),
  ),
)
```

### Card Example:
```dart
// ✅ Already configured in AppTheme!
Card(
  child: ListTile(title: Text('Item')),
)
```

## Testing Dark Mode

1. **Android**: Settings → Display → Dark theme
2. **iOS**: Settings → Display & Brightness → Dark
3. **In App**: Can also be tested by checking:
   ```dart
   Theme.of(context).brightness == Brightness.dark
   ```

## Key Improvements Made

✅ Consistent color scheme across light/dark modes
✅ Proper contrast ratios for accessibility
✅ AppBar, Card, Button themes configured
✅ InputDecoration theme configured
✅ SnackBar theme configured
✅ BottomNavigationBar theme configured
✅ Text styles configured
✅ Helper methods for dynamic color selection

## Next Steps

1. Update homepage.dart to use Theme.of(context) instead of hardcoded colors
2. Update other customer pages
3. Update driver app pages
4. Test on both light and dark modes
