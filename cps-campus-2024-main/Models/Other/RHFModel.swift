//
//  RHFModel.swift
//  CampusApp
//
//  Created on 7/12/2024
//  Built by Marcus Gallardo, Rahim Malik.
//

import FirebaseFirestore

struct RHFDropIn: Identifiable, Codable, Hashable {
    
    let id = UUID()
    
    let title: String
    let date: String
    let startTime: String
    let endTime: String
    let instructor: String
    let blockID: String
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case date = "date"
        case startTime = "start_time"
        case endTime = "end_time"
        case instructor = "instructor"
        case blockID = "block_id"
    }
}

struct RHFPointCell: Codable {
    
    let id: String
    let points: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case points = "Points"
    }
}

class RHFObject: ObservableObject {
    
    @Published var dropIns: [RHFDropIn] = []
    
    @MainActor func fetchDropIns() async {
        let dropInReference = firestoreDB.collection("rhf-dropins")
        
        do {
            let snapshhot = try await dropInReference.getDocuments()
            let fetchedDropIns = try snapshhot.documents.compactMap { document in
                try document.data(as: RHFDropIn.self)
            }
            self.dropIns = fetchedDropIns
        } catch {
            ConsoleMessage(type: .data, description: "fetchDropIns - \(error.localizedDescription)").error()
        }
    }
    
    func fetchPoints(id: String) async throws -> String? {
        let spreadsheetURL = URL(string: "")
        
        if let wrappedURL = spreadsheetURL {
            let urlRequest = URLRequest(url: wrappedURL)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let wrappedResponse = response as? HTTPURLResponse {
                if wrappedResponse.statusCode == 200 {
                    let decodedCells = try JSONDecoder().decode([RHFPointCell].self, from: data)
                    return decodedCells.first(where: { $0.id == id})?.points
                }
            }
        }
        
        return nil
    }
    
    func getDropInsToday() -> [RHFDropIn] {
        return dropIns.filter { $0.date == Date().toString() }
    }
    
    func getDropInDates() -> [String] {
        var dates: [String] = []
        
        for dropIn in dropIns {
            if dates.contains(dropIn.date) == false {
                dates.append(dropIn.date)
            }
        }
        
        return dates
    }
}
