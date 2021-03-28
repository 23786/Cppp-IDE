//
//  CDMainViewController+Diagnostics.swift
//  C+++
//
//  Created by 23786 on 2020/7/3.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//
/*
import Cocoa

extension CDMainViewController: CDDiagnosticsViewControllerDelegate {
    
    func diagnosticsViewController(_ vc: CDDiagnosticsViewController, shouldReplaceRange range: NSRange, with string: String) {
        self.mainTextView.textView.replaceCharacters(in: range, with: string)
    }
    
    func stringInRange(range: NSRange) -> String {
        return self.mainTextView.textView.string.nsString.substring(with: range)
    }
    
    
    @objc func showDiagnosticDetail(_ sender: NSButton) {
        
        if self.diagnostics.count > 0 {
            let vc = CDDiagnosticsViewController()
            vc.delegate = self
            // vc.openInPopover(relativeTo: sender.bounds, of: sender, preferredEdge: .minY, diagnostic: self.diagnostics[(sender.superview as! CDSnippet).index])
        }
        
    }
    
    /*
    func updateDiagnostics() {
        
        self.getDiagnostics()
        diagnosticsCells = [CDSnippetTableViewCell]()
        for (index, diagnostic) in self.diagnostics.enumerated() {
            
            let cell = CDSnippetTableViewCell(title: diagnostic.description, image: nil, code: "Line:\(diagnostic.line)\nColumn:\(diagnostic.column)\n\(diagnostic.spelling!)", width: 210.0)
            cell.index = index
            cell.explicitHeight = 32.0
            cell.titleLabel?.font? = NSFont.systemFont(ofSize: 12.0)
            cell.titleLabel?.target = self
            cell.titleLabel?.action = #selector(showDiagnosticDetail(_:))
            cell.menu = nil
            diagnosticsCells.append(cell)
            
            switch diagnostic.severity {
                
                case CKDiagnosticSeverityWarning:
                    self.lineNumberView.buttonsArray[Int(diagnostic.line - 1)].markAsWarningLine()
                    
                case CKDiagnosticSeverityError, CKDiagnosticSeverityFatal:
                    self.lineNumberView.buttonsArray[Int(diagnostic.line - 1)].markAsErrorLine()
                    
                default:
                    break
            }
            
        }
        
        if self.segmentedControl.selectedSegment == 2 {
            snippetAndDiagnositcsTableView.setup(cells: diagnosticsCells)
        }
        
    }
    */
    private func getDiagnostics() {
        
        self.diagnostics = [CKDiagnostic]()
        // TODO: Fix Diagnostic
        /*for item in self.mainTextView.translationUnit.diagnostics! {
            
            if let diagnostic = item as? CKDiagnostic {
                
                if diagnostic.range.contains(self.mainTextView.selectedRange.location) {
                    continue
                }
                
                self.diagnostics.append(diagnostic)
                
            }
            
        }*/
        
    }
    
}
*/
