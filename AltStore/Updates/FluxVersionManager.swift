//
//  FluxVersionManager.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import Foundation
import AltStoreCore

class FluxVersionManager {
    
    static let shared = FluxVersionManager()
    
    private init() {}
    
    // MARK: - Version Parsing
    
    struct VersionInfo {
        let version: String
        let isNightly: Bool
        let baseVersion: String
        let buildNumber: String?
        
        init(version: String) {
            self.version = version
            
            if version.contains("-nightly") {
                self.isNightly = true
                self.baseVersion = version.replacingOccurrences(of: "-nightly", with: "")
            } else {
                self.isNightly = false
                self.baseVersion = version
            }
            
            // Extract build number if present
            if let buildRange = version.range(of: "+build.") {
                self.buildNumber = String(version[buildRange.upperBound...])
            } else {
                self.buildNumber = nil
            }
        }
    }
    
    // MARK: - Version Comparison
    
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let info1 = VersionInfo(version: version1)
        let info2 = VersionInfo(version: version2)
        
        // Handle nightly comparisons
        if info1.isNightly && info2.isNightly {
            // Both are nightly, compare base versions
            return compareSemanticVersions(info1.baseVersion, info2.baseVersion)
        } else if info1.isNightly {
            // Nightly is considered newer than stable of same base version
            if compareSemanticVersions(info1.baseVersion, info2.baseVersion) == .orderedSame {
                return .orderedDescending
            } else {
                return compareSemanticVersions(info1.baseVersion, info2.baseVersion)
            }
        } else if info2.isNightly {
            // Stable is considered older than nightly of same base version
            if compareSemanticVersions(info1.baseVersion, info2.baseVersion) == .orderedSame {
                return .orderedAscending
            } else {
                return compareSemanticVersions(info1.baseVersion, info2.baseVersion)
            }
        } else {
            // Both are stable, compare normally
            return compareSemanticVersions(info1.baseVersion, info2.baseVersion)
        }
    }
    
    private func compareSemanticVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxCount {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0
            
            if v1Value < v2Value {
                return .orderedAscending
            } else if v1Value > v2Value {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
    
    // MARK: - Update Detection
    
    func isUpdateAvailable(currentVersion: String, availableVersion: String) -> Bool {
        return compareVersions(currentVersion, availableVersion) == .orderedAscending
    }
    
    func getUpdateType(currentVersion: String, availableVersion: String) -> UpdateType {
        let currentInfo = VersionInfo(version: currentVersion)
        let availableInfo = VersionInfo(version: availableVersion)
        
        if availableInfo.isNightly {
            return .nightly
        } else if currentInfo.isNightly && !availableInfo.isNightly {
            return .stableFromNightly
        } else {
            return .standard
        }
    }
    
    // MARK: - Ignored Updates
    
    private let ignoredUpdatesKey = "FluxStore.ignoredUpdates"
    
    func ignoreUpdate(for appID: String, version: String) {
        var ignoredUpdates = getIgnoredUpdates()
        ignoredUpdates[appID] = version
        UserDefaults.standard.set(ignoredUpdates, forKey: ignoredUpdatesKey)
    }
    
    func unignoreUpdate(for appID: String) {
        var ignoredUpdates = getIgnoredUpdates()
        ignoredUpdates.removeValue(forKey: appID)
        UserDefaults.standard.set(ignoredUpdates, forKey: ignoredUpdatesKey)
    }
    
    func isUpdateIgnored(for appID: String, version: String) -> Bool {
        let ignoredUpdates = getIgnoredUpdates()
        guard let ignoredVersion = ignoredUpdates[appID] else { return false }
        
        // If there's a newer version than the ignored one, don't ignore anymore
        return compareVersions(version, ignoredVersion) != .orderedDescending
    }
    
    func getIgnoredUpdates() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: ignoredUpdatesKey) as? [String: String] ?? [:]
    }
    
    func clearIgnoredUpdates() {
        UserDefaults.standard.removeObject(forKey: ignoredUpdatesKey)
    }
}

// MARK: - Update Types

enum UpdateType {
    case standard
    case nightly
    case stableFromNightly
    
    var localizedDescription: String {
        switch self {
        case .standard:
            return NSLocalizedString("Standard Update", comment: "")
        case .nightly:
            return NSLocalizedString("Nightly Build", comment: "")
        case .stableFromNightly:
            return NSLocalizedString("Stable Release (from Nightly)", comment: "")
        }
    }
    
    var badgeColor: UIColor {
        switch self {
        case .standard:
            return .systemBlue
        case .nightly:
            return .systemOrange
        case .stableFromNightly:
            return .systemGreen
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "arrow.up.circle.fill"
        case .nightly:
            return "moon.circle.fill"
        case .stableFromNightly:
            return "sun.circle.fill"
        }
    }
}
