//
//  ApplicationToggle.swift
//  Rectangle
//
//  Created by Ryan Hanson on 6/18/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class ApplicationToggle: NSObject {
    
    private var disabledApps = Set<String>()
    public private(set) var frontAppId: String? = "com.knollsoft.Rectangle"
    public private(set) var frontAppName: String? = "Rectangle"
    public private(set) var shortcutsDisabled: Bool = false
    private let fullIgnoreIds: [String] = Defaults.fullIgnoreBundleIds.typedValue ?? ["com.install4j", "com.mathworks.matlab"]

    override init() {
        super.init()
        registerFrontAppChangeNote()
        if let disabledApps = getDisabledApps() {
            self.disabledApps = disabledApps
        }
    }
    
    public func reloadFromDefaults() {
        if let disabledApps = getDisabledApps() {
            self.disabledApps = disabledApps
        } else {
            disabledApps.removeAll()
        }
    }
    
    private func saveDisabledApps() {
        let encoder = JSONEncoder()
        if let jsonDisabledApps = try? encoder.encode(disabledApps) {
            if let jsonString = String(data: jsonDisabledApps, encoding: .utf8) {
                Defaults.disabledApps.value = jsonString
            }
        }
    }
    
    private func getDisabledApps() ->  Set<String>? {
        guard let jsonDisabledAppsString = Defaults.disabledApps.value else { return nil }
        
        let decoder = JSONDecoder()
        guard let jsonDisabledApps = jsonDisabledAppsString.data(using: .utf8) else { return nil }
        guard let disabledApps = try? decoder.decode(Set<String>.self, from: jsonDisabledApps) else { return nil }
        
        return disabledApps
    }

    public func disableFrontApp() {
        if let frontAppId = self.frontAppId {
            disabledApps.insert(frontAppId)
            saveDisabledApps()
        }
    }
    
    public func enableFrontApp() {
        if let frontAppId = self.frontAppId {
            disabledApps.remove(frontAppId)
            saveDisabledApps()
        }
    }
    
    public func isDisabled(bundleId: String) -> Bool {
        return disabledApps.contains(bundleId)
    }
    
    private func registerFrontAppChangeNote() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.receiveFrontAppChangeNote(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    @objc func receiveFrontAppChangeNote(_ notification: Notification) {
        if let application = notification.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication {
            self.frontAppId = application.bundleIdentifier
            self.frontAppName = application.localizedName
            if let frontAppId = application.bundleIdentifier {
                if isDisabled(bundleId: frontAppId) {
                    DispatchQueue.main.async {
                        for id in self.fullIgnoreIds {
                            if frontAppId.starts(with: id) {
                                Notification.Name.windowSnapping.post(object: false)
                            }
                        }
                    }
                } else {
                    Notification.Name.windowSnapping.post(object: true)
                }
            }
        }
    }
    
}

// todo mode
extension ApplicationToggle {
    public func setTodoApp() {
        Defaults.todoApplication.value = self.frontAppId
    }

    public func todoAppIsActive() -> Bool {
        return Defaults.todoApplication.value == self.frontAppId
    }
}
