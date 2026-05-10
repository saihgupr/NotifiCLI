# Changelog

All notable changes to this project will be documented in this file.

## [1.4.1] - 2026-05-10
### Added
- **Shorthand Flags**: Added standard one-letter flags for faster CLI usage:
  - `-t` for `-title`
  - `-m` for `-message`
  - `-s` for `-subtitle`
  - `-a` for `-actions`
  - `-i` for `-icon`
  - `-u` for `-url`
  - `-v` for `-version`
- **Homebrew Automation**: Added `postflight` script to the Homebrew Cask to automatically clear macOS Gatekeeper/Quarantine flags upon installation.

### Changed
- Improved usage/help message to include shorthand flags.
- Updated DMG distribution with a `Fix Security.command` script.

## [1.4.0] - 2024-04-10
### Added
- **Icon Variants**: Support for using any application's icon via the `-icon` flag.
- **Automatic Caching**: NotifiCLI now automatically generates and caches app-specific variants.
- **Keyboard Maestro Action**: Added native support for Keyboard Maestro integration.

## [1.3.4] - 2024-03-25
### Added
- Initial support for actionable notifications with custom buttons.
- `-reply` flag for capturing text input from notifications.
- `-persistent` flag for sticky alerts.
