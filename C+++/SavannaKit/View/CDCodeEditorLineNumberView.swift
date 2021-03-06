//
//  CDCodeEditorLineNumberView.swift
//  C+++
//
//  Created by 23786 on 2020/7/30.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

@objc
protocol CDCodeEditorLineNumberViewDelegate {
    @objc optional func didClickButton(atLine: Int, button: CDCodeEditorLineNumberViewButton)
}

class CDCodeEditorLineNumberView: CDFlippedView {
    
    init(frame frameRect: NSRect, textView: NSTextView) {
        super.init(frame: frameRect)
        self.textView = textView
    }
    
    var textView: NSTextView!
    private(set) var buttonsArray = [CDCodeEditorLineNumberViewButton]()
    var debugLines: Set<Int> = []
    var debugCurrentLine: Int?
    var shouldReloadAfterChangingFrame: Bool = true
    var delegate: CDCodeEditorLineNumberViewDelegate?
    
    // var codeFoldingRanges: [CDParser.CodeFoldingRange] = []
    var codeFoldingLines: [Int] = []
    // var codeFoldingButtons: [CDCodeFoldingButton] = []
    
    @IBOutlet weak var codeEditor: SKSyntaxTextView!
    
    func markLineAsCurrentDebuggingLine(line: Int) {
        self.debugCurrentLine = line
        self.buttonsArray[line].markAsDebugCurrentLine()
    }
    
    private var textViewLineRects: [NSRect] {
        
        var array = [CGRect]()
        var location = 0
        for line in self.textView.string.components(separatedBy: "\n") {
            let rect = self.textView.layoutManager!.boundingRect(forGlyphRange: NSMakeRange(location, 0), in: self.textView.textContainer!)
            if rect != NSMakeRect(0, 0, 0, 0) {
                array.append(rect)
            }
            location += line.count + 1
        }
        return array
        
    }
    
    private var lastSavedLineRects: [NSRect] = []
    
    override var frame: NSRect {
        didSet {
            DispatchQueue.main.async {
                if self.shouldReloadAfterChangingFrame && oldValue.size != self.frame.size {
                    self.draw()
                }
            }
        }
    }
    
    func draw() {
        
        let currentLineRects = textViewLineRects
        if currentLineRects == lastSavedLineRects {
            return
        }
        
        lastSavedLineRects = currentLineRects
        
        var lineNumber = 0
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        self.buttonsArray = []
        // self.codeFoldingButtons = []
        
        for item in currentLineRects {
            
            let button = CDCodeEditorLineNumberViewButton(frame: NSMakeRect(2.0, item.origin.y, 34.0, item.height))
            button.isBordered = false
            button.font = NSFont(name: CDSettings.fontName, size: CGFloat(CDSettings.fontSize) * 0.92)
            button.target = self
            button.action = #selector(buttonClicked(_:))
            lineNumber += 1
            button.title = "\(lineNumber)"
            button.sizeToFit()
            button.frame.origin.x = self.bounds.width - button.frame.size.width - 2.0
            self.addSubview(button)
            if self.debugLines.contains(lineNumber) {
                button.markAsBreakpointLine()
            }
            if self.debugCurrentLine ?? -1 == lineNumber {
                button.markAsDebugCurrentLine()
            }
            self.buttonsArray.append(button)
            
            /* if let index = self.codeFoldingLines.firstIndex(of: lineNumber) {
                
                let button = CDCodeFoldingButton(frame: NSMakeRect(38.0, item.origin.y, 20.0, item.height))
                button.isBordered = false
                button.index = index
                button.target = self
                button.action = #selector(foldingButtonClicked(_:))
                button.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
                self.addSubview(button)
                self.codeFoldingButtons.append(button)
                
            }*/
            
        }
        
        self.shouldReloadAfterChangingFrame = false
        self.frame.size.height = (currentLineRects.last?.origin.y ?? 0)
                                + (currentLineRects.last?.height ?? 0)
        self.superview?.frame.size.height = (currentLineRects.last?.origin.y ?? 0)
                                + (currentLineRects.last?.height ?? 0)
        self.shouldReloadAfterChangingFrame = true
        
    }
    
    /* @objc func foldingButtonClicked(_ sender: CDCodeFoldingButton) {        let range = self.codeFoldingRanges[sender.index]
        let nsRange = NSMakeRange(range.begin.index, range.end.index - range.begin.index + 1)
        print(nsRange, self.codeEditor.text.count)
        self.codeEditor.textView.textStorage?.addAttribute(.foldedCode, value: true, range: nsRange)
    }*/
    
    @objc func buttonClicked(_ sender: CDCodeEditorLineNumberViewButton) {
        sender.markAsBreakpointLine()
        if let line = Int(sender.title) {
            self.delegate?.didClickButton?(atLine: line, button: sender)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
