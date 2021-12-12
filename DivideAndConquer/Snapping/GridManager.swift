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
    
    /// A rectangle may be represented by two cells, both representing opposite corners. Returns (top left, bottom right) cells that define rectangle.
    /// A rectangle is "defined" by the two cells that *closest* represent its opposite corners. A rectangle may be defined despite whether it's
    /// contained within the grid, partially contained, or not contained at all. cellsDefining will still pick the opposite corners that are closest to said rectangle.
    /// The best fit rectangle doesn't if the provided NSScreen doesn't exist.
    func closestCellRectangle(rectangle: CGRect, foundOn screen: NSScreen) -> (Cell, Cell)? {
        guard let grid = grids[screen] else {return nil}
        return grid.closestCellRectangle(rectangle: rectangle)
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
