// HelpWindowManager.swift

import Cocoa
import PDFKit

// GlobalHelpFunctions.swift (or put this near the bottom of HelpWindowManager.swift)
import Foundation

func showHelpTextWindow() {
    HelpWindowManager.showHelpWindow()
}


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

    private static func loadHelpDocument() -> PDFDocument? {
        // Adjust this logic to match your actual help PDF location
        guard let url = Bundle.main.url(forResource: "Read_Me_1st", withExtension: "pdf") else {
            print("Error: Help PDF not found in bundle.")
            return nil
        }
        return PDFDocument(url: url)
    }
}
