//
//  SerialSettings.swift
//  HP41SerialReader
//
//  Created by Jeff Rosengarden on 5/22/25.
//

//  New class to be used with SettingsView - all Serial Port settings now
//  reachable only on app's Main Settings menu choice

import SwiftUI
import ORSSerial

class SerialSettings: ObservableObject {
    @Published var availablePorts: [ORSSerialPort] = ORSSerialPortManager.shared().availablePorts
    @Published var selectedPort: ORSSerialPort? = nil
    
    @Published var baudRate: String = "115200"
    @Published var stopBits: Int = 1
    @Published var dataBits: Int = 8
    @Published var paritySelection: String = "None"
    
    let parityOptions = ["None", "Even", "Odd"]
    let commonBaudRates = [
        300, 1200, 2400, 4800, 9600,
        14400, 19200, 38400, 57600,
        115200, 230400, 460800, 921600
    ]
    
    init() {
        if let defaultPort = availablePorts.first(where: { $0.path == "/dev/cu.usbserial-00301314" }) {
            selectedPort = defaultPort
        } else {
            selectedPort = availablePorts.first
        }
    }
}
