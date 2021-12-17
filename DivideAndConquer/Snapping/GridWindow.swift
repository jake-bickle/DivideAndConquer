//
//  FootprintWindow.swift
//  Rectangle
//
//  Created by Ryan Hanson on 10/17/20.
//  Copyright © 2020 Ryan Hanson. All rights reserved.
//

import Cocoa

class GridWindow: NSWindow {
    
    var closeWorkItem: DispatchWorkItem?
    var view: NSView
    var cells: [[Cell]] = []
    var _screen: NSScreen  // Non-optional equivalent of NSWindow.screen
    
    init(screen: NSScreen) {
        _screen = screen
        let x = screen.frame.origin.x
        let y = screen.frame.origin.y
        let boundaries = screen.visibleFrame.size
        let screenHeight = boundaries.height
        let screenWidth = boundaries.width
        view = NSView(frame: NSRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        view.wantsLayer = true
        
        let initialSize = NSRect(x: x, y: y, width: screenWidth, height: screenHeight)
        super.init(contentRect: initialSize, styleMask: .borderless, backing: .buffered, defer: false)
        isReleasedWhenClosed = false   // Fixes crash when super.close() is called.
        
        contentView?.addSubview(view)
        alphaValue = CGFloat(Defaults.gridWindowAlpha.value)
        isOpaque = false
        fillWithCells()
    }
    
    override var canBecomeKey: Bool { get {true} }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        super.makeKeyAndOrderFront(sender)
    }
    
    private func fillWithCells() {
        cells = []
        let gridXDimension = Defaults.gridXDimension.value
        let gridYDimension = Defaults.gridYDimension.value
        let boundaries = frame.size
        let screenHeight = Int(boundaries.height)
        let screenWidth = Int(boundaries.width)
        let cellWidth = Int( Float(screenWidth) / Float(gridXDimension) )
        let cellHeight = Int( Float(screenHeight) / Float(gridYDimension) )
        for i in 0 ... gridXDimension - 1 {
            cells.append( [] )
            for j in 0 ... gridYDimension - 1 {
                // Grid dimensions aren't guaranteed to be divisible by screen dimensions, so some careful
                // padding is necessary for the grid to fill the screen properly while also making each cell
                // appear the same size.
                let widthRemainder = screenWidth % gridXDimension
                let heightRemainder = screenHeight % gridYDimension
                let xPadding = widthRemainder - i > 0 ? 1 : 0
                let yPadding = heightRemainder - j > 0 ? 1 : 0
                let previousXPadding = min(i, widthRemainder)
                let previousYPadding = min(j, heightRemainder)
                let xCoord = i * cellWidth + previousXPadding
                let yCoord = j * cellHeight + previousYPadding
                let rect = NSRect(x: xCoord, y: yCoord,
                                  width: cellWidth + xPadding, height: cellHeight + yPadding)
                let newCell = Cell(frame: rect, screen: _screen,
                                   row: j, rowMax: gridYDimension - 1,
                                   column: i, columnMax: gridXDimension - 1)
                newCell.rowMax = gridYDimension - 1
                newCell.columnMax = gridXDimension - 1
                view.addSubview(newCell)
                cells[i].append(newCell)
            }
        }
    }
    
    /// Returns the cell located at the specified screen coordinates (origin at bottom left of main screen).
    /// Points that lie on the edge favor towards the bottom left of the screen.
    func cellAt(point: CGPoint) -> Cell? {
        guard frame.contains(point: point, includeTopAndRightEdge: true) else { return nil }
        let screenX = point.x - _screen.frame.origin.x  // Translate to relative screen coordinates
        let screenY = point.y - _screen.frame.origin.y
        let boundaries = frame.size
        let screenHeight = Int(boundaries.height)
        let screenWidth = Int(boundaries.width)
        let gridXDimension = Defaults.gridXDimension.value
        let gridYDimension = Defaults.gridYDimension.value
        let unpaddedCellWidth = CGFloat( Int( screenWidth / gridXDimension ) )
        let unpaddedCellHeight = CGFloat( Int( screenHeight / gridYDimension ) )
        
        // This is a guess because it's impossible to mathematically ascertain how much padding the cells to the left have
        // when only given screen coordinates.
        // Guessing the row and column will either be correct or overshoot by 1 cell.
                                                             // \/ Forbid guessing outside array dimensions.
        let columnGuess = min(Int(screenX / unpaddedCellWidth), gridXDimension - 1)
        var guessedCellFrame = cells[columnGuess][0].frame
        let columnGuessIsCorrect = (guessedCellFrame.minX < screenX && screenX <= guessedCellFrame.maxX) || columnGuess == 0
                                
        let cellColumn = columnGuessIsCorrect ? columnGuess : columnGuess - 1
        
        let rowGuess = min(Int(screenY / unpaddedCellHeight), gridYDimension - 1)
        guessedCellFrame = cells[0][rowGuess].frame
        let rowGuessIsCorrect = guessedCellFrame.minY < screenY && screenY <= guessedCellFrame.maxY || rowGuess == 0
        let cellRow = rowGuessIsCorrect ? rowGuess : rowGuess - 1
        
        return cells[cellColumn][cellRow]
    }
    
    func cellAt(row: Int, column: Int) -> Cell {
        return cells[column][row]
    }
    
    /// Returns cells at and near point.
    func cellsNear(point: CGPoint) -> [Cell] {
        var cells: [Cell] = []
        let lowerLeftCell = cellAt(point: point)
        guard let lowerLeftCell = lowerLeftCell else { return cells }
        cells.append(lowerLeftCell)
        let cellsToTheRight = lowerLeftCell.column != lowerLeftCell.columnMax
        let cellsAbove = lowerLeftCell.row != lowerLeftCell.rowMax
        if cellsAbove {
            cells.append( cellAt(row: lowerLeftCell.row + 1, column: lowerLeftCell.column) )
        }
        if cellsToTheRight {
            cells.append( cellAt(row: lowerLeftCell.row, column: lowerLeftCell.column + 1) )
        }
        if cellsAbove && cellsToTheRight {
            cells.append( cellAt(row: lowerLeftCell.row + 1, column: lowerLeftCell.column + 1) )
        }
        return cells
    }
    
    func closestCellRectangle(rectangle: CGRect) -> (Cell, Cell)? {
        let screenFrame = _screen.visibleFrame
        var newFrame = rectangle
        if rectangle.width > screenFrame.width {
            newFrame.origin.x = screenFrame.origin.x
            newFrame.size.width = screenFrame.width
        }
        else if rectangle.maxX > screenFrame.maxX {
            newFrame.origin.x -= rectangle.maxX - screenFrame.maxX
        }
        else if rectangle.minX < screenFrame.minX {
            newFrame.origin.x += screenFrame.minX - rectangle.minX
        }
        
        if rectangle.height > screenFrame.height {
            newFrame.origin.y = screenFrame.origin.y
            newFrame.size.height = screenFrame.height
        }
        else if rectangle.maxY > screenFrame.maxY {
            newFrame.origin.y -= rectangle.maxY - screenFrame.maxY
        }
        else if rectangle.minY < screenFrame.minY {
            newFrame.origin.y += screenFrame.minY - rectangle.minY
        }
        
        let upperLeft = CGPoint(x: newFrame.minX, y: newFrame.maxY)
        let lowerRight = CGPoint(x: newFrame.maxX, y: newFrame.minY)
        
        // Replafce cellsAtt with cellsNear
        let competeingUpperLeftCells = cellsNear(point: upperLeft)
        guard let upperLeftCell = greatestIntersection(of: competeingUpperLeftCells, in: newFrame) else { return nil }
        
        // TODO Hm, this doesn't look right
        let competeingLowerRightCells = cellsNear(point: lowerRight)
        guard let lowerRightCell = greatestIntersection(of: competeingLowerRightCells, in: newFrame) else { return nil }
        return (upperLeftCell, lowerRightCell)
    }
    
    /// Given a list of cells, returns the cell with the largest intersection of the provided CGRect. If there is a tie, the first cell with the largest intersection is returned.
    func greatestIntersection(of cells: [Cell], in rect: CGRect) -> Cell? {
        var greatestIntersection: Cell?
        var greatestArea = CGFloat.infinity
        greatestArea.negate()
        for cell in cells {
            let cellFrame = cell.frame
            let intersection = rect.intersection(cellFrame)
            let area = intersection.width * intersection.height
            if area > greatestArea {
                greatestIntersection = cell
                greatestArea = area
            }
        }
        return greatestIntersection
    }
    
    override func close() {
        animator().alphaValue = 0.0
        let closeWorkItem = DispatchWorkItem {
            super.close()
        }
        self.closeWorkItem = closeWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: closeWorkItem)
    }
}

class CellView: NSView {
    override init(frame: NSRect){
        super.init(frame: frame)
        wantsLayer = true
        layer!.borderColor = Defaults.cellPrimaryColor.typedValue?.cgColor ?? NSColor.systemBlue.cgColor
        layer!.borderWidth = CGFloat(Defaults.cellBorderWidth.value)
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .enabledDuringMouseDrag, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name.leftMouseUp, object: nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name.leftMouseDown, object: nil)
        // Tecehnically not a drag, but aids in feel as this allows SnappingManager to snap right away.
        mouseDragged(with: event)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name.rightMouseUp, object: nil)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name.rightMouseDown, object: nil)
    }
    
    override func mouseDragged(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name.mouseDrag, object: nil)
    }
    
    override func mouseEntered(with event: NSEvent){
        super.mouseEntered(with: event)
        layer!.backgroundColor = Defaults.cellPrimaryColor.typedValue?.cgColor ?? NSColor.systemBlue.cgColor
    }
    
    override func mouseExited(with event: NSEvent){
        super.mouseExited(with: event)
        layer!.backgroundColor = NSColor.clear.cgColor
    }
    
}

class Cell: CellView {
    var row: Int
    var rowMax: Int
    var column: Int
    var columnMax: Int
    var screen: NSScreen
    var absoluteX: Int { Int(screen.frame.origin.x + frame.origin.x) }  // Translates cell to absolute`
    var absoluteY: Int { Int(screen.frame.origin.y + frame.origin.y) }
    var height: Int { Int(frame.height) }
    var width: Int { Int(frame.width) }
    var absoluteXRaster: Int { absoluteX }
    var absoluteYRaster: Int {
        let frameOfMainScreenWithMenuBar = NSScreen.screens[0].frame as CGRect
        let frameOfMainScreen = NSScreen.screens[0].visibleFrame as CGRect
        let menuBarHeight = Int(frameOfMainScreenWithMenuBar.size.height - frameOfMainScreen.height)
        let topOfCell = Int(frameOfMainScreen.height) - absoluteY - height
        return topOfCell + menuBarHeight
    }
    
    init(frame: NSRect, screen s: NSScreen, row r: Int, rowMax rm: Int, column c: Int, columnMax cm: Int) {
        row = r
        rowMax = rm
        column = c
        columnMax = cm
        screen = s
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
