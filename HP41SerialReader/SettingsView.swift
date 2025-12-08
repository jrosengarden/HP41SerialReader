//  APP:HP41SerialReader
//  SettingsView.swift
//
//  Created by Jeff Rosengarden on 5/22/25.
//

//  Populate Settings Panel fields (and linkages to other classes as needed)

// SettingsView.swift
import SwiftUI
import ORSSerial

struct SettingsView: View {
    @EnvironmentObject var settings: SerialSettings
    @Binding var isPresented: Bool  // ✅ controls modal state

    // Temporary working values
    @State private var tempSelectedPort: ORSSerialPort?
    @State private var tempBaudRate: String = ""
    @State private var tempStopBits: Int = 1
    @State private var tempDataBits: Int = 8
    @State private var tempParitySelection: String = "None"
    @State private var tempEnableDTR: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Serial Port Configuration:")
                .font(.headline)

            Picker("Serial Port", selection: $tempSelectedPort) {
                ForEach(settings.availablePorts, id: \.self) { port in
                    Text("\(port.name) (\(port.path))").tag(port as ORSSerialPort?)
                }
            }
            .pickerStyle(MenuPickerStyle())

            Picker("Baud Rate", selection: $tempBaudRate) {
                ForEach(settings.commonBaudRates, id: \.self) { rate in
                    Text("\(rate)").tag(String(rate))
                }
            }
            .pickerStyle(MenuPickerStyle())

            Picker("Stop Bits", selection: $tempStopBits) {
                ForEach([1, 2], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Data Bits", selection: $tempDataBits) {
                ForEach([5, 6, 7, 8], id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Parity", selection: $tempParitySelection) {
                ForEach(settings.parityOptions, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle("Enable DTR (for TULIP4041)", isOn: $tempEnableDTR)
                .help("Enable DTR line for TULIP4041 compatibility. Leave OFF for USB-41 interface.")

            Divider().padding(.vertical, 10)

            HStack {
                Spacer()
                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
                Button("OK") {
                    applyChanges()
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            tempSelectedPort = settings.selectedPort
            tempBaudRate = settings.baudRate
            tempStopBits = settings.stopBits
            tempDataBits = settings.dataBits
            tempParitySelection = settings.paritySelection
            tempEnableDTR = settings.enableDTR
        }
    }

    private func applyChanges() {
        settings.selectedPort = tempSelectedPort
        settings.baudRate = tempBaudRate
        settings.stopBits = tempStopBits
        settings.dataBits = tempDataBits
        settings.paritySelection = tempParitySelection
        settings.enableDTR = tempEnableDTR
    }
}
