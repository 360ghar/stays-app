# App Update Prompts

This document explains how the in-app update prompt feature works and how to configure it.

## Overview

The app automatically checks for updates on launch by querying the Google Play Store (Android) and Apple App Store (iOS). When a newer version is available, users are prompted to update.

## Update Types

### Optional Updates

For regular releases, users see a dismissible dialog with two options:
- **Update Now** - Opens the app store to download the update
- **Remind Me Later** - Dismisses the dialog; it will reappear after 24 hours

### Force Updates (Critical)

For critical releases that require all users to update, a full-screen blocking view is shown. Users cannot dismiss this screen and must update to continue using the app.

## Configuring Force Updates

Force updates are triggered based on a **minimum app version** that you specify in the app store description.

### Google Play Store

Add this text anywhere in your Play Store listing description:

```
[Minimum supported app version: X.Y.Z]
```

**Example:**
```
[Minimum supported app version: 1.2.0]
```

Users with app versions below 1.2.0 will see the force update screen.

### Apple App Store

Add this text anywhere in your App Store description:

```
[:mav: X.Y.Z]
```

**Example:**
```
[:mav: 1.2.0]
```

Users with app versions below 1.2.0 will see the force update screen.

## How It Works

1. **App Launch**: During splash screen initialization, `AppUpdateService` is initialized
2. **Version Check**: The service queries the respective app store for the latest version
3. **Comparison**: Current app version is compared against the store version
4. **Force Check**: If a minimum version is specified in the store description and the current version is below it, a force update is triggered
5. **Prompt Display**:
   - Force update → Full-screen blocking view
   - Optional update → Dismissible dialog

## Implementation Details

### Key Files

| File | Purpose |
|------|---------|
| `lib/app/data/services/app_update_service.dart` | Core service for version checking |
| `lib/app/ui/widgets/dialogs/update_dialog.dart` | Optional update dialog |
| `lib/features/update/views/force_update_view.dart` | Force update screen |
| `lib/features/splash/controllers/splash_controller.dart` | Integration point |

### Cooldown Logic

When a user taps "Remind Me Later":
- The current timestamp and dismissed version are saved locally
- The prompt won't appear again for 24 hours
- If a new version is released (different from dismissed version), the prompt appears immediately

### Error Handling

If the update check fails (network issues, store unavailable, etc.):
- The error is logged
- The app continues normally without showing any prompt
- Update check is retried on next app launch

## Testing

### Debug Mode

During development, you can test the update flow by:

1. Modifying `AppUpdateService` to set `debugLogging: true` (already enabled in dev builds)
2. Using the upgrader package's debug mode to simulate updates

### Testing Force Updates

To test force update behavior locally:

1. Temporarily modify `_checkIsForceUpdate()` in `AppUpdateService` to return `true`
2. Launch the app to see the force update screen
3. Revert the change after testing

## Localization

Update prompts are localized. Translation keys are in:
- `l10n/en.json` - English
- `l10n/hi.json` - Hindi

Key strings:
```json
"update": {
  "title": "Update Available",
  "new_version_available": "Version @version is now available",
  "update_now": "Update Now",
  "remind_later": "Remind Me Later",
  "required_title": "Update Required",
  "required_message": "A critical update is required..."
}
```

## Troubleshooting

### Update prompt not showing

1. Ensure the app is published to the store with a higher version
2. Check network connectivity
3. Verify the app's package name/bundle ID matches the store listing
4. Check logs for `AppUpdateService` messages

### Force update not triggering

1. Verify the minimum version tag is correctly formatted in the store description
2. Ensure the current app version is actually below the minimum
3. Store description changes may take time to propagate

### Store URL not opening

1. Check if `url_launcher` is properly configured
2. Verify the store URL is valid in the logs
3. On emulators, the Play Store may not be available
