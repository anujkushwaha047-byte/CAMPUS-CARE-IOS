//
//  DevHelpers.swift
//  CampusApp, CampusWidget
//
//  Created on 6/19/2024
//  Built by Rahim Malik.
//

import Foundation
import os.log

/// Structure representing a logged message with specific type and description. Conforms to error for throwing.
struct ConsoleMessage: Error {
    let type: MessageType
    let description: String
    
    /// Enum defining types of errors for logging.
    enum MessageType: String {
        case authentication
        case data
        case `internal`
        case network
    }
    
    /// Initializes a `ConsoleMessage` instance with message type and description.
    /// - Parameters:
    ///   - type: The type of message.
    ///   - description: A detailed description of the message.
    init(type: MessageType, description: String) {
        self.type = type
        self.description = description
    }
    
    #if DEBUG
    /// Logs the message as a normal log/debug/info.
    func log() {
        let logger = Logger(subsystem: "com.TheCollegePreparatorySchool.ScheduleApp", category: type.rawValue)
        logger.info("\(self.type.rawValue.uppercased()) - \(description)")
    }
    
    /// Logs the message as an error/warning.
    func error() {
        let logger = Logger(subsystem: "com.TheCollegePreparatorySchool.ScheduleApp", category: type.rawValue)
        logger.error("\(self.type.rawValue.uppercased()) - \(description)")
    }
    
    /// Logs the message as a critical/fault.
    func critical() {
        let logger = Logger(subsystem: "com.TheCollegePreparatorySchool.ScheduleApp", category: type.rawValue)
        logger.critical("\(self.type.rawValue.uppercased()) - \(description)")
    }
#else
    func log() { return }
    
    func error() { return }
    
    func critical() { return }
#endif
}

// MARK: - Debugging

/// Resets the app's storage for debug purposes.
func resetAppStorage() {
    // Uncomment the lines below to reset app storage
//    UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")?.removeObject(forKey: "setup")
//    UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")?.removeObject(forKey: "notif_prefs_active")
//    UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")?.removeObject(forKey: "notif_prefs_minutes")
//    UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")?.removeObject(forKey: "color_space")
//    UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")?.removeObject(forKey: "schedule_show_calendar")
}
