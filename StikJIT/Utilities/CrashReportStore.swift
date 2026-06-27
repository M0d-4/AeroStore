import Foundation
import UIKit
import OSLog

struct CrashReport: Codable {
    let crashedComponent: String
    let iOSVersion: String
    let deviceModel: String
    let timestamp: Date
}

enum CrashReportStore {

    // MARK: - Sentinel URLs
    // All sentinel files live in the app's Documents directory so they survive
    // a hard abort() — which bypasses UserDefaults.synchronize() and in-memory
    // state but cannot prevent an already-flushed atomic file write.

    static var launchSentinelURL: URL {
        URL.documentsDir.appendingPathComponent(".aerostore_launch_started", isDirectory: false)
    }

    static var tunnelSentinelURL: URL {
        URL.documentsDir.appendingPathComponent(".aerostore_tunnel_starting", isDirectory: false)
    }

    static var mountSentinelURL: URL {
        URL.documentsDir.appendingPathComponent(".aerostore_mount_checking", isDirectory: false)
    }

    static var minimuxerSentinelURL: URL {
        URL.documentsDir.appendingPathComponent(".aerostore_minimuxer_starting", isDirectory: false)
    }

    private static var reportURL: URL {
        URL.documentsDir.appendingPathComponent(".crash_report.json", isDirectory: false)
    }

    // MARK: - Detection

    /// Call this at the very beginning of `didFinishLaunchingWithOptions` — before
    /// writing the new launch sentinel.  Checks every sentinel file, aggregates a
    /// human-readable crash reason, clears ALL sentinels, and returns a report if
    /// any sentinel was found.
    ///
    /// Only the **launch** sentinel indicates a crash *during* didFinishLaunching.
    /// Tunnel / mount / minimuxer sentinels indicate crashes that happened *after*
    /// the main interface was already installed (post-launch work).  We still
    /// report them so the user sees the diagnostics screen, but the app is not
    /// blocked from starting up normally.
    @discardableResult
    static func detectPreviousCrash() -> CrashReport? {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "startup")
        let fm = FileManager.default
        var components: [String] = []

        if fm.fileExists(atPath: launchSentinelURL.path) {
            components.append("App launch setup (didFinishLaunchingWithOptions)")
            os_log(.default, log: log, "detectPreviousCrash: launch sentinel FOUND")
        }
        if fm.fileExists(atPath: tunnelSentinelURL.path) {
            components.append("JIT tunnel start (Rust startTunnel)")
            os_log(.default, log: log, "detectPreviousCrash: tunnel sentinel FOUND")
        }
        if fm.fileExists(atPath: mountSentinelURL.path) {
            components.append("Device mount check (Rust isMounted / isPairing)")
            os_log(.default, log: log, "detectPreviousCrash: mount sentinel FOUND")
        }
        if fm.fileExists(atPath: minimuxerSentinelURL.path) {
            components.append("Minimuxer start (Rust minimuxerStartWithLogger)")
            os_log(.default, log: log, "detectPreviousCrash: minimuxer sentinel FOUND")
        }

        try? fm.removeItem(at: launchSentinelURL)
        try? fm.removeItem(at: tunnelSentinelURL)
        try? fm.removeItem(at: mountSentinelURL)
        try? fm.removeItem(at: minimuxerSentinelURL)

        guard !components.isEmpty else {
            os_log(.default, log: log, "detectPreviousCrash: no sentinels found")
            return nil
        }

        os_log(.default, log: log, "detectPreviousCrash: components=%@", components.joined(separator: " + "))

        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let device = UIDevice.current
        let deviceModel = "\(device.model) — iOS \(device.systemVersion)"

        return CrashReport(
            crashedComponent: components.joined(separator: " + "),
            iOSVersion: osVersion,
            deviceModel: deviceModel,
            timestamp: Date()
        )
    }

    // MARK: - Persistence

    static func save(_ report: CrashReport) {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "startup")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(report) else {
            os_log(.error, log: log, "Failed to encode crash report")
            return
        }
        try? data.write(to: reportURL, options: .atomic)
        os_log(.default, log: log, "Crash report saved (component: %{public}@)", report.crashedComponent)
    }

    static func load() -> CrashReport? {
        guard let data = try? Data(contentsOf: reportURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CrashReport.self, from: data)
    }

    static func clear() {
        let log = OSLog(subsystem: "com.aero.aerostore", category: "startup")
        try? FileManager.default.removeItem(at: reportURL)
        os_log(.default, log: log, "Crash report cleared")
    }

    // MARK: - Launch Sentinel

    /// Write at the start of `didFinishLaunchingWithOptions`.
    /// If the process aborts anywhere before `clearLaunchSentinel()` is called,
    /// this file will be found on the next launch.
    static func writeLaunchSentinel() {
        try? "1".write(to: launchSentinelURL, atomically: true, encoding: .utf8)
    }

    /// Write at the end of `didFinishLaunchingWithOptions`, after all synchronous
    /// setup has completed without crashing.
    static func clearLaunchSentinel() {
        try? FileManager.default.removeItem(at: launchSentinelURL)
    }

    // MARK: - Debug Text

    static func debugText(for report: CrashReport) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let dateStr = formatter.string(from: report.timestamp)
        return """
        AeroStore Crash Report
        ──────────────────────────
        Detected:  \(dateStr)
        Component: \(report.crashedComponent)
        Device:    \(report.deviceModel)
        OS string: \(report.iOSVersion)

        No system crash log was generated because the process was
        terminated via abort() inside the Rust idevice bridge, which
        bypasses the iOS crash reporter entirely.

        Please share this text when reporting the issue.
        """
    }
}
