// APP: HP41SerialReader
// HP41SerialReaderApp.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Main program to launch everything as well as integrate the "Settings" and
// "Help" main app menu choices

// 05/23/25: Updated to present Settings as a modal floating window using NSPanel

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var serialSettings = SerialSettings()
    private let settingsWindowController = SettingsWindowController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serialSettings)
                .background(WindowAccessor())
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
                    settingsWindowController.showModal(settings: serialSettings)
                }
            }
        }
    }
}
