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
    func cellAt(point: CGPoint) -> Cell? {
        guard contains(point: point) else { return nil }
        let screenX = Int(point.x - _screen.frame.origin.x)  // Translate to relative screen coordinates
        let screenY = Int(point.y - _screen.frame.origin.y)
        let boundaries = frame.size
        let screenHeight = Int(boundaries.height)
        let screenWidth = Int(boundaries.width)
        let gridXDimension = Defaults.gridXDimension.value
        let gridYDimension = Defaults.gridYDimension.value
        let unpaddedCellWidth = Int( Float(screenWidth) / Float(gridXDimension) )
        let unpaddedCellHeight = Int( Float(screenHeight) / Float(gridYDimension) )
        
        // This is a guess because it's impossible to mathematically ascertain how much padding the cells to the left have
        // when only given screen coordinates.
        // Guessing the row and column will either be correct or overshoot by 1 cell.
                                                             // \/ Forbid guessing outside array dimensions.
        let columnGuess = min(Int(screenX / unpaddedCellWidth), gridXDimension - 1)
        var guessedCellFrame = cells[columnGuess][0].frame
        let columnGuessIsCorrect = guessedCellFrame.contains(CGPoint(x: screenX, y: 0))
        let cellColumn = columnGuessIsCorrect ? columnGuess : columnGuess - 1
        
        let rowGuess = min(Int(screenY / unpaddedCellHeight), gridYDimension - 1)
        guessedCellFrame = cells[0][rowGuess].frame
        let rowGuessIsCorrect = Int(guessedCellFrame.origin.y) <= screenY &&
                                   screenY <= Int((guessedCellFrame.origin.y + guessedCellFrame.height))
        let cellRow = rowGuessIsCorrect ? rowGuess : rowGuess - 1
        
        return cells[cellColumn][cellRow]
    }
    
    func cellAt(row: Int, column: Int) -> Cell {
        return cells[column][row]
    }
    
    func closestCellRectangle(rectangle: CGRect) -> (Cell, Cell) {
        let screenFrame = _screen.visibleFrame
        var newFrame = rectangle
        if rectangle.maxX > screenFrame.maxX {
            newFrame.origin.x = rectangle.origin.x - (rectangle.maxX - screenFrame.maxX)
        }
        else if rectangle.minX < screenFrame.minX {
            newFrame.origin.x = rectangle.origin.x + (screenFrame.minX - rectangle.minX)
        }
        if rectangle.maxY > screenFrame.maxY {
            newFrame.origin.y = rectangle.origin.y - (rectangle.maxY - screenFrame.maxY)
        }
        else if rectangle.minY < screenFrame.minY {
            newFrame.origin.y = rectangle.origin.y + (screenFrame.minY - rectangle.minY)
        }
        let upperLeft = CGPoint(x: newFrame.minX, y: newFrame.maxY)
        let lowerRight = CGPoint(x: newFrame.maxX, y: newFrame.minY)
        let upperLeftCell = cellAt(point: upperLeft)
        let lowerRightCell = cellAt(point: lowerRight)
        return (upperLeftCell!, lowerRightCell!)
    }
    
    func contains(point: CGPoint) -> Bool {
        // _screen.frame.contains() doesn't concider points on maxX or maxY to be contained.
        let screenFrame = _screen.frame
        return screenFrame.minX <= point.x && point.x <= screenFrame.maxX &&
               screenFrame.minY <= point.y && point.y <= screenFrame.maxY
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
