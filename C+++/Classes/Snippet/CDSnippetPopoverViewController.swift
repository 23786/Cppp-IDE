//
//  CDSnippetPopoverViewController.swift
//  C+++
//
//  Created by 23786 on 2020/5/7.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDSnippetPopoverViewController: NSViewController, SKSyntaxTextViewDelegate {
    
    
    // MARK: - Properties
        
    private let imageNames = ["Code", "YellowCode", "GreenCode", "PurpleCode", "BlueCode"]
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var textView: SKSyntaxTextView!
    @IBOutlet weak var imageView: NSButton!
    @IBOutlet weak var addToCodeButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var completionTextField: NSTextField!
    
    public var imageNameIndex: Int = 0
    private var snippetIndex: Int = 0
    private var popover: NSPopover!
    private(set) var isEditable: Bool = false
    
    private var theme = CDSettings.darkTheme
    private lazy var lexer = CDCppLexer()
    
    func lexerForSource(_ source: String) -> SKLexer {
        return self.lexer
    }
    
    
    @IBAction func addToCode(_ sender: Any) {
        GlobalMainWindowController.mainViewController.mainTextView.insertText(self.textView.text)
        self.popover?.close()
    }
    
    @objc func addItem() {
        CDSnippetController.shared.add(snippet: CDSnippet(title: self.titleLabel.stringValue, image: self.imageView.image, code: self.textView.text, completion: self.completionTextField.stringValue))
        self.popover?.close()
    }
    
    @IBAction func changeImage(_ sender: NSButton) {
        
        guard isEditable else {
            return
        }
        
        imageNameIndex += 1
        imageNameIndex %= 5
        self.imageView.image = NSImage(named: imageNames[imageNameIndex])!
        
    }
    
    @IBAction func editOrDone(_ sender: NSButton) {
        
        if isEditable {
            isEditable = false
            self.titleLabel.isEditable = false
            self.textView.textView.isEditable = false
            self.completionTextField.isEditable = false
            self.titleLabel.resignFirstResponder()
            self.editButton.isBordered = false
            self.editButton.imagePosition = .imageOnly
            self.addToCodeButton.isHidden = false
            CDSnippetController.shared.updateSnippet(
                index: self.snippetIndex,
                new: CDSnippet(title: self.titleLabel.stringValue, image: self.imageView.image, code: self.textView.text, completion: self.completionTextField.stringValue)
            )
        } else {
            isEditable = true
            self.titleLabel.isEditable = true
            self.textView.textView.isEditable = true
            self.completionTextField.isEditable = true
            self.titleLabel.becomeFirstResponder()
            self.editButton.isBordered = true
            self.addToCodeButton.isHidden = true
            self.editButton.imagePosition = .noImage
        }
        
    }

    /** Setup the view controller.
    - parameter title: The title.
    - parameter image: The image.
    - parameter code: The code.
    - parameter mode: Whether it is editable.
    - returns: none
    */
    func setup(title: String, image: NSImage?, code: String, completion: String, isEditable: Bool, index: Int) {
        
        self.loadView()
        self.titleLabel.stringValue = title
        
        self.textView.isUsingLSP = false
        if #available(OSX 10.14, *) {
            switch self.view.effectiveAppearance.name {
                case .aqua, .vibrantLight:
                    self.theme = CDSettings.lightTheme
                case .darkAqua, .vibrantDark:
                    self.theme = CDSettings.darkTheme
                default:
                    self.theme = CDSettings.lightTheme
            }
        } else {
            self.theme = CDSettings.lightTheme
        }
        self.textView.theme = self.theme
        self.textView.delegate = self
        
        self.textView.text = code
        self.imageView.image = image
        self.isEditable = isEditable
        self.snippetIndex = index
        self.editButton.imagePosition = .imageOnly
        self.editButton.isBordered = false
        self.completionTextField.stringValue = completion
        
        self.textView.textView.isEditable = isEditable
        
        if isEditable {
            
            self.editButton.isHidden = true
            self.titleLabel.isEditable = true
            self.textView.textView.isEditable = true
            self.completionTextField.isEditable = true
            self.titleLabel.becomeFirstResponder()
            self.addToCodeButton.title = "Done"
            self.addToCodeButton.action = #selector(addItem)
            
        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    func openInPopover(relativeTo rect: NSRect, of view: NSView, preferredEdge edge: NSRectEdge) {
        
        if popover == nil {
            
            popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = self
            popover.show(relativeTo: rect, of: view, preferredEdge: edge)
            
        }
        
    }
    
}
