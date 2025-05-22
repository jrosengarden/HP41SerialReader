// APP: HP41SerialReader
// HP41SerialReaderApp.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Main program to launch everything as well as integrate the "Settings" and
// "Help" main app menu choices

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var serialSettings = SerialSettings()
    @State private var showSettings = false  // ✅ new state variable

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serialSettings)
                .background(WindowAccessor())
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        isPresented: $showSettings  // ✅ pass in binding
                    )
                    .environmentObject(serialSettings)
                }
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("HP41SerialReader Help") {
                    showHelpTextWindow()
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    showSettings = true  // ✅ trigger modal
                }
            }
        }

    }
}
