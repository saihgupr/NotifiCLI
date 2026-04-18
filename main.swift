import Foundation
import UserNotifications
import AppKit

// MARK: - Argument Parsing
var title: String?
var subtitle: String?
var message: String?
var actions: [String] = []
var imagePath: String?
var soundName: String?
var replyPlaceholder: String?
var openUrl: String?


var args = CommandLine.arguments.dropFirst()
while let arg = args.popFirst() {
    switch arg {
    case "-title":
        title = args.popFirst()
    case "-subtitle":
        subtitle = args.popFirst()
    case "-message":
        message = args.popFirst()
    case "-actions":
        if let actionStr = args.popFirst() {
            actions = actionStr.split(separator: ",").map { String($0) }
        }
    case "-image":
        imagePath = args.popFirst()
    case "-sound":
        soundName = args.popFirst()
    case "-reply":
        replyPlaceholder = args.popFirst()
    case "-url":
        openUrl = args.popFirst()

    default:
        break
    }
}

guard let notificationTitle = title, let notificationMessage = message else {
    print("Usage: NotifiCLI -title \"Title\" -message \"Message\" [-subtitle \"Subtitle\"] [-actions \"Yes,No\"] [-reply \"Placeholder\"] [-url \"https://...\"] [-image \"/path/to/image.png\"] [-sound \"Name\"] [-silent]")
    exit(1)
}

// MARK: - Notification
let center = UNUserNotificationCenter.current()

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var selectedAction: String?
    let semaphore = DispatchSemaphore(value: 0)
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle Text Input
        if let textResponse = response as? UNTextInputNotificationResponse {
            selectedAction = textResponse.userText
        } 
        // Handle Default Click (Open URL)
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            selectedAction = "default"
            if let openUrl = openUrl, let url = URL(string: openUrl) {
                NSWorkspace.shared.open(url)
            }
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            selectedAction = "dismissed"
        } else {
            selectedAction = response.actionIdentifier
        }
        
        completionHandler()
        // No need to signal semaphore anymore, assuming we poll selectedAction
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        var options: UNNotificationPresentationOptions = [.banner]
        if notification.request.content.sound != nil {
            options.insert(.sound)
        }
        completionHandler(options)
    }
}

let delegate = NotificationDelegate()
center.delegate = delegate

// Diagnostic: Print bundle info in stderr if auth fails
let bundleID = Bundle.main.bundleIdentifier ?? "unknown"

// Request authorization
let authSemaphore = DispatchSemaphore(value: 0)
var authGranted = false

center.requestAuthorization(options: [.alert, .sound]) { granted, error in
    authGranted = granted
    if let error = error {
        fputs("Error requesting auth: \(error.localizedDescription)\n", stderr)
    }
    authSemaphore.signal()
}
_ = authSemaphore.wait(timeout: .now() + 5.0)

if !authGranted {
    fputs("Error: Notifications are not allowed for bundle '\(bundleID)'. Please check System Settings.\n", stderr)
    
    // Give the system a moment to show the prompt before we exit
    Thread.sleep(forTimeInterval: 2.0)
    exit(1)
}

// Register action category if needed
var notificationActions: [UNNotificationAction] = []

if let replyPlaceholder = replyPlaceholder {
    let replyAction = UNTextInputNotificationAction(
        identifier: "REPLY_ACTION",
        title: "Reply",
        options: [.foreground],  // Foreground required to receive response from Notification Center
        textInputButtonTitle: "Send",
        textInputPlaceholder: replyPlaceholder
    )
    notificationActions.append(replyAction)
}

if !actions.isEmpty {
    let customActions = actions.map { actionTitle in
        // Foreground ensures Notification Center relaunches the app and delivers
        // the selected action back to this waiting process.
        UNNotificationAction(identifier: actionTitle, title: actionTitle, options: [.foreground])
    }
    notificationActions.append(contentsOf: customActions)
}

if !notificationActions.isEmpty {
    let category = UNNotificationCategory(identifier: "ACTIONS_CATEGORY",
                                           actions: notificationActions,
                                           intentIdentifiers: [],
                                           options: [.customDismissAction])
    let categorySemaphore = DispatchSemaphore(value: 0)
    center.setNotificationCategories([category])
    // Give the system time to register the category
    center.getNotificationCategories { _ in
        categorySemaphore.signal()
    }
    _ = categorySemaphore.wait(timeout: .now() + 1.0)
}

// Create notification content
let content = UNMutableNotificationContent()
content.title = notificationTitle
if let notificationSubtitle = subtitle {
    content.subtitle = notificationSubtitle
}
content.body = notificationMessage

// Sound configuration - silent by default, only play if -sound is specified
content.sound = nil


if !notificationActions.isEmpty {
    content.categoryIdentifier = "ACTIONS_CATEGORY"
}

// Handle remote image
if let path = imagePath, (path.lowercased().hasPrefix("http://") || path.lowercased().hasPrefix("https://")), let url = URL(string: path) {
    let tempDir = URL(fileURLWithPath: "/tmp/notificli")
    do {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        let fileName = url.lastPathComponent.isEmpty ? "image-\(UUID().uuidString)" : url.lastPathComponent
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        // Simple synchronous download for CLI
        if let data = try? Data(contentsOf: url) {
            try data.write(to: destinationURL)
            fputs("Downloaded image to \(destinationURL.path)\n", stderr)
            imagePath = destinationURL.path
        } else {
            fputs("Warning: Failed to download image from \(path)\n", stderr)
        }
    } catch {
        fputs("Warning: Failed to process remote image: \(error.localizedDescription)\n", stderr)
    }
}

// Add image attachment if specified
if let imagePath = imagePath {
    let imageURL = URL(fileURLWithPath: imagePath)
    if FileManager.default.fileExists(atPath: imagePath) {
        do {
            // UNNotificationAttachment moves the file, so we make a temporary copy for the attachment
            let tempAttachmentURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + imageURL.pathExtension)
            try FileManager.default.copyItem(at: imageURL, to: tempAttachmentURL)
            
            let attachment = try UNNotificationAttachment(identifier: "image", url: tempAttachmentURL, options: nil)
            content.attachments = [attachment]
        } catch {
            fputs("Warning: Could not attach image: \(error.localizedDescription)\n", stderr)
        }
    } else {
        fputs("Warning: Image not found at \(imagePath)\n", stderr)
    }
}

// Schedule notification
let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

let notificationSemaphore = DispatchSemaphore(value: 0)

center.add(request) { error in
    if let error = error {
        print("Error scheduling notification: \(error.localizedDescription)")
        exit(1)
    }
    notificationSemaphore.signal()
}

// Wait for notification to be scheduled
_ = notificationSemaphore.wait(timeout: .now() + 2.0)

// Play sound after notification is scheduled
if let soundName = soundName {
    var soundPlayed = false
    
    // Try file in bundle Resources directory first
    if let resourcePath = Bundle.main.resourcePath {
        let soundPath = (resourcePath as NSString).appendingPathComponent(soundName)
        if FileManager.default.fileExists(atPath: soundPath) {
            if let sound = NSSound(contentsOfFile: soundPath, byReference: true) {
                sound.play()
                soundPlayed = true
            }
        }
    }
    
    // Try system sound by name (without extension)
    if !soundPlayed {
        let nameWithoutExt = (soundName as NSString).deletingPathExtension
        if let sound = NSSound(named: NSSound.Name(nameWithoutExt)) {
            sound.play()
            soundPlayed = true
        }
    }
    
    // Try absolute path (if passed directly)
    if !soundPlayed && FileManager.default.fileExists(atPath: soundName) {
        if let sound = NSSound(contentsOfFile: soundName, byReference: true) {
            sound.play()
            soundPlayed = true
        }
    }
    
    // Wait for sound to play before process exits
    if soundPlayed {
        Thread.sleep(forTimeInterval: 1.0)
    }
}

// Wait for user response if actions exist or reply is requested
if !actions.isEmpty || replyPlaceholder != nil || openUrl != nil {
    // Run the run loop until action is received
    while delegate.selectedAction == nil {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
    }
    
    if let action = delegate.selectedAction {
        print(action)
    }
}
