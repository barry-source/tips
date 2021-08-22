//
//  AppMode.swift
//  Leetcode
//
//  Created by TSC on 2020/12/3.
//

import UIKit

class AppMode: NSObject {
    
    static let shared = AppMode()
    
    var environmentType: EnvironmentType {
        get {
            #if DEBUG
                return .dev
            #else
                return .prod
            #endif
        }
    }
    
}

extension AppMode {
    enum EnvironmentType: Int, Codable {
        case prod
        case beta
        case test
        case dev
        
        var displayString: String {
            switch(self) {
            case .prod:
                return "正式环境"
            case .beta:
                return "Beta环境"
            case .test:
                return "Test环境"
            case .dev:
                return "Dev环境"
            }
        }
        
    }
}
