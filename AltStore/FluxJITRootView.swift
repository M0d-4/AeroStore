//
//  FluxJITRootView.swift
//  aerostore
//

import SwiftUI
import UIKit

struct FluxJITRootView: View {
    @ObservedObject private var crashState = CrashRecoveryState.shared
    @State private var isShowingPairingFilePicker = false

    var body: some View {
        InstalledAppsListView(
            onSelectApp: { bundleID in
                HapticFeedbackHelper.trigger()
                DispatchQueue.global(qos: .background).async {
                    let keepAlive = FluxDebugKeepAliveLease()
                    defer { keepAlive.invalidate() }
                    let logger: LogFunc = { message in
                        if let message {
                            LogManager.shared.addInfoLog(message)
                        }
                    }
                    _ = JITEnableContext.shared.debugApp(withBundleID: bundleID, logger: logger, jsCallback: nil)
                }
            },
            showDoneButton: true,
            onImportPairingFile: { isShowingPairingFilePicker = true }
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            if crashState.needsRepair {
                RePairBanner { isShowingPairingFilePicker = true }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: crashState.needsRepair)
        .onAppear {
            startTunnelInBackground(showErrorUI: false)
            MountingProgress.shared.checkforMounted()
            FluxStikJITHostBootstrap.ensureDeveloperDiskImagesPresent()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPairingFilePicker"))) { _ in
            isShowingPairingFilePicker = true
        }
        .fileImporter(
            isPresented: $isShowingPairingFilePicker,
            allowedContentTypes: PairingFileStore.supportedContentTypes
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try PairingFileStore.importFromPicker(url, fileManager: FileManager.default)
                    CrashRecoveryState.shared.needsRepair = false
                    pubTunnelConnected = false
                    startTunnelInBackground()
                    NotificationCenter.default.post(name: .pairingFileImported, object: nil)
                } catch {
                    LogManager.shared.addErrorLog("Failed to import pairing file: \(error.localizedDescription)")
                }
            case .failure(let error):
                LogManager.shared.addErrorLog("Pairing file picker error: \(error.localizedDescription)")
            }
        }
    }
}

private final class FluxDebugKeepAliveLease {
    private let stateLock = NSLock()
    private var isActive = false
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    init() {
        activate()
    }

    func invalidate() {
        stateLock.lock()
        guard isActive else {
            stateLock.unlock()
            return
        }
        isActive = false
        stateLock.unlock()

        runOnMain {
            BackgroundAudioManager.shared.requestStop()
            BackgroundLocationManager.shared.requestStop()

            if self.backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }
        }
    }

    private func activate() {
        stateLock.lock()
        guard !isActive else {
            stateLock.unlock()
            return
        }
        isActive = true
        stateLock.unlock()

        runOnMain {
            BackgroundAudioManager.shared.requestStart()
            BackgroundLocationManager.shared.requestStart()
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AeroStoreJITSession") { [weak self] in
                LogManager.shared.addWarningLog("JIT session background task expired")
                self?.invalidate()
            }
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.sync(execute: work) }
    }
}
