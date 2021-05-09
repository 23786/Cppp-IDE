//
//  SavannaKit+CodeCompletion.swift
//  C+++
//
//  Created by 23786 on 2020/10/1.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa
import NotificationCenter

extension SKInnerTextView: CDCodeCompletionViewControllerDelegate {
    
    var translationUnit: CKTranslationUnit {
        return CKTranslationUnit(text: self.string, language: CKLanguageCPP)
    }
    
    func codeCompletionViewController(_ viewController: CDCodeCompletionViewController, didSelectItemWithTitle title: String, range: NSRange) {
        self.insertCompletion(title, forPartialWordRange: range, movement: NSTextMovement.return.rawValue, isFinal: true)
    }
    
    override func insertText(_ string: Any, replacementRange: NSRange) {
        
        guard CDSettings.autoComplete else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }
        
        if let string = string as? String {
            
            switch string {
                case "(": super.insertText("()", replacementRange: replacementRange)
                case "[": super.insertText("[]", replacementRange: replacementRange)
                case "{": super.insertText("{}", replacementRange: replacementRange)
                case "\"": super.insertText("\"\"", replacementRange: replacementRange)
                case "'": super.insertText("''", replacementRange: replacementRange)
                default:
                    super.insertText(string, replacementRange: replacementRange)
                    if CDSettings.codeCompletion {
                        self.complete(nil)
                    }
                    return
            }
            self.setSelectedRange(NSMakeRange(self.selectedRange.location - 1, 0))
            self.showFindIndicator(for: NSMakeRange(self.selectedRange.location, 1))
            self.cachedCompletionResults = []
            
        }
        
    }
    
    @objc func receivedCompletion(_ obj: Notification) {
        
        guard self.wantsCodeCompletion else {
            self.cachedCompletionResults = []
            return
        }
        
        DispatchQueue.main.async {
            
            let range = self.rangeForUserCompletion
            let text = self.string.nsString.substring(with: range)
            self.filterCompletions(typedText: text)
            self.showCompletionViewController()
            
        }
        
    }
    
    func filterCompletions(typedText: String) {
        
        var new = [CDCompletionResult]()
        for res in self.cachedCompletionResults {
            let result = res.typedText.lowercased().compareWith(anotherString: typedText.lowercased())
            if result.right && typedText.count != res.completionString.count {
                res.matchedRanges = result.ranges
                new.append(res)
            }
        }
        self.cachedCompletionResults = new
        
    }
    
    func showCompletionViewController() {
        
        guard self.cachedCompletionResults.count > 0 else {
            return
        }
        
        guard !(self.codeCompletionViewController?.popover.isShown ?? false) else {
            return
        }
        
        if self.codeCompletionViewController == nil {
            self.codeCompletionViewController = CDCodeCompletionViewController()
            self.codeCompletionViewController?.delegate = self
        } else {
            self.codeCompletionViewController?.popover = nil
        }
        
        self.codeCompletionViewController?.results = self.cachedCompletionResults
        
        self.codeCompletionViewController?.range = self.rangeForUserCompletion
        var rect = self.layoutManager?.boundingRect(forGlyphRange: self.selectedRange, in: self.textContainer!)
        rect?.size.width = 1.0
        self.codeCompletionViewController?.openInPopover(relativeTo: rect!, of: self, preferredEdge: .maxY)
        self.codeCompletionViewController?.tableView?.selectRowIndexes(IndexSet([0]), byExtendingSelection: false)
        
    }
    
    
    func getCompletionResults(string: String, forTypedText typed: String, charRange: NSRange, cursorIndex: Int) {
        
       //  DispatchQueue(label: "C+++.Code_Completion", qos: .userInteractive).async {
            
            
            let line = string.lineNumber(at: cursorIndex)
            let column = string.columnNumber(at: cursorIndex)
            
            
            guard self.document?.fileURL != nil else {
                return
            }
            GlobalLSPClient?.completion(path: (self.document?.fileURL!.path)!, line: line, character: column)
            
            /* // currently commented to test the new completion system
            var completionResults = CDSnippetController.shared.completionItems
            
            let results = CKTranslationUnit(text: string, language: CKLanguageCPP).completionResults(forLine: UInt(line), column: UInt(column))
            
            if results != nil {
                
                for result in results! {
                    
                    if let _result = result as? CKCompletionResult {
                        
                        let completionResult = CDCompletionResult(clangKitCompletionResult: _result)
                        completionResults.append(completionResult)
                        
                    }
                    
                }
                
            }
            
            var array = [CDCompletionResult]()
            for result in completionResults {
                let _result = result.typedText.lowercased().compareWith(anotherString: typed.lowercased())
                if _result.right && typed.count != result.completionString.count {
                    result.matchedRanges = _result.ranges
                    array.append(result)
                }
            }
            
            completionResults = array
            
            self.cachedCompletionResults = completionResults
            
            NotificationCenter.default.post(name: NSNotification.Name("C+++_Received_Code_Completion_Data"), object: nil)
            */
       // }
        
    }
    
    override func complete(_ sender: Any?) {
        
        let string = self.string
        let range = self.rangeForUserCompletion
        
        let substring = string.nsString.substring(with: range)
        if substring == "" || !(substring.first ?? "\0").isLetter && (substring.first ?? "\0") != "_" {
            wantsCodeCompletion = false
            cachedCompletionResults = []
            return
        }
        
        if !CDSettings.autoComplete {
            return
        }
        
        if !wantsCodeCompletion {
            
            wantsCodeCompletion = true
            
            // let date = Date()
            
            
            getCompletionResults(string: string, forTypedText: substring, charRange: range, cursorIndex: self.selectedRange.location)
            
            // NSLog("In the front of a word: Time: %.5lf", -date.timeIntervalSinceNow)
            
        } else {
            
            // let date = Date()
            filterCompletions(typedText: substring)
            showCompletionViewController()
            // NSLog("In the middle of a word: Time: %.5lf", -date.timeIntervalSinceNow)
            
        }
        
    }
    
    override func deleteForward(_ sender: Any?) {
        super.deleteForward(sender)
        
        self.codeCompletionViewController?.closePopover()
        self.cachedCompletionResults = []
        self.wantsCodeCompletion = false
        
    }
    
    override func deleteBackward(_ sender: Any?) {
        super.deleteBackward(sender)
        
        self.codeCompletionViewController?.closePopover()
        self.cachedCompletionResults = []
        self.wantsCodeCompletion = false
        
    }
    
}
