//  APP:HP41SerialReader
//  SettingsWindowController.swift
//
//  Created by Jeff Rosengarden on 5/23/25.
//
// 05/23/25: Added so settings window could remain modal but still be a normal
//           floating window that is moveable.

import SwiftUI
import AppKit

class SettingsWindowController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var completionHandler: (() -> Void)?

    func showModal(settings: SerialSettings, onComplete: @escaping () -> Void = {}) {
        if panel != nil {
            return  // Already showing
        }

        let contentView = SettingsView(isPresented: .constant(true))
            .environmentObject(settings)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.level = .floating
        window.title = "Settings"
        window.contentView = hostingController.view
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)

        panel = window
        completionHandler = onComplete

        NSApp.activate(ignoringOtherApps: true)
        NSApp.runModal(for: window)
    }

    func windowWillClose(_ notification: Notification) {
        if let panel = panel {
            NSApp.stopModal()
            panel.orderOut(nil)
            self.panel = nil
            completionHandler?()
        }
    }
}
