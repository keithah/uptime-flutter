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

    // Call super first to setup plugins
    super.applicationDidFinishLaunching(aNotification)

    print("AppDelegate: About to schedule delayed setup")

    // Delay to ensure window is fully created before accessing it
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      print("AppDelegate: Delayed setup block executing")

      // Set up status bar BEFORE closing window to access FlutterViewController
      self.setupStatusBarOnly()

      // Now hide the main window after status bar is set up
      if let window = self.mainFlutterWindow {
        print("AppDelegate: Closing main window")
        window.orderOut(nil)
        window.setIsVisible(false)
        window.close()
      } else {
        print("AppDelegate: mainFlutterWindow is nil")
      }

      print("AppDelegate: Setup complete - menubar only app running")
    }
  }

  private func setupStatusBarOnly() {
    print("AppDelegate: setupStatusBarOnly called")

    // Get the FlutterViewController from the main Flutter window
    guard let mainWindow = mainFlutterWindow else {
      print("AppDelegate: ERROR - mainFlutterWindow is nil")
      return
    }

    guard let flutterViewController = mainWindow.contentViewController as? FlutterViewController else {
      print("AppDelegate: ERROR - contentViewController is not a FlutterViewController")
      return
    }

    // Set the size of the popover to match your screenshot
    flutterUIPopover.contentSize = NSSize(width: 400, height: 600)

    // Use the main Flutter view controller in the popover
    flutterUIPopover.contentViewController = flutterViewController

    // Initialize the status bar controller with the popover
    print("AppDelegate: About to initialize StatusBarController")
    statusBarController = StatusBarController.init(flutterUIPopover)
    print("AppDelegate: StatusBarController initialized successfully")
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
