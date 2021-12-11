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
    case windowDragged
    case secondaryHit
    case gridActivated
    case firstCellPicked
}

class SnappingManager {
    var snapState : SnapState = .idle
    var mouseEventNotifier = MouseMonitor()
    var firstPickedCell: CellView? = nil
    var windowElement: AccessibilityElement? = nil
    var windowId: Int? = nil
    var windowIdAttempt: Int = 0
    var lastWindowIdAttempt: TimeInterval? = nil
    var windowMoving: Bool = false
    var initialWindowRect: CGRect? = nil
    var mouseUpsToIgnore: Int = 0
    var mouseDownsToIgnore: Int = 0
    
    var grid: GridWindow?
    
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
        grid?.close()
        grid = nil
        snapState = .idle
        windowElement = nil
        windowId = nil
        windowMoving = false
        initialWindowRect = nil
        windowIdAttempt = 0
        lastWindowIdAttempt = nil
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
        if (mouseDownsToIgnore > 0) {
            mouseDownsToIgnore -= 1
        }
        else {
            windowElement = AccessibilityElement.windowUnderCursor()
            windowId = windowElement?.getIdentifier()
            initialWindowRect = windowElement?.rectOfElement()
            snapState = .windowSelected
            print("(.leftMouseDown) snapState = .windowActivated")
        }
    }
    
    @objc private func handleLeftMouseDragged() {
        if (snapState == .windowSelected || snapState == .secondaryHit) {
            guard let windowElement = windowElement else { return }
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
        else if (snapState == .firstCellPicked) {
            // Resnap if necessary
        }
        else if (snapState == .gridActivated){
            // TODO send parameters to WindowManager
            /*
            let location = NSEvent.mouseLocation
            if let cell = grid!.cellAt(location: location) {
//                let parameters = ExecutionParameters(self, updateRestoreRect: false, screen: screen, windowElement: windowElement, windowId: windowId)
//                windowManager.execute(cell1: cell, cell2: nil, screen)
//                OutdatedWindowMover.moveWindowRect(cell1: cell, cell2: nil, windowElement: windowElement!)
            }
            else {
                // TODO Outside screen coordinates. Could be in status bar or another screen.
            }
             */
        }
    }
    
    @objc private func handleRightMouseDown() {
        if (snapState == .windowSelected) {
            snapState = .secondaryHit
            print("(.rightMouseDown) snapState = .secondaryHit")
        }
        else if (snapState == .windowDragged) {
            print ("(.rightMouseDown) Attempting to activate grid.")
            activateGrid()
        }
        else if (snapState == .firstCellPicked) {
            snapState = .gridActivated
            print ("(.rightMouseDown) snapState = .firstCellPicked")
            // TODO Unsnap the first cell. This helps with the grid feel, especially if the user accidentally snapped on the wrong cell.
        }
        else {
            snapState = .idle
            print("(.rightMouseDown) snapState = .idle")
        }
    }
    
    @objc private func handleRightMouseUp() {
        if (snapState == .gridActivated) {
            snapState = .firstCellPicked
            print("(.rightMouseUp) snapState = .firstCellPicked")
        }
    }
    
    @objc private func handleLeftMouseUp() {
        if (mouseUpsToIgnore > 0) {
            mouseUpsToIgnore -= 1
        }
        else {
            print("(.leftMouseUp) Reseting state.")
            resetState()
        }
    }
    
    /// Attempts to set grid and display grid window. Updates snapState to .gridActivated on success, or .idle on failure.
    private func activateGrid() {
        guard let activeScreen = NSScreen.main else {
            Logger.log("Failed to find the active screen, so grid was not activated.")
            snapState = .idle
            print("(activateGrid) snapState = .idle (Grid failed to activate)")
            resetState()
            return
        }
        grid?.close()  // Grid shouldn't exist, let alone have a window open, but this is just to be safe.
        grid = GridWindow(screen: activeScreen)
        NSApp.activate(ignoringOtherApps: true)
        grid!.makeKeyAndOrderFront(nil)
        // grid.isVisible really means "I plan to be visible in the future". However, the Grid remains
        // invisible until sometime after this function returns, so focusing mouse on grid must be called asynchronously.
        // Yes, this means there is no way to focus the mouse on the grid in this function in this thread.
        // This also means there is no way to determine if the grid is either genuinely visible, or plans to be.
        // This creates a race condition. We have to hope the window becomes visible between now and the time
        // the async call below is made. Perhaps SwiftUI may have been a better choice...
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
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
        guard grid != nil && grid!.isVisible else {
            Logger.log("Attempted to focus mouse on grid, but the grid isn't present or is invisible.")
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
}
