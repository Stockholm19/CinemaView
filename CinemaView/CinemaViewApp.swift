//
//  CinemaViewApp.swift
//  CinemaView
//
//  Created by Роман Пшеничников on 10.05.2025.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct CinemaViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
            #else
            NavigationView {
                ContentView()
            }
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
