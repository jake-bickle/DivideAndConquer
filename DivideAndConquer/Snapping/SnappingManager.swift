//
//  SnappingManager.swift
//  Rectangle
//
//  Created by Ryan Hanson on 9/4/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

enum SnapState {
    case idle
    case windowSelected
    case windowDragged; case secondaryHit
    case gridActivated
    case firstCellPicked
}

class SnappingManager {
    var snapState : SnapState = .idle
    var mouseEventNotifier = MouseMonitor()
    var windowMover = WindowMover()
    var lock = NSLock()
    var firstPickedCell: Cell? = nil
    var windowElement: AccessibilityElement? = nil
    var initialWindowRect: CGRect? = nil
    var mouseUpsToIgnore: Int = 0
    var mouseDownsToIgnore: Int = 0
    
    let screenDetection = ScreenDetection()
    
    init() {
        if Defaults.windowSnapping.enabled != false {
            enableSnapping()
        }
    }
        
    // TODO Double check this is working as expected
    public func reloadFromDefaults() {
        if Defaults.windowSnapping.userDisabled {
            if mouseEventNotifier.running {
                disableSnapping()
            }
            
        } else {
            if !mouseEventNotifier.running {
                enableSnapping()
            }
        }
    }
    
    private func enableSnapping() {
        subscribeToMouseNotifications()
        mouseEventNotifier.start()
    }
    
    private func disableSnapping() {
        unsubscribeFromMouseNotifications()
        mouseEventNotifier.stop()
        resetState()
    }
    
    private func resetState() {
        GridManager.shared.close()
        snapState = .idle
        windowElement = nil
        initialWindowRect = nil
        firstPickedCell = nil
    }
    
    private func subscribeToMouseNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(handleLeftMouseDown),
                                               name: Notification.Name.leftMouseDown,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(handleLeftMouseDragged),
                                               name: Notification.Name.mouseDrag,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(handleRightMouseDown),
                                               name: Notification.Name.rightMouseDown,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(handleRightMouseUp),
                                               name: Notification.Name.rightMouseUp,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(handleLeftMouseUp),
                                               name: Notification.Name.leftMouseUp,
                                               object: nil)
    }
    
    private func unsubscribeFromMouseNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc private func handleLeftMouseDown() {
        lock.lock()
        if (mouseDownsToIgnore > 0) {
            mouseDownsToIgnore -= 1
        }
        else {
            windowElement = AccessibilityElement.windowUnderCursor()
            initialWindowRect = windowElement?.rectOfElement()
            snapState = .windowSelected
            print("(.leftMouseDown) snapState = .windowActivated")
        }
        lock.unlock()
    }
    
    @objc private func handleLeftMouseDragged() {
        lock.lock()
        if (snapState == .windowSelected || snapState == .secondaryHit) {
            guard let windowElement = getWindowElementElseResetState() else {
                lock.unlock()
                return
            }
            let currentRect = windowElement.rectOfElement()
            
            let windowIsDragging = currentRect.size == initialWindowRect?.size && currentRect.origin != initialWindowRect?.origin
            if (windowIsDragging && snapState == .windowSelected) {
                snapState = .windowDragged
                print("(.leftMouseDragged) snapState = .windowDragged")
            }
            else if (windowIsDragging /* snapState == secondaryHit */ ) {
                print("(.leftMouseDragged) Attempting to activate grid.")
                activateGrid()
            }
        }
        else if (snapState == .gridActivated || snapState == .firstCellPicked) {
            updateWindowPosition()
        }
        lock.unlock()
    }
    
    @objc private func handleRightMouseDown() {
        lock.lock()
        if (snapState == .windowSelected) {
            snapState = .secondaryHit
            print("(.rightMouseDown) snapState = .secondaryHit")
        }
        else if (snapState == .windowDragged) {
            print("(.rightMouseDown) Attempting to activate grid.")
            activateGrid()
            updateWindowPosition()
        }
        else if (snapState == .firstCellPicked) {
            snapState = .gridActivated
            print ("(.rightMouseDown) snapState = .gridActivated")
            firstPickedCell = nil
            updateWindowPosition()
        }
        lock.unlock()
    }
    
    @objc private func handleRightMouseUp() {
        lock.lock()
        if (snapState == .secondaryHit) {
            snapState = .windowSelected
            print("(.rightMouseUp) snapState = .windowSelected")
        }
        else if (snapState == .gridActivated) {
            let location = NSEvent.mouseLocation
            firstPickedCell = GridManager.shared.cellAt(point: location)  // It's okay if there is no cell at the mouse.
            snapState = .firstCellPicked
            print("(.rightMouseUp) snapState = .firstCellPicked")
            updateWindowPosition()
        }
        lock.unlock()
    }
    
    @objc private func handleLeftMouseUp() {
        lock.lock()
        if (mouseUpsToIgnore > 0) {
            mouseUpsToIgnore -= 1
        }
        else {
            print("(.leftMouseUp) Reseting state.")
            resetState()
        }
        lock.unlock()
    }
    
    /// Attempts to display grid window then focus on it. Updates snapState to .gridActivated on success, or .idle on failure.
    private func activateGrid() {
        GridManager.shared.show()
        // Run the event loop so the window becomes visible immediately. This allows the subsequent code to focus
        // the cursor on the window.
        CFRunLoopRunInMode(.defaultMode?, 0, false)
        
        if (self.focusMouseOnGrid()){
            self.snapState = .gridActivated
            print("(activateGrid) snapState = .gridActivated")
        }
        else {
            Logger.log("Failed to focus mouse on grid window, so grid was deactivated.")
            self.snapState = .idle
            self.resetState()
            print("(activateGrid) snapState = .idle (Grid failed to activate)")
        }
    }
    
    // The user activates the grid by dragging a window. Once activated, mouseDrag events call the WindowMover
    // and the window is resized. Unfortunately, the user is still technically dragging the window, and thus
    // WindowMover fights with the dragging mouse over who gets to resize and move the window.
    // There is no way to programatically tell the window to stop being dragged. Instead, we must
    // synthesize a MouseUp event. Additionally, we must MouseDown on top of the grid, to both reflect the fact
    // that the user is still physically holding the mouse button down, and enabling the GridWindow to receive mouse
    // events.
    // The goal of focusMouseOnGrid is to perform this seamlessly.
    /// Attempts to focus mouse cursor on grid window. Returns true if successful, false otherwise.
    private func focusMouseOnGrid() -> Bool {
        guard GridManager.shared.setToShow else {
            Logger.log("Attempted to focus mouse on grid, but the grid hasn't been revealed.")
            return false
        }
        let mouseLocation = NSEvent.mouseLocation
        guard let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: mouseLocation, mouseButton: .left)
        else {
            Logger.log("Attempted to synthesize a MouseUp event, but failed for some unexpected reason.")
            return false
        }
        guard let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mouseLocation, mouseButton: .left)
        else {
            Logger.log("Attempted to synthesize a MouseDown event, but failed for some unexpected reason.")
            return false
        }
        mouseUp.location = mouseUp.unflippedLocation
        mouseDown.location = mouseDown.unflippedLocation
        
        mouseUpsToIgnore = 2  // For some reason, mouseUp.post is sent twice to the MouseMonitor.
        mouseDownsToIgnore = 1
        mouseUp.post(tap: .cghidEventTap)
        mouseDown.post(tap: .cghidEventTap)
        return true
    }
    
    func updateWindowPosition() {
        let location = NSEvent.mouseLocation
        guard let windowElement = getWindowElementElseResetState(),
              let cellAtMouse = GridManager.shared.cellAt(point: location)
        else { return }
        var cell1: Cell
        var cell2: Cell?
        if let firstPickedCell = firstPickedCell {
            if firstPickedCell.screen == cellAtMouse.screen {
                cell1 = firstPickedCell
                cell2 = cellAtMouse
            }
            else {
                cell1 = firstPickedCell
                cell2 = nil
            }
        }
        else {
            cell1 = cellAtMouse
            cell2 = nil
        }
        DispatchQueue.main.async {
            let cs = CellSpace(cell1, cell2)
            GridManager.shared.dehighlight(screen: cell1.screen)
            GridManager.shared.highlight(cellSpace: cs)
        }
        windowMover.tryToMove(window: windowElement, to: cell1, and: cell2)
    }
    
    /// Returns windowElement if it exists, otherwise resets state, logs failure, then returns nil.
    private func getWindowElementElseResetState() -> AccessibilityElement? {
        if (windowElement == nil){
            resetState()
            Logger.log("Attempted to retrieve window element, but it is no longer set.")
            print("snapState = .idle (Error: Window element isn't set)")
        }
        return windowElement
    }
}
