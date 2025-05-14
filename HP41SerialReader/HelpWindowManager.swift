// APP: HP41SerialReader
// HelpWindowManager.swift
//
//  Created by Jeff Rosengarden on 5/13/25
//  NOTE: This Xcode project was created with assistance from ChatGPT's AI engine
//        (and it was VERY helpful for a couple of thorny problems I was having)

// Management of the Help window in the app's main menu bar

import Cocoa
import PDFKit

// GlobalHelpFunctions.swift for app's main menu "Help/HP41SerialPortReader Help" menu choice
import Foundation

func showHelpTextWindow() {
    HelpWindowManager.showHelpWindow()
}


// Manage/display help
class HelpWindowManager {
    private static var helpWindow: NSWindow?

    static func showHelpWindow() {
        guard let pdfDocument = loadHelpDocument() else {
            print("Error: Help document could not be loaded.")
            return
        }


        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.translatesAutoresizingMaskIntoConstraints = false 


        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth = min(816, screenRect.width)
            let windowHeight = min(1152, screenRect.height)

            let windowOriginX = screenRect.origin.x + (screenRect.width - windowWidth) / 2
            let windowOriginY = screenRect.origin.y + (screenRect.height - windowHeight) / 2

            helpWindow = NSWindow(
                contentRect: NSRect(x: windowOriginX, y: windowOriginY, width: windowWidth, height: windowHeight),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            helpWindow?.title = "HP41SerialReader Help"
            helpWindow?.contentView = pdfView
            helpWindow?.makeKeyAndOrderFront(nil)
            helpWindow?.isReleasedWhenClosed = false
        }
    }

    // load the help document from the bundle resources
    private static func loadHelpDocument() -> PDFDocument? {
        guard let url = Bundle.main.url(forResource: "Read_Me_1st", withExtension: "pdf") else {
            print("Error: Help PDF not found in bundle.")
            return nil
        }
        return PDFDocument(url: url)
    }
}
