//
//  HP41SerialReaderApp.swift
//  HP41SerialReader
//
//  Created by Jeff Rosengarden on 5/12/25.
//

//ToDos:
//      1.  add debug setting feature for all the print statements that go to console
//          ie: DEBUG=1 then print all debugging stmts, DEBUG=0 don't print debug stmts
//      2.  Properly comment all debug print statements
//      3.  Properly comment entire project
//      4.  Add in 82143ACharPrintMap String
//          a:  Modify func serialPort() in SerialPortManager to convert the character
//              read at the serial port to the proper character in the 82143ACharPrintMap
//          b:  Construct the proper logic to match Diego & My logic re:rcv'd characters
//      5.  Finish full debugging/testing cycle
//      6.  Wrap it up and send it to Diego (TA-DA!)

import SwiftUI

@main
struct HP41SerialReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor()) 
        }
    }
}
