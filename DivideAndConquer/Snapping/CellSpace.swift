//
//  CellSpace.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/13/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Cocoa

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
        upper = cell1.absoluteYRaster > cell2.absoluteYRaster ? cell1 : cell2
        lower = cell1.absoluteYRaster < cell2.absoluteYRaster ? cell1 : cell2
        right = cell1.absoluteXRaster > cell2.absoluteXRaster ? cell1 : cell2
        left = cell1.absoluteXRaster < cell2.absoluteXRaster ? cell1 : cell2
    }
    
    var origin: CGPoint {
        let x = Double( left.absoluteX )
        let y = Double( lower.absoluteY )
        return CGPoint(x: x, y: y)
    }
    
    var originRaster: CGPoint {
        let x = Double( left.absoluteXRaster )
        let y = Double( lower.absoluteYRaster )
        return CGPoint(x: x, y: y)
    }
    
    var rectRaster: CGRect {
        let origin = originRaster
        let width = Double(right.absoluteXRaster + right.width - left.absoluteXRaster)
        let height = Double(lower.absoluteYRaster + lower.height - upper.absoluteYRaster)
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    var rect: CGRect {
        let origin = origin
        let width = Double(right.absoluteX + right.width - left.absoluteX)
        let height = Double(lower.absoluteY + lower.height - upper.absoluteY)
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    func expandY() {
        // TODO
    }
    
    func expandX() {
        // TODO
    }
}
