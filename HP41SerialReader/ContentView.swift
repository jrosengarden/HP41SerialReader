
import SwiftUI
import ORSSerial
import PDFKit

struct ContentView: View {
    @StateObject private var serialManager = SerialPortManager()
    
    @State private var availablePorts: [ORSSerialPort] = []
    @State private var selectedPort: ORSSerialPort? = nil

    // set State & other comm variables and give them default values
    @State private var baudRate: String = "115200"
    @State private var stopBits: Int = 1
    @State private var dataBits: Int = 8
    @State private var paritySelection: String = "None"

    // set standard parity options for UI picker
    let parityOptions = ["None", "Even", "Odd"]
    
    // set standard baud rates for UI picker
    let commonBaudRates = [
        300, 1200, 2400, 4800, 9600,
        14400, 19200, 38400, 57600,
        115200, 230400, 460800, 921600
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Serial Port Configuration:")
                .font(.headline)
            
            // Picker to select serial port
            Picker("Serial Port", selection: $selectedPort) {
                ForEach(availablePorts, id: \.self) { port in
                    Text("\(port.name) (\(port.path))").tag(port as ORSSerialPort?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            HStack {
                // Picker to select baud rate
                Picker("Baud Rate", selection: $baudRate) {
                    ForEach(commonBaudRates, id: \.self) { rate in
                        Text("\(rate)").tag(String(rate))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Picker to select stop bits
            Picker("Stop Bits", selection: $stopBits) {
                ForEach([1, 2], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Picker to select data bits
            Picker("Data Bits", selection: $dataBits) {
                ForEach([5, 6, 7, 8], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Picker to select parity
            Picker("Parity", selection: $paritySelection) {
                ForEach(parityOptions, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // "Connect" button to start communications w/HP41
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
                
                // actual comm connection construct
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
            
            // Set up "Received Data" scrollview box
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
            
            
            // Setup all buttons in one HStack at bottom of app window
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
            // Scan system for all available serial ports
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
    // This function will help the user identify the comm port they are using
    // If they look at the drop down BEFORE plugging in their HP41 via
    // Diego Diaz's USB-41 interface and then look at the drop down AFTER
    // plugging in the USB-41 interface they should be able to see the port
    // that has been added (or dropped off...depending on what order they do this)
    // This is the ENTIRE purpose of the "Rescan Ports" button
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
        serialManager.disconnect() 
        NSApplication.shared.terminate(nil) // Terminate the app
    }
}

// struct to set window width & height
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


struct HelpTextView: View {
    let helpText: String

    var body: some View {
        ScrollView {
            Text(helpText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

func loadHelpDocument() -> PDFDocument? {
    guard let url = Bundle.main.url(forResource: "Read_Me_1st", withExtension: "pdf"),
          let pdfDocument = PDFDocument(url: url) else {
        return nil
    }

    return pdfDocument
}


var helpWindow: NSWindow?

func showHelpTextWindow() {
    guard let pdfDocument = loadHelpDocument() else {
        // Show an error message or fallback UI here
        return
    }
    
    // Create a PDFView to display the PDF content
    let pdfView = PDFView()
    pdfView.document = pdfDocument
    pdfView.autoScales = true  // Automatically scale the PDF to fit the view
    pdfView.displayMode = .singlePage  // You can customize the view mode as needed
    pdfView.translatesAutoresizingMaskIntoConstraints = false
    
  
    // Determine the appropriate window size based on the screen size
    if let screen = NSScreen.main {
        let screenRect = screen.visibleFrame
        
        // Cap the window size to the screen dimensions (max 816x1152)
        let windowWidth = min(816, screenRect.width)
        let windowHeight = min(1152, screenRect.height)
        
        // Center the window on screen
        let windowOriginX = screenRect.origin.x + (screenRect.width - windowWidth) / 2
        let windowOriginY = screenRect.origin.y + (screenRect.height - windowHeight) / 2
        
        // Create the window to display the PDF
        helpWindow = NSWindow(
            contentRect: NSRect(x: windowOriginX, y: windowOriginY, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        helpWindow?.title = "HP41SerialReader Help"
        
        // Add PDFView as the window's content
        helpWindow?.contentView = pdfView
        helpWindow?.makeKeyAndOrderFront(nil)
        
        // Avoid crash by keeping the window alive
        helpWindow?.isReleasedWhenClosed = false
    }
}
    



