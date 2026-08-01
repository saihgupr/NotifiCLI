# Changelog

All notable changes to NotifiCLI will be documented in this file.

## [1.4.2] - 2026-08-01

### Added
- Standard double-dash (`--`) flag support for all CLI parameters alongside existing single-dash (`-`) flags (e.g., `--title`, `--message`, `--persistent`, etc.) (#14).
- Added `-img` as a supported alias for the `-image` parameter (#16).

## [1.4.1] - 2026-07-16

### Fixed
- Fixed app bundle path resolution when installed via Homebrew Cask with custom `--appdir` (#15, #17).

## [1.4.0] - 2026-06-01

### Added
- Per-notification persistence support (`-persistent` / `-p`).
- Action buttons and reply input support.
- Custom icon caching (`-icon` / `-app`).
