//
//  RefreshAllAppsIntent.swift
//  AltStore
//
//  Created by Riley Testut on 8/18/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import AppIntents
import WidgetKit
import AltStoreCore

// Simple struct wrapper so we own both the type and the protocol conformance,
// avoiding any conflict with NSError's own CustomLocalizedStringResourceConvertible
// conformance introduced in newer SDK versions.
@available(iOS 16, *)
private struct IntentError: Error, CustomLocalizedStringResourceConvertible
{
    let localizedStringResource: LocalizedStringResource

    init(_ error: some Error)
    {
        self.localizedStringResource = "\(error.localizedDescription)"
    }
}

@available(iOS 17.0, *)
extension RefreshAllAppsIntent
{
    private actor OperationActor
    {
        private(set) var operation: BackgroundRefreshAppsOperation?
        
        func set(_ operation: BackgroundRefreshAppsOperation?)
        {
            self.operation = operation
        }
    }
}

@available(iOS 17.0, *)
struct RefreshAllAppsIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ProgressReportingIntent, ForegroundContinuableIntent
{
    static let intentClassName = "RefreshAllIntent"
    
    static var title: LocalizedStringResource = "Refresh All Apps"
    static var description = IntentDescription("Refreshes your sideloaded apps to prevent them from expiring.")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Refresh All Apps")
    }
    
    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(
                title: "Refresh All Apps",
                subtitle: ""
            )
        }
    }
    
    let presentsNotifications: Bool
    
    private let operationActor = OperationActor()
    
    init(presentsNotifications: Bool)
    {
        self.presentsNotifications = presentsNotifications
        
        self.progress.completedUnitCount = 0
        self.progress.totalUnitCount = 1
    }
    
    init()
    {
        self.init(presentsNotifications: false)
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog
    {
        do
        {
            // Request foreground execution at ~27 seconds to gracefully handle timeout.
            let deadline: ContinuousClock.Instant = .now + .seconds(27)
            
            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTask {
                    try await self.refreshAllApps()
                }
                
                taskGroup.addTask {
                    try await Task.sleep(until: deadline)
                    throw OperationError.timedOut
                }
                
                do
                {
                    for try await _ in taskGroup.prefix(1)
                    {
                        // We only care about the first child task to complete.
                        taskGroup.cancelAll()
                        break
                    }
                }
                catch OperationError.timedOut
                {
                    // We took too long to finish and return the final result,
                    // so we'll now present a normal notification when finished.
                    let operation = await self.operationActor.operation
                    operation?.presentsFinishedNotification = true
                    
                    try await self.requestToContinueInForeground()
                }
            }
            
            return .result(dialog: "All apps have been refreshed.")
        }
        catch
        {
            let intentError = IntentError(error)
            throw intentError
        }
    }
}

@available(iOS 17.0, *)
private extension RefreshAllAppsIntent
{
    func refreshAllApps() async throws
    {
        if !DatabaseManager.shared.isStarted
        {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DatabaseManager.shared.start { error in
                    if let error
                    {
                        continuation.resume(throwing: error)
                    }
                    else
                    {
                        continuation.resume()
                    }
                }
            }
        }
        
        let context = DatabaseManager.shared.persistentContainer.newBackgroundContext()
        let installedApps = await context.perform { InstalledApp.fetchAppsForRefreshingAll(in: context) }
        
        try await withCheckedThrowingContinuation { continuation in
            let operation = AppManager.shared.backgroundRefresh(installedApps, presentsNotifications: self.presentsNotifications) { (result) in
                do
                {
                    let results = try result.get()
                    
                    for (_, result) in results
                    {
                        guard case let .failure(error) = result else { continue }
                        throw error
                    }
                    
                    continuation.resume()
                }
                catch ~RefreshErrorCode.noInstalledApps
                {
                    continuation.resume()
                }
                catch
                {
                    continuation.resume(throwing: error)
                }
            }
            
            operation.ignoresServerNotFoundError = false
            
            self.progress.addChild(operation.progress, withPendingUnitCount: 1)
            
            Task {
                await self.operationActor.set(operation)
            }
        }
    }
}
