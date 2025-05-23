//  APP:HP41SerialReader
//  AppDelegate.swift
//
//  Created by Jeff Rosengarden on 5/22/25.
//

//  Needed in order to move the Serial Port settings from the Main App's UI into
//  a normal "Mac App" Settings menu pulldown.

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optionally, customize the application menu here if needed.
        // But SwiftUI Settings { } automatically adds it to the App menu
    }
}
