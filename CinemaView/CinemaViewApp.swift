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
            if let url = URL(string: "https://hdrezka.co/") {
                WebView(url: url)
            } else {
                Text("Некорректный URL")
            }
        }
    }
}
