# DeviceSpoofLabs

A Magisk module for spoofing device identity properties for testing and development purposes. Spoofs device properties to act like a brand new Pixel 7 Pro. Also changes props to hide emulator detection. Best used with Shamiko

## ⚠️ Legal Disclaimer

**THIS MODULE IS FOR EDUCATIONAL, TESTING, AND DEVELOPMENT PURPOSES ONLY.**

- Use this module responsibly and only on devices you own
- Do NOT use to bypass app restrictions, violate terms of service, or engage in fraudulent activity
- The author (@yubunus) is NOT responsible for any misuse or damage
- Changing device identifiers may violate app terms of service
- Some apps may ban accounts for device spoofing
- Use at your own risk

## 📋 Features

### Automatic Device Property Spoofing

- **Target Device**: Google Pixel 7 Pro (cheetah)
- **Android Version**: Android 14
- **Build**: UP1A.231005.007
- **Security Patch**: 2023-10-05 (matches fingerprint)

Spoofed properties include:

- Device brand, model, manufacturer, name
- Hardware platform (Google Tensor G2)
- Build fingerprint (real Pixel 7 Pro fingerprint)
- Security patch level
- System, vendor, and ODM props
- Anti-emulator detection props

### Manual ANDROID_ID Changer

- Interactive menu-driven script
- Automatic backup before changes
- Cryptographically secure random ID generation
- Easy restoration from backup
- Safety warnings and confirmations

## 🚀 Installation

### Prerequisites

- Rooted Android device
- [Magisk](https://github.com/topjohnwu/Magisk) v24.0 or higher installed
- Magisk Manager app

### Installation Steps

1. **Download the module**

   - Download the latest `devicespooflab-v1.0.zip` from [Releases](https://github.com/yubunus/DeviceSpoofLab-Magisk/releases)

2. **Install via Magisk Manager**

   - Open Magisk Manager app
   - Tap on **Modules** (bottom navigation)
   - Tap **Install from storage** (floating action button)
   - Select the downloaded `devicespooflab-v1.0.zip` file
   - Wait for installation to complete
   - Tap **Reboot** when prompted

3. **Verify Installation**
   - After reboot, open Magisk Manager
   - Navigate to **Modules**
   - Verify "DeviceSpoofLabs" is enabled (checked)
   - Check device props:
     ```bash
     adb shell getprop ro.product.model
     # Should output: Pixel 7 Pro
     ```

## 📖 Usage

### Device Property Spoofing

Device properties are **automatically spoofed on every boot** after module installation. No manual action required.

To verify spoofing is active:

```bash
# Via ADB
adb shell getprop ro.product.model
adb shell getprop ro.build.fingerprint
adb shell getprop ro.build.version.security_patch

# On device (Termux or Terminal Emulator)
su
getprop ro.product.model
getprop ro.build.fingerprint
```

Expected output:

```
ro.product.model: Pixel 7 Pro
ro.build.fingerprint: google/cheetah/cheetah:14/UP1A.231005.007/10754064:user/release-keys
ro.build.version.security_patch: 2023-10-05
```

### ANDROID_ID Changer (Manual Script)

⚠️ **WARNING**: Changing ANDROID_ID can cause serious issues!

#### Potential Side Effects:

- **App Logouts**: Most apps will log you out and require re-authentication
- **Google Play Services**: May reset, requiring Google account re-login
- **DRM Content**: Licensed content may become inaccessible
- **In-App Purchases**: May be lost or require restoration
- **Banking Apps**: May flag as suspicious activity and lock your account
- **Device Registration**: Apps tied to device ID will need re-registration
- **SafetyNet**: May fail SafetyNet checks (banking, Netflix, etc.)

#### Running the Script

**Method 1: Interactive Menu (Recommended)**

Via ADB:

```bash
adb shell su -c /data/adb/modules/devicespooflab/common/change_android_id.sh
```

Via Termux or Terminal Emulator on device:

```bash
su
/data/adb/modules/devicespooflab/common/change_android_id.sh
```

This will launch an interactive menu:

```
=========================================
  DeviceSpoofLabs - ANDROID_ID Changer
=========================================

ℹ️  Current ANDROID_ID: 1234567890abcdef

Select an option:
  1) Change ANDROID_ID to new random value
  2) Restore ANDROID_ID from backup
  3) View current ANDROID_ID and backup
  4) Exit

Enter choice [1-4]:
```

**Method 2: Command-Line Mode**

Change ANDROID_ID:

```bash
su -c '/data/adb/modules/devicespooflab/common/change_android_id.sh change'
```

Restore from backup:

```bash
su -c '/data/adb/modules/devicespooflab/common/change_android_id.sh restore'
```

View current ID and backup:

```bash
su -c '/data/adb/modules/devicespooflab/common/change_android_id.sh view'
```

#### After Changing ANDROID_ID

**IMPORTANT**: You MUST reboot your device after changing ANDROID_ID for changes to take full effect across all apps and services.

```bash
# Reboot command
su -c reboot
```

### Backup Location

ANDROID_ID backups are stored in:

```
/data/adb/modules/devicespooflab/android_id.backup
```

This file contains:

- Timestamp of backup
- Original ANDROID_ID value

**Keep this file safe** if you want to restore your original ANDROID_ID later.

## 🔄 Reverting Changes

### Revert Device Props

To stop spoofing device properties:

1. Open Magisk Manager
2. Go to **Modules**
3. Disable or uninstall "DeviceSpoofLabs"
4. Reboot device

Your original device properties will be restored.

### Revert ANDROID_ID

Run the restore command:

```bash
su -c '/data/adb/modules/devicespooflab/common/change_android_id.sh restore'
```

Or use the interactive menu (option 2).

Then reboot:

```bash
su -c reboot
```

## 🛠️ Advanced Usage

### Customizing Spoofed Device

You can edit the spoofed device properties by modifying `post-fs-data.sh`:

```bash
# Via ADB
adb pull /data/adb/modules/devicespooflab/post-fs-data.sh
# Edit the file locally
adb push post-fs-data.sh /data/adb/modules/devicespooflab/
adb shell chmod 755 /data/adb/modules/devicespooflab/post-fs-data.sh
adb reboot
```

**Important Rules for Custom Fingerprints:**

- ✅ Use REAL device fingerprints (not fake/made-up)
- ✅ Match security patch to the fingerprint build date
- ✅ Ensure all props are consistent (brand, device, model must match)
- ❌ Don't mix props from different devices
- ❌ Don't use outdated security patches with recent fingerprints

### Finding Real Device Fingerprints

Sources for legitimate fingerprints:

- [Google Factory Images](https://developers.google.com/android/images)
- [LineageOS Wiki](https://wiki.lineageos.org/devices/)
- [XDA Forums](https://forum.xda-developers.com/)
- Your own device: `getprop ro.build.fingerprint`

## 🐛 Troubleshooting

### Device Props Not Changing

**Problem**: `getprop` still shows old device model

**Solutions**:

1. **Check for MagiskHide Props Config conflict**: If you have MagiskHide Props Config installed, it will override this module's props. Disable it:
   ```bash
   adb shell su -c 'touch /data/adb/modules/MagiskHidePropsConf/disable'
   adb reboot
   ```
2. Verify module is enabled in Magisk Manager
3. Reboot device again (props change requires reboot)
4. Check Magisk logs: `adb logcat | grep DeviceSpoofLabs`
5. Ensure `post-fs-data.sh` has execute permissions (755)
6. Try reinstalling the module

### ANDROID_ID Script Fails

**Problem**: Permission denied or script won't run

**Solutions**:

```bash
# Fix permissions
su
chmod 755 /data/adb/modules/devicespooflab/common/change_android_id.sh

# Verify script exists
ls -l /data/adb/modules/devicespooflab/common/change_android_id.sh

# Run with explicit shell
su -c 'sh /data/adb/modules/devicespooflab/common/change_android_id.sh'
```

### Apps Detecting Magisk/Root

**Problem**: Apps refuse to run due to root detection

**Solutions**:

- Use [Magisk Hide](https://github.com/topjohnwu/Magisk/blob/master/docs/guides.md#magiskhide) / Zygisk DenyList
- Install [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases) for advanced hiding
- This module doesn't hide root - it only spoofs device props

### SafetyNet Failing

**Problem**: SafetyNet attestation fails after using module

**Note**: This module spoofs device props but doesn't guarantee SafetyNet pass. SafetyNet depends on many factors.

**Solutions**:

- Use [Universal SafetyNet Fix](https://github.com/kdrag0n/safetynet-fix)
- Ensure you're using a real device fingerprint (this module does)
- Check bootloader unlock status
- Some apps may still detect modifications

### Can't Restore ANDROID_ID

**Problem**: Backup file is missing or corrupted

**Solutions**:

1. Check if backup exists:

   ```bash
   su -c cat /data/adb/modules/devicespooflab/android_id.backup
   ```

2. If backup is lost, you'll need to:

   - Accept the new ANDROID_ID (apps will eventually sync)
   - Or use a backup from your device backup system
   - Or factory reset (last resort - data loss!)

3. Prevent future issues:
   ```bash
   # Make a copy of the backup
   su -c cp /data/adb/modules/devicespooflab/android_id.backup /sdcard/
   ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
