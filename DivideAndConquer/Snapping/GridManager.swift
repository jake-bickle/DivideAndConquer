//
//  GridManager.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/10/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Cocoa

class GridManager {
    var grids: [NSScreen : GridWindow] = [:]
    
    func cellAt(mouseLocation: CGPoint) -> Cell? {
        
    }
    
    func cellAt(row: Int, column: Int, screen: NSScreen) -> Cell? {
        
    }
    
    /// Generates and displays the grid on all screens.
    func show() {
        
    }
    
    /// Closes the grid on all screens.
    func close() {
        
    }
    
}

struct Cell {
    var row: Int
    var column: Int
    var screen: NSScreen
    var view: CellView
    var originX: Int { Int(screen.frame.origin.x + view.frame.origin.x) }
    var originY: Int { Int(screen.frame.origin.y + view.frame.origin.y) }
    var height: Int { Int(screen.frame.height) }
    var width: Int { Int(screen.frame.width) }
    var originRasterX: Int {
        get { originX }
    }
    var originRasterY: Int {
        get { Int(screen.visibleFrame.height) - height }
    }
}
