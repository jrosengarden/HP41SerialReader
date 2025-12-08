// APP: HP41SerialReader
// SerialPortManager.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

//  Management of serial ports and communication with proper linkages
//  between this class and ContentView, AppDelegate, SerialSettings & SettingsView
import Foundation
import ORSSerial

class SerialPortManager: NSObject, ObservableObject, ORSSerialPortDelegate {
    @Published var receivedData: String = ""
    @Published var connectionSuccessful: Bool? = nil

    private var serialPort: ORSSerialPort?
    private var HP41PrintLine = ""
    private var lineEndFlag = false
    private var dtrEnabled = false  // Track if DTR mode is active
    private var currentLineNumber = 0  // Track program line numbers
    private var inProgramListingMode = false  // Only add line numbers for program listings

    override init() {
        super.init()
    }

    func disconnect() {
        serialPort?.close()
        NSLog("Serial port disconnected")

        resetProgramListingMode()

        DispatchQueue.main.async {
            self.connectionSuccessful = nil // Reset connect button color
        }
    }

    func resetProgramListingMode() {
        // Reset program listing mode flags
        inProgramListingMode = false
        currentLineNumber = 0
    }

    func connect(portPath: String, baudRate: Int, stopBits: Int, parity: ORSSerialPortParity, dataBits: Int, enableDTR: Bool = false) {
        guard let port = ORSSerialPort(path: portPath) else {
            NSLog("❌ Invalid port path: %@", portPath)
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

        // Store DTR setting for use in data processing
        self.dtrEnabled = enableDTR

        // Disable hardware flow control (TULIP4041 needs DTR but not flow control)
        port.usesDTRDSRFlowControl = false
        port.usesRTSCTSFlowControl = false

        port.open()

        if port.isOpen {
            NSLog("✅ Serial port opened successfully: %@", portPath)

            // Enable DTR (Data Terminal Ready) line if requested (for TULIP4041 compatibility)
            if enableDTR {
                port.dtr = true
                // Note: RTS is left in its default state - not explicitly controlled
            }
        } else {
            NSLog("❌ Failed to open serial port: %@", portPath)
        }

        DispatchQueue.main.async {
            self.connectionSuccessful = port.isOpen
        }
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        for byte in data {
            let intValue = Int(byte)

            if lineEndFlag {
                lineEndFlag = false
                HP41PrintLine = ""
            }

            if intValue < 128 {
                HP41PrintLine += getCharacter(at: intValue) ?? ""
            }

            if intValue > 160 && intValue < 184 {
                if dtrEnabled && intValue == 162 {
                    // TULIP4041 mode: A2 (skip-2) is used as separator between program steps
                    // Treat it as a line break to un-batch the commands
                    HP41PrintLine += "\n"
                    lineEndFlag = true
                } else {
                    // Normal mode: just add spaces
                    HP41PrintLine += String(repeating: " ", count: intValue - 160)
                }
            }

            if intValue == 224 && HP41PrintLine != "" {
                HP41PrintLine += "\n"
                lineEndFlag = true
            }

            if intValue == 232 && HP41PrintLine != "" {
                if dtrEnabled {
                    // TULIP4041 mode: Right-justify by padding to 24 chars, then add newline
                    let currentLength = HP41PrintLine.count
                    let spacesNeeded = max(0, 24 - currentLength)
                    HP41PrintLine = String(repeating: " ", count: spacesNeeded) + HP41PrintLine + "\n"
                    lineEndFlag = true
                } else {
                    // USB-41 mode: Original behavior (prepend 24 spaces, no newline)
                    HP41PrintLine = String(repeating: " ", count: 24) + HP41PrintLine
                }
            }

            if lineEndFlag {
                // Detect program listing mode (PRP or LIST starts a new printout)
                if dtrEnabled {
                    detectProgramListingMode()
                }

                // Add line numbers for TULIP4041 program listings only
                if dtrEnabled && inProgramListingMode {
                    addLineNumberIfNeeded()
                }

                DispatchQueue.main.async {
                    self.receivedData += self.HP41PrintLine
                }
            }
        }
    }

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        NSLog("⚠️ Serial port was removed from system.")
        self.serialPort = nil
    }

    private func detectProgramListingMode() {
        // Check if this line starts a new printout (PRP or LIST)
        // Trim spaces first (right-justified lines have leading spaces)
        let trimmedLine = HP41PrintLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if trimmedLine.hasPrefix("PRP") || trimmedLine.hasPrefix("LIST") {
            // New program listing starting - reset and enable mode
            inProgramListingMode = true
            currentLineNumber = 0
        } else if trimmedLine.hasPrefix("PRFLAGS") || trimmedLine.hasPrefix("PRKEYS") ||
                  trimmedLine.hasPrefix("PRREG") || trimmedLine.hasPrefix("STATUS") {
            // Other printout types - disable program listing mode
            inProgramListingMode = false
            currentLineNumber = 0
        }
        // Otherwise, keep current mode (continuation of previous printout)
    }

    private func addLineNumberIfNeeded() {
        // Trim the line to check its content (handles right-justified lines with leading spaces)
        let trimmedLine = HP41PrintLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Don't add line numbers to the PRP or LIST command lines themselves
        if trimmedLine.hasPrefix("PRP") || trimmedLine.hasPrefix("LIST") {
            return
        }

        // Check if line already has a line number (label line with pattern: " XX♦")
        if HP41PrintLine.count >= 4 && HP41PrintLine.hasPrefix(" ") {
            let index1 = HP41PrintLine.index(HP41PrintLine.startIndex, offsetBy: 1)
            let index2 = HP41PrintLine.index(HP41PrintLine.startIndex, offsetBy: 2)
            let index3 = HP41PrintLine.index(HP41PrintLine.startIndex, offsetBy: 3)

            let char1 = HP41PrintLine[index1]
            let char2 = HP41PrintLine[index2]
            let char3 = HP41PrintLine[index3]

            // Check if this is a label with line number: " XX♦"
            if char1.isNumber && char2.isNumber && char3 == "♦" {
                // Extract and update current line number
                let lineNumStr = String([char1, char2])
                if let lineNum = Int(lineNumStr) {
                    currentLineNumber = lineNum
                }
                return
            }
        }

        // All non-label lines in program listings need line numbers
        currentLineNumber += 1
        // Remove trailing newline, prepend line number, add newline back
        let lineWithoutNewline = HP41PrintLine.trimmingCharacters(in: .newlines)
        HP41PrintLine = String(format: " %02d %@\n", currentLineNumber, lineWithoutNewline)
    }
}

var HP82143aCharMap = "♦¤ж←αβΓ↓Δσ♦λµдτΦΘΩδÅåÄäÖöÜüÆæ≠£▒ !" +
    "\"" +
    "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[" +
    "\\" +
    "]↑_`abcdefghijklmnopqrstuvwxyzπ|→Σ├"

func getCharacter(at index: Int) -> String? {
    guard index >= 0 && index < HP82143aCharMap.count else {
        NSLog("Index out of bounds")
        return nil
    }
    let stringIndex = HP82143aCharMap.index(HP82143aCharMap.startIndex, offsetBy: index)
    return String(HP82143aCharMap[stringIndex])
}

func arrayToInt(_ array: [Int]) -> Int {
    let numberString = array.map { String($0) }.joined()
    return Int(numberString) ?? 0
}
