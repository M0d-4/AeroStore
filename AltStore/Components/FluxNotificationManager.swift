//
//  FluxNotificationManager.swift
//  FluxStore
//
//  Created by FluxStore Team
//  Copyright © 2026 FluxStore. All rights reserved.
//

import UIKit
import UserNotifications
import AltStoreCore

class FluxNotificationManager: NSObject {
    static let shared = FluxNotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var pendingNotifications: [FluxNotification] = []
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleAppUpdateNotification(for app: InstalledApp) {
        let notification = FluxNotification(
            id: "app_update_\(app.bundleIdentifier)",
            title: NSLocalizedString("App Update Available", comment: ""),
            body: String(format: NSLocalizedString("%@ has an update available", comment: ""), app.name),
            category: .appUpdate,
            userInfo: ["bundleIdentifier": app.bundleIdentifier]
        )
        
        scheduleNotification(notification)
    }
    
    func scheduleCertificateExpirationWarning(for daysRemaining: Int) {
        let notification = FluxNotification(
            id: "certificate_warning",
            title: NSLocalizedString("Certificate Expiring Soon", comment: ""),
            body: String(format: NSLocalizedString("Your apps certificate expires in %d days", comment: ""), daysRemaining),
            category: .certificateWarning,
            userInfo: ["daysRemaining": daysRemaining]
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
        scheduleNotification(notification, trigger: trigger)
    }
    
    func scheduleJITStatusChange(for appName: String, enabled: Bool) {
        let status = enabled ? NSLocalizedString("enabled", comment: "") : NSLocalizedString("disabled", comment: "")
        let notification = FluxNotification(
            id: "jit_status_\(appName)",
            title: NSLocalizedString("JIT Status Changed", comment: ""),
            body: String(format: NSLocalizedString("JIT for %@ has been %@", comment: ""), appName, status),
            category: .jitStatus,
            userInfo: ["appName": appName, "enabled": enabled]
        )
        
        scheduleNotification(notification)
    }
    
    func showInAppNotification(_ notification: FluxNotification) {
        DispatchQueue.main.async {
            let toastView = FluxToastView(notification: notification)
            toastView.show()
        }
    }
    
    private func scheduleNotification(_ notification: FluxNotification, trigger: UNNotificationTrigger? = nil) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.categoryIdentifier = notification.category.rawValue
        content.userInfo = notification.userInfo
        
        if let trigger = trigger {
            let request = UNNotificationRequest(
                identifier: notification.id,
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        } else {
            // Show immediately
            let request = UNNotificationRequest(
                identifier: notification.id,
                content: content,
                trigger: nil
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule immediate notification: \(error)")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FluxNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.notification.request.content.categoryIdentifier {
        case FluxNotificationCategory.appUpdate.rawValue:
            if let bundleIdentifier = userInfo["bundleIdentifier"] as? String {
                navigateToApp(bundleIdentifier: bundleIdentifier)
            }
            
        case FluxNotificationCategory.certificateWarning.rawValue:
            navigateToSettings()
            
        case FluxNotificationCategory.jitStatus.rawValue:
            if let appName = userInfo["appName"] as? String {
                navigateToApp(appName: appName)
            }
            
        default:
            break
        }
    }
    
    private func navigateToApp(bundleIdentifier: String) {
        DispatchQueue.main.async {
            if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? TabBarController {
                tabBarController.selectedIndex = TabBarController.Tab.myApps.rawValue
                // Navigate to specific app
                NotificationCenter.default.post(name: NSNotification.Name("ShowAppDetails"), object: nil, userInfo: ["bundleIdentifier": bundleIdentifier])
            }
        }
    }
    
    private func navigateToApp(appName: String) {
        DispatchQueue.main.async {
            if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? TabBarController {
                tabBarController.selectedIndex = TabBarController.Tab.myApps.rawValue
                NotificationCenter.default.post(name: NSNotification.Name("ShowAppDetails"), object: nil, userInfo: ["appName": appName])
            }
        }
    }
    
    private func navigateToSettings() {
        DispatchQueue.main.async {
            if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? TabBarController {
                tabBarController.selectedIndex = TabBarController.Tab.settings.rawValue
            }
        }
    }
}

// MARK: - Notification Models
struct FluxNotification {
    let id: String
    let title: String
    let body: String
    let category: FluxNotificationCategory
    let userInfo: [String: Any]
}

enum FluxNotificationCategory: String {
    case appUpdate = "APP_UPDATE"
    case certificateWarning = "CERTIFICATE_WARNING"
    case jitStatus = "JIT_STATUS"
    case system = "SYSTEM"
}
