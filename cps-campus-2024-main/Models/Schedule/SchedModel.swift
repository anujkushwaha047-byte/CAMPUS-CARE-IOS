//
//  SchedModel.swift
//  CampusApp
//
//  Created on 6/13/2024
//  Built by Rahim Malik.
//

import FirebaseFirestore

struct Block: Codable, Hashable {
    let blockID: String
    let title: String
    let startTime: String
    let endTime: String
    var dates: [String]
    let type: BlockType
    
    enum CodingKeys: String, CodingKey {
        case blockID = "block_id"
        case title = "title"
        case startTime = "start_time"
        case endTime = "end_time"
        case dates = "dates"
        case type = "type"
    }
}

enum BlockType: String, Codable {
    case course
    case free
}

struct Holiday: Codable, Hashable {
    let holidayID: String
    let title: String
    var dates: [String]
    
    enum CodingKeys: String, CodingKey {
        case holidayID = "holiday_id"
        case title = "title"
        case dates = "dates"
    }
}

struct ScheduleData: Codable {
    let dates: [String]
    
    enum CodingKeys: String, CodingKey {
        case dates = "dates"
    }
}

class ScheduleObject: ObservableObject {
    
    @Published var blocks: [Block] = []
    @Published var holidays: [Holiday] = []
    @Published var scheduleData: [String: ScheduleData] = [:]
    
    func fetchSchedule() async {
        await fetchBlocks()
        await fetchHolidays()
        await fetchScheduleData()
    }
    
    @MainActor func fetchBlocks() async {
        let blockReference = firestoreDB.collection("blocks")
        
        do {
            let snapshot = try await blockReference.getDocuments()
            let fetchedBlocks = try snapshot.documents.compactMap { document in
                try document.data(as: Block.self)
            }
            self.blocks = fetchedBlocks
        } catch {
            ConsoleMessage(type: .data, description: "fetchBlocks - \(error.localizedDescription)").error()
        }
    }
    
    @MainActor func fetchHolidays() async {
        let holidayReference = firestoreDB.collection("holidays")
        
        do {
            let snapshot = try await holidayReference.getDocuments()
            let fetchedHolidays = try snapshot.documents.compactMap { document in
                try document.data(as: Holiday.self)
            }
            self.holidays = fetchedHolidays
        } catch {
            ConsoleMessage(type: .data, description: "fetchHolidays - \(error.localizedDescription)").error()
        }
    }
    
    @MainActor func fetchScheduleData() async {
        let scheduleReference = firestoreDB.collection("schedule")
        
        do {
            let snapshot = try await scheduleReference.getDocuments()
            var fetchedScheduleData: [String: ScheduleData] = [:]
            for document in snapshot.documents {
                if let entry = try? document.data(as: ScheduleData.self) {
                    fetchedScheduleData[document.documentID] = entry
                }
            }
            self.scheduleData = fetchedScheduleData
        } catch {
            ConsoleMessage(type: .data, description: "fetchScheduleData - \(error.localizedDescription)").error()
        }
    }
    
    static func getRotation(date: String, scheduleData: [String: ScheduleData]) -> String {
        if let rotation1Dates = scheduleData["rotation_1_dates"],
           let rotation2Dates = scheduleData["rotation_2_dates"],
           let rotation3Dates = scheduleData["rotation_3_dates"],
           let rotation4Dates = scheduleData["rotation_4_dates"] {
            if rotation1Dates.dates.contains(date) {
                return "1"
            } else if rotation2Dates.dates.contains(date) {
                return "2"
            } else if rotation3Dates.dates.contains(date) {
                return "3"
            } else if rotation4Dates.dates.contains(date) {
                return "4"
            } else {
                return ""
            }
        } else {
            return ""
        }
    }

    static func isCompass(block: Block, date: String, compass: UserCourse, gradYear: String?, scheduleData: [String: ScheduleData]) -> Bool {
        if block.title == compass.compassBlock {
            if let compassFreshDates = scheduleData["compass_fresh_dates"],
               let compassSophDates = scheduleData["compass_soph_dates"],
               let compassJuniorDates = scheduleData["compass_junior_dates"],
               let compassSeniorDates = scheduleData["compass_senior_dates"] {
                switch gradYear {
                case freshGradYear: return compassFreshDates.dates.contains(date)
                case sophGradYear: return compassSophDates.dates.contains(date)
                case juniorGradYear: return compassJuniorDates.dates.contains(date)
                case seniorGradYear: return compassSeniorDates.dates.contains(date)
                default: return false
                }
            } else {
                return false
            }
        }
        return false
    }
    
    static func isOpen(block: Block, date: String, gradYear: String?, scheduleData: [String: ScheduleData]) -> Bool {
        if block.title == "Advising" || block.title == "X-Block" {
            if let advisingFreshDates = scheduleData["advising_fresh_dates"],
               let advisingSophDates = scheduleData["advising_soph_dates"],
               let advisingJuniorDates = scheduleData["advising_junior_dates"],
               let advisingSeniorDates = scheduleData["advising_senior_dates"] {
                switch gradYear {
                case freshGradYear: return !advisingFreshDates.dates.contains(date)
                case sophGradYear: return !advisingSophDates.dates.contains(date)
                case juniorGradYear: return !advisingJuniorDates.dates.contains(date)
                case seniorGradYear: return !advisingSeniorDates.dates.contains(date)
                default: return false
                }
            } else {
                return false
            }
        } else if block.title == "X-Block" {
            if let xBlockFreshDates = scheduleData["x-block_fresh_dates"],
               let xBlockSophDates = scheduleData["x-block_soph_dates"],
               let xBlockJuniorDates = scheduleData["x-block_junior_dates"],
               let xBlockSeniorDates = scheduleData["x-block_senior_dates"] {
                switch gradYear {
                case freshGradYear: return !xBlockFreshDates.dates.contains(date)
                case sophGradYear: return !xBlockSophDates.dates.contains(date)
                case juniorGradYear: return !xBlockJuniorDates.dates.contains(date)
                case seniorGradYear: return !xBlockSeniorDates.dates.contains(date)
                default: return false
                }
            } else {
                return false
            }
        }
        return false
    }
    
    static func isFreePeriod(course: UserCourse, rotation: String) -> Bool {
        if course.freePeriod { return true }
        else if course.visibleRotation.isEmpty { return false }
        else if rotation.isEmpty { return false }
        else if course.visibleRotation == rotation { return false }
        else { return true }
    }
    
    func isSchoolDay(_ date: Date) -> Bool {
        let notificationDate = date
        for block in blocks {
            if block.dates.contains(notificationDate.toString(format: "yyyy-MM-dd")) {
                return true
            }
        }
        return false
    }
}
