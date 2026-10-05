//
//  CommClubMonthView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 9/4/24.
//

import SwiftUI

struct ClubsMonthView: View {
    
    @Binding var selectedDate: Date
    let dateRange: ClosedRange<Int> = -53...53
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 5) {
                    ForEach(dateRange.indices, id: \.self) { index in
                        if dateRange.startIndex == index, let currentDate = getDateFromWeekOffset(weekOffset: dateRange[index]) {
                            ClubsMonthHeader(date: currentDate)
                                .id(currentDate.toString(format: "yyyy-MM"))
                        } else if let previousDate = getDateFromWeekOffset(weekOffset: dateRange[dateRange.index(before: index)]), let currentDate = getDateFromWeekOffset(weekOffset: dateRange[index]) {
                            if previousDate.toString(format: "yyyy-MM") != currentDate.toString(format: "yyyy-MM") {
                                ClubsMonthHeader(date: currentDate)
                                    .id(currentDate.toString(format: "yyyy-MM"))
                            }
                        }
                        HStack(spacing: 5) {
                            ForEach(getWeekdaysFromWeekOffset(weekOffset: dateRange[index]), id: \.self) { date in
                                ClubsMonthCell(selectedDate: $selectedDate, date: date)
                                    .frame(height: 85)
                                    .padding(.horizontal, 1)
                                    .id(date)
                            }
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .scrollIndicators(.never)
            .padding(.horizontal, 5)
            .onAppear {
                proxy.scrollTo(selectedDate.toString(format: "yyyy-MM"), anchor: .top)
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
    
    private struct ClubsMonthHeader: View {
        let date: Date
        
        var body: some View {
            Text(date.toString(format: "MMMM, yyyy"))
                .subheading()
                .flushLeading()
                .padding()
        }
    }
    
    private struct ClubsMonthCell: View {
        
        @EnvironmentObject var scheduleObject: ScheduleObject
        @EnvironmentObject var clubsObject: ClubsObject
        
        @Binding var selectedDate: Date
        
        @State var showAlert = false
        @State var meetings: [ClubMeeting] = []
        
        let date: String
        
        var body: some View {
            Button {
                generateHaptic(.selection)
                selectedDate = date.toDate()
            } label: {
                VStack {
                    ZStack {
                        Color(.systemCellSecondary)
                        MonthCellColors(date: date, meetings: meetings)
                        
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12.5)
                            .stroke(selectedDate.toString() == date ? .accent : .clear, lineWidth: 3)
                        )
                    Text(date.reformatAsDate(newFormat: "d"))
                        .body()
                        .foregroundStyle(date == Date().toString() ? .accent : .systemContrast)
                }
            }
            .buttonStyle(.scale)
            .disabled(date.toDate() < Date())
            .opacity((date.toDate() < Date()) ? 0.5 : 1)
            .onAppear {
                meetings = clubsObject.clubMeetings.filter({ $0.date == date.reformatAsDate(newFormat: "yyyy-MM-dd") })
            }
            .onChange(of: selectedDate) { newValue in
                if newValue.toString(format: "yyyy-MM-dd") == date.reformatAsDate(newFormat: "yyyy-MM-dd") && meetings.count >= clubsObject.suggestedMeetingLimit {
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Are you sure you want to choose this day?"),
                    message: Text("There are already \(meetings.count) club events scheduled for \(date.reformatAsDate(newFormat: "EEEE, MMMM d"))"),
                    dismissButton: .default(Text("OK"))
                )
            }
//            .disabled(meetings.count > clubsObject.dailyMeetingLimit || date <= Date().toString())
//            .opacity(calculateOpacity(meetingsCount: meetings.count, date: date))
        }
        
//        private func calculateOpacity(meetingsCount: Int, date: String) -> Double {
//            if date <= Date().toString() || meetingsCount > clubsObject.dailyMeetingLimit {
//                return 0.5
//            }
//            
//            return 1
//        }
//        
        private struct MonthCellColors: View {
            
            @EnvironmentObject var userObject: UserObject
            @EnvironmentObject var clubsObject: ClubsObject
            
            @Environment(\.colorScheme) var colorScheme
            @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
            
            let date: String
            let meetings: [ClubMeeting]
            
            var body: some View {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        ForEach(0...clubsObject.suggestedMeetingLimit, id: \.self) { i in
                            if meetings.indices.contains(i), let clubID = meetings[i].clubID, let club = clubsObject.getClubFromID(clubID: clubID) {
                                club.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme)
                                    .frame(height: proxy.size.height / CGFloat(clubsObject.suggestedMeetingLimit))
                            } else {
                                Color.clear
                                    .frame(height: proxy.size.height / CGFloat(clubsObject.suggestedMeetingLimit))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
