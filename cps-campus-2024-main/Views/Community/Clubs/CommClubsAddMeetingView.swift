//
//  AddMeetingView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 9/4/24.
//

import SwiftUI

struct AddMeetingView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var clubsObject: ClubsObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @State var selectedClub: String
    
    @State var title: String = ""
    @State var location: String = ""
    @State var notes = ""
    
    @State var time = "Custom"
    @State var startTime = Date()
    @State var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
    ?? Date()
    
    @State var date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    ?? Date()
    
    @State var showRequestAlert = false
    @State var requestAlertMessage = ""
    @State var requestAlertTitle = ""
    
    var isBakeSale: Bool
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    HStack {
                        Text("Club")
                            .body(weight: .medium)
                        Spacer()
                        Picker("Choose a club", selection: $selectedClub) {
                            ForEach(clubsObject.ledClubs, id: \.clubID) { club in
                                Text(club.name).tag(club.clubID)
                            }
                        }
                        .tint(getClubColor())
                    }
                    .borderedCellStyle()
                    .padding(.vertical, 5)
                    
                    if isBakeSale == false {
                        VStack {
    //                        HStack {
    //                            Text("Title")
    //                                .body(weight: .medium)
    //                            Spacer()
    //                            TextField("Meeting Title", text: $title)
    //                                .fontSize(16)
    //                                .disabled(isBakeSale)
    //                                .fontWeight(.medium)
    //                                .opacity(isBakeSale ? 0.6 : 1)
    //                                .foregroundStyle(.accent)
    //                                .submitLabel(.done)
    //                                .multilineTextAlignment(.trailing)
    //                                .onAppear {
    //                                   setMeetingTitle()
    //                                }
    //                                .onChange(of: selectedClub) { _ in
    //                                    setMeetingTitle()
    //                                }
    //                        }
                            HStack {
                                Text("Room")
                                    .body(weight: .medium)
                                Spacer()
                                TextField("Proposed Room", text: $location)
                                    .fontSize(16)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)
                                    .submitLabel(.done)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
                            }
                        }
                        .borderedCellStyle()
                        .padding(.bottom, 5)
                    }
                    
                    if isBakeSale == false {
    //                        Text("Your club's name will be added to the event title if not included.")
    //                            .caption()
    //                            .flushLeading(padding: true)
    //                            .padding(.bottom, 10)
                        VStack {
                            HStack {
                                Text("Time")
                                    .body(weight: .medium)
                                Spacer()
                                VStack {
                                    HStack {
                                        Spacer()
                                        Picker("Select a Time", selection: $time) {
                                            if scheduleObject.blocks.filter({ $0.dates.contains(convertDateToString(date: date, format: "yyyy-MM-dd")) && $0.title == "Lunch" }).isEmpty == false {
                                                Text("Lunch").tag("Lunch")
                                            }
                                            if scheduleObject.blocks.filter({ $0.dates.contains(convertDateToString(date: date, format: "yyyy-MM-dd")) && $0.title == "Faculty Collaboration" }).isEmpty == false {
                                                Text("Faculty Collab").tag("Faculty Collab")
                                            }
                                            Text("Custom").tag("Custom")
                                        }
                                        .tint(getClubColor())
                                        .onChange(of: date) { newDate in
                                            if scheduleObject.blocks.filter({ $0.dates.contains(convertDateToString(date: newDate, format: "yyyy-MM-dd")) && $0.title == "Lunch" }).isEmpty == true && time == "Lunch" {
                                                time = "Custom"
                                            }
                                            if scheduleObject.blocks.filter({ $0.dates.contains(convertDateToString(date: newDate, format: "yyyy-MM-dd")) && $0.title == "Faculty Collaboration" }).isEmpty == true && time == "Faculty Collab" {
                                                time = "Custom"
                                            }
                                        }
                                    }
                                    if time == "Custom" {
                                        HStack {
                                            Spacer()
                                            DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .tint(getClubColor())
                                            DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .tint(getClubColor())
                                        }
                                    }
                                }
                            }
                            CapsuleDivider()
                                .padding(.bottom, 10)
                            HStack {
                                Text("Notes")
                                    .body(weight: .medium)
                                Spacer()
                                TextField(isBakeSale ? "Bake Sale Notes" : "Recurring Meeting Notes", text: $notes)
                                    .fontSize(16)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)
                                    .submitLabel(.done)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
                            }
                        }
                        .borderedCellStyle()
                        Text("Include notes to request a recurring meeting. For example, \"biweekly on Thursdays.\"")
                            .caption()
                            .flushLeading(padding: true)
                            .padding(.bottom)
                        
                    }

                    VStack {
                        HStack {
                            Text("Date")
                                .body(weight: .medium)
                            Spacer()
                            Text(date.toString(format: "EEEE, MMMM d, yyyy"))
                                .body(weight: .medium)
                                .foregroundStyle(getClubColor())
                        }
                        .padding(.bottom, 10)
                        CapsuleDivider()
                        ClubsMonthView(selectedDate: $date)
                            .frame(maxHeight: 300)
                    }
                    .borderedCellStyle()
                    .padding(.bottom)
                }
                .padding()
                .onAppear {
                    if let firstClub = clubsObject.ledClubs.first {
                        selectedClub = firstClub.clubID
                    }
                }
            }
            Spacer()
            Button(action: {
                generateHaptic(.impact(.heavy))
                if let club = clubsObject.getClubFromID(clubID: selectedClub), let startDate = calculateEventTime(date: date, time: startTime, timeType: time, isStart: true), let endDate = calculateEventTime(date: date, time: endTime, timeType: time, isStart: false) {
                    
                    title = club.name
                    
                    Task {
                        if await clubsObject.requestMeeting(club: club, isBakeSale: isBakeSale, title: title, location: location, notes: notes, date: date, start: startDate, end: endDate) == true {
                            requestAlertTitle = "Your \(isBakeSale ? "Bake Sale" : "Meeting") Request Was Sent Succesfully!"
                            requestAlertMessage = ""
                            showRequestAlert = true
                        } else {
                            requestAlertTitle = "Your \(isBakeSale ? "Bake Sale" : "Meeting") Request Could Not Be Sent."
                            requestAlertMessage = "Email the iteam@college-prep.org for assistance."
                            showRequestAlert = true
                        }
                    }
                }
            }, label: {
                Text(isBakeSale ? "Request Bake Sale" : "Request Meeting")
                    .body()
                    .flushCenter(padding: true)
                    .buttonCellStyle(color: Color(hexString: clubsObject.getClubFromID(clubID: selectedClub)?.color ?? Color.gray.toP3HexString()))
            })
            .padding()
            .buttonStyle(.plain)
            .alert(isPresented: $showRequestAlert) {
                Alert(title: Text(requestAlertTitle), message: Text(requestAlertMessage), dismissButton: .default(Text("OK")
                    .bold()))
            }
            .onChange(of: showRequestAlert) { newValue in
                if newValue == false {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
//    private func setMeetingTitle() {
//        if let club = clubsObject.getClubFromID(clubID: selectedClub) {
//            title = "\(club.name) \(isBakeSale ? "Bake Sale" : "Meeting")"
//        } else {
//            title =  "\(isBakeSale ? "Bake Sale" : "Meeting")"
//        }
//    }
    
    private func calculateEventTime(date: Date, time: Date, timeType: String, isStart: Bool ) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
       
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        
        var timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        if timeType == "Lunch", let lunchBlock = scheduleObject.blocks.filter({ $0.dates.contains(date.toString(format: "yyyy-MM-dd")) && $0.title == "Lunch" }).first {
            timeComponents = calendar.dateComponents([.hour, .minute], from: isStart ? lunchBlock.startTime.toDate(format: "HH:mm:ss") : lunchBlock.endTime.toDate(format: "HH:mm:ss"))
        } else if timeType == "Faculty Collab", let facultyCollabBlock = scheduleObject.blocks.filter({ $0.dates.contains(date.toString(format: "yyyy-MM-dd")) && $0.title == "Faculty Collaboration" }).first {
            timeComponents = calendar.dateComponents([.hour, .minute], from: isStart ? facultyCollabBlock.startTime.toDate(format: "HH:mm:ss") : facultyCollabBlock.endTime.toDate(format: "HH:mm:ss"))
        }
        
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        // Subtract five minutes from time because Google Calendar adds five minutes for some reason
        if let combinedDate = calendar.date(from: combinedComponents), let adjustedDate = calendar.date(byAdding: .minute, value: -5, to: combinedDate) {
            return adjustedDate
        } else {
            return nil
        }
    }
    
    private func getClubColor() -> Color {
        if let color = clubsObject.getClubFromID(clubID: selectedClub)?.color {
            return Color(hexString: color)
        }
        return .accent
    }
}
