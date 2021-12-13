//
//  CellSpaceTests.swift
//  DivideAndConquerTests
//
//  Created by Jake Bickle on 12/13/21.
//  Copyright © 2021 Jake Bickle. All rights reserved.
//

import XCTest
@testable import DivideAndConquer

class CellSpaceTests: XCTestCase {
    let mainScreen = NSScreen.screens[0]
    let gridWindow = GridWindow(screen: NSScreen.screens[0])
    let gridXDimension = 12
    let gridYDimension = 10
    
    override func setUp() {
        Defaults.gridXDimension.value = gridXDimension
        Defaults.gridYDimension.value = gridYDimension
    }
    
    func testRectWithOneCell() {
        let cell = gridWindow.cellAt(row: 0, column: 0)
        let cs = CellSpace(cell, cell)
        let rect = cs.cgRect
        XCTAssertEqual(rect, cell.frame)
        XCTAssertEqual(rect.origin, cs.origin)
        XCTAssertEqual(rect.width, cs.width)
        XCTAssertEqual(rect.height, cs.height)
    }
    
    func testRectWithTwoCells() {
        let cell1 = gridWindow.cellAt(row: 0, column: 0)
        let cell2 = gridWindow.cellAt(row: 1, column: 1)
        let cs = CellSpace(cell1, cell2)
        let rect = cs.cgRect
        XCTAssertEqual(rect.origin, cs.origin)
        XCTAssertEqual(rect.width, cs.width)
        XCTAssertEqual(rect.height, cs.height)
        XCTAssertEqual(rect.width, cell2.frame.maxX - cell1.frame.minX)
        XCTAssertEqual(rect.height, cell2.frame.maxY - cell1.frame.minY)
    }
    
    func testRasterRectWithOneCell() {
        let cell = gridWindow.cellAt(row: gridYDimension - 1, column: gridYDimension - 1)
        let cs = CellSpace(cell, cell)
        let rect = cs.cgRectRaster
        XCTAssertEqual(rect.origin, cs.originRaster)
    }
    
    func testRasterRectWithTwoCells() {
        let cell1 = gridWindow.cellAt(row: gridYDimension - 1, column: gridYDimension - 1)
        let cell2 = gridWindow.cellAt(row: gridYDimension - 2, column: gridYDimension - 2)
        let cs = CellSpace(cell1, cell2)
        let rect = cs.cgRectRaster
        XCTAssertEqual(rect.origin, cs.originRaster)
    }
    
    func testPropertyValuesWithOneCell() {
        var cell = gridWindow.cellAt(row: 0, column: 0)
        var cs = CellSpace(cell, cell)
        XCTAssertEqual(cs.origin, CGPoint(x: 0, y: 0))
        XCTAssertEqual(cs.width, CGFloat(cell.width))
        XCTAssertEqual(cs.height, CGFloat(cell.height))
        
        cell = gridWindow.cellAt(row: gridYDimension - 1, column: 0)
        cs = CellSpace(cell, cell)
        let menuBarHeight = mainScreen.frame.height - mainScreen.visibleFrame.height
        XCTAssertEqual(cs.originRaster, CGPoint(x: 0, y: menuBarHeight))
    }
    
    func testPropertyValuesWithTwoCells() {
        var cell1 = gridWindow.cellAt(row: 0, column: 0)
        var cell2 = gridWindow.cellAt(row: 1, column: 1)
        var cs = CellSpace(cell1, cell2)
        XCTAssertEqual(cs.origin, CGPoint(x: 0, y: 0))
        XCTAssertEqual(cs.width, cell2.frame.maxX)
        XCTAssertEqual(cs.height, cell2.frame.maxY)
        
        cell1 = gridWindow.cellAt(row: gridYDimension - 1, column: 0)
        cell2 = gridWindow.cellAt(row: gridYDimension - 2, column: 1)
        cs = CellSpace(cell1, cell2)
        let menuBarHeight = mainScreen.frame.height - mainScreen.visibleFrame.height
        XCTAssertEqual(cs.originRaster, CGPoint(x: 0, y: menuBarHeight))
    }
}
