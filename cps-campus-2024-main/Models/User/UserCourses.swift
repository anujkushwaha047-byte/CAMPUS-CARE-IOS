//
//  UserCourses.swift
//  CampusApp
//
//  Created on 6/13/2024
//  Built by Rahim Malik.
//

import FirebaseFirestore

/// A structure representing a user's course.
struct UserCourse: Codable, Hashable {
    var courseID: String
    
    var name: String
    var room: String
    var teacher: String
    var freePeriod: Bool
    var color: String
    
    var compassBlock: String // empty except for Compass
    var visibleRotation: String // empty means all rotations possible
    var canvasID: String?
    
    /// Enum for coding keys to match Firestore document fields.
    enum CodingKeys: String, CodingKey {
        case courseID = "course_id"
        
        case name = "name"
        case room = "room"
        case teacher = "teacher"
        case freePeriod = "free_period"
        case color = "color"
        
        case compassBlock = "compass_block"
        case visibleRotation = "visible_rotation"
        case canvasID = "canvas_id"
    }
}

/// Extension for `UserObject` to manage user courses.
extension UserObject {
    
    /// Fetches all courses for a given user from Firestore asynchronously.
    /// - Parameters:
    ///   - campusID: The unique campus identifier of the user.
    /// - Returns: An array of `UserCourse` objects representing the fetched courses.
    /// - Throws: A `ConsoleMessage` if fetching the course data fails.
    static func fetchCourses(campusID: String) async throws -> [UserCourse] {
        let coursesReference = firestoreDB.collection("users").document(campusID).collection("courses")
        
        do {
            let querySnapshot = try await coursesReference.getDocuments()
            let courses = try querySnapshot.documents.map { document in
                return try document.data(as: UserCourse.self)
            }
            
            return courses
        } catch {
            throw ConsoleMessage(type: .internal, description: "fetchAllCourses - \(error.localizedDescription)")
        }
    }
    
    /// Initializes courses for a user with given course IDs.
    /// - Parameter courseIDs: Array of course IDs to initialize.
    func initCourses(courseIDs: [String]) async throws {
        guard let campusID = currentUser?.campusID else {
            ConsoleMessage(type: .internal, description: "initCourses - campusID not found").error()
            return
        }
        
        let courseReference = firestoreDB.collection("users").document(campusID).collection("courses")
        
        for courseID in courseIDs {
            let course = UserCourse(
                courseID: courseID,
                name: courseID,
                room: "",
                teacher: "",
                freePeriod: false,
                color: defaultPalette[courseID, default: ""],
                compassBlock: "",
                visibleRotation: "",
                canvasID: nil
            )
            
            do {
                let documentID = courseID.lowercased().replacingOccurrences(of: " ", with: "_")
                try courseReference.document(documentID).setData(from: course)
            } catch let error {
                ConsoleMessage(type: .data, description: "initCourses - Error adding course \(courseID): \(error.localizedDescription)").error()
            }
        }
    }
    
    /// Adds a Firestore listener to monitor changes in user courses.
    func addCourseListener() async {
        guard let campusID = currentUser?.campusID else {
            ConsoleMessage(type: .internal, description: "addCourseListener - campusID not found").error()
            return
        }
        
        let courseReference = firestoreDB.collection("users").document(campusID).collection("courses")
        
        courseListener = courseReference.addSnapshotListener(includeMetadataChanges: true) { [weak self] collection, error in
            guard let self = self else {
                ConsoleMessage(type: .internal, description: "addCourseListener - weak self uninitialized").error()
                return
            }
            
            if let error = error {
                ConsoleMessage(type: .data, description: "\(error.localizedDescription)").error()
                return
            }
            
            guard let snapshot = collection else {
                ConsoleMessage(type: .data, description: "addCourseListener - watchlist snapshot not found").error()
                return
            }
            
            var tempCourses = [UserCourse]()
            
            for document in snapshot.documents {
                do {
                    tempCourses.append(try document.data(as: UserCourse.self))
                } catch {
                    ConsoleMessage(type: .data, description: "addCourseListener - \(error.localizedDescription)").error()
                    Task {
                        do {
                            try await self.initCourses(courseIDs: allCourseIDs)
                        } catch {
                            ConsoleMessage(type: .data, description: "initCourses - \(error.localizedDescription)").error()
                        }
                    }
                }
            }
            
            if !tempCourses.isEmpty {
                courses = tempCourses
            } else {
                Task {
                    do {
                        try await self.initCourses(courseIDs: allCourseIDs)
                    } catch {
                        ConsoleMessage(type: .data, description: "initCourses - \(error.localizedDescription)").error()
                    }
                }
            }
        }
    }
    
    /// Removes the Firestore listener for user courses.
    func removeCourseListener() {
        courseListener?.remove()
        courseListener = nil
    }
    
    /// Updates a specific course for the user in Firestore.
    /// - Parameter course: The course to update.
    func updateCourse(_ course: UserCourse) async {
        if let wrappedUser = currentUser {
            let courseReference = firestoreDB.collection("users").document(wrappedUser.campusID).collection("courses").document(course.courseID.lowercasedWithUnderscores())
            
            let updatedData = course.toDictionary()
            
            do {
                try await courseReference.updateData(updatedData)
            } catch {
                ConsoleMessage(type: .data, description: "updateCourse - \(error.localizedDescription)").error()
            }
        } else {
            ConsoleMessage(type: .data, description: "updateCourse - current user uninitialized").error()
        }
    }
}
