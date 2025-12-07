# DeviceSpoofLabs

A Magisk module for spoofing device identity properties. Spoofs device as a brand new Google Pixel 7 Pro running Android 15 with comprehensive persona management. For development and testing purposes only.

## Limitations (Cannot Be Spoofed with Pure Magisk)

**Note:** The identifiers below require advanced hooks and cannot be spoofed by Magisk alone.<br>
They are supported via our companion Xposed module: [DeviceSpoofLabs-Hooks](https://github.com/yubunus/DeviceSpoofLabs-Hooks)

| Identifier                            | Reason                                       |
| ------------------------------------- | -------------------------------------------- |
| **IMEI/MEID**                         | Requires TelephonyManager framework hooks    |
| **IMSI**                              | Requires SIM framework hooks                 |
| **EID**                               | Requires eUICC framework hooks               |
| **SIM Serial (ICCID)**                | Requires TelephonyManager hooks              |
| **MAC Address**                       | Network-level change may break connectivity  |
| **IP Address**                        | Network-level change may break connectivity  |
| **GAID (Advertising ID)**             | Requires Google Play Services hooks          |
| **Google App Set ID**                 | Requires Play Services hooks                 |
| **MediaDrm deviceUniqueId**           | Requires DRM framework hooks                 |
| **Widevine UUID**                     | Requires DRM framework hooks                 |
| **Installation UUID / App Device ID** | Per-app storage (cleared via app data reset) |

**What CAN be spoofed:**

- All `ro.*` build properties (50+ props)
- `Settings.Secure.ANDROID_ID`
- Screen size/density via `wm` commands
- GSM operator properties
- Serial numbers

---

## Legal Disclaimer

**THIS MODULE IS FOR EDUCATIONAL, TESTING, AND DEVELOPMENT PURPOSES ONLY.**

- Use this module responsibly and only on devices you own
- Do NOT use to bypass app restrictions, violate terms of service, or engage in fraudulent activity
- The author (@yubunus) is NOT responsible for any misuse or damage
- Changing device identifiers may violate app terms of service
- Some apps may ban accounts for device spoofing
- Use at your own risk

---

## Features

### v2.0 - Persona Management System

- **Target Device**: Google Pixel 7 Pro (cheetah)
- **Android Version**: Android 15
- **Build**: AP4A.241205.013 (December 2024)
- **Security Patch**: 2024-12-05

### Key Features

1. **Interactive CLI** (`devicespooflabs` command)

   - Persona management menu
   - App data/cache clearing tools
   - Validation and status checks

2. **Automatic Persona Persistence**

   - Persona saves across reboots
   - Auto-applies on every boot
   - No manual intervention needed after setup

3. **Backup & Restore**

   - Original device identity backed up on first boot
   - Easy restore to original state

4. **App Data Cleaner**
   - Clear all third-party app data
   - Clear Chrome/WebView/Google Play Services
   - Reset app-specific identifiers

### Spoofed Properties Include

- Device brand, model, manufacturer, name
- Hardware platform (Google Tensor G2 / gs201)
- Build fingerprint (real Pixel 7 Pro Android 15 fingerprint)
- Security patch level (2024-12-05)
- System, vendor, and ODM partition props
- Anti-emulator detection props
- Serial number (randomized per persona)
- ANDROID_ID (randomized per persona)
- Screen size/density (1440x3120 @ 512dpi)

---

## Installation

### Prerequisites

- Rooted Android device
- [Magisk](https://github.com/topjohnwu/Magisk) v24.0 or higher
- Magisk Manager app

### Installation Steps

1. **Download the module**

   - Download `devicespooflab-v2.0.zip` from Releases

2. **Install via Magisk Manager**

   - Open Magisk Manager
   - Tap **Modules** (bottom navigation)
   - Tap **Install from storage**
   - Select the downloaded zip file
   - Wait for installation
   - **Reboot** when prompted

3. **First Boot**

   - Module automatically backs up your original device identity
   - **No spoofing is applied yet** - your device remains unchanged
   - Run `devicespooflabs` to set up your first persona

4. **Set Up Persona**

   ```bash
   adb shell
   su
   devicespooflabs
   # Select [1] Persona Management
   # Select [2] Generate NEW persona
   # Select [1] or [2] to generate
   # Reboot when prompted
   ```

5. **Verify Installation** (after persona is set up and reboot)

   ```bash
   adb shell su -c 'getprop ro.product.model'
   # Should output: Pixel 7 Pro

   adb shell su -c 'getprop ro.build.fingerprint'
   # Should output: google/cheetah/cheetah:15/AP4A.241205.013/12621605:user/release-keys
   ```

---

## Usage

### CLI Interface

After installation and reboot, run the CLI:

```bash
adb shell
su
devicespooflabs
```

You'll see:

```
  ____             _           ____                    __ _          _
 |  _ \  _____   _(_) ___ ___ / ___| _ __   ___   ___ / _| |    __ _| |__  ___
 | | | |/ _ \ \ / / |/ __/ _ \\___ \| '_ \ / _ \ / _ \ |_| |   / _` | '_ \/ __|
 | |_| |  __/\ V /| | (_|  __/ ___) | |_) | (_) | (_) |  _| |__| (_| | |_) \__ \
 |____/ \___| \_/ |_|\___\___|____/| .__/ \___/ \___/|_| |_____\__,_|_.__/|___/
                                   |_|                              v2.0

-------------------------------------------

[INFO] Active: Pixel 7 Pro - Android 15
[INFO] Model: Pixel 7 Pro

-------------------------------------------

  [1] Persona Management
  [2] App Data / Cache Tools
  [0] Exit

-------------------------------------------

Select an option:
```

### Persona Management Menu

```
[1] View current persona      - Shows persona details with live validation
[2] Generate NEW persona      - Creates new random identifiers
[3] Restore default persona   - Restores original device identity from backup
[0] Back
```

### Generate NEW Persona

When generating a new persona:

```
[1] Continue and generate new identifiers only
    - New serial number
    - New ANDROID_ID
    - Same Pixel 7 Pro device props
    - Requires reboot

[2] Continue and generate new identifiers + reset ALL apps
    - All of the above PLUS
    - Clears all third-party app data
    - Clears Chrome/WebView/GMS
    - Completely fresh start

[0] Cancel
```

### App Data / Cache Tools

```
[1] Clear ALL third-party app data
[2] Clear Chrome/WebView/GMS only
[3] Clear EVERYTHING (third-party + system)
[4] List installed third-party apps
[0] Back
```

---

## Flow

1. **Install module** → Reboot
2. **First boot**:
   - Original device backed up to `personas/backup.conf`
   - **No spoofing applied** - device identity unchanged
3. **Run `devicespooflabs`** to set up:
   - Generate NEW persona (creates random serial/ANDROID_ID)
   - Reboot to apply
4. **After setup, run `devicespooflabs`** when you want to:
   - View current persona status
   - Generate a completely new identity
   - Clear app data
   - Restore to original device
5. **Reboot** after generating new persona for full effect
6. **Persona persists** across all future reboots until changed

---

## File Locations

| File                                                                 | Purpose                      |
| -------------------------------------------------------------------- | ---------------------------- |
| `/data/adb/modules/devicespooflab/personas/current.conf`             | Active persona configuration |
| `/data/adb/modules/devicespooflab/personas/backup.conf`              | Original device backup       |
| `/data/adb/modules/devicespooflab/personas/pixel7pro_android15.conf` | Default template             |
| `/data/local/tmp/devicespooflab.log`                                 | Module logs                  |

---

## Verification Commands

```bash
# Check model
getprop ro.product.model

# Check fingerprint
getprop ro.build.fingerprint

# Check security patch
getprop ro.build.version.security_patch

# Check Android version
getprop ro.build.version.release

# Check ANDROID_ID
settings get secure android_id

# Check serial
getprop ro.serialno

# View module logs
cat /data/local/tmp/devicespooflab.log
```

---

## Reverting Changes

### Restore Original Device

```bash
su
devicespooflabs
# Select [1] Persona Management
# Select [3] Restore default persona
# Reboot
```

Or completely remove:

1. Open Magisk Manager
2. Go to **Modules**
3. Uninstall "DeviceSpoofLabs"
4. Reboot

---

## Troubleshooting

### Props Not Changing

1. Verify module is enabled in Magisk Manager
2. Check logs: `cat /data/local/tmp/devicespooflab.log`
3. Ensure no conflicting modules (MagiskHide Props Config)
4. Reboot device

### devicespooflabs Command Not Found

```bash
# Direct path
/data/adb/modules/devicespooflab/common/devicespooflabs.sh

# Or wait for next reboot (symlink created by service.sh)
```

### ANDROID_ID Not Changing

1. ANDROID_ID is applied after boot completes (service.sh)
2. Some ROMs protect ANDROID_ID changes
3. Check logs for errors
4. Try generating new persona and rebooting

### Apps Still Detecting Original Device

- Some apps cache device info - clear their data
- Some apps use hardware-level identifiers (see Limitations)
- Use Shamiko/LSPosed for additional hiding

---

## Complementary Tools

For best results, consider using:

- [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases) - Hide root from apps
- [Play Integrity Fix](https://github.com/chiteroman/PlayIntegrityFix) - Pass Play Integrity
- [LSPosed](https://github.com/LSPosed/LSPosed) - For additional spoofing via Xposed modules

---

## Changelog

### v2.0

- Complete rewrite with persona management system
- Interactive CLI (`devicespooflabs` command)
- Updated to Pixel 7 Pro Android 15 (December 2024 security patch)
- Auto-apply persona on boot
- Backup and restore original device
- App data clearing tools
- Randomized serial and ANDROID_ID per persona
- Comprehensive logging

### v1.0

- Initial release
- Basic Pixel 7 Pro Android 14 spoofing
- Manual ANDROID_ID changer script

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
