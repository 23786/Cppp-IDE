//
//  WindowController.swift
//  C+++
//
//  Created by apple on 2020/3/23.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDMainWindowController: NSWindowController, NSWindowDelegate {
    
    @objc dynamic var statusString = "C+++ | Ready"
    
    var documents: [CDCodeDocument] = []
    
    var mainViewController: CDMainViewController {
        return (self.contentViewController as! CDMainViewController)
    }
    
    func addDocument(_ document: CDCodeDocument) {
        
        if documents.contains(document) {
            return
        }
        
        self.documents.append(document)
        self.mainViewController.mainTextView.setDocument(newDocument: document)
        self.document = document
        
        if document.fileURL != nil {
            GlobalLSPClient?.openDocument(path: document.fileURL!.path, content: document.content.contentString)
        }
        
        if self.mainViewController.leftSidebarMode == .openFiles {
            self.mainViewController.leftSidebarTableView.reloadData()
            self.mainViewController.leftSidebarTableView.selectRowIndexes([self.mainViewController.leftSidebarTableView.numberOfRows - 1], byExtendingSelection: false)
        }
        
    }
    
    func setCurrentDocument(index: Int) {
        
        guard index >= 0 && index < self.documents.count else {
            return
        }
        self.document?.removeWindowController(self)
        let document = self.documents[index]
        document.addWindowController(self)
        self.mainViewController.mainTextView.setDocument(newDocument: document)
        if self.mainViewController.leftSidebarMode == .openFiles {
            self.mainViewController.leftSidebarTableView.selectRowIndexes([index], byExtendingSelection: false)
        }
        self.document = document
        
    }
    
    
    @objc func closeSelectedDocument() {
        
        let row = self.mainViewController.leftSidebarTableView.clickedRow
        guard row >= 0 else {
            return
        }
        
        self.documents.remove(at: row)
        self.mainViewController.leftSidebarTableView.reloadData()
        
        if self.documents.count == 0 {
            self.close()
            return
        }
        
        let newRow = row == 0 ? 1 : (row - 1)
        self.setCurrentDocument(index: newRow)
        
    }
    
    @objc func showCurrentDocumentInFinder() {
        
        let row = self.mainViewController.leftSidebarTableView.clickedRow
        guard row >= 0 else {
            return
        }
        
        NSWorkspace.shared.selectFile(self.documents[row].fileURL?.path, inFileViewerRootedAtPath: "")
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.shouldCascadeWindows = true
        GlobalMainWindowController = self
        
    }
    
    @IBAction func toggleLeftSidebar(_ sender: Any?) {
        
        self.mainViewController.toggleLeftSidebar(sender)
        
    }
    
    func windowWillClose(_ notification: Notification) {
        
        self.documents.forEach() { doc in
            doc.close()
        }
        self.documents = []
        
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        GlobalLaunchViewController.view.window?.close()
        
    }
    
    override func close() {
        super.close()
        
        GlobalLaunchViewController.view.window?.windowController?.showWindow(nil)
        
    }
    
    func clearDiagnostics() {
        
        let editor = self.mainViewController.mainTextView.textView
        
        editor.errorLineRanges = []
        editor.warningLineRanges = []
        editor.noteLineRanges = []
        
    }
    
    func displayDiagnosticsForCurrentFile(_ diagnostics: [CDDiagnostic]) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            
            let editor = self.mainViewController.mainTextView.textView
            
            if diagnostics.isEmpty {
                self.clearDiagnostics()
            }
            
            var maxLine = -1, column = -1
            
            for diagnostic in diagnostics {
                
                if diagnostic.range != nil {
                    maxLine = max(maxLine, diagnostic.range!.end.line + 1)
                    if maxLine == diagnostic.range!.end.line + 1 {
                        column = max(column, diagnostic.range!.end.character)
                    }
                }
                
            }
            
            var lineIndices = [Int : Int]()
            
            let sep = editor.string.components(separatedBy: "\n")
            
            var index = -1, line = 0;
            
            for item in sep {
                
                line += 1
                index += 1
                lineIndices[line] = index
                index += item.count
                
            }
            
            // print(maxLine, column)
            // print((lineIndices[maxLine] ?? 10000000) + column)
            if (lineIndices[maxLine] ?? 10000000) + column > editor.text.count {
                return
            }
            
            var errorRangeArray = [NSRange]()
            var warningRangeArray = [NSRange]()
            var noteRangeArray = [NSRange]()
            
            for diagnostic in diagnostics {
                
                if let range = diagnostic.range {
                    
                    let start = lineIndices[range.start.line + 1]! + range.start.character// - 1
                    let end = lineIndices[range.end.line + 1]! + range.end.character - 1
                    
                    let nsRange = NSRange(location: start, length: end - start + 1)
                    
                    switch diagnostic.severity {
                        case .error, .none:
                            errorRangeArray.append(nsRange)
                        case .hint, .information:
                            noteRangeArray.append(nsRange)
                        case .warning:
                            warningRangeArray.append(nsRange)
                    }
                    
                    editor.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                    editor.textStorage?.addAttribute(.underlineColor, value: NSColor.red, range: nsRange)
                    
                }
                
            }
            
            editor.errorLineRanges = errorRangeArray
            editor.warningLineRanges = warningRangeArray
            editor.noteLineRanges = noteRangeArray
            
        }
        
    }
    
}
