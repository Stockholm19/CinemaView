//
//  CinemaViewApp.swift
//  CinemaView
//
//  Created by Роман Пшеничников on 10.05.2025.
//

import SwiftUI

@main
struct CinemaViewApp: App {
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
