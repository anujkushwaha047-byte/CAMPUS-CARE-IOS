//
//  SchedView.swift
//  CampusApp
//
//  Created on 6/23/2021
//  Built by Rahim Malik.
//

import SwiftUI

// MARK: - iOS

#if os(iOS)
struct ScheduleView_iOS: View {
    
    @State var selectedDate = Date()
    @State var showHolidays = false
    
    @State var scheduleMode = ScheduleOption.week
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Picker("Mode", selection: $scheduleMode) {
                    Text("Week").tag(ScheduleOption.week)
                    Text("Month").tag(ScheduleOption.month)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
                .flushCenter()
                HStack {
                    Button {
                        generateHaptic(.impact(.medium))
                        selectedDate = Date()
                    } label: {
                        Text("Today")
                            .fontSize(17)
                            .fontWeight(.medium)
                            .foregroundStyle(.accent)
                    }
                    .buttonStyle(.scale)
                    Spacer()
                    Button {
                        generateHaptic(.selection)
                        showHolidays.toggle()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .fontSize(21)
                            .fontWeight(.medium)
                            .foregroundStyle(.accent)
                            .padding(.bottom, 3)
                    }
                    .buttonStyle(.scale)
                }
            }
            .padding(.top, 5)
            .padding(.horizontal, 20)
            switch scheduleMode {
            case .week:
                VStack {
                    ScheduleWeekView(selectedDate: $selectedDate)
                    Spacer().frame(height: 25)
                }
            case .month:
                VStack {
                    Divider()
                        .padding(.top)
                    ScheduleMonthView(selectedDate: $selectedDate, inSidebar: false)
                }
            }
        }
        .background(.systemWindow)
        .onChange(of: selectedDate) { _ in
            scheduleMode = .week
        }
        .sheet(isPresented: $showHolidays) {
            StackView("Export", cancelButton: true) {
                ScheduleExportView()
            }
        }
    }
}

// MARK: - iPadOS

struct ScheduleView_iPadOS: View {

    @SceneStorage("schedule_selected_date") var selectedDate = Date()
    
    @SceneStorage("schedule_mode") var scheduleMode = ScheduleOption.week
    @AppStorage("schedule_show_calendar", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var showCalendar = true
    @State var showHolidays = false
    
    var body: some View {
        StackView("Schedule") {
            ZStack {
                ScheduleWeekView(selectedDate: $selectedDate)
                    .padding(.bottom, -20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.systemWindow)
                if showCalendar {
                    HStack(spacing: 0) {
                        Divider().frame(width: 1)
                        ScheduleMonthView(selectedDate: $selectedDate, inSidebar: true)
                            .frame(width: 325, alignment: .trailing)
                    }
                    .background(.systemWindow)
                    .flushTrailing()
                }
                if showHolidays {
                    HStack(spacing: 0) {
                        Divider().frame(width: 1)
                        ScheduleExportView()
                            .frame(width: 325, alignment: .trailing)
                    }
                    .background(.systemWindow)
                    .flushTrailing()
                }
            }
        } toolbar: {
            HStack(spacing: 5) {
                Button {
                    generateHaptic(.impact(.medium))
                    selectedDate = Date()
                } label: {
                    Text("Today")
                        .action()
                        .foregroundStyle(.accent)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .frame(height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
                Spacer()
                Button {
                    generateHaptic(.selection)
                    showHolidays = false
                    showCalendar.toggle()
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showCalendar ? .accentColor : .systemContrast.opacity(0.75))
                        .frame(width: 35, height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
                Button {
                    generateHaptic(.selection)
                    showCalendar = false
                    showHolidays.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showHolidays ? .accentColor : .systemContrast.opacity(0.75))
                        .padding(.bottom, 3)
                        .frame(width: 35, height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
            }
        }
    }
}
#endif

// MARK: - macOS

#if os(macOS)
struct ScheduleView_macOS: View {
    
    @SceneStorage("schedule_selected_date") var selectedDate = Date()
    
    @SceneStorage("schedule_mode") var scheduleMode = ScheduleOption.week
    @AppStorage("schedule_show_calendar", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var showCalendar = true
    @State var showHolidays = false
    
    var body: some View {
        StackView("Schedule") {
            ZStack {
                ScheduleWeekView(selectedDate: $selectedDate)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.systemWindow)
                if showCalendar {
                    LazyHStack(spacing: 0) {
                        Divider().frame(width: 1)
                        ScheduleMonthView(selectedDate: $selectedDate, inSidebar: true)
                            .frame(width: 325, alignment: .trailing)
                    }
                    .background(.systemWindow)
                    .flushTrailing()
                }
                if showHolidays {
                    LazyHStack(spacing: 0) {
                        Divider().frame(width: 1)
                        ScheduleExportView()
                            .frame(width: 325, alignment: .trailing)
                    }
                    .background(.systemWindow)
                    .flushTrailing()
                }
            }
        } toolbar: {
            HStack(spacing: 5) {
                Button {
                    generateHaptic(.impact(.medium))
                    selectedDate = Date()
                } label: {
                    Text("Today")
                        .action()
                        .foregroundStyle(.accent)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .frame(height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
                Button {
                    generateHaptic(.selection)
                    showHolidays = false
                    showCalendar.toggle()
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showCalendar ? .accentColor : .systemContrast.opacity(0.75))
                        .frame(width: 35, height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
                Button {
                    generateHaptic(.selection)
                    showCalendar = false
                    showHolidays.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showHolidays ? .accentColor : .systemContrast.opacity(0.75))
                        .padding(.bottom, 3)
                        .frame(width: 35, height: 35)
                        .toolbarHoverEffect()
                }
                .buttonStyle(.scale)
            }
        }
    }
}
#endif
