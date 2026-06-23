//
//  ConsoleLog.swift
//  AltStore
//
//  Created by Magesh K on 25/11/24.
//  Copyright © 2024 SideStore. All rights reserved.
//
//

import Foundation

class ConsoleLog {
    private static let CONSOLE_LOGS_DIRECTORY = "ConsoleLogs"
    private static let CONSOLE_LOG_NAME_PREFIX = "console"
    private static let CONSOLE_LOG_EXTN = ".log"
    
    private lazy var consoleLogger: ConsoleLogger? = {
        guard let logFileHandle = createLogFileHandle() else {
            print("ConsoleLog: Failed to create log file handle")
            return nil
        }
        let fileOutputStream = FileOutputStream(logFileHandle)
        
        return UnBufferedConsoleLogger(stream: fileOutputStream)
    }()
    
    func startCapturing() {
        consoleLogger?.startCapturing()
    }
    
    func stopCapturing() {
        consoleLogger?.stopCapturing()
    }
    
    private lazy var consoleLogsDir: URL = {
        let docsDir = FileManager.default.documentsDirectory
        let consoleLogsDir = docsDir.appendingPathComponent(ConsoleLog.CONSOLE_LOGS_DIRECTORY)
        if !FileManager.default.fileExists(atPath: consoleLogsDir.path) {
            do {
                try FileManager.default.createDirectory(at: consoleLogsDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("ConsoleLog: Failed to create logs directory: \(error)")
            }
        }
        return consoleLogsDir
    }()
    
    public lazy var logName: String = {
        logFileURL.lastPathComponent
    }()
    
    public lazy var logFileURL: URL = {
        let currentTime = Date()
        let dateTimeStamp = DateTimeUtil.getDateInTimeStamp(date: currentTime)
        
        let logName = DateTimeUtil.getTimeStampSuffixedFileName(
            fileName: ConsoleLog.CONSOLE_LOG_NAME_PREFIX,
            timestamp: dateTimeStamp,
            extn: ConsoleLog.CONSOLE_LOG_EXTN
        )
        let logFileURL = consoleLogsDir.appendingPathComponent(logName)
        return logFileURL
    }()
    
    
    private func createLogFileHandle() -> FileHandle? {
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        return try? FileHandle(forWritingTo: logFileURL)
    }

}

