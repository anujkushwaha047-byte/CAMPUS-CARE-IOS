//
//  SchedWeekView.swift
//  CampusApp
//
//  Created on 7/9/2021
//  Built by Rahim Malik.
//

import SwiftUI

struct ScheduleWeekView: View {
    
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Binding var selectedDate: Date
    
    let dateRange: ClosedRange<Int> = -365...365
    
    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if #available(iOS 17.0, macOS 20.0, *) { // basically not on macOS
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: -7.5) {
                            ForEach(dateRange, id: \.self) { dayOffset in
                                if let date = getDateFromOffset(selectedDate, dayOffset: dayOffset) {
                                    ScheduleWeekPage(date: date, rotation: ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData))
                                        .id(date)
#if os(iOS)
                                        .frame(width: 150)
#elseif os(macOS)
                                        .frame(width: 135)
#endif
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.never)
                    .scrollTargetBehavior(.viewAligned)
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: -7.5) {
                            ForEach(dateRange, id: \.self) { dayOffset in
                                if let date = getDateFromOffset(selectedDate, dayOffset: dayOffset) {
                                    ScheduleWeekPage(date: date, rotation: ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData))
                                        .id(date)
#if os(iOS)
                                        .frame(width: 150)
#elseif os(macOS)
                                        .frame(width: 135)
#endif
                                }
                            }
                        }
                    }
                    .scrollIndicators(.never)
                }
            }
            .onAppear {
                proxy.scrollTo(selectedDate.toString(), anchor: .leading)
            }
            .onChange(of: selectedDate) { _ in
                withAnimation {
                    proxy.scrollTo(selectedDate.toString(), anchor: .leading)
                }
            }
        }
    }
    
    private func getDateFromOffset(_ date: Date, dayOffset: Int) -> String? {
        return date.addDays(dayOffset)?.toString()
    }
}

struct ScheduleWeekPage: View {

    @EnvironmentObject var scheduleObject: ScheduleObject
    
    let date: String
    let rotation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            WeekPageHeader(date: date, rotation: rotation)
                .padding(.bottom, 5)
            if let holiday = scheduleObject.holidays.first(where: { $0.dates.contains(date) }) {
                VStack(alignment: .leading) {
                    Text(holiday.title)
                        .scheduleLabel()
                        .fontWeight(.semibold)
                        .foregroundStyle(.systemContrast.opacity(0.75))
                        .flushLeading()
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .padding(5)
                .coloredCellStyle(.systemCellSecondary)
            } else if let blocks = Optional(scheduleObject.blocks.filter { $0.dates.contains(date) }.sorted { $0.startTime < $1.startTime }), !blocks.isEmpty {
                GeometryReader { geometry in
                    VStack(spacing: 7.5) {
                        ForEach(blocks, id: \.blockID) { block in
                            ScheduleWeekCell(block: block, date: date, rotation: rotation)
                                .frame(maxHeight: block.title == "Faculty Collaboration" ? .infinity : geometry.size.height * scheduleProportion(block, blocks: blocks))
                        }
                    }
                }
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .coloredCellStyle(.systemCellSecondary)
            }
            Spacer()
        }
#if os(iOS)
        .padding(.bottom)
#endif
        .padding(.top)
        .padding(.leading)
    }
    
    private func scheduleProportion(_ block: Block, blocks: [Block]) -> CGFloat {
        let blockStart = block.startTime.toDate(format: "HH:mm:ss")
        let blockEnd = block.endTime.toDate(format: "HH:mm:ss")
        
        guard let firstBlockStart = blocks.first.flatMap({ $0.startTime.toDate(format: "HH:mm:ss") }),
              let lastBlockEnd = blocks.last.flatMap({ $0.endTime.toDate(format: "HH:mm:ss") }) else {
            return 0
        }
        
        let blockDuration = blockEnd.timeIntervalSince(blockStart)
        
        var totalDuration = lastBlockEnd.timeIntervalSince(firstBlockStart)
        guard totalDuration > 0 else { return 0 }
        totalDuration += 7.5*Double((blocks.count - 1)) // compensate for VStack padding
        
        return CGFloat(blockDuration / totalDuration)
    }
    
    struct WeekPageHeader: View {
        
        let date: String
        let rotation: String
        let isToday: Bool
        
        init(date: String, rotation: String) {
            self.date = date
            self.rotation = rotation
            self.isToday = date == Date().toString()
        }
        
        var body: some View {
            VStack {
                HStack {
                    Text("\(date.reformatAsDate(newFormat: "EEE")), \(date.reformatAsDate(newFormat: "MMM d"))")
                        .scheduleHeader()
                        .fontWeight(.semibold)
                        .foregroundStyle(isToday ? .accent : .systemContrast)
                        .textCase(.uppercase)
                    Spacer()
                    if !rotation.isEmpty {
                        Image(systemName: rotation+".circle")
                            .scheduleHeader()
                            .fontWeight(.medium)
                            .foregroundStyle(isToday ? .accent : .systemContrast)
                            .textCase(.uppercase)
                            .padding(.trailing, 2)
                    }
                }
            }
        }
    }
}

struct ScheduleWeekCell: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
    
    let block: Block
    let date: String
    let rotation: String
    
    var body: some View {
        let (title, time, textColor, backgroundColor) = getProperties(block: block, date: date, rotation: rotation)
        
        VStack(spacing: 2) {
            Text(title)
                .scheduleLabel()
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
            Text(time)
                .scheduleLabel()
                .fontWeight(.medium)
                .foregroundStyle(textColor.opacity(0.75))
                .lineLimit(1)
        }
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coloredCellStyle(backgroundColor)
#if os(iOS)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 15, style: .continuous))
#endif
        .contextMenu {
            Text(block.title)
            if let course = userObject.courses.first(where: { $0.courseID == block.title }) {
                if !course.teacher.isEmpty {
                    Label(course.teacher, systemImage: "person")
                }
                if !course.room.isEmpty {
                    Label(course.room, systemImage: "location")
                }
            }
            Divider()
            Button {
                if let account = userObject.currentUser?.campusID {
                    openURL(createGCalEvent(startDate: date, endDate: date, account: account+"@thecollegepreparatoryschool.org"))
                } else {
                    openURL(createGCalEvent(startDate: date, endDate: date))
                }
            } label: {
                Label("Create Event", systemImage: "calendar.badge.plus")
            }
        }
    }
    
    func getProperties(block: Block, date: String, rotation: String) -> (String, String, Color, Color) {
        if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }),
           ScheduleObject.isCompass(block: block, date: date, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return (
                compass.name,
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                compass.color.toScheduleTextColor(colorSpace: colorSpace, colorScheme: colorScheme),
                compass.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme)
            )
        } else if ScheduleObject.isOpen(block: block, date: date, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return (
                "Open",
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                .systemContrast.opacity(0.75),
                .systemCellSecondary
            )
        } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
            if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                return (
                    "Free Period",
                    "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                    .systemContrast.opacity(0.75),
                    .systemCellSecondary
                )
            } else {
                return (
                    course.name,
                    "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                    course.color.toScheduleTextColor(colorSpace: colorSpace, colorScheme: colorScheme),
                    course.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme)
                )
            }
        } else {
            return (
                block.title,
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                defaultPalette[block.title]?.toScheduleTextColor(colorSpace: .displayP3, colorScheme: colorScheme) ?? .systemContrast.opacity(0.75),
                defaultPalette[block.title]?.toScheduleCellColor(colorSpace: .displayP3, colorScheme: colorScheme) ?? .systemCellSecondary
            )
        }
    }
}


extension Text {
    fileprivate func scheduleLabel() -> some View {
#if os(iOS)
        return self.fontSize(16)
#elseif os(macOS)
        return self.fontSize(14)
#endif
    }
    
    fileprivate func scheduleHeader() -> some View {
#if os(iOS)
        return self.fontSize(15)
#elseif os(macOS)
        return self.fontSize(13)
#endif
    }
}

extension Image {
    fileprivate func scheduleHeader() -> some View {
    #if os(iOS)
        return self.fontSize(15)
    #elseif os(macOS)
        return self.fontSize(13)
    #endif
    }
}
