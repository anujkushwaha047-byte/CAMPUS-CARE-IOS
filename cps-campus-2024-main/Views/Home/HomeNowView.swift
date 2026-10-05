//
//  HomeNowView.swift
//  CampusApp
//
//  Created on 7/11/2021
//  Built by Rahim Malik.
//

import SwiftUI

//TODO: Test
struct HomeNowView: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 10) {
            let rotation = ScheduleObject.getRotation(date: Date().toString(), scheduleData: scheduleObject.scheduleData)
            HStack {
                Text(Date().toString(format: "EEE, MMM d"))
                    .subheading()
                Spacer()
                if !rotation.isEmpty {
                    Image(systemName: rotation+".circle")
                        .body()
                }
            }
            .flushLeading(padding: true)
            
            TimelineView(.periodic(from: Date(), by: 0.5)) { _ in
                if let blocks = Optional(scheduleObject.blocks.filter { $0.dates.contains(Date().toString()) }.sorted { $0.startTime < $1.startTime }), !blocks.isEmpty {
                    if let currentBlock = blocks.first(where: { $0.endTime > Date().toString(format: "HH:mm:ss") }) {
                        if blocks.first == currentBlock && currentBlock.startTime > Date().toString(format: "HH:mm:ss") {
                            
                            HomeNowCell(block: currentBlock, date: Date(), rotation: rotation, current: false)
                        } else if currentBlock.startTime > Date().toString(format: "HH:mm:ss") {
                            if let previousBlock = blocks.element(before: currentBlock) {
                                let passing = Block(blockID: "passing", title: "Passing Period", startTime: previousBlock.endTime, endTime: currentBlock.startTime, dates: [Date().toString()], type: .free)
                                HomeNowCell(block: passing, date: Date(), rotation: rotation, current: true)
                            }
                            HomeNowCell(block: currentBlock, date: Date(), rotation: rotation, current: false)
                        } else {
                            HomeNowCell(block: currentBlock, date: Date(), rotation: rotation, current: true)
                            if let nextBlock = blocks.first(where: { $0.startTime >= Date().toString(format: "HH:mm:ss") }) {
                                HStack {
                                    Text("Passing Period")
                                        .body(weight: .semibold)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Text(passingTimeDifference(from: String(Date().toString(format: "yyyy-MM-dd ") + currentBlock.endTime).toDate(format: "yyyy-MM-dd HH:mm:ss"), to: String(Date().toString(format: "yyyy-MM-dd ") + nextBlock.startTime).toDate(format: "yyyy-MM-dd HH:mm:ss")))
                                        .body()
                                        .foregroundStyle(.gray)
                                }
                                .borderedCellStyle()
                                HomeNowCell(block: nextBlock, date: Date(), rotation: rotation, current: false)
                            }
                        }
                    } else {
                        Button {
                            generateHaptic(.selection)
                            openURL(URL(string: "cpscampus://schedule")!)
                        } label: {
                            Text("See Schedule")
                                .body(weight: .semibold)
                                .foregroundStyle(.accent)
                                .flushCenter()
                                .borderedCellStyle()
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        generateHaptic(.selection)
                        openURL(URL(string: "cpscampus://schedule")!)
                    } label: {
                        Text("See Schedule")
                            .body(weight: .semibold)
                            .foregroundStyle(.accent)
                            .flushCenter()
                            .borderedCellStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    func passingTimeDifference(from startDate: Date, to endDate: Date) -> String {
        
        let components = systemCalendar.dateComponents([.hour, .minute, .second], from: startDate, to: endDate)
        let minutes = components.minute ?? 0
        
        var result = ""
        result += String(format: "%2d min", minutes)
        
        return result
    }
    
    struct HomeNowCell: View {
        
        @EnvironmentObject var userObject: UserObject
        @EnvironmentObject var scheduleObject: ScheduleObject
        @EnvironmentObject var ccObject: CCObject
        
        @Environment(\.colorScheme) var colorScheme
        @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
        
        let block: Block
        var date: Date
        let rotation: String
        let current: Bool
        
        var body: some View {
            let (title, time, backgroundColor, description, timeDifferenceText) = getProperties(block: block, date: date, rotation: rotation, current: current)
            
            VStack(spacing: 12.5) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .body(weight: .semibold)
                            .multilineTextAlignment(.leading)
                        Text(time)
                            .body()
                            .foregroundStyle(.gray)
                        if let description = description, !description.isEmpty {
                            Text(description)
                                .body()
                                .foregroundStyle(.gray)
                        }
                    }
                    .flushLeading()
                    Text(timeDifferenceText)
                        .body()
                        .padding(5)
                        .coloredCellStyle(backgroundColor, cornerRadius: 12.5)
                }
                if current {
                    NowProgressBar(date: date, startDate: String(date.toString(format: "yyyy-MM-dd ") + block.startTime).toDate(format: "yyyy-MM-dd HH:mm:ss"), endDate: String(date.toString(format: "yyyy-MM-dd ") + block.endTime).toDate(format: "yyyy-MM-dd HH:mm:ss"), color: backgroundColor)
                }
            }
            .borderedCellStyle()
        }
        
        func getProperties(block: Block, date: Date, rotation: String, current: Bool) -> (String, String, Color, String?, String) {
            let dateString = date.toString()
            let time = "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))"
            let timeDifferenceText = timeDifference(from: date, to: current ? String(date.toString(format: "yyyy-MM-dd ") + block.endTime).toDate(format: "yyyy-MM-dd HH:mm:ss") : String(date.toString(format: "yyyy-MM-dd ") + block.startTime).toDate(format: "yyyy-MM-dd HH:mm:ss"))
            
            if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }), ScheduleObject.isCompass(block: block, date: dateString, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                return (
                    compass.name,
                    time,
                    compass.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme),
                    [compass.teacher, compass.room].filter { !$0.isEmpty }.joined(separator: " | "),
                    timeDifferenceText
                )
            } else if ScheduleObject.isOpen(block: block, date: dateString, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                return (
                    "Open",
                    time,
                    .gray,
                    nil,
                    timeDifferenceText
                )
            } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
                if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                    return (
                        "Free Period",
                        time,
                        .gray,
                        nil,
                        timeDifferenceText
                    )
                } else if block.title == "Common Classroom", let commonClassroom = ccObject.currentCC, let ccTitle = commonClassroom.title, let ccRoom = commonClassroom.room, let date = commonClassroom.dateRaw, date == Date().toString(format: "yyyy-MM-dd") {
                    return (
                        ccTitle,
                        time,
                        defaultPalette[block.title]?.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme) ?? .gray,
                        ccRoom,
                        timeDifferenceText
                    )
                } else {
                    return (
                        course.name,
                        time,
                        course.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme),
                        [course.teacher, course.room].filter { !$0.isEmpty }.joined(separator: " | "),
                        timeDifferenceText
                    )
                }
            } else {
                return (
                    block.title,
                    time,
                    defaultPalette[block.title]?.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme) ?? .gray,
                    nil,
                    timeDifferenceText
                )
            }
            
            func timeDifference(from startDate: Date, to endDate: Date) -> String {
                
                let components = systemCalendar.dateComponents([.hour, .minute, .second], from: startDate, to: endDate)
                let hours = components.hour ?? 0
                let minutes = components.minute ?? 0
                let seconds = components.second ?? 0
                
                var result = ""
                if hours > 0 {
                    result += "\(hours):"
                }
                result += String(format: "%02d:", minutes)
                result += String(format: "%02d", seconds)
                
                return result
            }
        }
        
        struct NowProgressBar: View {
            var date: Date
            
            let startDate: Date
            let endDate: Date
            let color: Color
            
            var body: some View {
                ZStack {
                    GeometryReader { geo in
                        Capsule()
                            .frame(width: geo.size.width, height: 10)
                            .foregroundStyle(.systemCellSecondary)
                        HStack {
                            Capsule()
                                .frame(width: geo.size.width * CGFloat((date.timeIntervalSince(startDate)/(endDate.timeIntervalSince(startDate)))), height: 10)
                                .foregroundStyle(color)
                                .animation(.linear, value: date)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
