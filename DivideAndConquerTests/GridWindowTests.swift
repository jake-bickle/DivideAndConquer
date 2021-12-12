//
//  GridWindowTests.swift
//  DivideAndConquerTests
//
//  Created by Jake Bickle on 12/12/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import XCTest
@testable import DivideAndConquer

class GridWindowTests: XCTestCase {
    let mainScreen = NSScreen.screens[0]
    let gridWindow = GridWindow(screen: NSScreen.main!)
    let gridXDimension = 12
    let gridYDimension = 10
    
    override func setUp() {
        Defaults.gridXDimension.value = gridXDimension
        Defaults.gridYDimension.value = gridYDimension
    }
    
    func testCellAtEdgeOfScreen() {
        let topRight = CGPoint(x: mainScreen.visibleFrame.maxX, y: mainScreen.visibleFrame.maxY)
        let topRightCell = gridWindow.cellAt(point: topRight)
        guard let topRightCell = topRightCell else {
            XCTFail("Cell should have been found, but it was nil.")
            return
        }
        XCTAssertEqual(topRightCell.row, gridYDimension - 1)
        XCTAssertEqual(topRightCell.column, gridXDimension - 1)
        XCTAssertEqual(topRightCell.screen, mainScreen)
        subsequentCellValuesAreCorrect(cell: topRightCell)
        
        let lowerLeft = CGPoint(x: mainScreen.visibleFrame.minX, y: mainScreen.visibleFrame.minY)
        let lowerLeftCell = gridWindow.cellAt(point: lowerLeft)
        guard let lowerLeftCell = lowerLeftCell else {
            XCTFail("Cell should have been found, but it was nil.")
            return
        }
        XCTAssertEqual(lowerLeftCell.row, 0)
        XCTAssertEqual(lowerLeftCell.column, 0)
        XCTAssertEqual(lowerLeftCell.screen, mainScreen)
        subsequentCellValuesAreCorrect(cell: lowerLeftCell)
    }
    
    func subsequentCellValuesAreCorrect(cell: Cell) {
        XCTAssertEqual(cell.columnMax, gridXDimension - 1)
        XCTAssertEqual(cell.rowMax, gridYDimension - 1)
    }
}
