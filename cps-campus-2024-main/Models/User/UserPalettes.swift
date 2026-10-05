//
//  UserPalettes.swift
//  CampusApp
//
//  Created on 6/25/2024
//  Built by Rahim Malik.
//

import SwiftUI
import FirebaseFirestore

/// A structure representing a color palette.
struct Palette: Codable, Hashable, Equatable {
    
    var name: String
    var colors: [String]
    var campusID: String
    var creator: String
    var collection: String
    
    /// Enum for coding keys to match Firestore document fields.
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case colors = "colors"
        case campusID = "campus_id"
        case creator = "creator"
        case collection = "collection"
    }
}

/// Fetches all palettes from the Firestore "palettes" collection.
/// - Returns: An array of `Palette` objects.
func fetchPalettes() async throws -> [Palette] {
    let paletteReference = firestoreDB.collection("palettes")
    
    do {
        let snapshot = try await paletteReference.getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: Palette.self)
        }
    } catch {
        throw error
    }
}

/// Extension for `UserObject` to manage user palettes.
extension UserObject {
    
    /// Recolors the user's courses using the provided palette.
    /// - Parameter palette: The `Palette` object to use for recoloring.
    func recolorCourses(_ palette: Palette) async {
        for index in allCourseIDs.indices {
            if var userCourse = courses.first(where: { $0.courseID == allCourseIDs[index] }) {
                if index >= palette.colors.count {
                    userCourse.color = palette.colors.last ?? Color.gray.toP3HexString()
                } else {
                    userCourse.color = palette.colors[index]
                }
                await updateCourse(userCourse)
            }
        }
    }
    
    /// Generates a `Palette` object from the user's courses.
    /// - Returns: A `Palette` object.
    func generatePaletteFromCourses(name: String = "") -> Palette {
        var colors = [String]()
        
        for index in 0..<min(9, allCourseIDs.count) {
            if let userCourse = courses.first(where: { $0.courseID == allCourseIDs[index] }) {
                colors.append(userCourse.color)
            }
        }
        
        while colors.count < 9 {
            colors.append(Color.systemCellSecondary.toP3HexString())
        }
        
        if let user = currentUser {
            return Palette(name: name, colors: colors, campusID: user.campusID, creator: user.name, collection: "")
        } else {
            return Palette(name: name, colors: colors, campusID: "", creator: "", collection: "")
        }
    }
    
    /// Fetches custom palettes for the current user from Firestore.
    /// - Returns: An array of `Palette` objects.
    func fetchCustomPalettes() async throws -> [Palette] {
        guard let campusID = currentUser?.campusID else {
            throw ConsoleMessage(type: .internal, description: "fetchPalettes - campusID not found")
        }
        
        let paletteReference = firestoreDB.collection("users").document(campusID).collection("palettes")
        
        let querySnapshot = try await paletteReference.getDocuments()
        
        var palettes = [Palette]()
        
        for document in querySnapshot.documents {
            do {
                let palette = try document.data(as: Palette.self)
                palettes.append(palette)
            } catch {
                ConsoleMessage(type: .data, description: "fetchPalettes - Error decoding palette: \(error.localizedDescription)").error()
            }
        }
        
        return palettes
    }
    
    /// Updates a custom palette for the current user in Firestore.
    /// - Parameter palette: The `Palette` object to update.
    func updateCustomPalette(_ palette: Palette) async throws {
        guard let campusID = currentUser?.campusID else {
            throw ConsoleMessage(type: .internal, description: "updatePalette - campusID not found")
        }
        
        let paletteID = palette.colors.joined(separator: "-").lowercased().replacingOccurrences(of: "#", with: "")
        let paletteReference = firestoreDB.collection("users").document(campusID).collection("palettes").document(paletteID)
        
        do {
            try await paletteReference.setData(palette.toDictionary())
        } catch {
            throw ConsoleMessage(type: .data, description: "updatePalette - \(error.localizedDescription)")
        }
    }
    
    /// Removes a custom palette for the current user from Firestore.
    /// - Parameter palette: The `Palette` object to remove.
    func removeCustomPalette(_ palette: Palette) async throws {
        guard let campusID = currentUser?.campusID else {
            throw ConsoleMessage(type: .internal, description: "removeCustomPalette - campusID not found")
        }
        
        let paletteID = palette.colors.joined(separator: "-").lowercased().replacingOccurrences(of: "#", with: "")
        let paletteReference = firestoreDB.collection("users").document(campusID).collection("palettes").document(paletteID)
        
        do {
            try await paletteReference.delete()
        } catch {
            throw ConsoleMessage(type: .data, description: "removeCustomPalette - \(error.localizedDescription)")
        }
    }
    
    /// Publishes a palette to the global Firestore "palettes" collection.
    /// - Parameters:
    ///   - palette: The `Palette` object to publish.
    ///   - anonymous: A boolean indicating whether to publish anonymously.
    func publishPalette(_ palette: Palette, anonymous: Bool) async throws {
        guard let campusID = currentUser?.campusID else {
            throw ConsoleMessage(type: .internal, description: "publishPalette - campusID not found")
        }
        
        let paletteID = palette.colors.joined(separator: "-").lowercased().replacingOccurrences(of: "#", with: "")
        let paletteReference = firestoreDB.collection("palettes").document(paletteID)
        
        let document = try await paletteReference.getDocument()
        if document.exists {
            throw ConsoleMessage(type: .data, description: "publishPalette - A palette with identical colors already exists.")
        }
        
        var updatedPalette = palette
        updatedPalette.campusID = campusID
        updatedPalette.collection = "New"
        updatedPalette.creator = ""
        if !anonymous, let name = currentUser?.name {
            updatedPalette.creator = name
        }
        
        try await paletteReference.setData(updatedPalette.toDictionary())
    }
    
    /// Unpublishes a palette from the global Firestore "palettes" collection.
    /// - Parameter palette: The `Palette` object to unpublish.
    func unpublishPalette(_ palette: Palette) async throws {
        guard let campusID = currentUser?.campusID else {
            throw ConsoleMessage(type: .internal, description: "deletePalette - campusID not found")
        }
        
        let paletteID = palette.colors.joined(separator: "-").lowercased().replacingOccurrences(of: "#", with: "")
        let paletteReference = firestoreDB.collection("palettes").document(paletteID)
        
        let document = try await paletteReference.getDocument()
        
        do {
            let existingPalette = try document.data(as: Palette.self)
            
            if existingPalette.campusID != campusID {
                throw ConsoleMessage(type: .data, description: "deletePalette - You do not have permission to delete this palette")
            }
            
            try await paletteReference.delete()
        } catch {
            throw ConsoleMessage(type: .data, description: "deletePalette - Palette document not found or cannot be decoded")
        }
    }
}
