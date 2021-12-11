//
//  Config.swift
//  Rectangle
//
//  Created by Ryan Hanson on 12/15/20.
//  Copyright © 2020 Ryan Hanson. All rights reserved.
//

import Foundation
import MASShortcut

extension Defaults {
    static func encoded() -> String? {
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { return nil }
        
        var codableDefaults = [String: CodableDefault]()
        for exportableDefault in Defaults.array {
            codableDefaults[exportableDefault.key] = exportableDefault.toCodable()
        }
                
        let config = Config(bundleId: "com.knollsoft.Rectangle",
                            version: version,
                            defaults: codableDefaults)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encodedJson = try? encoder.encode(config) {
            if let jsonString = String(data: encodedJson, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
        }
        return nil
    }
    
    static func convert(jsonString: String) -> Config? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Config.self, from: jsonData)
    }
    
    static func load(fileUrl: URL) {
        guard let jsonString = try? String(contentsOf: fileUrl, encoding: .utf8),
              let config = convert(jsonString: jsonString) else { return }

        for availableDefault in Defaults.array {
            if let codedDefault = config.defaults[availableDefault.key] {
                availableDefault.load(from: codedDefault)
            }
        }
        
        Notification.Name.configImported.post()
    }
}

struct Config: Codable {
    let bundleId: String
    let version: String
    let defaults: [String: CodableDefault]
}
