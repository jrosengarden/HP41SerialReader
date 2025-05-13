
import SwiftUI
import ORSSerial

struct MyGreatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MyGreatApp") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Some custom info about my app.",
                                attributes: [
                                    NSAttributedString.Key.font: NSFont.boldSystemFont(
                                        ofSize: NSFont.smallSystemFontSize)
                                ]
                            ),
                            NSApplication.AboutPanelOptionKey(
                                rawValue: "Copyright"
                            ): "© 2020 NATALIA PANFEROVA"
                        ]
                    )
                }
            }
        }
    }
}

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
            
            Button("Connect") {
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
            }
            .padding(.top, 10)
            
            Divider().padding(.vertical, 10)
            
            Text("Received Data:")
                .font(.headline)
            
            ScrollView {
                Text(serialManager.receivedData.isEmpty ? "<No Data>" : serialManager.receivedData)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // ← important
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // ← allow ScrollView to expand
            .background(Color(NSColor.controlBackgroundColor))
            
            // HStack for all UI buttons
            HStack {
                Button("Clear") {
                    serialManager.receivedData = ""  // Clear the received data
                }
                .padding(.top, 10)
                .buttonStyle(DefaultButtonStyle())
                
                Button("Copy Data") {
                    copyToClipboard()
                }
                .padding(.top, 10)
                .buttonStyle(DefaultButtonStyle())
                
                Button("Quit") {
                    quitApp()  // Close the serial port and quit
                }
                .padding(.top, 10)
                .buttonStyle(DefaultButtonStyle())
            
                Spacer()
                Button("Rescan Ports") {
                    rescanPorts()  // Rescan ports when the user clicks
                }
                .buttonStyle(DefaultButtonStyle())
        }
        .padding(.top, 10) // Optional: Add bottom padding for spacing from the bottom edge
        Spacer()
        }
        .padding()
        .onAppear {
            let ports = ORSSerialPortManager.shared().availablePorts
            self.availablePorts = ports

            // Try to set the default port to /dev/cu.usbserial-00301314"
            // if it isn't available then just select the 1st available port
            // as the default and let the user change it as needed.
            if let defaultPort = ports.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
                self.selectedPort = defaultPort
            } else {
                self.selectedPort = ports.first // fallback to the first available port
            }
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Rescan the serial ports
      @MainActor
      private func rescanPorts() {
          let ports = ORSSerialPortManager.shared().availablePorts
          availablePorts = ports

          // After rescan try to set the default port to /dev/cu.usbserial-00301314"
          // if it isn't available then just select the 1st available port
          // as the default and let the user change it as needed.
          if let defaultPort = ports.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
              self.selectedPort = defaultPort
          } else {
              self.selectedPort = ports.first // fallback to the first available port
          }

          print("🔄 Rescanned ports. Found: \(ports.map(\.path))")
      }

    // Function to copy the received data to the clipboard
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()  // Clear any existing contents
        pasteboard.setString(serialManager.receivedData, forType: .string)  // Copy received data
    }

    // Function to close the serial port and quit the app
    private func quitApp() {
        // Ensure the serial port is disconnected before quitting
        serialManager.disconnect() // This should now work since disconnect is a valid method in SerialPortManager
        NSApplication.shared.terminate(nil) // Terminate the app
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.setContentSize(NSSize(width: 500, height: 800)) // Set your desired window size
                window.minSize = NSSize(width: 500, height: 800)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
