//
//  SchedMonthView.swift
//  CampusApp
//
//  Created on 7/10/2021
//  Built by Rahim Malik.
//

import SwiftUI

struct ScheduleMonthView: View {
    
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Binding var selectedDate: Date
    let dateRange: ClosedRange<Int> = -53...53
    
    let inSidebar: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: inSidebar ? 5 : 10) {
                    ForEach(dateRange.indices, id: \.self) { index in
                        if dateRange.startIndex == index, let currentDate = getDateFromWeekOffset(weekOffset: dateRange[index]) {
                            ScheduleMonthHeader(date: currentDate)
                                .id(currentDate.toString(format: "yyyy-MM"))
                        } else {
                            if let previousDate = getDateFromWeekOffset(weekOffset: dateRange[dateRange.index(before: index)]),
                                let currentDate = getDateFromWeekOffset(weekOffset: dateRange[index]) {
                                if previousDate.toString(format: "yyyy-MM") != currentDate.toString(format: "yyyy-MM") {
                                    ScheduleMonthHeader(date: currentDate)
                                        .id(currentDate.toString(format: "yyyy-MM"))
                                }
                            }
                        }
                        
                        HStack(spacing: inSidebar ? 5 : 10) {
                            ForEach(getWeekdaysFromWeekOffset(weekOffset: dateRange[index]), id: \.self) { date in
                                ScheduleMonthCell(selectedDate: $selectedDate, date: date, rotation: ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData))
                                    .frame(height: inSidebar ? 85 : 100)
                                    .id(date)
                            }
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .scrollIndicators(.never)
            .padding(.horizontal, 15)
            .onAppear {
                proxy.scrollTo(selectedDate.toString(format: "yyyy-MM"), anchor: .top)
            }
            .onChange(of: selectedDate) { _ in
                if inSidebar {
                    withAnimation {
                        proxy.scrollTo(selectedDate.toString(format: "yyyy-MM"), anchor: .top)
                    }
                }
            }
        }
    }
    
    func getDateFromWeekOffset(weekOffset: Int) -> Date? {
        return Date().startOfWeek()?.addWeeks(weekOffset)
    }
    
    func getWeekdaysFromWeekOffset(weekOffset: Int) -> [String] {
        guard let targetWeek = Date().startOfWeek()?.addWeeks(weekOffset) else {
            return []
        }
        
        var weekdays = [String]()
        for dayOffset in 1...5 {
            if let dayDate = targetWeek.addDays(dayOffset) {
                weekdays.append(dayDate.toString())
            }
        }
        
        return weekdays
    }
    
    struct ScheduleMonthHeader: View {
        let date: Date
        
        var body: some View {
            Text(date.toString(format: "MMMM, yyyy"))
                .subheading()
                .flushLeading()
                .padding()
        }
    }
}

struct ScheduleMonthCell: View {
    
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Binding var selectedDate: Date
    let date: String
    let rotation: String
    
    var body: some View {
        Button {
            generateHaptic(.selection)
            selectedDate = date.toDate()
        } label: {
            VStack {
                ZStack {
                    Color(.systemCellSecondary)
                    if scheduleObject.holidays.first(where: { $0.dates.contains(date) }) != nil {
                        Color(.systemCellSecondary)
                    } else if let blocks = Optional(scheduleObject.blocks.filter { $0.dates.contains(date) }.sorted { $0.startTime < $1.startTime }), !blocks.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(blocks, id: \.blockID) { block in
                                MonthCellColor(block: block, date: date, rotation: rotation)
                            }
                        }
                    } else {
                        Color(.systemCellSecondary)
                    }
                    if !rotation.isEmpty {
                        Text(rotation)
                            .body()
                            .frame(width: 25, height: 25)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .opacity(date < Date().toString() ? 0.5 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                Text(date.reformatAsDate(newFormat: "d"))
                    .body()
                    .foregroundStyle(date == Date().toString() ? .accent : .systemContrast)
            }
        }
        .buttonStyle(.scale)
    }
    
    struct MonthCellColor: View {
        
        @EnvironmentObject var userObject: UserObject
        @EnvironmentObject var scheduleObject: ScheduleObject
        
        @Environment(\.colorScheme) var colorScheme
        @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
        
        let block: Block
        let date: String
        let rotation: String
        
        var body: some View {
            getColor(block: block, date: date, rotation: rotation)
        }
        
        func getColor(block: Block, date: String, rotation: String) -> Color {
            if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }),
               ScheduleObject.isCompass(block: block, date: date, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                return compass.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme)
            } else if ScheduleObject.isOpen(block: block, date: date, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
                return .systemCellSecondary
            } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
                if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                    return .systemCellSecondary
                } else {
                    return course.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme)
                }
            } else if block.title == "Faculty Collaboration" {
                return .systemCellSecondary
            } else if block.type == .course {
                return defaultPalette[block.title]?.toP3Color() ?? .clear
            } else {
                return .clear
            }
        }
    }
}
