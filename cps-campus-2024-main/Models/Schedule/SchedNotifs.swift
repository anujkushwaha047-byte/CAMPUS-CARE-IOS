//
//  SchedNotifs.swift
//  CampusApp
//
//  7/11/2021
//  Built by Rahim Malik.
//

import Foundation
import UserNotifications

//TODO: Test
class NotifManager {
    
    var userObject: UserObject
    var scheduleObject: ScheduleObject
    var clubsObject: ClubsObject
    var ccObject: CCObject
    
    var classStarts: Bool
    var classEnds: Bool
    var classMinutes: Int
    var clubMinutes: Int
    
    init(userObject: UserObject, scheduleObject: ScheduleObject, clubsObject: ClubsObject, ccObject: CCObject, notifPrefsActive: [String : Bool], notifPrefsMinutes: [String : Int]) {
        self.userObject = userObject
        self.scheduleObject = scheduleObject
        self.clubsObject = clubsObject
        self.ccObject = ccObject
        
        self.classStarts = notifPrefsActive["class_starts"] ?? true
        self.classEnds = notifPrefsActive["class_ends"] ?? false
        self.classMinutes = notifPrefsMinutes["class_minutes"] ?? 5
        self.clubMinutes = notifPrefsMinutes["club_minutes"] ?? 5
    }
    
    enum ClassNotifType {
        case start
        case end
    }
    
    static func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        switch settings.authorizationStatus {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    static func removeNotifications(for category: String) async {
        let center = UNUserNotificationCenter.current()
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        
        for request in requests {
            if request.content.categoryIdentifier == category {
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
        }
    }
    
    static private func addNotificationRequest(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    ConsoleMessage(type: .internal, description: "addNotificationRequest - \(error.localizedDescription)").error()
                }
                continuation.resume()
            }
        }
    }
    
    func generateScheduleNotifications() async {
        await NotifManager.removeNotifications(for: "schedule")

        // Date range doesn't seem to have an inclusive start bound
        let currentDate = Date().addDays(-1) ?? Date()
        let dateRange = currentDate...(currentDate.addDays(7) ?? currentDate)
        
        var blocksInRange = scheduleObject.blocks.flatMap { block -> [Block] in
            // Get blocks with dates within date range
            block.dates.filter { dateString in
                return dateRange.contains(dateString.toDate())
            }.map { dateString in
                var newBlock = block
                newBlock.dates = [dateString]
                return newBlock
            }
        }
        
        blocksInRange = blocksInRange.sorted {
            if let first = $0.dates.first?.toDate(), let second = $1.dates.first?.toDate() {
                return first < second
            } else {
                return false
            }
        }
        
        for block in blocksInRange {
            if classStarts == true {
                await scheduleNotification(for: block, notifType: .start, minutesOffset: classMinutes)
            }
            if classEnds == true {
                await scheduleNotification(for: block, notifType: .end, minutesOffset: classMinutes)
            }
        }
        
        func scheduleNotification(for block: Block, notifType: ClassNotifType, minutesOffset: Int) async {
            guard let date = block.dates.first else { return }
            var notificationDate: Date?
            
            switch notifType {
            case .start:
                let startDate = String(date + " " + block.startTime).toDate(format: "yyyy-MM-dd HH:mm:ss")
                notificationDate = startDate.addingTimeInterval(TimeInterval(-minutesOffset * 60))
            case .end:
                let endDate = String(date + " " + block.endTime).toDate(format: "yyyy-MM-dd HH:mm:ss")
                notificationDate = endDate.addingTimeInterval(TimeInterval(-minutesOffset * 60))
            }
            
            guard let triggerDate = notificationDate else { return }
            
            // Do not schedule if notification date has already passed
            if triggerDate < Date() {
                return
            }
            
            let content = UNMutableNotificationContent()
            
            let (title, body) = getProperties(block: block, date: date, rotation: ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData))
            
            content.title = title
            if var wrappedBody = body {
                if minutesOffset == 0 {
                    switch notifType {
                    case .end:
                        wrappedBody += (wrappedBody == "" ? "has ended" : " has ended")
                    case .start:
                        wrappedBody += (wrappedBody == "" ? "has started" : " has started")
                    }
                } else {
                    switch notifType {
                    case .end:
                        wrappedBody = "ends in \(minutesOffset) min"
                    case .start:
                        wrappedBody += (wrappedBody == "" ? "in \(minutesOffset) min" : " in \(minutesOffset) min")
                    }
                }
                content.body = wrappedBody
            } else {
                if minutesOffset == 0 {
                    switch notifType {
                    case .end:
                        content.body = "Has ended"
                    case .start:
                        content.body = "Has started"
                    }
                } else {
                    switch notifType {
                    case .end:
                        content.body = "Ends in \(minutesOffset) min"
                    case .start:
                        content.body = "In \(minutesOffset) min"
                    }
                }
            }
            
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "cling.mp3"))
            content.categoryIdentifier = "schedule"
            content.interruptionLevel = .timeSensitive
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate), repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            await NotifManager.addNotificationRequest(request)
            
            func getProperties(block: Block, date: String, rotation: String) -> (String, String?) {
                if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }), ScheduleObject.isCompass(block: block, date: date, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                    return (
                        compass.name,
                        [compass.teacher, compass.room].filter { !$0.isEmpty }.joined(separator: " | ")
                    )
                } else if ScheduleObject.isOpen(block: block, date: date, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                    return (
                        "Open",
                        nil
                    )
                } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
                    if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                        return (
                            "Free Period",
                            nil
                        )
                    } else if block.title == "Common Classroom", let commonClassroom = ccObject.currentCC, let ccTitle = commonClassroom.title, let ccRoom = commonClassroom.room, let date = commonClassroom.dateRaw, date == Date().toString(format: "yyyy-MM-dd") {
                        return (
                            ccTitle,
                            "CC | \(ccRoom)"
                        )
                    } else {
                        return (
                            course.name,
                            [course.teacher, course.room].filter { !$0.isEmpty }.joined(separator: " | ")
                        )
                    }
                } else {
                    return (
                        block.title,
                        nil
                    )
                }
            }
        }
    }
    
    func generateClubNotifications() async {
        // Check that user is not nil
        guard let currentUser = userObject.currentUser else {
            return
        }
        
        // Remove existing clubs notifications
        await NotifManager.removeNotifications(for: "clubs")
        
        // Get clubs that user has joined
        var clubs = clubsObject.clubs.filter({ currentUser.clubs.contains($0.clubID) || currentUser.clubs.contains($0.clubID) })
        
        // Add led clubs
        clubs.append(contentsOf: clubsObject.ledClubs)
        
        // Get all club meetings from joined or led clubs
        let clubMeetings = clubsObject.clubMeetings.filter({ clubs.map({ $0.clubID }).contains($0.clubID) })
        
        for meeting in clubMeetings {
            await scheduleNotification(for: meeting, minutesOffset: clubMinutes)
        }
        
        func scheduleNotification(for meeting: ClubMeeting, minutesOffset: Int) async {
            
            let notificationDate = { () -> Date in
                if let startTime = meeting.startTime {
                    return ("\(meeting.date) \(startTime)").toDate(format: "yyyy-MM-dd HH:mm:ss").addingTimeInterval(TimeInterval(-minutesOffset * 60))
                }
                
                // Return just the current date (this will fail the next check)
                return Date()
            }()
            
            // If the notification date is anytime in the past or if the notification date is not during school, return
            if (notificationDate < Date()) || (scheduleObject.isSchoolDay(notificationDate) == false) {
                return
            }
            
            let content = UNMutableNotificationContent()
            
            content.title = meeting.title
            
            if let location = meeting.location {
                content.body = location
            }
            
            if minutesOffset > 0 && meeting.isBakeSale == false {
                content.body += " in \(minutesOffset) min"
            } else {
                content.body += " has started"
            }
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "cling.mp3"))
            content.categoryIdentifier = "clubs"
            content.interruptionLevel = .timeSensitive
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationDate), repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            await NotifManager.addNotificationRequest(request)
        }
    }
}
