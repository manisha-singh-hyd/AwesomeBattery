//
//  SettingsManager.swift
//  AwesomeBattery
//
//  Created by Manisha
//  Copyright © 2025 Manisha. All rights reserved.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let alertBatteryKey = "alertBatteryPercentage"
    private let criticalBatteryKey = "criticalBatteryPercentage"
    
    private var observers: [() -> Void] = []
    
    var alertBatteryPercentage: Int {
        get {
            return defaults.integer(forKey: alertBatteryKey)
        }
        set {
            let newAlert = newValue
            // Ensure critical level is not higher than alert level
            if criticalBatteryPercentage > newAlert {
                criticalBatteryPercentage = newAlert
            }
            defaults.set(newAlert, forKey: alertBatteryKey)
            notifyObservers()
        }
    }
    
    var criticalBatteryPercentage: Int {
        get {
            return defaults.integer(forKey: criticalBatteryKey)
        }
        set {
            // Ensure critical level stays between 2% and alert level
            let newCritical = min(max(2, newValue), alertBatteryPercentage)
            defaults.set(newCritical, forKey: criticalBatteryKey)
            notifyObservers()
        }
    }
    
    private init() {
        // Set default values if not set
        if defaults.object(forKey: alertBatteryKey) == nil {
            alertBatteryPercentage = 20 // Default alert percentage
        }
        if defaults.object(forKey: criticalBatteryKey) == nil {
            criticalBatteryPercentage = 10 // Default critical percentage
        }
        // Ensure critical is not higher than alert on init
        if criticalBatteryPercentage > alertBatteryPercentage {
            criticalBatteryPercentage = alertBatteryPercentage
        }
    }
    
    func addObserver(_ callback: @escaping () -> Void) {
        observers.append(callback)
        // Notify immediately of current values
        callback()
    }
    
    private func notifyObservers() {
        observers.forEach { $0() }
    }
}
