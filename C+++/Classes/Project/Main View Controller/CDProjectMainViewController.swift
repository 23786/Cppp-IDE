//
//  CDProjectSidebarViewController.swift
//  C+++
//
//  Created by 23786 on 2020/8/10.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDProjectMainViewController: NSViewController {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var fileView: NSView!
    @IBOutlet weak var projectSettingsView: CDProjectSettingsView!
    
    weak var document: CDProjectDocument!
    weak var contentVC: CDMainViewController!
    
    // MARK: - Dragging
    var draggedItem: Any? = nil
    
    // MARK: - Right-Click Menu
    @objc dynamic var isShowInFinderItemEnabled: Bool {
        if let item = self.outlineView?.item(atRow: self.outlineView.selectedRow) as? CDProjectItem {
            switch item {
                case .folder(_): return false
                default: return true
            }
        }
        return false
    }
    
    @objc dynamic var isRemoveFromProjectItemEnabled: Bool {
        if let item = self.outlineView?.item(atRow: self.outlineView.selectedRow) as? CDProjectItem {
            switch item {
                case .project(_): return false
                default: return true
            }
        }
        return false
    }
    
    // MARK: - Document Information
    
    @IBOutlet weak var documentInfoFileNameLabel: NSTextField!
    @IBOutlet weak var documentInfoFileTypeLabel: NSTextField!
    @IBOutlet weak var documentInfoFilePathLabel: NSTextField!
    @IBOutlet weak var documentInfoDescription: NSTextView!
    @IBOutlet weak var log: NSTextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentVC = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Main View Controller") as? CDMainViewController
        contentVC.isOpeningInProjectViewController = true
        self.addChild(contentVC)
        
        self.outlineView?.registerForDraggedTypes([.string])
        
        self.projectSettingsView?.delegate = self
        
        self.log.font = menloFont(ofSize: 13.0)
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.document = self.view.window?.windowController?.document as? CDProjectDocument
        self.outlineView.reloadData()
        
        self.projectSettingsView.versionTextField.stringValue = self.document?.project?.version ?? "nil"
        self.projectSettingsView.button.state = self.document?.project?.compileCommand == "Default" ? .on : .off
        
    }
 
    
}
