//
//  PrefsViewController.swift
//  Rectangle
//
//  Created by Ryan Hanson on 6/18/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa
import MASShortcut
import ServiceManagement

class PreferencesViewController: NSViewController {
    @IBOutlet weak var xDimensionTextField: NSTextField!
    @IBOutlet weak var yDimensionTextField: NSTextField!
    
    // Some commented out code is unused shortcut code. Will make use of shortcuts later, so commenting it out for now.
    override func awakeFromNib() {
        xDimensionTextField.delegate = self
        yDimensionTextField.delegate = self
        
        /*
        if Defaults.allowAnyShortcut.enabled {
            let passThroughValidator = PassthroughShortcutValidator()
            actionsToViews.values.forEach { $0.shortcutValidator = passThroughValidator }
        }
        
        subscribeToAllowAnyShortcutToggle()
         */
    }
    
    override func viewWillAppear() {
        xDimensionTextField.stringValue = String(AppSettings.shared.gridXDimension)
        yDimensionTextField.stringValue = String(AppSettings.shared.gridYDimension)
    }
    
    /*
    private func subscribeToAllowAnyShortcutToggle() {
        Notification.Name.allowAnyShortcut.onPost { notification in
            guard let enabled = notification.object as? Bool else { return }
            let validator = enabled ? PassthroughShortcutValidator() : MASShortcutValidator()
            self.actionsToViews.values.forEach { $0.shortcutValidator = validator }
        }
    }
     */
    
}

// It's not possible to get an IBAction when a text field changes, so making a text field delegate is necessary.
extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        // To make matters worse, Notification does not contain information on *which* text field has changed.
        let gridXDimensionsMax = AppSettings.shared.gridXDimensionMax
        let gridYDimensionsMax = AppSettings.shared.gridYDimensionMax
        if var xDimension = Int(xDimensionTextField.stringValue) {
            if (xDimension > 0) {
                if (xDimension > gridXDimensionsMax){
                    xDimensionTextField.stringValue = String(gridXDimensionsMax)
                    xDimension = gridXDimensionsMax
                }
                AppSettings.shared.gridXDimension = xDimension
            }
        }
        if var yDimension = Int(yDimensionTextField.stringValue) {
            if (yDimension > 0) {
                if (yDimension > gridYDimensionsMax){
                    yDimensionTextField.stringValue = String(gridYDimensionsMax)
                    yDimension = gridYDimensionsMax
                }
                AppSettings.shared.gridYDimension = yDimension
            }
        }
    }
}

class PassthroughShortcutValidator: MASShortcutValidator {
    
    override func isShortcutValid(_ shortcut: MASShortcut!) -> Bool {
        return true
    }
    
    override func isShortcutAlreadyTaken(bySystem shortcut: MASShortcut!, explanation: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        return false
    }
    
    override func isShortcut(_ shortcut: MASShortcut!, alreadyTakenIn menu: NSMenu!, explanation: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        return false
    }
    
}
