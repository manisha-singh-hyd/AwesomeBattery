//
//  AwesomeBatteryApp.swift
//  AwesomeBattery
//
//  Created by Manisha
//  Copyright © 2025 Manisha. All rights reserved.
//

import SwiftUI

@main
struct AwesomeBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        NSApplication.shared.setActivationPolicy(.prohibited)
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var borderController: BorderController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Initialize controllers
        menuBarController = MenuBarController()
        borderController = BorderController()
        
        // Start battery monitoring
        BatteryMonitor.shared.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up
        BatteryMonitor.shared.stopMonitoring()
    }
}
