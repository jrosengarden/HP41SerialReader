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
// it to an asciiCharacter, a hex value and an intvalue.  All 3 versions of
// the byte rec'd are needed for debugging info in the debug console.  The
// only item really needed, after receiving the byte, is the intValue.
// This version of serialPort(...) was modified to be platform agnostic regarding
// serial port buffering.  For example: on an Intel Mac only 1 byte at a time is rec'd
// However on M1 and M3 Apple Silicon Mac's multiple bytes at a time were being rec'd
// in a chunk.  This function was re-written to be able to handle ANY data length
// that is received!!!!
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





