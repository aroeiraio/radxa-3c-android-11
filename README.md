# Android 11 - Radxa Rock 3C

This repository contains comprehensive implementations to enable advanced functionality on the Radxa Rock 3C single-board computer running Android 11. 

The project focuses on three main areas:

- **Touchscreen Rotation**: Manual display rotation control through Android Settings
- **Wi-Fi Support**: Full AIC8800D80 Wi-Fi implementation with modern security protocols
- **Bluetooth Support**: Complete AIC8800 Bluetooth 4.2/5.0 BLE integration

## Project Objective

This implementation provides a complete Android 11 solution for the Radxa Rock 3C, transforming it from a basic Android device into a fully functional development board with enterprise-grade connectivity features. The project emphasizes clean, maintainable code using Android's overlay mechanism rather than framework modifications, ensuring compatibility with future Android updates.

**Target Hardware**: Radxa Rock 3C (Board version 1.4) with Rockchip RK356x SoC  
**Android Version**: Android 11 (API Level 30)  
**Manifest**: Android11_Radxa_rk11


## Repository initialization and sync

```bash
repo init -u https://github.com/radxa/manifests.git -b Android11_Radxa_rk11 -m rockchip-r-release.xml
repo sync -d -c -j4
```
Syncing will take several minutes and consume approximately 115GB of storage.


## Image generation

```
cd REPO_FOLDER
source build/envsetup.sh
lunch rk356x_rock_3c_r-userdebug
./build.sh -UACKup

```
Building will take many hours. Bear in mind that CPU cores and memory space (RAM) plays an important factor on this.
The test machine used an Intel Core i5 12th gen (12 cores) with 48GB RAM + 20GB swap space.


## Tests

✅  Rotation is configurable through Android Settings and persists across reboots
✅  WIFI works flawlessly, but automatic connection to saved SSIDs is disabled when Ethernet is connected
✅  Bluetooth works flawlessly

## Documentation

There are some documentation created by claude describing all details of what was modified in the AOSP provided by Radxa.
Some modifications were more complex and extensive than initially expected.

Comprehensive documentation is available in the [`/doc`](./doc/) directory, covering all implementation details, technical specifications, and configuration options:

### Core Features
- **[Touchscreen Rotation Overview](./doc/TOUCHESCREEN_OVERVIEW.md)** - Complete guide to manual display rotation implementation
- **[Touchscreen Rotation Changes](./doc/TOUCHSCREEN_ROTATION_CHANGES.md)** - Detailed technical changes and modifications
- **[Wi-Fi Implementation](./doc/WIFI_IMPLEMENTATION.md)** - AIC8800D80 Wi-Fi integration guide
- **[Wi-Fi Implementation Details](./doc/WIFI_IMPLEMENTATION_DETAILS.md)** - Technical deep-dive into Wi-Fi configuration
- **[Wi-Fi Quick Reference](./doc/WIFI_QUICK_REFERENCE.md)** - Quick setup and troubleshooting guide

### Connectivity & Hardware
- **[AIC8800 Bluetooth Integration](./doc/AIC8800_BLUETOOTH_INTEGRATION.md)** - Bluetooth 4.2/5.0 BLE implementation
- **[AIC8800 Bluetooth Detailed Changes](./doc/AIC8800_BLUETOOTH_DETAILED_CHANGES.md)** - Comprehensive Bluetooth modification details
- **[Kernel Configuration](./doc/KERNEL_CONFIGURATION.md)** - Kernel-level changes and device tree modifications

### Tools & Utilities
- **[Scripts and Services](./doc/SCRIPTS_SERVICES.md)** - Shell scripts and init services for advanced use cases




