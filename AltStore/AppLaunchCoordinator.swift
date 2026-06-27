//
//  AppLaunchCoordinator.swift
//  AltStore
//

import UIKit
import AltStoreCore
import OSLog

/// Single place that installs the main tab interface on the key window.
@MainActor
enum AppLaunchCoordinator {
    private static var didInstallMainInterface = false

    static var isMainInterfaceInstalled: Bool { didInstallMainInterface }

    @MainActor
    static func installMainInterface(animated: Bool = true) {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "launch-ui")
        guard !didInstallMainInterface else {
            os_log(.default, log: log, "installMainInterface: already installed, skipping")
            return
        }
        guard let window = resolveKeyWindow() else {
            os_log(.error, log: log, "installMainInterface: no key window yet")
            return
        }
        os_log(.default, log: log, "installMainInterface: animated=%@, window=%@", String(describing: animated), String(describing: window))
        installMainInterface(in: window, animated: animated)
    }

    @MainActor
    static func installMainInterface(in window: UIWindow, animated: Bool) {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "launch-ui")
        guard !didInstallMainInterface else { return }

        do {
            os_log(.default, log: log, "Creating TabBarController...")
            let tabBar = TabBarController.makeMainInterface()
            os_log(.default, log: log, "TabBarController created")

            tabBar.loadViewIfNeeded()
            tabBar.view.setNeedsLayout()
            tabBar.view.layoutIfNeeded()
            tabBar.selectedViewController?.loadViewIfNeeded()

            window.backgroundColor = .systemBackground
            window.tintColor = .altPrimary

            let applyRoot = {
                window.rootViewController = tabBar
                window.makeKeyAndVisible()
                FluxAppearancePreference.applyToAllWindows()
            }

            if animated {
                UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: applyRoot)
            } else {
                applyRoot()
            }

            didInstallMainInterface = true
            os_log(.default, log: log, "Main interface installed (%d tabs)", tabBar.viewControllers?.count ?? 0)
        } catch {
            os_log(.error, log: log, "Failed to install main interface: %{public}@", String(describing: error))
            let fallbackVC = UIViewController()
            fallbackVC.view.backgroundColor = .systemBackground
            fallbackVC.title = "AeroStore"
            window.rootViewController = fallbackVC
            window.makeKeyAndVisible()
            didInstallMainInterface = true
            os_log(.default, log: log, "Using fallback interface")
        }
    }

    @MainActor
    static func resolveKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first
    }

    /// Safety net if storyboard custom classes failed to load and launch never finished.
    @MainActor
    static func installMainInterfaceIfNeeded(reason: String) {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "launch-ui")
        guard !didInstallMainInterface else { return }
        guard let window = resolveKeyWindow() else { return }
        let root = window.rootViewController
        if root is TabBarController { return }
        os_log(.default, log: log, "installMainInterfaceIfNeeded (%{public}@): root=%@", reason, String(describing: type(of: root)))
        installMainInterface(in: window, animated: false)
    }
}
