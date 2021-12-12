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
        subsequentCellValuesAreCorrect(cell: topRightCell)
        
        let lowerLeft = CGPoint(x: mainScreen.visibleFrame.minX, y: mainScreen.visibleFrame.minY)
        let lowerLeftCell = gridWindow.cellAt(point: lowerLeft)
        guard let lowerLeftCell = lowerLeftCell else {
            XCTFail("Cell should have been found, but it was nil.")
            return
        }
        XCTAssertEqual(lowerLeftCell.row, 0)
        XCTAssertEqual(lowerLeftCell.column, 0)
        subsequentCellValuesAreCorrect(cell: lowerLeftCell)
    }
    
    func testCellInMiddleOfScreen() {
        let point = CGPoint(x: Int(mainScreen.visibleFrame.maxX / 2), y: Int(mainScreen.visibleFrame.maxY / 2))
        let lowerLeftCell = gridWindow.cellAt(point: point)
        guard let lowerLeftCell = lowerLeftCell else {
            XCTFail("Cell should have been found, but it was nil.")
            return
        }
        XCTAssertNotEqual(lowerLeftCell.row, 0)
        XCTAssertNotEqual(lowerLeftCell.row, gridYDimension - 1)
        XCTAssertNotEqual(lowerLeftCell.column, 0)
        XCTAssertNotEqual(lowerLeftCell.column, gridXDimension - 1)
        subsequentCellValuesAreCorrect(cell: lowerLeftCell)
        
    }
    
    func subsequentCellValuesAreCorrect(cell: Cell) {
        XCTAssertEqual(cell.columnMax, gridXDimension - 1)
        XCTAssertEqual(cell.rowMax, gridYDimension - 1)
        XCTAssertEqual(cell.screen, mainScreen)
    }
    
    func testGridContainsPoint() {
        let topRight = CGPoint(x: mainScreen.visibleFrame.maxX, y: mainScreen.visibleFrame.maxY)
        let lowerLeft = CGPoint(x: mainScreen.visibleFrame.minX, y: mainScreen.visibleFrame.minY)
        let point = CGPoint(x: Int(mainScreen.visibleFrame.maxX / 2), y: Int(mainScreen.visibleFrame.maxY / 2))
        let offScreen = CGPoint(x: mainScreen.visibleFrame.maxX, y: mainScreen.visibleFrame.maxY + 1)
        let veryOffScreen = CGPoint(x: mainScreen.visibleFrame.maxX * -1, y: mainScreen.visibleFrame.maxY)
        XCTAssertTrue(gridWindow.contains(point: point))
        XCTAssertTrue(gridWindow.contains(point: topRight))
        XCTAssertTrue(gridWindow.contains(point: lowerLeft))
        XCTAssertFalse(gridWindow.contains(point: offScreen))
        XCTAssertFalse(gridWindow.contains(point: veryOffScreen))
    }
    
    func testClosestCellRectangleWithLargeRectangle() {
        let largeFrame = mainScreen.frame
        let (upperLeft, lowerRight) = gridWindow.closestCellRectangle(rectangle: largeFrame)
        XCTAssertEqual(upperLeft.row, gridYDimension - 1)
        XCTAssertEqual(upperLeft.column, 0)
        XCTAssertEqual(lowerRight.row, 0)
        XCTAssertEqual(lowerRight.column, gridXDimension - 1)
        subsequentCellValuesAreCorrect(cell: upperLeft)
        subsequentCellValuesAreCorrect(cell: lowerRight)
    }
    
    func testClosestCellRectangleWithSmallRectangle() {
        var smallFrame = gridWindow.cellAt(row: 0, column: 0).frame
        smallFrame.origin.x += 1
        smallFrame.origin.y += 1
        smallFrame.size.width -= 2
        smallFrame.size.height -= 2
        let (upperLeft, lowerRight) = gridWindow.closestCellRectangle(rectangle: smallFrame)
        XCTAssertEqual(upperLeft.row, 0)
        XCTAssertEqual(upperLeft.column, 0)
        XCTAssertEqual(lowerRight.row, 0)
        XCTAssertEqual(lowerRight.column, 0)
        subsequentCellValuesAreCorrect(cell: upperLeft)
        subsequentCellValuesAreCorrect(cell: lowerRight)
    }
    
    func testRequiredProperties() {
        XCTAssertFalse(gridWindow.isReleasedWhenClosed)
        XCTAssertTrue(gridWindow.canBecomeKey)
    }
}
