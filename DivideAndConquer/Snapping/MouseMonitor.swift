//
//  EventMonitor.swift
//  Rectangle
//
//  Created by Ryan Hanson on 9/4/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

public class MouseMonitor {
    private var monitor: Any?

    var running: Bool { monitor != nil }
    
    deinit {
        stop()
    }
    
    public func handle(event: NSEvent?) {
        guard let event = event else { return }
        var name : Notification.Name
        switch (event.type){
        case .leftMouseDown:
            name = Notification.Name.leftMouseDown
        case .leftMouseDragged:
            name = Notification.Name.mouseDrag
        case .rightMouseDown:
            name = Notification.Name.rightMouseDown
        case .rightMouseUp:
            name = Notification.Name.rightMouseUp
        case .leftMouseUp:
            name = Notification.Name.leftMouseUp
        default:
            Logger.log("Unexpected event handled in MouseEventNotifier: \(event.type)")
            print("Unexpected event handled in MouseEventNotifier: \(event.type)")
            return
        }
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    public func start() {
        if monitor == nil {
            monitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp],
                handler: self.handle)
        }
    }
    
    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
