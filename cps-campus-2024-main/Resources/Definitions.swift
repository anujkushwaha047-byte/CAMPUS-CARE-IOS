//
//  Definitions.swift
//  CampusApp, CampusWidget
//
//  Created on 6/19/2021
//  Built by Rahim Malik.
//

import Foundation
#if APP
import FirebaseFirestore
#endif

// MARK: - Databases

#if APP
/// Firestore database instance used throughout the application.
let firestoreDB = Firestore.firestore()
#endif

// Used exclusively for palette ID implementation
/// Extension on `String` providing a method to convert to lowercase and replace spaces with underscores.
extension String {
    /// Converts the string to lowercase and replaces spaces with underscores.
    /// - Returns: Modified string with spaces replaced by underscores.
    func lowercasedWithUnderscores() -> String {
        return self.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}

/// Extracts campus ID from an email address if it matches predefined school domains.
/// - Parameter email: The email address to extract campus ID from.
/// - Returns: The campus ID extracted from the email, or `nil` if not found.
func campusIDFromEmail(_ email: String?) -> String? {
    if let wrappedEmail = email {
        if wrappedEmail.contains("@thecollegepreparatoryschool.org") || wrappedEmail.contains("@college-prep.org") {
            return wrappedEmail
                .replacingOccurrences(of: "@thecollegepreparatoryschool.org", with: "")
                .replacingOccurrences(of: "@college-prep.org", with: "")
        }
    }
    return nil
}

// MARK: - Courses

/// Predefined course IDs categorized into different blocks and community periods.
let classCourseIDs = ["A-Block", "B-Block", "C-Block", "D-Block", "E-Block", "F-Block", "G-Block", "H-Block"]
let communityCourseIDs = ["Compass", "X-Block", "Assembly", "Advising", "Common Classroom"]

/// Combined list of all course IDs including class and community periods.
let allCourseIDs: [String] = classCourseIDs + communityCourseIDs

/// Course IDs categorized by rotation periods.
let rotation1and3CourseIDs = ["A-Block", "B-Block", "C-Block", "D-Block"]
let rotation2and4CourseIDs = ["E-Block", "F-Block", "G-Block", "H-Block"]

/// Course IDs where rooms cannot be assigned to teachers.
let noTeacherRoomCourseIDs = ["X-Block", "Assembly", "Common Classroom"]

// MARK: - Users

/// Social options available for user profiles.
let socialOptions: [String] = ["Phone", "Instagram", "Snapchat", "Discord", "GitHub", "LinkedIn"]

let freshGradYear = "2028"
let sophGradYear = "2027"
let juniorGradYear = "2026"
let seniorGradYear = "2025"

let defaultPalette: [String: String] = ["A-Block": "#6773E8",
                                        "B-Block": "#E0A3BD",
                                        "C-Block": "#F8DA85",
                                        "D-Block": "#E7A042",
                                        "E-Block": "#9CE9B5",
                                        "F-Block": "#4FB3DC",
                                        "G-Block": "#B8F19A",
                                        "H-Block": "#3555C8",
                                        "Compass": "#00B1B8",
                                        "X-Block": "#00B1B8",
                                        "Assembly": "#00B1B8",
                                        "Advising": "#00B1B8",
                                        "Common Classroom": "#00B1B8"]

// MARK: - Clubs

let clubCategories = ["Affinities", "Activism", "Arts", "Fitness", "Humanities", "Lifestyle", "Politics/Economics", "STEM"]

// MARK: - Other

let userAccessGroup = ""

let restrictedPages = ["community", "clubs", "sports", "directory"]

let iteamContributions = ["Rahim Malik '23", "Marcus G. '26", "Aiden F. '27"]
let facultyContributions = ["Edwin Kirimi", "Linh Tran Tsang", "Steve Chabon"]

let externalContributions: [(name: String, link: URL)] = [("Firebase", URL(string: "https://github.com/firebase/firebase-ios-sdk")!), ("GoogleSignIn", URL(string: "https://github.com/google/GoogleSignIn-iOS")!), ("DynamicColor", URL(string: "https://github.com/yannickl/DynamicColor")!), ("ColorThiefSwift", URL(string: "https://github.com/yamoridon/ColorThiefSwift")!)]

var systemCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    
    if let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles") {
        calendar.timeZone = pacificTimeZone
    }
    
    calendar.firstWeekday = 1 // Sunday
    calendar.minimumDaysInFirstWeek = 4 // Common setting for ISO 8601
    calendar.locale = Locale(identifier: "en_US_POSIX") // A locale that avoids locale-specific issues
    
    return calendar
}

#if APP

#if os(iOS)
let defaultHomePage = [
    HomePageItem(id: "RHF", icon: "figure.badminton", visible: true),
    HomePageItem(id: "Links", icon: "link", visible: true),
    HomePageItem(id: "Map", icon: "map", visible: true)
]
#elseif os(macOS)
let defaultHomePage = [
    HomePageItem(id: "RHF", icon: "figure.badminton", visible: true),
    HomePageItem(id: "Links", icon: "link", visible: true)
]
#endif

let defaultQuickLinks = [
    QuickLink(id: "", label: "CC", icon: "rectangle.inset.filled.and.person.filled", visible: true),
    QuickLink(id: "", label: "Radar", icon: "newspaper", visible: true),
    QuickLink(id: "", label: "Library", icon: "books.vertical", visible: false),
    QuickLink(id: "", label: "Feedback", icon: "exclamationmark.bubble", visible: true),
    QuickLink(id: "Map", label: "Map", icon: "map", visible: true)
]

#endif
