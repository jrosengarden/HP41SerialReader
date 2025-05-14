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
    
    private var serialPort: ORSSerialPort?
    
    // Global variables for sending line-at-a-time to Recieved Data Box
    private var HP41PrintLine = ""
    private var lineEndFlag = false
    
   
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

    
    // main serial port receiving function.
    // this function receives each data byte being sent by HP41 and then converts
    // it to a plain integer.
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        if lineEndFlag {
            lineEndFlag = false
            HP41PrintLine = ""
        }
        
        let string = String(decoding: data, as: Unicode.ASCII.self)
        let byteString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        
        // Deprecated: combined into a single line of code below
        // Decode each byte as an integer (UInt8)
        //let integerValues = data.map { Int($0) }  // Convert each byte to an integer (UInt8 to Int)
        
        // Integrated line of code that replaces the above deprecated line of code
        // prior to combining 2 lines of code and deprecating the above line of code
        // this line of code was:
        //      let combinedInteger = integerValues.reduce(0) { ($0 << 8) + $1 }
        // Decode each byte as an Int[array] and then convert Int[array] to plain integer
        let combinedInteger = data.map { Int($0) }.reduce(0) { ($0 << 8) + $1 }
        
        print("Raw bytes: \(byteString) + ASCII Char: \(string) + Integer Value: \(combinedInteger)")
        
        if combinedInteger < 128 {
            HP41PrintLine += getCharacter(at: combinedInteger) ?? ""
        }
        
        if combinedInteger > 160 && combinedInteger < 184 {
            HP41PrintLine += String(repeating: " ", count: combinedInteger - 160)
        }
        
        if combinedInteger == 224 && HP41PrintLine != "" {
            HP41PrintLine += "\n"
            lineEndFlag = true
        }
        
        if combinedInteger == 232 && HP41PrintLine != "" {
            HP41PrintLine = String(repeating: " ", count: 24) + HP41PrintLine
        }
        
        if lineEndFlag {
            DispatchQueue.main.async {
                self.receivedData += self.HP41PrintLine
            }
        }

    }


    

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("⚠️ Serial port was removed from system.")
        self.serialPort = nil
    }
}


// COMMENT: Character map for translation of each byte read via serial port
//            DO NOT ADD/DELETE/CHANGE ORDER OF THIS VERY IMPORTANT TEXT STRING!!!

var HP82143aCharMap = "♦¤ж←αβΓ↓Δσ♦λµдτΦΘΩδÅåÄäÖöÜüÆæ≠£▒ !"
                        + "\""      // Special case of double quote character
                        + "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
                        + "\\"        // Special case of backslash character
                        + "]↑_`abcdefghijklmnopqrstuvwxyzπ|→Σ├"

func getCharacter(at index: Int) -> String? {
    // Ensure the index is within bounds
    guard index >= 0 && index < HP82143aCharMap.count else {
        print("Index out of bounds")
        return nil
    }
    
    // Get the correct String.Index from the integer index
    let stringIndex = HP82143aCharMap.index(HP82143aCharMap.startIndex, offsetBy: index)
    
    // Return the character as a String (instead of Character)
    return String(HP82143aCharMap[stringIndex])
}


func arrayToInt(_ array: [Int]) -> Int {
    let numberString = array.map { String($0) }.joined()  // Convert array to string and join
    return Int(numberString) ?? 0  // Convert the string to an integer
}





