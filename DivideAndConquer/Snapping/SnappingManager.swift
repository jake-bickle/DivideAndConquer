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
    case halfActivated
    case gridActivated
    case firstCellPicked
}

class SnappingManager {
    
    var snapState : SnapState = .idle
    let eventMonitor: EventMonitor
    var windowElement: AccessibilityElement?
    var windowId: Int?
    var windowIdAttempt: Int = 0
    var lastWindowIdAttempt: TimeInterval?
    var windowMoving: Bool = false
    var initialWindowRect: CGRect?
    
    var grid: GridWindow?
    
    let screenDetection = ScreenDetection()
    
    init() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .leftMouseUp, .leftMouseDragged,
                                           .rightMouseDown, .rightMouseUp, .rightMouseDragged], handler: handle)
        
        if Defaults.windowSnapping.enabled != false {
            enableSnapping()
        }
        
        Notification.Name.windowSnapping.onPost { notification in
            guard let enabled = notification.object as? Bool else { return }
            if enabled {
                if !Defaults.windowSnapping.userDisabled {
                    self.enableSnapping()
                }
            } else {
                self.disableSnapping()
            }
        }
    }
        
    public func reloadFromDefaults() {
        if Defaults.windowSnapping.userDisabled {
            if eventMonitor.running {
                disableSnapping()
            }
            
        } else {
            if !eventMonitor.running {
                enableSnapping()
            }
        }
    }
    
    private func enableSnapping() {
        eventMonitor.start()
    }
    
    private func disableSnapping() {
        eventMonitor.stop()
        resetState()
    }
    
    // TODO Get a better name
    private func resetState() {
        grid = nil
        snapState = .idle
        windowElement = nil
        windowId = nil
        windowMoving = false
        initialWindowRect = nil
        windowIdAttempt = 0
        lastWindowIdAttempt = nil
    }
    
    var windowSelected: Bool { get { return windowElement != nil } }
    
    func handle(event: NSEvent?) {
        guard let event = event else { return }
        switch event.type {
            
            
        // TODO Check if all of the extra "else .idle" code is necessary
        case .leftMouseDown:
            windowElement = AccessibilityElement.windowUnderCursor()
            windowId = windowElement?.getIdentifier()
            initialWindowRect = windowElement?.rectOfElement()
            snapState = .windowSelected

        case .leftMouseDragged:
            if (snapState == .windowSelected || snapState == .halfActivated ) {
                guard let windowElement = windowElement else { return }
                let currentRect = windowElement.rectOfElement()
                let windowIsDragging = currentRect.size == initialWindowRect?.size && currentRect.origin != initialWindowRect?.origin
                if (snapState == .windowSelected && windowIsDragging) {
                    snapState = .halfActivated
                }
                else if (windowIsDragging){
                    snapState = .gridActivated
                    // TODO Activate the grid!
                }
                snapState = windowIsDragging ? .windowDragging : .idle
            }
            else if (snapState == .firstCellPicked) {
                
            }
            else {
                snapState = .idle
            }

        case .rightMouseDown:
            if (snapState == .windowSelected) {
                snapState = .halfActivated
            }
            else if (snapState == .halfActivated) {
                snapState = .gridActivated
                // TODO Activate the grid! Snap the window to the current selected cell
            }
            else if (snapState == .firstCellPicked) {
                snapState = .gridActivated
                // TODO Unsnap the first cell. This helps with the grid feel, especially if the user accidentally snapped on the wrong cell.
            }
            else {
                snapState = .idle
            }

        case .rightMouseDragged:
            if (snapState == .gridActivated) {
                // TODO If mf ouse hovers over another cell, resnap the window to said cell
            }
            else {
                snapState = .idle
            }
    
        case .leftMouseUp:
            if (snapState == .gridActivated || snapState == .firstCellPicked) {
                // Turn off grid. Leave the window snapped where it is.
            }
            snapState = .idle
        // TODO A lot of the code below is old. Repurpose it.
        
            if let currentSnapArea = self.currentSnapArea {
                grid?.close()
                currentSnapArea.action.postSnap(windowElement: windowElement, windowId: windowId, screen: currentSnapArea.screen)
                self.currentSnapArea = nil
            } else {
                // it's possible that the window has moved, but the mouse dragged events are not getting the updated window position
                // this typically only happens if the user is dragging and dropping windows really quickly
                // in this scenario, the footprint doesn't display but the snap will still occur, as long as the window position is updated as of mouse up.
                if let currentRect = windowElement?.rectOfElement(),
                   let windowId = windowId,
                   currentRect.size == initialWindowRect?.size,
                   currentRect.origin != initialWindowRect?.origin,
                   let snapArea = snapAreaContainingCursor(priorSnapArea: currentSnapArea)  {
                    grid?.close()
                    if !(Defaults.snapModifiers.value > 0) ||
                       event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue == Defaults.snapModifiers.value {
                        snapArea.action.postSnap(windowElement: windowElement, windowId: windowId, screen: snapArea.screen)
                    }
                    self.currentSnapArea = nil
                }
            }
            windowElement = nil
            windowId = nil
            windowMoving = false
            initialWindowRect = nil
            windowIdAttempt = 0
            lastWindowIdAttempt = nil
        case .leftMouseDragged:
            if windowId == nil, windowIdAttempt < 20 {
                if let lastWindowIdAttempt = lastWindowIdAttempt {
                    if event.timestamp - lastWindowIdAttempt < 0.1 {
                        return
                    }
                }
                if windowElement == nil {
                    windowElement = AccessibilityElement.windowUnderCursor()
                }
                windowId = windowElement?.getIdentifier()
                initialWindowRect = windowElement?.rectOfElement()
                windowIdAttempt += 1
                lastWindowIdAttempt = event.timestamp
            }
            guard let currentRect = windowElement?.rectOfElement(),
                let windowId = windowId
            else { return }
            
            if !windowMoving {
                if currentRect.size == initialWindowRect?.size {
                    if currentRect.origin != initialWindowRect?.origin {
                        windowMoving = true

                        if Defaults.unsnapRestore.enabled != false {
                            // if window was put there by rectangle, restore size
                            if let lastRect = AppDelegate.windowHistory.lastRectangleActions[windowId]?.rect,
                                lastRect == initialWindowRect,
                                let restoreRect = AppDelegate.windowHistory.restoreRects[windowId] {
                                
                                windowElement?.set(size: restoreRect.size)
                                AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
                            } else {
                                AppDelegate.windowHistory.restoreRects[windowId] = initialWindowRect
                            }
                        }
                    }
                }
                else {
                    AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
                }
            }
            if windowMoving {
                if Defaults.snapModifiers.value > 0 {
                    if event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue != Defaults.snapModifiers.value {
                        if currentSnapArea != nil {
                            grid?.close()
                            currentSnapArea = nil
                        }
                        return
                    }
                }
                
                if let snapArea = snapAreaContainingCursor(priorSnapArea: currentSnapArea) {
                    if snapArea == currentSnapArea {
                        return
                    }
                    let currentWindow = Window(id: windowId, rect: currentRect)
                    
                    if let newBoxRect = getBoxRect(hotSpot: snapArea, currentWindow: currentWindow) {
                        if grid == nil {
                            box = GridWindow()
                        }
                        box?.setFrame(newBoxRect, display: true)
                        grid?.makeKeyAndOrderFront(nil)
                    }
                    
                    currentSnapArea = snapArea
                } else {
                    if currentSnapArea != nil {
                        grid?.close()
                        currentSnapArea = nil
                    }
                }
            }
        default:
            return
        }
    }
    
    func getBoxRect(hotSpot: SnapArea, currentWindow: Window) -> CGRect? {
        if let calculation = WindowCalculationFactory.calculationsByAction[hotSpot.action] {
            
            let rectCalcParams = RectCalculationParameters(window: currentWindow, visibleFrameOfScreen: hotSpot.screen.adjustedVisibleFrame, action: hotSpot.action, lastAction: nil)
            let rectResult = calculation.calculateRect(rectCalcParams)
            
            let gapsApplicable = hotSpot.action.gapsApplicable
            
            if Defaults.gapSize.value > 0, gapsApplicable != .none {
                let gapSharedEdges = rectResult.subAction?.gapSharedEdge ?? hotSpot.action.gapSharedEdge

                return GapCalculation.applyGaps(rectResult.rect, dimension: gapsApplicable, sharedEdges: gapSharedEdges, gapSize: Defaults.gapSize.value)
            }
            
            return rectResult.rect
        }
        return nil
    }
    
    func snapAreaContainingCursor(priorSnapArea: SnapArea?) -> SnapArea? {
        let loc = NSEvent.mouseLocation
        
        for screen in NSScreen.screens {
            
            if screen.frame.isLandscape {
                if let snapArea = landscapeSnapArea(loc: loc, screen: screen, priorSnapArea: priorSnapArea) {
                    return snapArea
                }
            } else {
                if let snapArea = portraitSnapArea(loc: loc, screen: screen, priorSnapArea: priorSnapArea) {
                    return snapArea
                }
            }
        }
        
        return nil
    }
    
    private func landscapeSnapArea(loc: NSPoint, screen: NSScreen, priorSnapArea: SnapArea?) -> SnapArea? {
        
        let frame = screen.frame
        if loc.x >= frame.minX {
            if loc.x < frame.minX + marginLeft + 20 {
                if loc.y >= frame.maxY - marginTop - 20 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topLeft, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 20 {
                    if let area = snapArea(for: .bottomLeft, on: screen) {
                        return area
                    }
                }
            }
            
            if loc.x < frame.minX + marginLeft {
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 145 {
                    if let area = snapArea(for: .bottomLeftShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.maxY - marginTop - 145 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topLeftShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.maxY {
                    if let area = snapArea(for: .left, on: screen) {
                        return area
                    }
                }
            }
        }
        
        if loc.x <= frame.maxX {
            if loc.x > frame.maxX - marginRight - 20 {
                if loc.y >= frame.maxY - marginTop - 20 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topRight, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 20 {
                    if let area = snapArea(for: .bottomRight, on: screen) {
                        return area
                    }
                }
            }
            
            if loc.x > frame.maxX - marginRight {
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 145 {
                    if let area = snapArea(for: .bottomRightShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.maxY - marginTop - 145 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topRightShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.maxY {
                    if let area = snapArea(for: .right, on: screen) {
                        return area
                    }
                }
            }
        }
        
        if loc.y <= frame.maxY && loc.y > frame.maxY - marginTop {
            if loc.x >= frame.minX && loc.x <= frame.maxX {
                if let area = snapArea(for: .top, on: screen) {
                    return area
                }
            }
        }
        
        if loc.y >= frame.minY && loc.y < frame.minY + marginBottom && !ignoredSnapAreas.contains(.bottom) {
            let thirdWidth = floor(frame.width / 3)
            if loc.x >= frame.minX && loc.x <= frame.minX + thirdWidth {
                return SnapArea(screen: screen, action: .firstThird)
            }
            if loc.x >= frame.minX + thirdWidth && loc.x <= frame.maxX - thirdWidth{
                if let priorAction = priorSnapArea?.action {
                    let action: WindowAction
                    switch priorAction {
                    case .firstThird, .firstTwoThirds:
                        action = .firstTwoThirds
                    case .lastThird, .lastTwoThirds:
                        action = .lastTwoThirds
                    default: action = .centerThird
                    }
                    return SnapArea(screen: screen, action: action)
                }
                return SnapArea(screen: screen, action: .centerThird)
            }
            if loc.x >= frame.minX + thirdWidth && loc.x <= frame.maxX {
                return SnapArea(screen: screen, action: .lastThird)
            }
        }
        return nil
    }
    
    private func portraitSnapArea(loc: NSPoint, screen: NSScreen, priorSnapArea: SnapArea?) -> SnapArea? {
        
        let frame = screen.frame
        if loc.x >= frame.minX {
            if loc.x < frame.minX + marginLeft + 20 {
                if loc.y >= frame.maxY - marginTop - 20 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topLeft, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 20 {
                    if let area = snapArea(for: .bottomLeft, on: screen) {
                        return area
                    }
                }
            }
            
            if loc.x < frame.minX + marginLeft {
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 145 {
                    if let area = snapArea(for: .bottomLeftShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.maxY - marginTop - 145 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topLeftShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.maxY && !ignoredSnapAreas.contains(.left) {
                    // left
                    if let area = portraitThirdsSnapArea(loc: loc, screen: screen, priorSnapArea: priorSnapArea) {
                        return area
                    }
                }
            }
        }
        
        if loc.x <= frame.maxX {
            if loc.x > frame.maxX - marginRight - 20 {
                if loc.y >= frame.maxY - marginTop - 20 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topRight, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 20 {
                    if let area = snapArea(for: .bottomRight, on: screen) {
                        return area
                    }
                }
            }
            
            if loc.x > frame.maxX - marginRight {
                if loc.y >= frame.minY && loc.y <= frame.minY + marginBottom + 145 {
                    if let area = snapArea(for: .bottomRightShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.maxY - marginTop - 145 && loc.y <= frame.maxY {
                    if let area = snapArea(for: .topRightShort, on: screen) {
                        return area
                    }
                }
                if loc.y >= frame.minY && loc.y <= frame.maxY && !ignoredSnapAreas.contains(.right) {
                    // right
                    if let area = portraitThirdsSnapArea(loc: loc, screen: screen, priorSnapArea: priorSnapArea) {
                        return area
                    }
                }
            }
        }
        
        if loc.y <= frame.maxY && loc.y > frame.maxY - marginTop {
            if loc.x >= frame.minX && loc.x <= frame.maxX {
                if let area = snapArea(for: .top, on: screen) {
                    return area
                }
            }
        }
        
        if loc.y >= frame.minY && loc.y < frame.minY + marginBottom && !ignoredSnapAreas.contains(.bottom) {
            
            return loc.x < frame.maxX - (frame.width / 2)
                ? SnapArea(screen: screen, action: .leftHalf)
                : SnapArea(screen: screen, action: .rightHalf)
            
        }
        return nil
    }
    
    private func portraitThirdsSnapArea(loc: NSPoint, screen: NSScreen, priorSnapArea: SnapArea?) -> SnapArea? {
        let frame = screen.frame
        let thirdHeight = floor(frame.height / 3)
        if loc.y >= frame.minY && loc.y <= frame.minY + thirdHeight {
            return SnapArea(screen: screen, action: .lastThird)
        }
        if loc.y >= frame.minY + thirdHeight && loc.y <= frame.maxY - thirdHeight {
            if let priorAction = priorSnapArea?.action {
                let action: WindowAction
                switch priorAction {
                case .firstThird, .firstTwoThirds:
                    action = .firstTwoThirds
                case .lastThird, .lastTwoThirds:
                    action = .lastTwoThirds
                default: action = .centerThird
                }
                return SnapArea(screen: screen, action: action)
            }
            return SnapArea(screen: screen, action: .centerThird)
        }
        if loc.y >= frame.minY + thirdHeight && loc.y <= frame.maxY {
            return SnapArea(screen: screen, action: .firstThird)
        }
        return nil
    }
    
    private func snapArea(for snapOption: SnapAreaOption, on screen: NSScreen) -> SnapArea? {
        if ignoredSnapAreas.contains(snapOption) { return nil }
        if let action = snapOptionToAction[snapOption] {
            return SnapArea(screen: screen, action: action)
        }
        return nil
    }
    
}

struct SnapArea: Equatable {
    let screen: NSScreen
    let action: WindowAction
}

struct SnapAreaOption: OptionSet, Hashable {
    let rawValue: Int
    
    static let top = SnapAreaOption(rawValue: 1 << 0)
    static let bottom = SnapAreaOption(rawValue: 1 << 1)
    static let left = SnapAreaOption(rawValue: 1 << 2)
    static let right = SnapAreaOption(rawValue: 1 << 3)
    static let topLeft = SnapAreaOption(rawValue: 1 << 4)
    static let topRight = SnapAreaOption(rawValue: 1 << 5)
    static let bottomLeft = SnapAreaOption(rawValue: 1 << 6)
    static let bottomRight = SnapAreaOption(rawValue: 1 << 7)
    static let topLeftShort = SnapAreaOption(rawValue: 1 << 8)
    static let topRightShort = SnapAreaOption(rawValue: 1 << 9)
    static let bottomLeftShort = SnapAreaOption(rawValue: 1 << 10)
    static let bottomRightShort = SnapAreaOption(rawValue: 1 << 11)
    
    static let all: SnapAreaOption = [.top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft, .bottomRight, .topLeftShort, .topRightShort, .bottomLeftShort, .bottomRightShort]
    static let none: SnapAreaOption = []
}
