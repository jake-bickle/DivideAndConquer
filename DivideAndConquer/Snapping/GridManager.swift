//
//  GridManager.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/10/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Cocoa

class GridManager {
    static var shared: GridManager = GridManager()
    
    var grids: [NSScreen : GridWindow] = [:]
    
    // setToShow is named as such because there is no way to determine if the window is actually
    // visible or not (NSWindow.isVisible is naive, returning true if makeKeyAndOrderFront has
    // been called, but not if it's actually been shown).
    var setToShow: Bool = false
    
    private init() {}
  
    func cellAt(point: CGPoint) -> Cell? {
        for (screen, gridWindow) in grids {
            if (screen.visibleFrame.contains(point)) {
                return gridWindow.cellAt(point: point)
            }
        }
        return nil
    }
    
    func cellAt(row: Int, column: Int, screen: NSScreen) -> Cell? {
        guard let gridWindow = grids[screen] else {return nil}
        return gridWindow.cellAt(row: row, column: column)
    }
    
    /// Returns the cellSpace that most closesly resembles the provided rectangle on a given screen.
    /// The cellSpace doesn't exist if the provided NSScreen doesn't exist.
    func closestCellSpace(rectangle: CGRect, foundOn screen: NSScreen) -> CellSpace? {
        guard let grid = grids[screen] else {return nil}
        return grid.closestCellSpace(rectangle: rectangle)
    }
    }
    
    func dehighlight(cellSpace: CellSpace) {
        guard let grid = grids[cellSpace.cell1.screen] else {return}
        grid.dehighlight(cellSpace: cellSpace)
    }
    
    /// Generates and displays the grid on all screens.
    func show() {
        if (setToShow){
            close()
        }
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let newGrid = GridWindow(screen: screen)
            grids[screen] = newGrid
            newGrid.makeKeyAndOrderFront(self)
        }
        setToShow = true
    }
    
    /// Closes the grid on all screens.
    func close() {
        for (_, gridWindow) in grids {
            gridWindow.close()
        }
        grids = [:]
        setToShow = false
    }
}
