//
//  Logger.swift
//  sup
//
//  Created by Robert Malko on 2/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import os.log
import PaperTrailLumberjack

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let debug = OSLog(subsystem: subsystem, category: "debug")
    static let viewCycle = OSLog(subsystem: subsystem, category: "viewCycle")
}

private let logMessages = true
private let loggedCategories: [OSLog] = [.debug]

struct Logger {
    private static var hasSetupPaperTrail = false
    private static var paperTrailLogger: RMPaperTrailLogger? = nil

    static func log(_ message: StaticString, log: OSLog, type: OSLogType, _ args: CVarArg...) {
        if logMessages && loggedCategories.contains(log) {
            os_log(message, log: log, type: type, args)
        }
    }

    static func setupPapertrail(userId: String?, username: String? = nil) {
        if !hasSetupPaperTrail {
            if let paperTrailLogger = RMPaperTrailLogger.sharedInstance() as RMPaperTrailLogger? {
                paperTrailLogger.host = "logs.papertrailapp.com"
                paperTrailLogger.port = 46353
                if let info = Bundle.main.infoDictionary, let bundleId = info["CFBundleIdentifier"] as? String {
                    paperTrailLogger.machineName = bundleId
                }
                self.paperTrailLogger = paperTrailLogger
                DDLog.add(paperTrailLogger)
            }
            self.hasSetupPaperTrail = true
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        var programName = ""
        if userId != nil {
            programName = userId!
            if let username = username {
                programName += "|\(username)"
            }
            if let appVersion = appVersion {
                programName += "|\(appVersion)"
            }
        } else {
            if let appVersion = appVersion {
                programName = appVersion
            }
        }

        self.paperTrailLogger?.programName = programName
    }
}
