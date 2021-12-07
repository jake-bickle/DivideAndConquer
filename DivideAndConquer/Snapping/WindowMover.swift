//
//  WindowMover.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/7/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Foundation

class WindowMover {
    // TODO Update arguments where necessary
    func moveWindowRect(cell1: Cell, cell2: Cell?, frameOfScreen: CGRect, visibleFrameOfScreen: CGRect, windowElement: AccessibilityElement) {
        standardMove(cell1, cell2, windowElement)
//        bestEffortMove()
    }
    
    // TODO What does standardMove always get right? Does it always get origin right?
    private func standardMove(_ cell1: Cell, _ cell2: Cell?, _ windowElement : AccessibilityElement) {
        var x, y, width, height : Double
        if let cell2 = cell2 {
            // Find the rectangle that contains the two cells.
            let higherCell = cell1.frame.origin.y > cell2.frame.origin.y ? cell1 : cell2
            let rightMostCell = cell1.frame.origin.x > cell2.frame.origin.x ? cell1 : cell2
            x = min(cell1.frame.origin.x, cell2.frame.origin.x)
            y = min(cell1.frame.origin.y, cell2.frame.origin.y)
            width = rightMostCell.frame.origin.x + rightMostCell.frame.width - x
            height = higherCell.frame.origin.y + higherCell.frame.height - y
        }
        else {
            x = cell1.frame.origin.x
            y = cell1.frame.origin.y
            width = cell1.frame.width
            height = cell1.frame.width
        }
        
        let newFrame = CGRect(x: x, y: y, width: width, height: height)
        windowElement.setRectOf(newFrame)
    }
    
    /// Some windows have a minimum and/or maximum size which likely doesn't align with the grid. bestEffortMove attempts to snap the window to the grid space as best it can, even if it takes multiple cells.
    func bestEffortMove() {
        // TODO Because the grid is not uniform, WindowMover needs to be able to get the entire grid space (at least just the dimensions of each cell in a 2d array)
        // TODO Needs to be able to see the entire grid space, not just 1 or 2 cells.
        
    }
}
