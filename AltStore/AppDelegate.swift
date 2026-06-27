//
//  AppDelegate.swift
//  AltStore
//
//  Created by Riley Testut on 5/9/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import UserNotifications
import AVFoundation
import Intents
import AltStoreCore
import AltSign
import Roxas
import OSLog

import Nuke

extension UIApplication: LegacyBackgroundFetching {}

extension AppDelegate
{
    static let openPatreonSettingsDeepLinkNotification = Notification.Name(Bundle.Info.appbundleIdentifier + ".OpenPatreonSettingsDeepLinkNotification")
    static let importAppDeepLinkNotification = Notification.Name(Bundle.Info.appbundleIdentifier + ".ImportAppDeepLinkNotification")
    static let addSourceDeepLinkNotification = Notification.Name(Bundle.Info.appbundleIdentifier + ".AddSourceDeepLinkNotification")
    
    static let appBackupDidFinish = Notification.Name(Bundle.Info.appbundleIdentifier + ".AppBackupDidFinish")
    static let exportCertificateNotification = Notification.Name(Bundle.Info.appbundleIdentifier + ".ExportCertificateNotification")
    
    static let importAppDeepLinkURLKey = "fileURL"
    static let appBackupResultKey = "result"
    static let addSourceDeepLinkURLKey = "sourceURL"
    static let exportCertificateCallbackTemplateKey = "callback"
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let intentHandler = IntentHandler()
    private let viewAppIntentHandler = ViewAppIntentHandler()
    
    public let consoleLog = ConsoleLog()

    // Holds an imported .ipa URL when the app isn't active yet (cold launch),
    // so the import notification can be posted once the app becomes active.
    private var pendingImportIPAURL: URL?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "startup")
        os_log(.info, log: log, "application:didFinishLaunchingWithOptions - ENTRY")

        // ── Crash detection ────────────────────────────────────────────────────
        // Detect previous crash via sentinel file.  We ALWAYS show diagnostics
        // when a crash report exists — never auto-clear.  The user dismisses it.
        let loopSentinelURL = CrashReportStore.launchSentinelURL.deletingLastPathComponent().appendingPathComponent(".aerostore_crash_loop")
        let fm = FileManager.default
        let previousReport = CrashReportStore.load()
        if previousReport != nil {
            let count = (try? Int(String(contentsOf: loopSentinelURL, encoding: .utf8))) ?? 0
            let next = count + 1
            if next >= 20 {
                try? "1".write(to: loopSentinelURL, atomically: true, encoding: .utf8)
            } else {
                try? "\(next)".write(to: loopSentinelURL, atomically: true, encoding: .utf8)
            }
            os_log(.info, log: log, "Previous crash report persists (loop #%d) — diagnostics will show", next)
        } else {
            try? fm.removeItem(at: loopSentinelURL)
        }
        if let report = CrashReportStore.detectPreviousCrash() {
            CrashReportStore.save(report)
            os_log(.info, log: log, "Previous launch crashed — component: %{public}@", report.crashedComponent)
        }
        CrashReportStore.writeLaunchSentinel()
        os_log(.info, log: log, "Crash sentinel written")
        // ────────────────────────────────────────────────────────────────────────

        // Set up exception handler to log crashes
        NSSetUncaughtExceptionHandler { exception in
            os_log(.fault, log: log, "UNCAUGHT EXCEPTION: %{public}@", exception)
            os_log(.fault, log: log, "Call stack: %{public}@", exception.callStackSymbols.joined(separator: "\n"))
        }

        // navigation bar buttons spacing is too much (so hack it to use minimal spacing)
        let stackViewAppearance = UIStackView.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        stackViewAppearance.spacing = -8

        consoleLog.startCapturing()
        os_log(.info, log: log, "App is Starting up — ConsoleLog capturing")

        // Register default settings before doing anything else.
        UserDefaults.registerDefaults()
        UserDefaults.standard.register(defaults: [FluxAppearancePreference.storageKey: FluxAppearancePreference.light.rawValue])
        os_log(.info, log: log, "UserDefaults registered")
        
        // Prepare integrations (safe — no Rust FFI here, only defaults + audio + swizzle)
        os_log(.info, log: log, "Preparing FluxStikJIT integrations...")
        FluxStikJITHostBootstrap.prepareIntegrations()
        os_log(.info, log: log, "FluxStikJIT integrations prepared")
        
        // Recreate Database if requested
        if UserDefaults.standard.recreateDatabaseOnNextStart{
            os_log(.info, log: log, "Recreating database as requested...")
            UserDefaults.standard.recreateDatabaseOnNextStart = false
            DatabaseManager.recreateDatabase()
            os_log(.info, log: log, "Database recreated")
        }
        
        // Start DatabaseManager without blocking the main thread.
        os_log(.info, log: log, "Starting DatabaseManager (async)...")
        DatabaseManager.shared.start { error in
            if let error {
                os_log(.error, log: log, "Failed to start DatabaseManager (AppDelegate observer). Error: %{public}@", String(describing: error))
            } else {
                os_log(.info, log: log, "DatabaseManager started successfully (AppDelegate observer)")
            }
        }
        
        os_log(.info, log: log, "Setting tint color and image cache...")
        self.setTintColor()
        self.prepareImageCache()
        os_log(.info, log: log, "Tint color and image cache configured")

        DispatchQueue.main.async {
            FluxAppearancePreference.applyToAllWindows()
        }

        if UserDefaults.standard.enableEMPforWireguard {
            os_log(.info, log: log, "Starting EM Proxy...")
            startEMProxy(bind_addr: AppConstants.Proxy.serverURL)
        }

        SecureValueTransformer.register()
        os_log(.info, log: log, "SecureValueTransformer registered")
        
        if UserDefaults.standard.firstLaunch == nil
        {
            os_log(.info, log: log, "First launch detected, resetting keychain...")
            Keychain.shared.reset()
            UserDefaults.standard.firstLaunch = Date()
            os_log(.info, log: log, "Keychain reset for first launch")
        } else {
            os_log(.info, log: log, "Not first launch")
        }
        
        UserDefaults.standard.preferredServerID = Bundle.main.object(forInfoDictionaryKey: Bundle.Info.serverID) as? String
        os_log(.info, log: log, "Preferred server ID set")
        
        #if DEBUG && targetEnvironment(simulator)
        UserDefaults.standard.isDebugModeEnabled = true
        os_log(.info, log: log, "Debug mode enabled")
        #endif
        
        self.prepareForBackgroundFetch()
        os_log(.info, log: log, "Background fetch prepared")

        // All synchronous setup completed without crashing — clear the sentinel.
        CrashReportStore.clearLaunchSentinel()
        os_log(.info, log: log, "application:didFinishLaunchingWithOptions - EXIT (returning true)")
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "startup")
        os_log(.info, log: log, "applicationDidBecomeActive")
        // ── Crash guard: if a crash report is pending, do NOT start the JIT tunnel.
        if CrashReportStore.load() != nil {
            os_log(.info, log: log, "Crash report pending — deferring JIT tunnel start")
        } else {
            FluxStikJITHostBootstrap.onAppDidBecomeActive()
        }

        guard let url = self.pendingImportIPAURL else { return }
        self.pendingImportIPAURL = nil
        NotificationCenter.default.post(name: AppDelegate.importAppDeepLinkNotification, object: nil, userInfo: [AppDelegate.importAppDeepLinkURLKey: url])
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Make sure to update SceneDelegate.sceneDidEnterBackground() as well.
        // TODO: @mahee96: find if we need to stop em_proxy as in altstore?
        if UserDefaults.standard.enableEMPforWireguard {
            stopEMProxy()
        }
        guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return }
        
        let midnightOneMonthAgo = Calendar.current.startOfDay(for: oneMonthAgo)
        DatabaseManager.shared.purgeLoggedErrors(before: midnightOneMonthAgo) { result in
            switch result
            {
            case .success: break
            case .failure(let error): print("[ALTLog] Failed to purge logged errors before \(midnightOneMonthAgo).", error)
            }
        }
             
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        AppManager.shared.update()
        if UserDefaults.standard.enableEMPforWireguard {
            startEMProxy(bind_addr: AppConstants.Proxy.serverURL)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
    {
        return self.open(url)
    }
    
    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any?
    {
        switch intent
        {
        case is RefreshAllIntent: return self.intentHandler
        case is ViewAppIntent: return self.viewAppIntentHandler
        default: return nil
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Stop console logging and clean up resources
        print("\n ")
        print("===================================================")
        print("| Console Logger stopped capturing output streams |")
        print("===================================================")
        print("|           App is being terminated               |")
        print("===================================================")
        consoleLog.stopCapturing()
    }
}

extension AppDelegate
{
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

private extension AppDelegate
{
    func setTintColor()
    {
        self.window?.tintColor = .altPrimary
        self.window?.backgroundColor = .systemBackground
    }
    
    func prepareImageCache()
    {
        // Avoid caching responses twice.
        DataLoader.sharedUrlCache.diskCapacity = 0
        
        let pipeline = ImagePipeline { configuration in
            do
            {
                let dataCache = try DataCache(name: "io.sidestore.Nuke")
                dataCache.sizeLimit = 512 * 1024 * 1024 // 512MB
                
                configuration.dataCache = dataCache
            }
            catch
            {
                Logger.main.error("Failed to create image disk cache. Falling back to URL cache. \(error.localizedDescription, privacy: .public)")
            }
        }
        
        ImagePipeline.shared = pipeline
        
        if let dataCache = ImagePipeline.shared.configuration.dataCache as? DataCache, #available(iOS 15, *)
        {
            Logger.main.info("Current image cache size: \(dataCache.totalSize.formatted(.byteCount(style: .file)), privacy: .public)")
        }
    }
    
    func open(_ url: URL) -> Bool
    {
        if url.isFileURL
        {
            guard url.pathExtension.lowercased() == "ipa" else { return false }

            // Copy the shared .ipa out of its security-scoped location into a
            // temporary directory we own, so it stays readable while signing.
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }

            let temporaryDirectory = FileManager.default.uniqueTemporaryURL()
            do {
                try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[ALTLog] Failed to create temp directory for imported IPA: \(error)")
                return false
            }

            let ipaURL = temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                try FileManager.default.copyItem(at: url, to: ipaURL)
            } catch {
                print("[ALTLog] Failed to copy imported IPA: \(error)")
                return false
            }

            if UIApplication.shared.applicationState == .active {
                NotificationCenter.default.post(name: AppDelegate.importAppDeepLinkNotification, object: nil, userInfo: [AppDelegate.importAppDeepLinkURLKey: ipaURL])
            } else {
                // Defer until the app is active (cold launch) — see applicationDidBecomeActive.
                self.pendingImportIPAURL = ipaURL
            }

            return true
        }
        else
        {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
            guard let host = components.host?.lowercased() else { return false }
            
            switch host
            {
            case "appbackupresponse":
                let result: Result<Void, Error>
                
                switch url.path.lowercased()
                {
                case "/success": result = .success(())
                case "/failure":
                    let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]
                    guard
                        let errorDomain = queryItems["errorDomain"],
                        let errorCodeString = queryItems["errorCode"], let errorCode = Int(errorCodeString),
                        let errorDescription = queryItems["errorDescription"]
                    else { return false }
                    
                    let error = NSError(domain: errorDomain, code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                    result = .failure(error)
                    
                default: return false
                }
                
                NotificationCenter.default.post(name: AppDelegate.appBackupDidFinish, object: nil, userInfo: [AppDelegate.appBackupResultKey: result])
                
                return true
                
            case "install":
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let downloadURLString = queryItems["url"], let downloadURL = URL(string: downloadURLString) else { return false }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AppDelegate.importAppDeepLinkNotification, object: nil, userInfo: [AppDelegate.importAppDeepLinkURLKey: downloadURL])
                }
                
                return true
            
            case "source":
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let sourceURLString = queryItems["url"], let sourceURL = URL(string: sourceURLString) else { return false }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AppDelegate.addSourceDeepLinkNotification, object: nil, userInfo: [AppDelegate.addSourceDeepLinkURLKey: sourceURL])
                }
                
                return true
                
            case "pairing":
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let callbackTemplate = queryItems["urlName"]?.removingPercentEncoding else { return false }
                
                DispatchQueue.main.async {
                    exportPairingFile(callbackTemplate)
                }
                
                return true
            
            case "certificate":
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return false }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AppDelegate.exportCertificateNotification, object: nil, userInfo: [AppDelegate.exportCertificateCallbackTemplateKey: callbackTemplate])
                }
                
                return true
                
            default: return false
            }
        }
    }
}

extension AppDelegate
{
    private func prepareForBackgroundFetch()
    {
        // "Fetch" every hour, but then refresh only those that need to be refreshed (so we don't drain the battery).
        (UIApplication.shared as LegacyBackgroundFetching).setMinimumBackgroundFetchInterval(1 * 60 * 60)
        
        #if DEBUG && targetEnvironment(simulator)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Push Token:", token)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        self.application(application, performFetchWithCompletionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler backgroundFetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if UserDefaults.standard.isBackgroundRefreshEnabled && !UserDefaults.standard.presentedLaunchReminderNotification
        {
            let threeHours: TimeInterval = 3 * 60 * 60
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: threeHours, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("App Refresh Tip", comment: "")
            content.body = NSLocalizedString("The more you open AeroStore, the more chances it's given to refresh apps in the background.", comment: "")
            
            let request = UNNotificationRequest(identifier: "background-refresh-reminder5", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
            UserDefaults.standard.presentedLaunchReminderNotification = true
        }
        
        BackgroundTaskManager.shared.performExtendedBackgroundTask { (taskResult, taskCompletionHandler) in
            if let error = taskResult.error
            {
                print("Error starting extended background task. Aborting.", error)
                backgroundFetchCompletionHandler(.failed)
                taskCompletionHandler()
                return
            }
            
            if !DatabaseManager.shared.isStarted
            {
                DatabaseManager.shared.start() { (error) in
                    if error != nil
                    {
                        backgroundFetchCompletionHandler(.failed)
                        taskCompletionHandler()
                    }
                    else
                    {
                        self.performBackgroundFetch { (backgroundFetchResult) in
                            backgroundFetchCompletionHandler(backgroundFetchResult)
                        } refreshAppsCompletionHandler: { (refreshAppsResult) in
                            taskCompletionHandler()
                        }
                    }
                }
            }
            else
            {
                self.performBackgroundFetch { (backgroundFetchResult) in
                    backgroundFetchCompletionHandler(backgroundFetchResult)
                } refreshAppsCompletionHandler: { (refreshAppsResult) in
                    taskCompletionHandler()
                }
            }
        }
    }
    
    func performBackgroundFetch(backgroundFetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void,
                                refreshAppsCompletionHandler: @escaping (Result<[String: Result<InstalledApp, Error>], Error>) -> Void)
    {
        self.fetchSources { (result) in
            switch result
            {
            case .failure: backgroundFetchCompletionHandler(.failed)
            case .success: backgroundFetchCompletionHandler(.newData)
            }
            
            if !UserDefaults.standard.isBackgroundRefreshEnabled
            {
                refreshAppsCompletionHandler(.success([:]))
            }
        }
        
        guard UserDefaults.standard.isBackgroundRefreshEnabled else { return }
        
        DatabaseManager.shared.persistentContainer.performBackgroundTask { (context) in
            let installedApps = InstalledApp.fetchAppsForBackgroundRefresh(in: context)
            AppManager.shared.backgroundRefresh(installedApps, completionHandler: refreshAppsCompletionHandler)
        }
    }
}

private extension AppDelegate
{
    func fetchSources(completionHandler: @escaping (Result<Set<Source>, Error>) -> Void)
    {
        AppManager.shared.fetchSources() { (result) in
            do
            {
                let (sources, context) = try result.get()
                
                let previousUpdatesFetchRequest = InstalledApp.supportedUpdatesFetchRequest() as! NSFetchRequest<NSFetchRequestResult>
                previousUpdatesFetchRequest.includesPendingChanges = false
                previousUpdatesFetchRequest.resultType = .dictionaryResultType
                previousUpdatesFetchRequest.propertiesToFetch = [#keyPath(InstalledApp.bundleIdentifier),
                                                                 #keyPath(InstalledApp.storeApp.latestSupportedVersion.version),
                                                                 #keyPath(InstalledApp.storeApp.latestSupportedVersion._buildVersion)]
                
                let previousNewsItemsFetchRequest = NewsItem.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
                previousNewsItemsFetchRequest.includesPendingChanges = false
                previousNewsItemsFetchRequest.resultType = .dictionaryResultType
                previousNewsItemsFetchRequest.propertiesToFetch = [#keyPath(NewsItem.identifier)]
                
                let previousUpdates = try context.fetch(previousUpdatesFetchRequest) as! [[String: String]]
                let previousNewsItems = try context.fetch(previousNewsItemsFetchRequest) as! [[String: String]]
                
                try context.save()
                
                
                
                let updatesFetchRequest = InstalledApp.supportedUpdatesFetchRequest()
                let newsItemsFetchRequest = NewsItem.fetchRequest() as NSFetchRequest<NewsItem>
                
                let updates = try context.fetch(updatesFetchRequest)
                let newsItems = try context.fetch(newsItemsFetchRequest)
                
                for update in updates
                {
                    guard let storeApp = update.storeApp, let latestSupportedVersion = storeApp.latestSupportedVersion, latestSupportedVersion.isSupported else { continue }
                    
                    if let previousUpdate = previousUpdates.first(where: { $0[#keyPath(InstalledApp.bundleIdentifier)] == update.bundleIdentifier })
                    {
                        // An update for this app was already available, so check whether the version or build version is different.
                        guard let previousVersion = previousUpdate[#keyPath(InstalledApp.storeApp.latestSupportedVersion.version)] else { continue }
                        
                        // previousUpdate might not contain buildVersion, but if it does then map empty string to nil to match AppVersion.
                        let previousBuildVersion = previousUpdate[#keyPath(InstalledApp.storeApp.latestSupportedVersion._buildVersion)].map { $0.isEmpty ? nil : "" }
                        
                        // Only show notification if previous latestSupportedVersion does not _exactly_ match current latestSupportedVersion.
                        guard previousVersion != latestSupportedVersion.version || previousBuildVersion != latestSupportedVersion.buildVersion  else { continue }
                    }
                    
                    // Determine update type from version strings
                    let updateType: UpdateType
                    if latestSupportedVersion.version.lowercased().contains("nightly") {
                        updateType = .nightly
                    } else if update.version.lowercased().contains("nightly") {
                        updateType = .stableFromNightly
                    } else {
                        updateType = .standard
                    }

                    if UserDefaults.standard.isUpdateNotificationsEnabled {
                        FluxNotificationManager.shared.scheduleUpdateNotification(
                            for: update,
                            newVersion: latestSupportedVersion.localizedVersion,
                            updateType: updateType
                        )
                    } else {
                        let content = UNMutableNotificationContent()
                        content.title = NSLocalizedString("New Update Available", comment: "")
                        content.body = String(format: NSLocalizedString("%@ %@ is now available for download.", comment: ""), update.name, latestSupportedVersion.localizedVersion)
                        content.sound = .default
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
                
                for newsItem in newsItems
                {
                    guard !previousNewsItems.contains(where: { $0[#keyPath(NewsItem.identifier)] == newsItem.identifier }) else { continue }
                    guard !newsItem.isSilent else { continue }
                    
                    let content = UNMutableNotificationContent()
                    
                    if let app = newsItem.storeApp
                    {
                        content.title = String(format: NSLocalizedString("%@ News", comment: ""), app.name)
                    }
                    else
                    {
                        content.title = NSLocalizedString("AeroStore News", comment: "")
                    }
                    
                    content.body = newsItem.title
                    content.sound = .default
                    
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }

                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = updates.count
                }
                
                completionHandler(.success(sources))
            }
            catch
            {
                print("Error fetching apps:", error)
                completionHandler(.failure(error))
            }
        }
    }
}
