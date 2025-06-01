//
//  BatteryMonitor.swift
//  AwesomeBattery
//
//  Created by Manisha
//  Copyright © 2025 Manisha. All rights reserved.
//

import Foundation
import IOKit.ps

class BatteryMonitor {
    static let shared = BatteryMonitor()
    
    private var timer: Timer?
    private var observers: [(Double, Bool, BatteryState) -> Void] = []
    
    enum BatteryState {
        case normal
        case alert
        case critical
    }
    
    private init() {}
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkBatteryStatus()
        }
        timer?.fire() // Initial check
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func addObserver(_ callback: @escaping (Double, Bool, BatteryState) -> Void) {
        observers.append(callback)
        checkBatteryStatus() // Initial callback
    }
    
    func checkBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            
            if let percentage = info[kIOPSCurrentCapacityKey] as? Int,
               let isCharging = info[kIOPSIsChargingKey] as? Bool {
                let batteryLevel = Double(percentage)
                let state = determineBatteryState(level: batteryLevel, isCharging: isCharging)
                observers.forEach { $0(batteryLevel, isCharging, state) }
                break
            }
        }
    }
    
    private func determineBatteryState(level: Double, isCharging: Bool) -> BatteryState {
        if isCharging {
            return .normal
        }
        
        let settings = SettingsManager.shared
        let criticalLevel = Double(settings.criticalBatteryPercentage)
        let alertLevel = Double(settings.alertBatteryPercentage)
        
        if level <= criticalLevel {
            return .critical
        } else if level <= alertLevel {
            return .alert
        }
        return .normal
    }
}
