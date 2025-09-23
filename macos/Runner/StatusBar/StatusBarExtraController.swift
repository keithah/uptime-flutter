import Foundation
import AppKit
import SwiftUI
import Cocoa

class StatusBarExtraController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var mainView: NSView

    init(_ view: NSView) {
        self.mainView = view
        statusBar = NSStatusBar()
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)

        if let statusBarButton = statusItem.button {
            // Set initial icon - we'll update this based on monitor status
            statusBarButton.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Uptime Kuma")
            statusBarButton.image?.isTemplate = true

            let menuItem = NSMenuItem()
            menuItem.view = mainView
            let menu = NSMenu()
            menu.addItem(menuItem)
            statusItem.menu = menu
        }
    }

    func updateStatus(status: String, color: NSColor) {
        if let statusBarButton = statusItem.button {
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

            statusBarButton.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Uptime Kuma - \(status)")
            statusBarButton.image?.isTemplate = true
        }
    }

    func updateTooltip(_ tooltip: String) {
        statusItem.button?.toolTip = tooltip
    }
}