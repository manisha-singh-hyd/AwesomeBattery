//
//  MenuBarController.swift
//  AwesomeBattery
//
//  Created by Manisha
//  Copyright © 2025 Manisha. All rights reserved.
//

import SwiftUI
import Cocoa

class MenuBarController {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    
    init() {
        setupMenuBar()
        setupPopover()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Start observing battery status
        BatteryMonitor.shared.addObserver { [weak self] batteryLevel, isCharging, _ in
            self?.updateMenuBarIcon(batteryLevel: batteryLevel, isCharging: isCharging)
        }
    }
    
    private func updateMenuBarIcon(batteryLevel: Double, isCharging: Bool) {
        guard let button = statusItem.button else { return }
        
        if isCharging {
            if let image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Charging") {
                let config = NSImage.SymbolConfiguration(pointSize: 9, weight: .regular)
                let scaledImage = image.withSymbolConfiguration(config)
                button.image = scaledImage
                button.imagePosition = .imageRight
                button.imageHugsTitle = true
                button.title = "\(Int(batteryLevel))"
            }
        } else {
            button.image = nil
            button.title = "\(Int(batteryLevel))%"
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 200, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

struct SettingsView: View {
    @State private var alertPercentage: Double
    @State private var criticalPercentage: Double
    
    init() {
        _alertPercentage = State(initialValue: Double(SettingsManager.shared.alertBatteryPercentage))
        _criticalPercentage = State(initialValue: Double(SettingsManager.shared.criticalBatteryPercentage))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                Text("Alert Battery Level")
                    .font(.headline)
                
            HStack {
                Slider(value: $alertPercentage, in: 10...100, step: 1)
                Text("\(Int(alertPercentage))%")
                    .frame(width: 40)
            }
            .onChange(of: alertPercentage) { oldValue, newValue in
                // When alert level changes, ensure critical level doesn't exceed it
                if criticalPercentage > newValue {
                    criticalPercentage = newValue
                }
            }
                .padding(.horizontal)
                
                Text("Border appears below this level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Group {
                Text("Critical Battery Level")
                    .font(.headline)
                
            HStack {
                Slider(value: $criticalPercentage, in: 2...Double(alertPercentage), step: 1)
                Text("\(Int(criticalPercentage))%")
                    .frame(width: 40)
            }
                .padding(.horizontal)
                
                Text("Border starts flashing below this level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Apply") {
                SettingsManager.shared.alertBatteryPercentage = Int(alertPercentage)
                SettingsManager.shared.criticalBatteryPercentage = Int(criticalPercentage)
                BatteryMonitor.shared.checkBatteryStatus()
            }
            .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 4)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 200)
    }
}
