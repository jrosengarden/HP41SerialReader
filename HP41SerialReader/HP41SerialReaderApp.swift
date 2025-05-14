// APP: HP41SerialReader
// HP41SerialReaderApp.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Main program to launch everything


import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("HP41SerialReader Help") {
                    showHelpTextWindow()
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
            }
        }
    }
}

