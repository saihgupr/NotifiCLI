# NotifiCLI

A lightweight, headless macOS command-line tool for sending actionable, persistent notifications.

Unlike `terminal-notifier`, NotifiCLI offers:
- **Reply input** — capture typed responses with `-reply` (removed from terminal-notifier in v1.7)
- **Per-notification persistence** — use the `-persistent` flag instead of a system-wide setting
- **Stdout scripting** — outputs clicked actions, reply text, or dismissals (terminal-notifier outputs nothing)
- **Custom icons** — use any app's icon via `-icon`, with automatic caching shorthand

<table>
  <tr>
    <td align="center" valign="top" width="50%">
      <b>Action Buttons</b><br>
      <img src="images/actions.png?raw=true" width="100%"><br>
      <code>notificli -title "Deploy to Production?" -message "Version 1.4.0 is ready." -actions "Deploy Now,Schedule Later,Cancel"</code>
    </td>
    <td align="center" valign="top" width="50%">
      <b>Reply Input</b><br>
      <img src="images/reply.png?raw=true" width="100%"><br>
      <code>notificli -title "Weekend Trip" -message "What time do you want to leave on Friday?" -reply "Time you want to leave"</code>
    </td>
  </tr>
  <tr>
    <td align="center" valign="top" width="50%">
      <b>Notification Image</b><br>
      <img src="images/image.png?raw=true" width="100%"><br>
      <code>notificli -title "hi" -subtitle "hello" -message "what's up" -image "https://images.unsplash.com/photo..."</code>
    </td>
    <td align="center" valign="top" width="50%">
      <b>Open URL</b><br>
      <img src="images/url.png?raw=true" width="100%"><br>
      <code>notificli -title "Package Delivered" -subtitle "Your order has arrived at the front door." -message "Click to open website" -url "https://fedex.com/track"</code>
    </td>
  </tr>
</table>

<details>
<summary><b>Full Parameter List & Arguments</b></summary>

### Arguments
Both standard double-dash (`--flag`) and legacy single-dash (`-flag`) forms are supported.

| Flag | Shorthand | Description |
| :--- | :--- | :--- |
| `--title` / `-title` | `-t` | The bold title of the notification. |
| `--message` / `-message` | `-m` | The body text/subtitle. |
| `--persistent` / `-persistent` | `-p` | Notification stays on screen until dismissed. |
| `--icon` / `--app` / `-icon` / `-app` | `-i` / `-a` | Path to an `.app` (or just its name) to use its icon. |
| `--subtitle` / `-subtitle` | | (Optional) Secondary text line below the title. |
| `--actions` / `-actions` | | (Optional) Comma-separated list of button labels. |
| `--image` / `--img` / `-image` / `-img` | | (Optional) Path to an image file (right thumbnail). |
| `--reply` / `-reply` | | (Optional) Adds a "Reply" button with text input. |
| `--url` / `-url` | | (Optional) Opens the specified URL when clicked. |
| `--sound` / `-sound` | | (Optional) System sound or file path. |

### Output Behavior
When using `-actions`, `-reply`, or `-url`, the command waits for user interaction and prints the result:
- **Action buttons**: Prints the clicked button label (e.g., `Yes`)
- **Reply**: Prints the user's typed text directly
- **Dismiss**: Prints `dismissed`
- **Click notification**: Prints `default` (and opens URL if specified)
</details>

## Persistent Mode

To use persistent alerts (notifications that don't disappear), use the `-p` or `-persistent` flag.

<details>
<summary><b>Setup & Configuration</b></summary>

**Naming Convention:**
Standard variants and Persistent variants are separated in macOS settings so you can have different rules for each:
- **Standard**: `Safari`
- **Persistent**: `Safari (Persistent)`

**Setup:**
1. Run a persistent test: `notificli -m 'Setup' -p`
2. Open **System Settings > Notifications**.
3. Find the entry ending in **(Persistent)**.
4. Change the **Alert Style** from *Banners* to **Alerts** (Persistent).
</details>

## Scripting Examples

NotifiCLI pauses execution until the user clicks a button. Capture the output to drive your logic:

```bash
RESPONSE=$(notificli -persistent \
  -title 'Deploy?' \
  -message 'Verify production deploy?' \
  -actions 'Yes,No')

if [ "$RESPONSE" == "Yes" ]; then
  echo "Deploying..."
elif [ "$RESPONSE" == "No" ]; then
  echo "Aborted."
else
  echo "Dismissed."
fi
```

<details>
<summary><b>Advanced: Multi-Step & User Interaction</b></summary>

### Multi-Step Workflow
Chain notifications for complex interactive scripts:

```bash
#!/bin/bash
RESPONSE=$(notificli -persistent \
  -title 'Deploy to Production?' \
  -message 'Version 1.4.0 is ready.' \
  -actions 'Deploy Now,Schedule Later,Cancel' \
  -icon 'Terminal' -sound 'Glass')

case "$RESPONSE" in
  'Deploy Now')
    notificli -title 'Deploying!' -message 'Pushing to production...'
    # ... run deploy script ...
    notificli -title 'Success!' -message 'v1.4.0 is now live!' -sound 'Glass'
    ;;
  'Schedule Later')
    WHEN=$(notificli -persistent -title 'Schedule Deploy' \
      -message 'When should we deploy?' -reply 'e.g., tomorrow 3am')
    notificli -title 'Scheduled' -message "Deploy set for: $WHEN"
    ;;
  'Cancel'|'dismissed')
    notificli -title 'Cancelled' -message 'Deployment aborted'
    ;;
esac
```

### Reply Input
Capture user input directly:
```bash
OUTPUT=$(notificli -title 'Status' -message 'Update status?' -reply 'Type here')
echo "You typed: $OUTPUT"
```

### Open URL
Open a link when the user clicks:
```bash
notificli -title 'Build Failed' -message 'Click to view logs' -url 'https://github.com/my/repo/actions'
```
</details>

## Installation

### Option 1: Homebrew (Recommended)

The cleanest install — no security warnings, auto-updates via `brew upgrade`:

```bash
brew tap saihgupr/notificli
brew install --cask notificli
```

Homebrew automatically removes macOS quarantine restrictions, so the app opens without any Gatekeeper dialog.

---

### Option 2: Manual DMG Install

1. **Download `NotifiCLI.dmg`** from [Releases](https://github.com/saihgupr/NotifiCLI/releases)
2. Open the DMG and drag **`NotifiCLI.app`** to your **Applications** folder
3. **Fix the security warning** — on macOS Sequoia/Tahoe, double-clicking the app shows *"Apple could not verify..."* with no "Open Anyway" button. Use one of these fixes:
   - **Easy**: Double-click **`Fix Security.command`** (included in the DMG) → Terminal opens, runs the fix, confirms with a dialog. *(macOS may ask permission to run it — click Allow.)*
   - **Terminal**: `xattr -cr /Applications/NotifiCLI.app`
4. Open **`NotifiCLI.app`** normally to grant notification permissions

**Add to PATH** (optional):
```bash
ln -s /Applications/NotifiCLI.app/Contents/MacOS/notificli /usr/local/bin/notificli
```

<details>
<summary><b>Build from Source</b></summary>

```bash
./build.sh
```
</details>

## 🔐 Security & Gatekeeper (macOS)

NotifiCLI is not signed with a paid Apple Developer certificate. On macOS Sequoia and Tahoe, this means the app shows **only "Move to Trash"** when first launched — the "Open Anyway" button no longer appears.

**The fix is a one-liner:**
```bash
xattr -cr /Applications/NotifiCLI.app
```

Or use the **`Fix Security.command`** included in the DMG — just double-click it after dragging the app to Applications.

> [!TIP]
> Avoid all of this by installing via **Homebrew**, which handles quarantine automatically.

<details>
<summary><b>Keyboard Maestro Plug-in</b></summary>

<img src="images/km.png?raw=true" width="600">

NotifiCLI includes a native **Keyboard Maestro Action** for easy integration into your macros.

### Installation Guide
1. **Install the main app first**: Ensure `NotifiCLI.app` is in your `/Applications` folder.
2. Download the action folder from [here](https://github.com/saihgupr/NotifiCLI/tree/main/Keyboard-Maestro-Action/NotifiCLI).
3. Move the contents of the folder to:
   `~/Library/Application Support/Keyboard Maestro/Keyboard Maestro Actions/NotifiCLI`
4. Restart the Keyboard Maestro Engine.

> [!IMPORTANT]
> **Security Warning (Gatekeeper)**
> macOS may block the embedded action. If it fails to run:
> 1. Go to the action folder: `~/Library/Application Support/Keyboard Maestro/Keyboard Maestro Actions/NotifiCLI`
> 2. Right-click `NotifiCLI.app` inside that folder and choose **Open**.
> 3. Click **Open** in the dialog to whitelist it.

### Usage
- Add the **"NotifiCLI"** action to your macro.
- Fill in the Title, Subtitle, and Message.
- Use the **"Actions"** field for comma-separated buttons.
- The action saves the result to a variable for use in "If Then Else" logic.
</details>

## Custom Icons

Use any app's icon for your notifications:

```bash
notificli -icon 'Terminal' -title 'Build' -message 'Complete'
```

<details>
<summary><b>Advanced: Automatic Caching & Permissions</b></summary>

### Automatic Caching
The first time you use a new icon, NotifiCLI creates a variant (takes ~1 second). Subsequent uses are instant.
```bash
# Shorthand works after first run
notificli -icon 'Spotify' -title 'Now Playing' -message 'Song Name'
```

> [!IMPORTANT]
> **macOS Security (Sequoia/Tahoe)**
> Each custom icon variant acts as a unique app. The first time you use a new icon, it may be blocked.
> **The Fix**: Run this command to prompt for access for all variants:
> ```bash
> find /Applications/NotifiCLI.app/Contents/Apps -name '*.app' -maxdepth 1 -exec open {} \;
> ```

> [!WARNING]
> **Notification Preferences Bloat**
> Each custom icon variant appears in **System Settings > Notifications**. Be selective with which icons you generate!
</details>

## Troubleshooting

<details>
<summary><b>Common Issues & Fixes</b></summary>

**"Notifications are not allowed"**
1. **The Finder Trick**: Navigate to `/Applications/NotifiCLI.app/Contents/Apps`, right-click the variant, and choose **Open**.
2. **System Settings**: Check **System Settings > Notifications** for the variant name and enable "Allow Notifications".
3. **Verify Location**: Ensure `NotifiCLI.app` is in `/Applications/`.
</details>

---

## Issues & Feedback

Found a bug or have a feature request? [Open an issue](https://github.com/saihgupr/NotifiCLI/issues)

If you like this project, please consider giving the repo a star!