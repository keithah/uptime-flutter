import AppKit
import FlutterMacOS

class StatusBarController {
    // Instance of the status bar
    private var appStatusBar: NSStatusBar

    // Instance of the status bar item
    private var statusBarMenuItem: NSStatusItem

    // Instance of the popover that will display the Flutter UI
    private var flutterUIPopover: NSPopover

    // Initializer for the StatusBarController class
    init(_ popover: NSPopover) {
        print("StatusBarController: Initializing...")
        self.flutterUIPopover = popover
        appStatusBar = NSStatusBar.system
        statusBarMenuItem = appStatusBar.statusItem(withLength: 28.0)
        print("StatusBarController: Created status item: \(statusBarMenuItem)")
        print("StatusBarController: Status bar system: \(appStatusBar)")
        print("StatusBarController: Setting up button...")

        // Configure the status bar item's button
        if let statusBarMenuButton = statusBarMenuItem.button {
            // Set the button's image - using fallback for macOS 10.15 compatibility
            if #available(macOS 11.0, *) {
                statusBarMenuButton.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Uptime Kuma")
            } else {
                // Fallback for macOS 10.15
                statusBarMenuButton.image = NSImage(named: NSImage.statusPartiallyAvailableName)
            }
            statusBarMenuButton.image?.size = NSSize(width: 18.0, height: 18.0)
            statusBarMenuButton.image?.isTemplate = true

            // Set the button's action to toggle the popover when clicked
            statusBarMenuButton.action = #selector(togglePopover(sender:))
            statusBarMenuButton.target = self

            print("StatusBarController: Button configured successfully")
            print("StatusBarController: Button image: \(statusBarMenuButton.image?.description ?? "nil")")
            print("StatusBarController: Button action: \(statusBarMenuButton.action?.description ?? "nil")")
        } else {
            print("StatusBarController: ERROR - Could not get button from status item!")
        }

        print("StatusBarController: Initialization complete!")
    }

    // Function to toggle the popover when the status bar item's button is clicked
    @objc func togglePopover(sender: AnyObject) {
        if(flutterUIPopover.isShown) {
            hidePopover(sender)
        }
        else {
            showPopover(sender)
        }
    }

    // Function to show the popover
    func showPopover(_ sender: AnyObject) {
        if let statusBarMenuButton = statusBarMenuItem.button {
            // Get the main Flutter window and its view controller
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
               let mainWindow = appDelegate.mainFlutterWindow,
               let flutterViewController = mainWindow.contentViewController as? FlutterViewController {

                // Set the Flutter view controller as the popover content
                flutterUIPopover.contentViewController = flutterViewController

                // Show the popover
                flutterUIPopover.show(relativeTo: statusBarMenuButton.bounds, of: statusBarMenuButton, preferredEdge: NSRectEdge.maxY)
            }
        }
    }

    // Function to hide the popover
    func hidePopover(_ sender: AnyObject) {
        flutterUIPopover.performClose(sender)
    }

    // Function to update the status bar icon based on monitor status
    func updateStatusIcon(status: String) {
        if let statusBarMenuButton = statusBarMenuItem.button {
            var iconName: String

            switch status.lowercased() {
            case "up", "operational":
                iconName = "checkmark.circle"
            case "down", "failed":
                iconName = "xmark.circle"
            case "pending", "warning":
                iconName = "exclamationmark.triangle"
            case "paused":
                iconName = "pause.circle"
            default:
                iconName = "questionmark.circle"
            }

            if #available(macOS 11.0, *) {
                statusBarMenuButton.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Uptime Kuma - \(status)")
            } else {
                // Fallback for macOS 10.15 - use different icons based on status
                let imageName: String
                switch status.lowercased() {
                case "up", "operational":
                    imageName = NSImage.statusAvailableName
                case "down", "failed":
                    imageName = NSImage.statusUnavailableName
                case "pending", "warning":
                    imageName = NSImage.statusPartiallyAvailableName
                default:
                    imageName = NSImage.statusNoneName
                }
                statusBarMenuButton.image = NSImage(named: imageName)
            }
            statusBarMenuButton.image?.size = NSSize(width: 18.0, height: 18.0)
            statusBarMenuButton.image?.isTemplate = true
        }
    }

    // Function to update tooltip
    func updateTooltip(_ tooltip: String) {
        statusBarMenuItem.button?.toolTip = tooltip
    }
}