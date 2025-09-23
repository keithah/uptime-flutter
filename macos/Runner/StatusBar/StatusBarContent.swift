import Foundation
import SwiftUI
import FlutterMacOS
import Cocoa
import AppKit

struct StatusBarContent: View {
    @State private var monitorData: String = "Loading..."
    @State private var overallStatus: String = "Unknown"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getStatusIcon())
                    .foregroundColor(getStatusColor())
                Text("Uptime Kuma Monitor")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Text(monitorData)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)

            Divider()

            HStack {
                Button("Refresh") {
                    refreshData()
                }

                Spacer()

                Button("Show App") {
                    showMainWindow()
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            refreshData()
        }
    }

    private func getStatusIcon() -> String {
        switch overallStatus.lowercased() {
        case "up", "operational":
            return "checkmark.circle"
        case "down", "failed":
            return "xmark.circle"
        case "pending", "warning":
            return "exclamationmark.triangle"
        case "paused":
            return "pause.circle"
        default:
            return "questionmark.circle"
        }
    }

    private func getStatusColor() -> Color {
        switch overallStatus.lowercased() {
        case "up", "operational":
            return .green
        case "down", "failed":
            return .red
        case "pending", "warning":
            return .orange
        case "paused":
            return .gray
        default:
            return .secondary
        }
    }

    private func refreshData() {
        // Send refresh command to Flutter app
        let methodCall = FlutterMethodCall(methodName: "refreshMonitors", arguments: nil)
        sendToFlutter(methodCall)
    }

    private func showMainWindow() {
        // Send show window command to Flutter app
        let methodCall = FlutterMethodCall(methodName: "showMainWindow", arguments: nil)
        sendToFlutter(methodCall)
    }

    private func sendToFlutter(_ methodCall: FlutterMethodCall) {
        // This will need to be connected to the Flutter method channel
        // For now, we'll simulate the action
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

struct StatusBarContent_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarContent()
    }
}