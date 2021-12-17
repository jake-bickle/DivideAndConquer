//
//  WindowMover.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/11/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Foundation
class WindowMover {
    var previousCell1: Cell?
    var previousCell2: Cell?
    
    func tryToMove(window: AccessibilityElement, to cell1: Cell, and cell2: Cell?) {
        if previousCell1 == cell1 && previousCell2 == cell2 {
            return
        }
        previousCell1 = cell1
        previousCell2 = cell2
        
        var cell2 = cell2
        if cell2 == nil {
            cell2 = cell1
        }
        /* The goal for the this method is to
             1. Keep the window on screen.
             2. Keep the window snapped to the grid, even if it expands outside of cell1 and cell2
           However, either one of these could be impossible (window is super large and either
           unresizable or its resize constraints are too limited)
        */
        let screen = cell1.screen
        let screenFrame = screen.visibleFrame
        
        let windowFrame = AccessibilityElement.normalizeCoordinatesOf(window.rectOfElement(), frameOfScreen: screenFrame)
        let initialCellSpace = CellSpace(cell1, cell2!).cgRect
        // If we translated the window, where would its frame end up?
        let initialSnapLocation = CGRect(x: initialCellSpace.origin.x,
                                         // TODO This isn't taking into account the fact that cells dont have the same height
                                         y: initialCellSpace.maxY - windowFrame.height,
                                         width: windowFrame.width,
                                         height: windowFrame.height)
        
        // Given that, find the nearest cell rectangle that is on screen.
        guard let (newCell1, newCell2) = GridManager.shared.closestCellRectangle(rectangle: initialSnapLocation, foundOn: screen)
        else {
            Logger.log("Failed to find cells defining the translated window, because the specified screen was not found in GridManager.")
            return
        }
        let newSnapLocation = CellSpace(newCell1, newCell2)
        
        // TODO Not necessary, just used for debugging
        window.setRectOf(newSnapLocation.cgRectRaster)
        
        
    }
}

