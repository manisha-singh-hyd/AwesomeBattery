//
//  BorderWindow.swift
//  AwesomeBattery
//
//  Created by Manisha
//  Copyright © 2025 Manisha. All rights reserved.
//

import Cocoa

class BorderView: NSView {
    private(set) var borderWidth: CGFloat = 0
    private var borderColor: NSColor = .red
    private var isVisible: Bool = true
    private var warningLabel: NSTextField?
    private var showWarning: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupWarningLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWarningLabel()
    }
    
    private func setupWarningLabel() {
        warningLabel = NSTextField(frame: .zero)
        warningLabel?.stringValue = "CHARGE NOW"
        warningLabel?.textColor = .red
        warningLabel?.font = .systemFont(ofSize: 120, weight: .bold)
        warningLabel?.backgroundColor = .clear
        warningLabel?.isBezeled = false
        warningLabel?.isEditable = false
        warningLabel?.isSelectable = false
        warningLabel?.alignment = .center
        warningLabel?.isHidden = true
        if let warningLabel = warningLabel {
            addSubview(warningLabel)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if isVisible {
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)
            
            let rect = bounds.insetBy(dx: borderWidth/2, dy: borderWidth/2)
            context.stroke(rect)
        }
        
        // Update warning label position
        if let warningLabel = warningLabel {
            let labelSize = warningLabel.sizeThatFits(bounds.size)
            warningLabel.frame = NSRect(
                x: (bounds.width - labelSize.width) / 2,
                y: (bounds.height - labelSize.height) / 2,
                width: labelSize.width,
                height: labelSize.height
            )
        }
    }
    
    func updateBorder(width: CGFloat, visible: Bool = true, showWarningText: Bool = false) {
        self.borderWidth = width
        self.isVisible = visible
        self.showWarning = showWarningText
        warningLabel?.isHidden = !showWarningText || !visible
        self.needsDisplay = true
    }
}

class BorderWindow: NSWindow {
    private(set) var borderView: BorderView
    
    var currentBorderWidth: CGFloat {
        return borderView.borderWidth
    }
    
    init() {
        // Calculate the frame that encompasses all screens
        let frame = NSScreen.screens.reduce(NSRect.zero) { result, screen in
            return result.union(screen.frame)
        }
        
        // Initialize the border view
        borderView = BorderView(frame: frame)
        
        super.init(contentRect: frame,
                  styleMask: .borderless,
                  backing: .buffered,
                  defer: false)
        
        self.level = .floating // Lower level than statusBar
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Use border view directly as content view
        self.contentView = borderView
    }
    
    func updateBorder(width: CGFloat, visible: Bool = true, showWarningText: Bool = false) {
        borderView.updateBorder(width: width, visible: visible, showWarningText: showWarningText)
        
        // Set window level based on whether warning text is shown
        self.level = showWarningText ? .screenSaver : .floating
        
        // Update window frame to encompass all screens
        let frame = NSScreen.screens.reduce(NSRect.zero) { result, screen in
            return result.union(screen.frame)
        }
        self.setFrame(frame, display: true)
        borderView.frame = frame
    }
}

class BorderController {
    private var borderWindow: BorderWindow?
    // Calculate max border width as 1.6% of the smallest screen dimension
    private var maxBorderWidth: CGFloat {
        let screens = NSScreen.screens
        let minDimension = screens.map { min($0.frame.width, $0.frame.height) }.min() ?? 1080
        return minDimension * 0.016 // 1.6% of smallest screen dimension
    }
    private var flashTimer: Timer?
    private var isFlashing: Bool = false
    private var currentBatteryLevel: Double = 100.0
    private var criticalBorderWidth: CGFloat?
    
    init() {
        setupBorderWindow()
        setupObservers()
    }
    
    deinit {
        flashTimer?.invalidate()
    }
    
    private func setupBorderWindow() {
        borderWindow = BorderWindow()
    }
    
    private func setupObservers() {
        // Observe battery status
        BatteryMonitor.shared.addObserver { [weak self] batteryLevel, isCharging, state in
            self?.updateBorder(batteryLevel: batteryLevel, isCharging: isCharging, state: state)
        }
    }
    
    private func updateBorder(batteryLevel: Double, isCharging: Bool, state: BatteryMonitor.BatteryState) {
        self.currentBatteryLevel = batteryLevel
        guard let window = borderWindow else { return }
        
        if isCharging {
            stopFlashing()
            window.updateBorder(width: 0, visible: false, showWarningText: false)
            window.orderOut(nil)
            return
        }
        
        switch state {
        case .critical:
            let settings = SettingsManager.shared
            // Set critical border width when we first enter critical state
            if criticalBorderWidth == nil {
                criticalBorderWidth = maxBorderWidth
            }
            let showWarning = batteryLevel <= (Double(settings.criticalBatteryPercentage) / 2.0) // Show at half of critical
            window.updateBorder(width: criticalBorderWidth ?? maxBorderWidth, showWarningText: showWarning)
            window.orderFront(nil)
            startFlashing()
            
        case .alert:
            stopFlashing()
            let settings = SettingsManager.shared
            // For alert state, use full max width
            let percentage = (Double(settings.alertBatteryPercentage) - batteryLevel) / Double(settings.alertBatteryPercentage)
            let borderWidth = CGFloat(percentage) * maxBorderWidth
            window.updateBorder(width: borderWidth, showWarningText: false)
            window.orderFront(nil)
            
        case .normal:
            stopFlashing()
            window.orderOut(nil)
            criticalBorderWidth = nil  // Reset critical border width when returning to normal
        }
    }
    
    private func startFlashing() {
        guard !isFlashing else { return }
        isFlashing = true
        
        flashTimer?.invalidate()
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let window = self?.borderWindow else { return }
            self?.isFlashing.toggle()
            window.updateBorder(width: self?.criticalBorderWidth ?? window.currentBorderWidth, visible: self?.isFlashing ?? true, showWarningText: (self?.currentBatteryLevel ?? 100.0) <= (Double(SettingsManager.shared.criticalBatteryPercentage) / 2.0))
        }
    }
    
    private func stopFlashing() {
        flashTimer?.invalidate()
        flashTimer = nil
        isFlashing = false
        borderWindow?.updateBorder(width: borderWindow?.currentBorderWidth ?? 0, visible: true)
    }
}
