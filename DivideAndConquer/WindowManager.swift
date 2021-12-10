//
//  WindowManager.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/12/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class WindowManager {

    private let screenDetection = ScreenDetection()
    private let standardWindowMoverChain: [WindowMoverOLD]
    private let fixedSizeWindowMoverChain: [WindowMoverOLD]

    init() {
        standardWindowMoverChain = [
            StandardWindowMover(),
            BestEffortWindowMover()
        ]

        fixedSizeWindowMoverChain = [
            CenteringFixedSizedWindowMover(),
            BestEffortWindowMover()
        ]
    }

    private func recordAction(windowId: Int, resultingRect: CGRect, action: WindowAction, subAction: SubWindowAction?) {
        let newCount: Int
        if let lastRectangleAction = AppDelegate.windowHistory.lastRectangleActions[windowId], lastRectangleAction.action == action {
            newCount = lastRectangleAction.count + 1
        } else {
            newCount = 1
        }

        AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
            action: action,
            subAction: subAction,
            rect: resultingRect,
            count: newCount
        )
    }

    func execute(_ parameters: ExecutionParameters) {
        guard let frontmostWindowElement = parameters.windowElement ?? AccessibilityElement.frontmostWindow(),
              let windowId = parameters.windowId ?? frontmostWindowElement.getIdentifier()
        else {
            NSSound.beep()
            return
        }

        var screens: UsableScreens?
        if let screen = parameters.screen {
            screens = UsableScreens(currentScreen: screen, numScreens: 1)
        } else {
            screens = screenDetection.detectScreens(using: frontmostWindowElement)
        }
        
        guard let usableScreens = screens else {
            NSSound.beep()
            Logger.log("Unable to obtain usable screens")
            return
        }
        
        let currentWindowRect: CGRect = frontmostWindowElement.rectOfElement()
        
        if frontmostWindowElement.isSheet()
            || frontmostWindowElement.isSystemDialog()
            || currentWindowRect.isNull
            || usableScreens.frameOfCurrentScreen.isNull
            || usableScreens.visibleFrameOfCurrentScreen.isNull {
            NSSound.beep()
            Logger.log("Window is not snappable or usable screen is not valid")
            return
        }
        
        let currentNormalizedRect = AccessibilityElement.normalizeCoordinatesOf(currentWindowRect, frameOfScreen: usableScreens.frameOfCurrentScreen)
        let currentWindow = Window(id: windowId, rect: currentNormalizedRect)
        
        // TODO Calculate frame based on given cell or cells. Windowmover will do its best to fit it in.
        let windowCalculation = WindowCalculationFactory.calculationsByAction[action]
        
        let calculationParams = WindowCalculationParameters(window: currentWindow, usableScreens: usableScreens, action: action, lastAction: lastRectangleAction)
        guard var calcResult = windowCalculation?.calculate(calculationParams) else {
            NSSound.beep()
            Logger.log("Nil calculation result")
            return
        }
        
        let gapsApplicable = calcResult.resultingAction.gapsApplicable
        
        if Defaults.gapSize.value > 0, gapsApplicable != .none {
            let gapSharedEdges = calcResult.resultingSubAction?.gapSharedEdge ?? calcResult.resultingAction.gapSharedEdge
            
            calcResult.rect = GapCalculation.applyGaps(calcResult.rect, dimension: gapsApplicable, sharedEdges: gapSharedEdges, gapSize: Defaults.gapSize.value)
        }

        if currentNormalizedRect.equalTo(calcResult.rect) {
            Logger.log("Current frame is equal to new frame")
            
            recordAction(windowId: windowId, resultingRect: currentWindowRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)
            
            return
        }
        
        let newRect = AccessibilityElement.normalizeCoordinatesOf(calcResult.rect, frameOfScreen: usableScreens.frameOfCurrentScreen)

        let visibleFrameOfDestinationScreen = calcResult.screen.adjustedVisibleFrame

        let useFixedSizeMover = !frontmostWindowElement.isResizable()
        let windowMoverChain = useFixedSizeMover
            ? fixedSizeWindowMoverChain
            : standardWindowMoverChain

        for windowMover in windowMoverChain {
            windowMover.moveWindowRect(newRect, frameOfScreen: usableScreens.frameOfCurrentScreen, visibleFrameOfScreen: visibleFrameOfDestinationScreen, frontmostWindowElement: frontmostWindowElement, action: action)
        }
        
        let resultingRect = frontmostWindowElement.rectOfElement()
        
        if usableScreens.currentScreen != calcResult.screen {
            frontmostWindowElement.bringToFront(force: true)
            
            if Defaults.moveCursorAcrossDisplays.userEnabled {
                let windowCenter = NSMakePoint(NSMidX(resultingRect), NSMidY(resultingRect))
                CGWarpMouseCursorPosition(windowCenter)
            }
        }
        
        recordAction(windowId: windowId, resultingRect: resultingRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)
        
        if Logger.logging {
            var srcDestScreens: String = ""
            if #available(OSX 10.15, *) {
                srcDestScreens += ", srcScreen: \(usableScreens.currentScreen.localizedName)"
                srcDestScreens += ", destScreen: \(calcResult.screen.localizedName)"
                if let resultScreens = screenDetection.detectScreens(using: frontmostWindowElement) {
                    srcDestScreens += ", resultScreen: \(resultScreens.currentScreen.localizedName)"
                }
            }
            
            Logger.log("Completed move | display: \(visibleFrameOfDestinationScreen.debugDescription), calculatedRect: \(newRect.debugDescription), resultRect: \(resultingRect.debugDescription)\(srcDestScreens)")
        }
    }
}

struct RectangleAction {
    let action: WindowAction
    let subAction: SubWindowAction?
    let rect: CGRect
    let count: Int
}

struct ExecutionParameters {
    let screen: NSScreen?
    let windowElement: AccessibilityElement?
    let windowId: Int?

    init(_ action: WindowAction, updateRestoreRect: Bool = true, screen: NSScreen? = nil, windowElement: AccessibilityElement? = nil, windowId: Int? = nil, source: ExecutionSource = .keyboardShortcut) {
        self.screen = screen
        self.windowElement = windowElement
        self.windowId = windowId
    }
}

enum ExecutionSource {
    case keyboardShortcut, dragToSnap, menuItem
}
