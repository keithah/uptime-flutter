import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // Instance of the status bar controller
  var statusBarController: StatusBarController?

  // Instance of the popover that will display the Flutter UI
  var flutterUIPopover = NSPopover.init()

  // Initializer for the AppDelegate class
  override init() {
    // Set the popover behavior to transient, meaning it will close when the user clicks outside of it
    flutterUIPopover.behavior = NSPopover.Behavior.transient
  }

  // Function to determine whether the application should terminate when the last window is closed
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Return false to keep the application running even if all windows are closed
    return false
  }

  // Function called when the application has finished launching
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("AppDelegate: applicationDidFinishLaunching called")

    // Set up status bar immediately - keep it simple and working
    self.setupStatusBarOnly()

    // Call the superclass's applicationDidFinishLaunching function first
    super.applicationDidFinishLaunching(aNotification)
    print("AppDelegate: super.applicationDidFinishLaunching completed")

    // Hide the main window after everything is set up
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      print("AppDelegate: Hiding main window")
      self.mainFlutterWindow?.orderOut(nil)
    }
  }

  private func setupStatusBarOnly() {
    print("AppDelegate: setupStatusBarOnly called")

    // Set the size of the popover to match your screenshot
    flutterUIPopover.contentSize = NSSize(width: 400, height: 600)

    // Initialize the status bar controller with the popover
    print("AppDelegate: About to initialize StatusBarController")
    statusBarController = StatusBarController.init(flutterUIPopover)
    print("AppDelegate: StatusBarController initialized successfully")
  }

  private func setupStatusBar() {
    print("AppDelegate: setupStatusBar called")

    // Get the FlutterViewController from the main Flutter window
    print("AppDelegate: Getting FlutterViewController from mainFlutterWindow")
    guard let mainWindow = mainFlutterWindow else {
      print("AppDelegate: ERROR - mainFlutterWindow is nil")
      return
    }
    print("AppDelegate: mainFlutterWindow exists: \(mainWindow)")

    guard let flutterViewController = mainWindow.contentViewController as? FlutterViewController else {
      print("AppDelegate: ERROR - contentViewController is not a FlutterViewController")
      return
    }
    print("AppDelegate: FlutterViewController found: \(flutterViewController)")

    // Set the size of the popover
    flutterUIPopover.contentSize = NSSize(width: 400, height: 600) // Size for Uptime Kuma interface

    // Set the content view controller for the popover to the FlutterViewController
    flutterUIPopover.contentViewController = flutterViewController

    // Initialize the status bar controller with the popover
    print("AppDelegate: About to initialize StatusBarController")
    statusBarController = StatusBarController.init(flutterUIPopover)
    print("AppDelegate: StatusBarController initialized successfully")

    // Close the default Flutter window as the Flutter UI will be displayed in the popover
    print("AppDelegate: About to close main Flutter window")
    mainFlutterWindow?.close()
    print("AppDelegate: Main Flutter window closed")

    print("Status bar controller initialized: \(statusBarController != nil)")
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
