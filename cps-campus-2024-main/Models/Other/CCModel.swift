//
//  CCModel.swift
//  CampusApp
//
//  Created on 7/12/2024
//  Built by Marcus Gallardo, Rahim Malik.
//

import FirebaseFirestore

struct CommonClassroom: Codable, Hashable {
    
    let title: String?
    let room: String?
//    let dateLabel: String?
//    let hosts: String?
//    let published: Bool?
    let dateRaw: String?
//    let description: String?
//    let maxAttendees: String?
//    let notes: String?
//    let overflow: String?
//    let publishDate: String?
//    let submitDate: String?
//    let submitter: String?
//    let coasterID: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case room = "room"
//        case dateLabel = "dateLabel"
//        case hosts = "hosts"
//        case published = "published"
        case dateRaw = "dateRaw"
//        case description = "description"
//        case maxAttendees = "maximumAttendees"
//        case notes = "notes"
//        case overflow = "overflow"
//        case publishDate = "publishDate"
//        case submitDate = "submitDate"
//        case submitter = "submitter"
//        case coasterID = "coasterId"
    }
}

class CCObject: ObservableObject {
    
    @Published var currentCC: CommonClassroom?
    
    @MainActor func fetchUserCC(user: User) async throws {
        let userDocRef = firestoreDB.collection("cc-users").document(user.campusID)
        let userDocument = try await userDocRef.getDocument()
        
        if let currentSignup = userDocument.get("commonClassroom") as? String, !currentSignup.isEmpty {
            let ccDocRef = firestoreDB.collection("common-classrooms").document(currentSignup)
            let ccDoc = try await ccDocRef.getDocument()
            
            currentCC = try ccDoc.data(as: CommonClassroom.self)
        } else {
            currentCC = nil
        }
    }
}
