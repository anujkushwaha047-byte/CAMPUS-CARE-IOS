//
//  UserModel.swift
//  CampusApp
//
//  Created on 6/13/2024
//  Built by Rahim Malik.
//

import FirebaseFirestore
import FirebaseAuth

/// Represents a user profile stored in Firestore.
struct User: Codable, Hashable {
    var campusID: String
    var name: String
    var gradYear: String
    var imageLink: String
    
    var pronouns: String
    var bio: String
    var privacy: [String: Bool]
    var socials: [String: String]
    
    /// The list of club IDs representing the  clubs that a user has joined.
    /// These clubs will be publically viewable.
    var clubs: [String]
    
    /// The list of club IDs representing the non clubs that a user has joined.
    /// Others cannot see that the user has joined these clubs.
    var hiddenClubs: [String]
    
    var sports: [String]
    
    var parents: [String]
    
    enum CodingKeys: String, CodingKey {
        case campusID = "campus_id"
        case name = "name"
        case gradYear = "grad_year"
        case imageLink = "image_link"
        
        case pronouns = "pronouns"
        case bio = "bio"
        case privacy = "privacy"
        case socials = "socials"
        
        case clubs = "clubs"
        case hiddenClubs = "hidden_clubs"
        case sports = "sports"
        case parents = "parents"
    }
}

/// Observable object managing the current user's profile and associated courses.
class UserObject: ObservableObject {
    
    /// Current user's profile.
    @Published var currentUser: User?
    
    /// List of courses associated with the current user.
    @Published var courses: [UserCourse]
    
    /// The currently selected child for users signed in as parents.
    @Published var currentChild: User? {
        didSet {
            if let child = currentChild {
                KeychainManager.manager.saveToken(child.campusID, tokenID: "childCampusID")
            } else {
                KeychainManager.manager.delete("childCampusID")
            }
        }
    }
    
    @Published var childCampusIDs: [String] {
        didSet {
            if childCampusIDs.isEmpty {
                KeychainManager.manager.delete("childCampusIDs")
                
            } else {
                KeychainManager.manager.saveArray(childCampusIDs, arrayID: "childCampusIDs")
            }
        }
    }
    
    /// Listener for changes in the user's profile data.
    var userListener: ListenerRegistration?
    
    /// Listener for changes in the user's enrolled courses.
    var courseListener: ListenerRegistration?
    
    /// Initializes `UserObject` with default values.
    init() {
        currentUser = nil
        currentChild = nil
        childCampusIDs = []
        courses = []
    }
    
    /// Fetches a user profile from Firestore asynchronously.
    /// - Parameters:
    ///   - campusID: The unique campus identifier of the user.
    /// - Returns: A `User` object representing the fetched user profile.
    /// - Throws: A `ConsoleMessage` if fetching the user data fails.
    static func fetchUser(campusID: String) async throws -> User {
        let userReference = firestoreDB.collection("users").document(campusID)
        
        do {
            let document = try await userReference.getDocument()
            
            guard document.exists else {
                throw ConsoleMessage(type: .data, description: "fetchUser - user document not found")
            }
            
            return try document.data(as: User.self)
        } catch {
            throw ConsoleMessage(type: .internal, description: "fetchUser - \(error.localizedDescription)")
        }
    }
    
    /// Fetches the courses of a user profile from Firestore asynchronously.
    /// - Parameters:
    ///   - campusID: The unique campus identifier of the user.
    /// - Returns: An array of `UserCourse` representing the fetched user courses.
    /// - Throws: A `ConsoleMessage` if fetching the user courses fails.
    static func fetchUserCourses(campusID: String) async throws -> [UserCourse] {
        let coursesReference = firestoreDB.collection("users").document(campusID).collection("courses")
        
        do {
            let documents = try await coursesReference.getDocuments()
            
            guard documents.isEmpty == false else {
                throw ConsoleMessage(type: .data, description: "fetchUserCourses - course documents not found")
            }
            
            var courses: [UserCourse] = []
            
            for doc in documents.documents {
                courses.append(try doc.data(as: UserCourse.self))
            }
            
            return courses
        } catch {
            throw ConsoleMessage(type: .internal, description: "fetchUserCourses - \(error.localizedDescription)")
        }
    }
    
    /// Fetches the users stored in the Keychain from Firestore asynchronously.
    /// - Parameters:
    ///   - campusIDs: A string array of all the child campus IDs.
    /// - Returns: An array of `User` representing the fetched users.
    static func fetchChildren(_ campusIDs: [String]) async -> [User] {
        var children: [User] = []
        for campusID in campusIDs {
            do {
                let child = try await fetchUser(campusID: campusID)
                children.append(child)
            } catch {
                ConsoleMessage(type: .data, description: "fetchChildren - \(error)").error()
            }
        }
        return children
    }
    
    /// Fetches all user profiles from Firestore asynchronously.
    /// - Returns: An array of `User` objects representing the fetched user profiles.
    /// - Throws: A `ConsoleMessage` if fetching the user data fails.
    static func fetchAllUsers() async throws -> [User] {
        let usersReference = firestoreDB.collection("users")
        do {
            let querySnapshot = try await usersReference.getDocuments()
            var users: [User] = []
            for document in querySnapshot.documents {
                do {
                    try users.append(document.data(as: User.self))
                } catch {
                    ConsoleMessage(type: .data, description: "fetchAllUsers - Failed to decode user: \(error)").error()
                }
            }
            return users
        } catch {
            ConsoleMessage(type: .data, description: "fetchAllUsers - \(error)").error()
            throw error
        }
    }
    
    /// Adds a snapshot listener to observe changes in the user's profile data.
    /// - Parameter campusID: The unique campus identifier of the user.
    func addUserListener(campusID: String) {
        let userReference = firestoreDB.collection("users").document(campusID)
        
        userListener = userReference.addSnapshotListener(includeMetadataChanges: false) { [weak self] document, error in
            guard let self = self else {
                ConsoleMessage(type: .internal, description: "addUserListener - weak self uninitialized").error()
                return
            }
            
            if let error = error {
                ConsoleMessage(type: .data, description: "\(error.localizedDescription)").error()
                return
            }
            
            guard let document = document, document.exists else {
                ConsoleMessage(type: .data, description: "addUserListener - user document not found").error()
                return
            }
            
            do {
                self.currentUser = try document.data(as: User.self)
            } catch {
                ConsoleMessage(type: .data, description: "addUserListener - \(error.localizedDescription)").error()
            }
        }
    }
    
    /// Removes the snapshot listener observing changes in the user's profile data.
    func removeUserListener() {
        userListener?.remove()
        userListener = nil
    }
    
    /// Updates the user's profile preferences in Firestore asynchronously.
    /// - Parameters:
    ///   - pronouns: Optional new pronouns to update.
    ///   - bio: Optional new biography to update.
    ///   - privacy: Optional new privacy settings to update.
    ///   - socials: Optional new social links to update.
    ///   - clubs: Optional new clubs to update.
    ///   - hiddenClubs: Optional new anonymous clubs to update.
    func updateUserPreferences(pronouns: String? = nil, bio: String? = nil, privacy: [String: Bool]? = nil, socials: [String: String]? = nil, clubs: [String]? = nil, hiddenClubs: [String]? = nil, parents: [String]? = nil) async {
        if let wrappedUser = currentUser {
            let userReference = firestoreDB.collection("users").document(wrappedUser.campusID)
            
            let updatedData: [String: Any] = ["pronouns": pronouns ?? wrappedUser.pronouns,
                                              "bio": bio ?? wrappedUser.bio,
                                              "privacy": privacy ?? wrappedUser.privacy,
                                              "socials": socials ?? wrappedUser.socials,
                                              "clubs": clubs ?? wrappedUser.clubs,
                                              "hidden_clubs": hiddenClubs ?? wrappedUser.hiddenClubs,
                                              "parents": parents ?? wrappedUser.parents]
            do {
                try await userReference.updateData(updatedData)
            } catch {
                ConsoleMessage(type: .data, description: "updateUser - \(error.localizedDescription)").error()
            }
        } else {
            ConsoleMessage(type: .data, description: "createUser - current user uninitialized").error()
        }
    }
    
    /// Removes the current user's profile and associated data.
    func removeUser() {
        removeUserListener()
        removeCourseListener()
        
        courses.removeAll()
        
        currentUser = nil
    }
    
    func removeChildren() {
        currentChild = nil
        courses.removeAll()
        childCampusIDs.removeAll()
    }
}
