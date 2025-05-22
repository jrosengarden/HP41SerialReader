// APP: HP41SerialReader
// ContentView.swift
//
//  Created by Jeff Rosengarden on 5/22/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Management of the main app window along with integration of:
// SerialPortManager.swift
// SerialSettings.swift
// SettingsView.swift

import SwiftUI
import ORSSerial
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var serialManager = SerialPortManager()
    //@StateObject private var settings = SerialSettings()
    @EnvironmentObject var settings: SerialSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: {
                    guard let port = settings.selectedPort,
                          let baud = Int(settings.baudRate)
                    else {
                        print("⚠️ Invalid input.")
                        return
                    }

                    let parity: ORSSerialPortParity = {
                        switch settings.paritySelection {
                        case "Even": return .even
                        case "Odd": return .odd
                        default: return .none
                        }
                    }()

                    serialManager.connect(
                        portPath: port.path,
                        baudRate: baud,
                        stopBits: settings.stopBits,
                        parity: parity,
                        dataBits: settings.dataBits
                    )
                }) {
                    Text("Connect")
                        .foregroundColor(connectButtonColor)
                }

                Button(action: {
                    disconnectSerialPort()
                }) {
                    Text("Disconnect")
                }

                Spacer()

                Button("Rescan Ports") {
                    rescanPorts()
                }
            }

            Divider().padding(.vertical, 10)

            Text("Received Data:")
                .font(.headline)

            ScrollView {
                Text(serialManager.receivedData.isEmpty ? "<No Data>" : serialManager.receivedData)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))

            HStack {
                Button("Clear") {
                    serialManager.receivedData = ""
                }
                .disabled(serialManager.receivedData.isEmpty)

                Button("Copy Data") {
                    copyToClipboard()
                }
                .disabled(serialManager.receivedData.isEmpty)

                Button("Save") {
                    saveToFile()
                }
                .disabled(serialManager.receivedData.isEmpty)

                Button("Print") {
                    sendToPrinter()
                }
                .disabled(serialManager.receivedData.isEmpty)

                Button("Quit") {
                    quitApp()
                }

                Spacer()
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var connectButtonColor: Color {
        if let success = serialManager.connectionSuccessful {
            return success ? .green : .red
        } else {
            return .primary
        }
    }

    @MainActor
    private func rescanPorts() {
        let ports = ORSSerialPortManager.shared().availablePorts
        settings.availablePorts = ports

        if let defaultPort = ports.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
            settings.selectedPort = defaultPort
        } else {
            settings.selectedPort = ports.first
        }

        print("🔄 Rescanned ports. Found: \(ports.map(\.path))")
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(serialManager.receivedData, forType: .string)
    }

    private func quitApp() {
        serialManager.disconnect()
        NSApplication.shared.terminate(nil)
    }

    private func disconnectSerialPort() {
        serialManager.disconnect()
        serialManager.connectionSuccessful = nil // Reset connect button color
    }

    private func sendToPrinter() {
        let printText = serialManager.receivedData

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 800))
        textView.string = printText
        textView.isEditable = false
        textView.font = NSFont.userFixedPitchFont(ofSize: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        let printOperation = NSPrintOperation(view: textView)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        printOperation.run()
    }

    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.canCreateDirectories = true
        panel.title = "Save Data As"
        panel.nameFieldStringValue = "receivedData.txt"

        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    try serialManager.receivedData.write(to: url, atomically: true, encoding: .utf8)
                    print("Data saved to: \(url.path)")
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
}


struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.setContentSize(NSSize(width: 500, height: 800))
                window.minSize = NSSize(width: 500, height: 800)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

