// APP: HP41SerialReader
// ContentView.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Management of the main app window along with integration with
// SerialPortManager.swift
// ContentView.swift
// HP41SerialReader
import SwiftUI
import ORSSerial
import PDFKit

struct ContentView: View {
    @StateObject private var serialManager = SerialPortManager()

    @State private var availablePorts: [ORSSerialPort] = []
    @State private var selectedPort: ORSSerialPort? = nil

    @State private var baudRate: String = "115200"
    @State private var stopBits: Int = 1
    @State private var dataBits: Int = 8
    @State private var paritySelection: String = "None"

    let parityOptions = ["None", "Even", "Odd"]
    let commonBaudRates = [
        300, 1200, 2400, 4800, 9600,
        14400, 19200, 38400, 57600,
        115200, 230400, 460800, 921600
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Serial Port Configuration:")
                .font(.headline)

            Picker("Serial Port", selection: $selectedPort) {
                ForEach(availablePorts, id: \.self) { port in
                    Text("\(port.name) (\(port.path))").tag(port as ORSSerialPort?)
                }
            }
            .pickerStyle(MenuPickerStyle())

            HStack {
                Picker("Baud Rate", selection: $baudRate) {
                    ForEach(commonBaudRates, id: \.self) { rate in
                        Text("\(rate)").tag(String(rate))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Picker("Stop Bits", selection: $stopBits) {
                ForEach([1, 2], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Data Bits", selection: $dataBits) {
                ForEach([5, 6, 7, 8], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Parity", selection: $paritySelection) {
                ForEach(parityOptions, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Connect + Disconnect buttons side-by-side
            HStack {
                Button(action: {
                    guard let port = selectedPort,
                          let baud = Int(baudRate)
                    else {
                        print("⚠️ Invalid input.")
                        return
                    }

                    let parity: ORSSerialPortParity = {
                        switch paritySelection {
                        case "Even": return .even
                        case "Odd": return .odd
                        default: return .none
                        }
                    }()

                    serialManager.connect(
                        portPath: port.path,
                        baudRate: baud,
                        stopBits: stopBits,
                        parity: parity,
                        dataBits: dataBits
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
            }
            .padding(.top, 10)

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
                .padding(.top, 10)

                Button("Copy Data") {
                    copyToClipboard()
                }
                .padding(.top, 10)

                Button("Quit") {
                    quitApp()
                }
                .padding(.top, 10)

                Spacer()

                Button("Rescan Ports") {
                    rescanPorts()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .onAppear {
            let ports = ORSSerialPortManager.shared().availablePorts
            self.availablePorts = ports

            if let defaultPort = ports.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
                self.selectedPort = defaultPort
            } else {
                self.selectedPort = ports.first
            }
        }
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
        availablePorts = ports

        if let defaultPort = ports.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
            self.selectedPort = defaultPort
        } else {
            self.selectedPort = ports.first
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
