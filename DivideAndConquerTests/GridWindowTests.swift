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
    
    func testCellsCoverEntireScreen() {
        var columnWidth = 0
        var rowHeight = 0
        for colIndex in 0 ... gridXDimension - 1 {
            let cell = gridWindow.cellAt(row: 0, column: colIndex)
            columnWidth += cell.width
        }
        for rowIndex in 0 ... gridYDimension - 1 {
            let cell = gridWindow.cellAt(row: rowIndex, column: 0)
            rowHeight += cell.height
        }
        XCTAssertEqual(columnWidth, Int(mainScreen.visibleFrame.width))
        XCTAssertEqual(rowHeight, Int(mainScreen.visibleFrame.height))
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
        XCTAssertTrue(gridWindow.frame.contains(point: point, includeTopAndRightEdge: true))
        XCTAssertTrue(gridWindow.frame.contains(point: topRight, includeTopAndRightEdge: true))
        XCTAssertTrue(gridWindow.frame.contains(point: lowerLeft, includeTopAndRightEdge: true))
        XCTAssertFalse(gridWindow.frame.contains(point: offScreen, includeTopAndRightEdge: true))
        XCTAssertFalse(gridWindow.frame.contains(point: veryOffScreen, includeTopAndRightEdge: true))
    }
    
    func testClosestCellRectangleWithLargeRectangle() {
        var largeFrame = mainScreen.frame
        largeFrame.size.width *= 2
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
    
    func testClosestCellRectangleOffScreen() {
        let lowerLeftFrame = gridWindow.cellAt(row: 0, column: 0).frame
        let upperRightFrame = gridWindow.cellAt(row: 1, column: 1).frame
        let offScreenRect = CGRect(x: lowerLeftFrame.origin.x - lowerLeftFrame.width * 2,
                                   y: lowerLeftFrame.origin.y - lowerLeftFrame.height * 2,
                                   width: upperRightFrame.maxX,
                                   height: upperRightFrame.maxY)
        var (upperLeft, lowerRight) = gridWindow.closestCellRectangle(rectangle: offScreenRect)
        XCTAssertEqual(upperLeft.row, 1)
        XCTAssertEqual(upperLeft.column, 0)
        XCTAssertEqual(lowerRight.row, 0)
        XCTAssertEqual(lowerRight.column, 1)
        subsequentCellValuesAreCorrect(cell: upperLeft)
        subsequentCellValuesAreCorrect(cell: lowerRight)
        
        let newRect = CGRect(x: upperLeft.frame.origin.x, y: lowerRight.frame.origin.y,
                             width: lowerRight.frame.maxX, height: upperLeft.frame.maxY)
        
        (upperLeft, lowerRight) = gridWindow.closestCellRectangle(rectangle: newRect)
        XCTAssertEqual(upperLeft.row, 1)
        XCTAssertEqual(upperLeft.column, 0)
        XCTAssertEqual(lowerRight.row, 0)
        XCTAssertEqual(lowerRight.column, 1)
        subsequentCellValuesAreCorrect(cell: upperLeft)
        subsequentCellValuesAreCorrect(cell: lowerRight)
        
    }
    
    func testRequiredProperties() {
        XCTAssertFalse(gridWindow.isReleasedWhenClosed)
        XCTAssertTrue(gridWindow.canBecomeKey)
    }
}
