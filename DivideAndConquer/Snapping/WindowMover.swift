//
//  WindowMover.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/11/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Foundation
class WindowMover {
    static func tryToMove(window: AccessibilityElement, to cell1: Cell, and cell2: Cell?) {
        var x, y, width, height : Double
        if let cell2 = cell2 {
            if (cell1.screen != cell2.screen) {
                // TODO Throw a fit somehow somewhere
            }
            // Find the rectangle that contains the two cells.
            let higherCell = cell1.frame.origin.y > cell2.frame.origin.y ? cell1 : cell2
            let rightMostCell = cell1.frame.origin.x > cell2.frame.origin.x ? cell1 : cell2
            x = Double( min(cell1.originRasterX, cell2.originRasterX) )
            y = Double( min(cell1.originRasterY, cell2.originRasterY) )
            width = rightMostCell.frame.origin.x + rightMostCell.frame.width - x
            height = higherCell.frame.origin.y + higherCell.frame.height - y
        }
        else {
            width = cell1.frame.width
            height = cell1.frame.height
            x = Double(cell1.originRasterX)
            y = Double(cell1.originRasterY)
        }
        
        
        let newFrame = CGRect(x: x, y: y, width: width, height: height)
        window.setRectOf(newFrame)
        
        // TODO Ensure best effort of window snapping to grid, probably a while loop here
//        let windowOnScreen =
//        let windowOnGrid =
    }
}
