import Foundation
import ORSSerial

class SerialPortManager: NSObject, ObservableObject, ORSSerialPortDelegate {
    @Published var receivedData: String = ""
    
    private var serialPort: ORSSerialPort?
    
    override init() {
        super.init()
        // No connection on init — call `connect(...)` later
    }
    
      func disconnect() {
          serialPort?.close()
          print("Serial port disconnected")
      }

    func connect(portPath: String, baudRate: Int, stopBits: Int, parity: ORSSerialPortParity, dataBits: Int) {
        // Print available ports
        let availablePorts = ORSSerialPortManager.shared().availablePorts
        print("Available Serial Ports:")
        for port in availablePorts {
            print("• \(port.name) at path \(port.path)")
        }

        guard let port = ORSSerialPort(path: portPath) else {
            print("❌ Invalid port path: \(portPath)")
            return
        }

        self.serialPort = port
        port.baudRate = NSNumber(value: baudRate)
        port.numberOfStopBits = UInt(stopBits)
        port.parity = parity
        port.numberOfDataBits = UInt(dataBits)
        port.delegate = self

        port.open()

        if port.isOpen {
            print("✅ Serial port opened successfully: \(portPath)")
        } else {
            print("❌ Failed to open serial port: \(portPath)")
        }
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        let string = String(decoding: data, as: Unicode.ASCII.self)
        let byteString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        print("Raw bytes: \(byteString)")

        DispatchQueue.main.async {
            self.receivedData += string
        }
    }
    

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("⚠️ Serial port was removed from system.")
        self.serialPort = nil
    }
}


