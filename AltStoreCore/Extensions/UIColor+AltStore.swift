//
//  UIColor+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/9/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

public enum FluxAccentColorPreference: Int, CaseIterable
{
    case aeroBlue = 0
    case cyberPurple = 1
    case neonGreen = 2
    case sunsetOrange = 3
    case crimsonRed = 4

    public static let storageKey = "aerostore.accentColorPreference"

    public static var current: FluxAccentColorPreference
    {
        let raw = UserDefaults.standard.integer(forKey: storageKey)
        return Self(rawValue: raw) ?? .aeroBlue
    }

    public var color: UIColor
    {
        switch self
        {
        case .aeroBlue:
            return UIColor(named: "Primary", in: Bundle(for: DatabaseManager.self), compatibleWith: nil) ?? UIColor(red: 0.18, green: 0.50, blue: 0.93, alpha: 1.0)
        case .cyberPurple:
            return UIColor(red: 0.62, green: 0.33, blue: 1.0, alpha: 1.0)
        case .neonGreen:
            return UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        case .sunsetOrange:
            return UIColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 1.0)
        case .crimsonRed:
            return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0)
        }
    }

    public var localizedTitle: String
    {
        switch self
        {
        case .aeroBlue: return NSLocalizedString("Aero Blue", comment: "")
        case .cyberPurple: return NSLocalizedString("Cyber Purple", comment: "")
        case .neonGreen: return NSLocalizedString("Neon Green", comment: "")
        case .sunsetOrange: return NSLocalizedString("Sunset Orange", comment: "")
        case .crimsonRed: return NSLocalizedString("Crimson Red", comment: "")
        }
    }

    public func saveAndApply()
    {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
        NotificationCenter.default.post(name: .fluxAccentColorDidChange, object: nil)
    }
}

public extension Notification.Name
{
    static let fluxAccentColorDidChange = Notification.Name("aerostore.fluxAccentColorDidChange")
}

public extension UIColor
{
    private static let colorBundle = Bundle(for: DatabaseManager.self)
    
    static var altPrimary: UIColor { FluxAccentColorPreference.current.color }
    static let deltaPrimary = UIColor(named: "DeltaPrimary", in: colorBundle, compatibleWith: nil)
    static let clipPrimary = UIColor(named: "ClipPrimary", in: colorBundle, compatibleWith: nil)
    
    static let refreshRed = UIColor(named: "RefreshRed", in: colorBundle, compatibleWith: nil)!
    static let refreshOrange = UIColor(named: "RefreshOrange", in: colorBundle, compatibleWith: nil)!
    static let refreshYellow = UIColor(named: "RefreshYellow", in: colorBundle, compatibleWith: nil)!
    static let refreshGreen = UIColor(named: "RefreshGreen", in: colorBundle, compatibleWith: nil)!

    // Flux design tokens (phase 1)
    static let fluxSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1.0)
    }

    static let fluxElevatedSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.16, blue: 0.21, alpha: 1.0)
            : UIColor.white
    }

    static let fluxSeparator = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.08)
    }
}
