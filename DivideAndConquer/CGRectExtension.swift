//
//  CGRectExtension.swift
//  DivideAndConquer
//
//  Created by Jake Bickle on 12/12/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import Cocoa

extension CGRect {
    
    func contains(point: CGPoint, includeTopAndRightEdge: Bool) -> Bool {
        if includeTopAndRightEdge {
            return point.x >= minX && point.x <= maxX &&
                   point.y >= minX && point.y <= maxY
        }
        return contains(point)
    }
}
