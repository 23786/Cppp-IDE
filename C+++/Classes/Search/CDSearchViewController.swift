//
//  CDSearchViewController.swift
//  C+++
//
//  Created by 23786 on 2020/7/25.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDSearchViewController: NSViewController, NSTableViewDataSource, NSTextFieldDelegate, NSTableViewDelegate, NSPopoverDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var textField: NSTextField!
    
    var popover: NSPopover!
    var isDarkMode = false
    var currentFileContent = ""
    
    var allResults = [CDSearchResult]()
    var filteredResults = [CDSearchResult]()
    
    func controlTextDidChange(_ obj: Notification) {
        
        DispatchQueue.main.async {
            
            self.filteredResults = []
            for i in self.allResults {
                if i.containsKeyword(word: self.textField.stringValue) {
                    self.filteredResults.append(i)
                }
            }
            self.tableView.reloadData()
            
        }
        
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn?.title == "Title" {
            return self.filteredResults[row].title
        } else {
            return self.filteredResults[row].image
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.filteredResults.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        for view in self.detailView.subviews {
            view.removeFromSuperview()
        }
        if self.tableView.selectedRowIndexes.count != 0 {
            self.filteredResults[self.tableView.selectedRow].loadResultDetailInView(view: self.detailView, isDarkMode: self.isDarkMode)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textField?.becomeFirstResponder()
        if #available(OSX 10.14, *) {
            self.isDarkMode = true
            self.popover?.appearance = darkAqua
        } else {
            self.isDarkMode = false
            self.popover?.appearance = aqua
        }
        self.allResults[self.tableView.selectedRow].loadResultDetailInView(view: self.detailView, isDarkMode: self.isDarkMode)
        
    }
    
    func openInPopover(relativeTo rect: NSRect, of view: NSView, preferredEdge edge: NSRectEdge) {
        
        if popover == nil {
            
            popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = self
            popover.delegate = self
            popover.show(relativeTo: rect, of: view, preferredEdge: edge)
            
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for snippet in CDSnippetTableView.savedSnippets {
            self.allResults.append(CDSearchResult(snippet: snippet))
        }
        for url in NSDocumentController.shared.recentDocumentURLs {
            self.allResults.append(CDSearchResult(recentFileUrl: url))
        }
        for help in NSApplication.cpppHelp {
            self.allResults.append(CDSearchResult(helpWithTitle: help.key, content: help.value))
        }
        self.filteredResults = self.allResults
        self.tableView?.reloadData()
        
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
}
