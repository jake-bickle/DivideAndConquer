//
//  FootprintWindow.swift
//  Rectangle
//
//  Created by Ryan Hanson on 10/17/20.
//  Copyright © 2020 Ryan Hanson. All rights reserved.
//

import Cocoa

// TODO Could this be improved by using a tableview?
class GridWindow: NSWindow {
    
    private var closeWorkItem: DispatchWorkItem?
    private var view: NSView
    private var cells: [[Cell]] = []
    
    init(screen: NSScreen) {
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
        fillWithCells()
    }
    
    override var canBecomeKey: Bool { get {true} }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        animator().alphaValue = CGFloat(Defaults.footprintAlpha.value)
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
                let newCell = Cell(frame: rect)
                view.addSubview(newCell)
                cells[i].append(newCell)
            }
        }
    }
    
    // Returns the cell located at the specified screen coordinates.
    func cellAt(location: CGPoint) -> Cell? {
        guard frame.contains(location) else { return nil }
        let screenX = Int(location.x)
        let screenY = Int(location.y)
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
    
    override func close() {
        animator().alphaValue = 0.0
        let closeWorkItem = DispatchWorkItem {
            super.close()
        }
        self.closeWorkItem = closeWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: closeWorkItem)
    }
}

class Cell: NSView {
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

extension NSView {
    
    /// Attempts to flip origin.frame.y based on the container the view is in. If the view is not in a container, returns nil.
    func originFlippedY() -> CGFloat? {
        let y = frame.origin.y
        var parentContainerHeight: CGFloat
        if let superview = superview {
            parentContainerHeight = superview.frame.height
        }
        else if let window = window {
            parentContainerHeight = window.frame.height
        }
        else {
            return nil
        }
        return parentContainerHeight - y
    }
}
