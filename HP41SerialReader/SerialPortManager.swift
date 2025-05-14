// APP: HP41SerialReader
// SerialPortManager.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

//  Management of serial ports and communication with proper linkages
//  between this class and ContentView
import Foundation
import ORSSerial

class SerialPortManager: NSObject, ObservableObject, ORSSerialPortDelegate {
    @Published var receivedData: String = ""
    @Published var connectionSuccessful: Bool? = nil

    private var serialPort: ORSSerialPort?
    private var HP41PrintLine = ""
    private var lineEndFlag = false

    override init() {
        super.init()
    }

    func disconnect() {
        serialPort?.close()
        print("Serial port disconnected")

        DispatchQueue.main.async {
            self.connectionSuccessful = nil // Reset connect button color
        }
    }

    func connect(portPath: String, baudRate: Int, stopBits: Int, parity: ORSSerialPortParity, dataBits: Int) {
        let availablePorts = ORSSerialPortManager.shared().availablePorts
        print("Available Serial Ports:")
        for port in availablePorts {
            print("• \(port.name) at path \(port.path)")
        }

        guard let port = ORSSerialPort(path: portPath) else {
            print("❌ Invalid port path: \(portPath)")
            DispatchQueue.main.async {
                self.connectionSuccessful = false
            }
            return
        }

        self.serialPort = port
        port.baudRate = NSNumber(value: baudRate)
        port.numberOfStopBits = UInt(stopBits)
        port.parity = parity
        port.numberOfDataBits = UInt(dataBits)
        port.delegate = self

        port.open()

        DispatchQueue.main.async {
            self.connectionSuccessful = port.isOpen
        }

        if port.isOpen {
            print("✅ Serial port opened successfully: \(portPath)")
        } else {
            print("❌ Failed to open serial port: \(portPath)")
        }
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        for byte in data {
            let asciiChar = String(decoding: Data([byte]), as: Unicode.ASCII.self)
            let hexString = String(format: "%02X", byte)
            let intValue = Int(byte)

            print("Raw byte: \(hexString) + ASCII Char: \(asciiChar) + Integer Value: \(intValue)")

            if lineEndFlag {
                lineEndFlag = false
                HP41PrintLine = ""
            }

            if intValue < 128 {
                HP41PrintLine += getCharacter(at: intValue) ?? ""
            }

            if intValue > 160 && intValue < 184 {
                HP41PrintLine += String(repeating: " ", count: intValue - 160)
            }

            if intValue == 224 && HP41PrintLine != "" {
                HP41PrintLine += "\n"
                lineEndFlag = true
            }

            if intValue == 232 && HP41PrintLine != "" {
                HP41PrintLine = String(repeating: " ", count: 24) + HP41PrintLine
            }

            if lineEndFlag {
                DispatchQueue.main.async {
                    self.receivedData += self.HP41PrintLine
                }
            }
        }
    }

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("⚠️ Serial port was removed from system.")
        self.serialPort = nil
    }
}

var HP82143aCharMap = "♦¤ж←αβΓ↓Δσ♦λµдτΦΘΩδÅåÄäÖöÜüÆæ≠£▒ !" +
    "\"" +
    "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[" +
    "\\" +
    "]↑_`abcdefghijklmnopqrstuvwxyzπ|→Σ├"

func getCharacter(at index: Int) -> String? {
    guard index >= 0 && index < HP82143aCharMap.count else {
        print("Index out of bounds")
        return nil
    }
    let stringIndex = HP82143aCharMap.index(HP82143aCharMap.startIndex, offsetBy: index)
    return String(HP82143aCharMap[stringIndex])
}

func arrayToInt(_ array: [Int]) -> Int {
    let numberString = array.map { String($0) }.joined()
    return Int(numberString) ?? 0
}
