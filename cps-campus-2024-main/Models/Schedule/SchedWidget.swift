//
//  SchedWidget.swift
//  CampusApp, CampusWidget
//
//  Created on 7/12/2024
//  Built by Rahim Malik.
//

import SwiftUI

struct WidgetBlock: Identifiable, Codable, Hashable {
    var id = UUID()
    
    let title: String
    let startTime: String
    let endTime: String
    let date: String
    let rotation: String
    let color: String // empty if block.type == .free
}

#if APP
func fetchWidgetBlocks(scheduleObject: ScheduleObject, userObject: UserObject) async -> [WidgetBlock] {
    let currentDate = Date().toString()
    let endDate = Date().addDays(14)?.toString() ?? currentDate
    
    var widgetBlocks: [WidgetBlock] = []
    
    for block in scheduleObject.blocks {
        for date in block.dates {
            if currentDate <= date && date <= endDate {
                let rotation = ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData)
                let (title, color) = await getProperties(block: block, date: date, rotation: rotation, userObject: userObject, scheduleObject: scheduleObject)
                
                let widgetBlock = WidgetBlock(
                    title: title,
                    startTime: block.startTime,
                    endTime: block.endTime,
                    date: date,
                    rotation: rotation,
                    color: color ?? ""
                )
                
                widgetBlocks.append(widgetBlock)
            }
        }
    }
    
    return widgetBlocks
    
    func getProperties(block: Block, date: String, rotation: String, userObject: UserObject, scheduleObject: ScheduleObject) async -> (String, String?) {
        if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }), ScheduleObject.isCompass(block: block, date: date, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return (compass.name, compass.color)
        } else if ScheduleObject.isOpen(block: block, date: date, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return ("Open", nil)
        } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
            if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                return ("Free Period", nil)
            } else {
                return (course.name, course.color)
            }
        } else {
            return (block.title, defaultPalette[block.title])
        }
    }
}
#endif
