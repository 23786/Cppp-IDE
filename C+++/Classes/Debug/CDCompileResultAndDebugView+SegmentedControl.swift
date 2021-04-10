//
//  CDCompileResultAndDebugView+SegmentedControl.swift
//  C+++
//
//  Created by 23786 on 2020/10/16.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

extension CDCompileResultAndDebugView {
    
    func switchModeToCompileResult() {
        
        self.segmentedControl.selectedSegment = 0
        self.debugSplitView.isHidden = true
        self.logView.enclosingScrollView?.isHidden = true
        self.errorCountLabel.isHidden = false
        self.errorImageLabel.isHidden = false
        self.warningImageView.isHidden = false
        self.warningCountLabel.isHidden = false
        self.resultAndRunSplitView.isHidden = false
        self.titleLabel.stringValue = "Compile Result"
        
    }
    
    func switchModeToCompileLog() {
        
        self.segmentedControl.selectedSegment = 1
        self.debugSplitView.isHidden = true
        self.logView.enclosingScrollView?.isHidden = false
        self.errorCountLabel.isHidden = false
        self.errorImageLabel.isHidden = false
        self.warningImageView.isHidden = false
        self.warningCountLabel.isHidden = false
        self.resultAndRunSplitView.isHidden = true
        self.titleLabel.stringValue = "Compile Log"
        
    }
    
    func switchModeToDebug() {
        
        self.segmentedControl.selectedSegment = 2
        self.debugSplitView.isHidden = false
        self.logView.enclosingScrollView?.isHidden = true
        self.errorCountLabel.isHidden = true
        self.errorImageLabel.isHidden = true
        self.warningImageView.isHidden = true
        self.warningCountLabel.isHidden = true
        self.resultAndRunSplitView.isHidden = true
        self.titleLabel.stringValue = "Debug"
        
    }
    
    @IBAction func didClickSegmentedControl(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                switchModeToCompileResult()
            case 1:
                switchModeToCompileLog()
            case 2:
                switchModeToDebug()
            default:
                break
                
        }
        
    }
    
}
