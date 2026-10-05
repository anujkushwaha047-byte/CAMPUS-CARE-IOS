//
//  ClubModel.swift
//  CampusApp
//
//  Created on 7/12/2024
//  Designed by by Rahim Malik in California
//

import FirebaseFirestore

struct Club: Codable, Equatable, Hashable {
    let category: String
    let clubID: String
    let color: String
    let description: String
    let imageLink: String
    let leaders: [String]
    let name: String
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
        case category = "category"
        case clubID = "club_id"
        case color = "color"
        case description = "description"
        case imageLink = "image_link"
        case leaders = "leaders"
        case name = "name"
        case nickname = "nickname"
    }
}

struct ClubMeeting: Codable, Equatable, Hashable {
    let clubID: String?
    let date: String
    let endTime: String?
    let startTime: String?
    let location: String?
    let title: String
    let isBakeSale: Bool
    
    enum CodingKeys: String, CodingKey {
        case clubID = "club_id"
        case date = "date"
        case endTime = "end_time"
        case startTime = "start_time"
        case location = "location"
        case title = "title"
        case isBakeSale = "is_bake_sale"
    }
}

struct Email: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var to: [String]
    var cc: [String]
    var bcc: [String]
    var replyTo: [String]
    var subject: String
    var body: String
    var type: String
}

class ClubsObject: ObservableObject {
    
    @Published var clubs: [Club] = []
    @Published var ledClubs: [Club] = []
    @Published var joinedClubs: [String] = []
    @Published var hiddenClubs: [String] = []
    @Published var clubMeetings: [ClubMeeting] = []
    
    /// The suggested number of club meetings allowed to be scheduled each day.
    let suggestedMeetingLimit = 3
    
    private var ccEmails: [String]?
    private var bakeSaleEmails: [String]?
    private var clubMeetingEmails: [String]?
    
    /// Returns all clubs the user has joined, anonymous or not.
    func allJoinedClubs() -> [String] {
        return joinedClubs + hiddenClubs
    }
    
    /// Fetches all clubs from Firebase and updates the @Published "clubs" variable in ClubsObject.
    @MainActor func fetchClubs() async {
        let clubsReference = firestoreDB.collection("clubs")
        
        do {
            let snapshot = try await clubsReference.getDocuments()
            let fetchedClubs = try snapshot.documents.compactMap { document in
                try document.data(as: Club.self)
            }
            self.clubs = fetchedClubs
        } catch {
            ConsoleMessage(type: .data, description: "fetchClubs - \(error.localizedDescription)").error()
        }
    }
    
    /// Fetches all club meetings from Firebase and updates the @Published "clubsMeetings" variable in ClubsObject.
    @MainActor func fetchClubMeetings() async {
        let clubMeetingsReference = firestoreDB.collection("club-meetings")
        
        do {
            let snapshot = try await clubMeetingsReference.getDocuments()
            let fetchedClubMeetings = try snapshot.documents.compactMap { document in
                try document.data(as: ClubMeeting.self)
            }
            self.clubMeetings = fetchedClubMeetings
        } catch {
            ConsoleMessage(type: .data, description: "fetchClubMeetings - \(error.localizedDescription)").error()
        }
    }
    
    /// Fetches the users marked as club leaders for the given club.
    @MainActor func fetchClubLeaders(club: Club) async -> [User]? {
        do {
            let users = try await UserObject.fetchAllUsers()
            return users.filter({ club.leaders.contains($0.campusID) })
        } catch {
            ConsoleMessage(type: .data, description: "fetchClubLeaders - \(error.localizedDescription)").error()
        }
        
        return nil
    }
    
    /// Fetches the members of a given club who are not joined anonymously.
    /// Automatically filters leaders out of the member list.
    @MainActor func fetchClubMembers(club: Club) async -> [User]? {
        do {
            let users = try await UserObject.fetchAllUsers()
            return users.filter({ $0.clubs.contains(club.clubID) && club.leaders.contains($0.campusID) == false })
        } catch {
            ConsoleMessage(type: .data, description: "fetchClubMembers - \(error.localizedDescription)").error()
        }
        
        return nil
    }
    
    /// Fetches the list of clubs which the given user leads and updates the @Published ledClubs variable.
    @MainActor func fetchLedClubs(user: User) async {
        // Update the list of clubs before continuing
        await fetchClubs()
        self.ledClubs = clubs.filter { $0.leaders.contains(user.campusID) }
    }
    
    /// Returns the Club from the given club ID.
    /// Nil is returned if the club is not found.
    func getClubFromID(clubID: String) -> Club? {
        return clubs.filter({ $0.clubID == clubID }).first
    }
    
    /// Checks if the user has joined the given club.
    /// If the given user is nil, false is returned.
    func userHasJoinedClub(clubID: String, user: User?) -> Bool {
        if let wrappedUser = user {
            return wrappedUser.clubs.contains(clubID) || wrappedUser.hiddenClubs.contains(clubID)
        } else {
            return false
        }
    }
    
    /// Fetches all the clubs that the user has joined.
    /// Anonymously joined clubs are stored in ClubsObject.hiddenClubs.
    /// All other others are in ClubsObject.joinedClubs
    @MainActor func fetchJoinedClubs(user: User?) async {
        if let wrappedUser = user {
            joinedClubs = wrappedUser.clubs
            hiddenClubs = wrappedUser.hiddenClubs
        }
    }
    
    /// Allows the user to register for a new club.
    /// Updates the user's data in Firebase.
    func joinClub(clubID: String, isAnonymous: Bool, userObject: UserObject) async {
        
        if let wrappedUser = userObject.currentUser {
            // Update user data in Firebase
            var updatedClubs = isAnonymous ? wrappedUser.hiddenClubs : wrappedUser.clubs
            
            // Check if user has already joined
            if userHasJoinedClub(clubID: clubID, user: wrappedUser) == false {
                updatedClubs.append(clubID)
                
                if isAnonymous {
                    await userObject.updateUserPreferences(hiddenClubs: updatedClubs)
                } else {
                    await userObject.updateUserPreferences(clubs: updatedClubs)
                }
                
            }
        }
    }
    
    /// Allows the user to leave a club.
    /// Update's the user's data in Firebase.
    func leaveClub(clubID: String, userObject: UserObject) async {
        if let wrappedUser = userObject.currentUser {
            var clubs = wrappedUser.clubs
            var hiddenClubs = wrappedUser.hiddenClubs
            
            clubs.removeAll(where: { $0 == clubID })
            hiddenClubs.removeAll(where: { $0 == clubID })
            
            await userObject.updateUserPreferences(clubs: clubs, hiddenClubs: hiddenClubs)
        }
    }

    /// Requests that either a club meeting or bake sale be added to the appropriate calendars. Returns a boolean indicating whether the request was sucessful or not
    func requestMeeting(club: Club, isBakeSale: Bool, title: String, location: String, notes: String, date: Date, start: Date, end: Date) async -> Bool {
        
        let calendarID = ""
        let calendarLink: String = { () -> String in
            if isBakeSale {
                // Creates event with all-day time
                return String("https://www.google.com/calendar/u/0/event?action=TEMPLATE&dates=\(date.toString(format: "YYYYMMdd"))/\(date.toString(format: "YYYYMMdd"))&text=\(title.replacingOccurrences(of: " ", with: "+"))&location=\(location.replacingOccurrences(of: " ", with: "+"))&src=\(calendarID)")
            } else {
                // Creates event with start and end times
                return String("https://www.google.com/calendar/u/0/event?action=TEMPLATE&dates=\(start.toString(format: "YYYYMMdd'T'HHmm"))/\(end.toString(format: "YYYYMMdd'T'HHmm"))&text=\(title.replacingOccurrences(of: " ", with: "+"))&location=\(location.replacingOccurrences(of: " ", with: "+"))&src=\(calendarID)")
            }
        }()
        let emailBody = { () -> String in
            if isBakeSale {
                return """
                <p><a href="\(calendarLink)">Add Bake Sale to Clubs Calendar</a></p>
                <p><strong>Bake Sale Details</strong></p>
                <p>Club Name: \(club.name)<br />
                Date: \(date.toString(format: "EEEE, MMMM d, yyyy"))<br />
                Leaders: \(club.leaders.joined(separator: "@college-prep.org, "))@college-prep.org<br /><br />
                Sent from CPS Campus<br />
                Reply all to this email to contact the club<br />
                Contact the <a href="mailto:">Innovation Team</a> for assistance</p>
                """
            } else {
                return """
                <p><a href="\(calendarLink)">Add Meeting to Clubs Calendar</a></p>
                <p><strong>Meeting Details</strong></p>
                <p>Club Name: \(club.name)<br />
                Proposed Room: \(location)<br />
                Date: \(date.toString(format: "EEEE, MMMM d, yyyy"))<br />
                Time: \(start.toString(format: "h:mm a")) - \(end.toString(format: "h:mm a"))<br />
                Recurring Notes: \(notes)<br />
                Leaders: \(club.leaders.joined(separator: "@college-prep.org, "))@college-prep.org<br /><br />
                Sent from CPS Campus<br />
                Reply all to this email to contact the club<br />
                Contact the <a href="mailto:">Innovation Team</a> for assistance</p>
                """
            }
        }()
        
        let email = { () -> Email in
            if isBakeSale {
                return Email(to: bakeSaleEmails ?? [""], cc: ccEmails ?? [] , bcc: [], replyTo: club.leaders.map { $0+"@college-prep.org" }, subject: "\(club.nickname.isEmpty ? club.name : club.nickname) - Bake Sale Request", body: emailBody, type: "BAKE SALE REQUEST")

            } else {
                return Email(to: clubMeetingEmails ?? [""], cc: ccEmails ?? [], bcc: [], replyTo: club.leaders.map { $0+"@college-prep.org" }, subject: "\(club.nickname.isEmpty ? club.name : club.nickname) - Club Meeting Request", body: emailBody, type: "CLUB MEETING REQUEST")
            }
        }()
        
        do {
            try await sendEmailRequest(email: email)
            return true
        } catch {
            return false
        }
    }
    
    /// Asynchronously sends email requests for club meetings and bakesales.
    func sendEmailRequest(email: Email) async throws {
        let sendGridURL = "https://api.sendgrid.com/v3/mail/send"
        let sendGridAPIKey = ""
        
        if let url = URL(string: sendGridURL) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(sendGridAPIKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            var replyTo = [[String: String]]()
            for email in email.replyTo {
                replyTo.append(["email": email])
            }
            
            let json: [String:Any] = [
                "personalizations":[["to": [["email": email.to[0]]]]],
                "from": ["name":"CPS Campus", "email": ""],
                "reply_to_list": replyTo,
                "subject": email.subject,
                "content": [["type":"text/html", "value": email.body]]
            ]
            
            do {
                let emailData = try JSONSerialization.data(withJSONObject: json, options: [])
                request.httpBody = emailData
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 202 {
                        ConsoleMessage(type: .data, description: "Club event request sent").log()
                    } else {
                        ConsoleMessage(type: .data, description: "Status code \(httpResponse.statusCode) for club event request").error()
                    }
                }
            } catch {
                ConsoleMessage(type: .data, description: "Email send error").error()
            }
        }
    }
    
    /// Fetches the email addresses which email requests should be sent to
    func fetchRequestEmails() async {
        self.ccEmails = await fetchEmails("cc")
        self.bakeSaleEmails = await fetchEmails("bake-sale")
        self.clubMeetingEmails = await fetchEmails("club-meeting")
        
        func fetchEmails(_ docPath: String) async -> [String]? {
            let docRef = firestoreDB.collection("club-email-recipients").document(docPath)
            
            do {
                let doc = try await docRef.getDocument()
                
                guard doc.exists else {
                    throw ConsoleMessage(type: .data, description: "email document not found")
                }
                
                return try doc.data(as: [String:[String]].self)["emails"]
            } catch {
                ConsoleMessage(type: .data, description: "fetchRequestEmails - \(error)").error()
            }
            
            return nil
        }
    }
}
