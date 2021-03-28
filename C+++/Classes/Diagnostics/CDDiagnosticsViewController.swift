//
//  CDDiagnosticsViewController.swift
//  C+++
//
//  Created by 23786 on 2020/7/3.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDDiagnosticsViewController: NSViewController, NSTableViewDataSource {
    
    var popover: NSPopover!
    var diagnostics = [CDDiagnostic]()
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    
    func openInPopover(relativeTo rect: NSRect, of view: NSView, preferredEdge edge: NSRectEdge, diagnostics: [CDDiagnostic]) {
        
        self.diagnostics = diagnostics
        
        if popover == nil {
            
            popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = self
            popover.show(relativeTo: rect, of: view, preferredEdge: edge)
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.titleLabel.stringValue = ""
        var minSeverityRawValue = Int.max
        for diagnostic in diagnostics {
            let message = diagnostic.message ?? "Error"
            let source = diagnostic.source ?? "Error"
            let code = diagnostic.code ?? "Error"
            self.titleLabel.stringValue += "\(message) (\(source): \(code))\n\n"
            minSeverityRawValue = min(minSeverityRawValue, diagnostic.severity?.rawValue ?? Int.max)
        }
        
        self.titleLabel.stringValue = self.titleLabel.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard minSeverityRawValue != Int.max else {
            return
        }
        
        switch CDDiagnostic.Severity(rawValue: minSeverityRawValue) {
            case .error:
                self.imageView.image = #imageLiteral(resourceName: "error")
            case .warning:
                self.imageView.image = #imageLiteral(resourceName: "warning")
            case .hint, .information:
                self.imageView.image = #imageLiteral(resourceName: "note")
            default:
                break
        }
        
    }
   
    
}
