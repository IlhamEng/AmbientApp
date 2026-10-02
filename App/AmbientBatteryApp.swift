//
//  AmbientBatteryApp.swift
//  AmbientApp
//

import SwiftUI

@main
struct AmbientBatteryApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
