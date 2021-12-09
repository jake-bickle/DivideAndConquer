//
//  NotificationExtension.swift
//  Rectangle
//
//  Created by Ryan Hanson on 12/23/20.
//  Copyright © 2020 Ryan Hanson. All rights reserved.
//

import Cocoa

extension Notification.Name {
  
    static let configImported = Notification.Name("configImported")
    static let windowSnapping = Notification.Name("windowSnapping")
    static let allowAnyShortcut = Notification.Name("allowAnyShortcutToggle")
    static let changeDefaults = Notification.Name("changeDefaults")
    static let todoMenuToggled = Notification.Name("todoMenuToggled")

    func post(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        userInfo: [AnyHashable : Any]? = nil) {
        
        center.post(name: self, object: object, userInfo: userInfo)
    }
    
    @discardableResult
    func onPost(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (Notification) -> Void)
    -> NSObjectProtocol {
        
        return center.addObserver(
            forName: self,
            object: object,
            queue: queue,
            using: using)
    }

}

extension Notification.Name {
    static let leftMouseDown = Notification.Name("leftMouseDown")
    static let leftMouseUp = Notification.Name("leftMouseUp")
    static let mouseDrag = Notification.Name("mouseDrag")
    static let rightMouseDown = Notification.Name("rightMouseDown")
    static let rightMouseUp = Notification.Name("rightMouseUp")
}
