# AwesomeBattery

A macOS menu bar application that provides visual battery alerts through screen borders.

## Features

- Menu bar battery percentage indicator
- Visual border alerts when battery is low
- Configurable alert and critical battery thresholds
- Automatic border width adjustment based on screen size
- Multi-screen support
- "Charge Now" warning text for extremely low battery

## How It Works

The app monitors your MacBook's battery level and provides visual feedback through colored borders around your screen(s):

### Alert State (11%-20% by default)
- Shows a red border around all screens
- Border width gradually increases as battery level drops
- Maximum border width is 1.6% of the smallest screen dimension

### Critical State (10% and below by default)
- Border starts flashing to grab attention
- Uses maximum border width (1.6% of smallest screen dimension)
- Shows "CHARGE NOW" warning text when battery drops below half of critical threshold (5%)

### Normal State (Above 20% by default)
- No border shown
- Battery percentage visible in menu bar

### Charging State
- All alerts are cleared
- Border disappears
- Battery percentage shows charging indicator in menu bar

## Settings

You can configure:
- Alert battery threshold (default: 20%)
- Critical battery threshold (default: 10%, cannot be set lower than 2% or higher than alert threshold)
- Enable/disable the app from the menu bar

## Installation

1. Download the latest AwesomeBattery_Installer.dmg
2. Open the DMG file
3. Drag AwesomeBattery to your Applications folder
4. Launch AwesomeBattery from Applications
5. (Optional) Add to Login Items to start automatically

## System Requirements

- macOS 11.0 or later
- Apple Silicon or Intel Mac

## Privacy & Permissions

The app requires:
- Permission to run in the background
- Screen recording permission (to draw borders around screens)

## Building from Source

1. Clone the repository
2. Open in Xcode
3. Build and run

## License

Copyright © 2025 Manisha. All rights reserved.
