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
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        animator().alphaValue = CGFloat(Defaults.footprintAlpha.value)
        super.makeKeyAndOrderFront(sender)
    }
    
    private func fillWithCells() {
        let gridXDimension = Defaults.gridXDimension.value
        let gridYDimension = Defaults.gridYDimension.value
        let boundaries = frame.size
        let screenHeight = Int(boundaries.height)
        let screenWidth = Int(boundaries.width)
        let cellWidth = Int( Float(screenWidth) / Float(gridXDimension) )
        let cellHeight = Int( Float(screenHeight) / Float(gridYDimension) )
        for i in 0 ... gridXDimension - 1 {
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
            }
        }
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
    
    override func mouseEntered(with event: NSEvent){
        super.mouseEntered(with: event)
        layer!.backgroundColor = Defaults.cellPrimaryColor.typedValue?.cgColor ?? NSColor.systemBlue.cgColor
    }
    
    override func mouseExited(with event: NSEvent){
        super.mouseEntered(with: event)
        layer!.backgroundColor = NSColor.clear.cgColor
    }
    
}
