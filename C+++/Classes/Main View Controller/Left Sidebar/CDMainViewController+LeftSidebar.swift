//
//  CDMainViewController+LeftSidebar.swift
//  C+++
//
//  Created by 23786 on 2020/9/23.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

extension CDMainViewController {
    
    @IBAction func changeSidebar(_ sender: NSButton) {
        
        switch self.leftSidebarMode {
            
            case .snippets:
                self.leftSidebarMode = .diagnostics
                self.leftSidebarTableView.dataSource = nil
                self.leftSidebarTableView.delegate = nil
                sender.image = #imageLiteral(resourceName: "warning")
                
            case .diagnostics:
                self.leftSidebarMode = .recentFiles
                self.leftSidebarTableView.dataSource = nil
                self.leftSidebarTableView.delegate = nil
                sender.image = #imageLiteral(resourceName: "Debug")
                
            case .recentFiles:
                self.leftSidebarMode = .snippets
                self.leftSidebarTableView.dataSource = self.snippetDataSource
                self.leftSidebarTableView.delegate = self.snippetDataSource
                sender.image = #imageLiteral(resourceName: "Code")
            
        }
        
    }
    
}
