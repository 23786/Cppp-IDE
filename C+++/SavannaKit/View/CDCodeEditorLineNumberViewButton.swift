//
//  CDCodeEditorLineNumberViewButton.swift
//  C+++
//
//  Created by 23786 on 2020/7/31.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDCodeEditorLineNumberViewButton: NSButton {
    
    var backgroundColor: NSColor!
    var isBreakpoint: Bool = false
    var correspondingDiagnostics = [CDDiagnostic]() {
        didSet {
            
            if correspondingDiagnostics.isEmpty {
                self.image = nil
                return
            }
            
            var minSeverityRawValue = Int.max
            for i in correspondingDiagnostics {
                minSeverityRawValue = min(minSeverityRawValue, i.severity?.rawValue ?? Int.max)
            }
            
            guard minSeverityRawValue != Int.max else {
                return
            }
            
            switch CDDiagnostic.Severity(rawValue: minSeverityRawValue) {
                case .error:
                    self.image = #imageLiteral(resourceName: "error")
                case .warning:
                    self.image = #imageLiteral(resourceName: "warning")
                case .hint, .information:
                    self.image = #imageLiteral(resourceName: "note")
                default:
                    break
            }
            
        }
    }
    
    private func drawBackground(color: NSColor) {
        /*
        self.backgroundColor = color
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
        self.layer?.setNeedsDisplay()
        */
    }
    
    func markAsNoteLine() {
        self.drawBackground(color: .systemGray)
    }
    
    func markAsErrorLine() {
        self.drawBackground(color: .systemRed)
    }
    
    func markAsBreakpointLine() {
        
        let superview = self.superview! as! CDCodeEditorLineNumberView
        if self.isBreakpoint {
            self.isBreakpoint = false
            superview.debugLines.remove(self.title.nsString.integerValue)
            superview.draw()
            return
        }
        self.isBreakpoint = true
        self.drawBackground(color: .systemBlue)
        if self.superview != nil {
            superview.debugLines.insert(self.title.nsString.integerValue)
        }
        
    }
    
    func markAsWarningLine() {
        self.drawBackground(color: .systemYellow)
    }
    
    func markAsDebugCurrentLine() {
        self.drawBackground(color: .systemGreen)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // self.wantsLayer = true
        // self.layer?.masksToBounds = true
        // self.layer?.cornerRadius = frameRect.height / 2 - 4
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
