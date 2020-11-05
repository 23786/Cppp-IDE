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
        
        if self.mainViewController.leftSidebarMode == .openFiles {
            self.mainViewController.leftSidebarTableView.reloadData()
            self.mainViewController.leftSidebarTableView.selectRowIndexes([self.mainViewController.leftSidebarTableView.numberOfRows - 1], byExtendingSelection: false)
        }
        
    }
    
    func setCurrentDocument(index: Int) {
        
        guard index >= 0 && index < self.documents.count else{
            return
        }
        self.document?.removeWindowController(self)
        let document = self.documents[index]
        document.addWindowController(self)
        self.mainViewController.mainTextView.setDocument(newDocument: document)
        self.document = document
        
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
    
    func disableCompiling() {
        
        let vc = (self.contentViewController as! CDMainViewController)
        vc.enterSimpleMode(self)
        vc.rightConstraint.constant = 0.0
        
    }
    
    @IBAction func toggleLeftSidebar(_ sender: Any?) {
        
        let vc = (self.contentViewController as! CDMainViewController)
        vc.toggleLeftSidebar(sender)
        
    }
    
    func windowWillClose(_ notification: Notification) {
        
        self.documents.forEach() { doc in
            doc.close()
        }
        self.documents = []
        
    }
    
}
