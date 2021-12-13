//
//  CellSpace.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/13/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Cocoa

/// Immitates (does not inherit) CGRect for a rectangular space defined by two cells.
class CellSpace {
    let upper: Cell
    let lower: Cell
    let left: Cell
    let right: Cell
    let cell1: Cell
    let cell2: Cell
    
    init(_ cellA: Cell, _ cellB: Cell) {
        cell1 = cellA
        cell2 = cellB
        if cell1.absoluteY > cell2.absoluteY {
            upper = cell1
            lower = cell2
        }
        else {
            upper = cell2
            lower = cell1
        }
        if cell1.absoluteX > cell2.absoluteX {
            right = cell1
            left = cell2
        }
        else {
            right = cell2
            left = cell1
        }
    }
    
    var width: CGFloat { abs(right.frame.maxX) - abs(left.frame.minX) }
    var height: CGFloat { abs(upper.frame.maxY) - abs(lower.frame.minY) }
    
    var origin: CGPoint {
        let x = Double( left.absoluteX )
        let y = Double( lower.absoluteY )
        return CGPoint(x: x, y: y)
    }
    
    var originRaster: CGPoint {
        let x = Double( left.absoluteXRaster )
        let y = Double( upper.absoluteYRaster )
        return CGPoint(x: x, y: y)
    }
    
    var cgRect: CGRect {
        let origin = origin
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    var cgRectRaster: CGRect {
        let origin = originRaster
        let width = Double(right.absoluteXRaster + right.width - left.absoluteXRaster)
        let height = Double(lower.absoluteYRaster + lower.height - upper.absoluteYRaster)
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    func expandY() {
        // TODO
    }
    
    func expandX() {
        // TODO
    }
}
