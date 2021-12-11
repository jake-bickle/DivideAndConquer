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
        for (screen, gridWindow) in grids {
            if (screen.visibleFrame.contains(mouseLocation)) {
                return gridWindow.cellAt(location: mouseLocation)
            }
        }
        return nil
    }
    
    func cellAt(row: Int, column: Int, screen: NSScreen) -> Cell? {
        guard let gridWindow = grids[screen] else {return nil}
        return gridWindow.cellAt(row: row, column: column)
    }
    
    /// Generates and displays the grid on all screens.
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let newGrid = GridWindow(screen: screen)
            grids[screen] = newGrid
            newGrid.makeKeyAndOrderFront(self)
        }
    }
    
    /// Closes the grid on all screens.
    func close() {
        for (_, gridWindow) in grids {
            gridWindow.close()
        }
        grids = [:]
    }
}
