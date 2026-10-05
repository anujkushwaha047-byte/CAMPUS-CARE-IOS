//
//  HomeRHFView.swift
//  CampusApp
//
//  Created on 7/18/2024
//  Built by Marcus Gallardo, Rahim Malik.
//

import SwiftUI

struct HomeRHFView: View {
    
    @EnvironmentObject var rhfObject: RHFObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Your RHF")
                .subheading()
                .flushLeading(padding: true)
                .padding(.top)
            
            RHFPointsView()
            ForEach(rhfObject.getDropInsToday().sorted { $0.startTime.toDate(format: "HH:mm:ss") < $1.startTime.toDate(format: "HH:mm:ss") }, id: \.self) { dropIn in
                RHFDropInCell(dropIn: dropIn)
            }
#if os(iOS)
            NavigationLink {
                StackView("RHF", backButton: true) {
                    RHFMainView()
                }
            } label: {
                Text("See All Drop-ins")
                    .body(weight: .semibold)
                    .foregroundStyle(.accent)
                    .flushCenter()
                    .borderedCellStyle()
            }
            .buttonStyle(.plain)
#elseif os(macOS)
            Button {
                RHFMainView()
                    .environmentObject(rhfObject)
                    .environmentObject(scheduleObject)
                    .frame(minWidth: 500, minHeight: 700)
                    .openInWindow(title: "RHF", isClear: false, sender: self)
            } label: {
                Text("See All Drop-ins")
                    .body(weight: .semibold)
                    .foregroundStyle(.accent)
                    .flushCenter()
                    .borderedCellStyle()
            }
            .buttonStyle(.plain)
#endif
        }
    }
}

struct RHFPointsView: View {
    
    @EnvironmentObject var rhfObject: RHFObject
    
    @AppStorage("rhf_id", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var rhfID = ""
    @AppStorage("rhf_points", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var rhfPoints = ""
    
    @State private var disabled = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ID")
                    .caption(weight: .semibold)
                    .foregroundStyle(.gray)
                    .frame(height: 15)
                TextField("--", text: $rhfID)
                    .fontSize(24)
                    .fontWeight(.bold)
                    .foregroundStyle(.accent)
                    .textFieldStyle(.plain)
                    .disabled(disabled)
                    .task(id: rhfID) {
                        do {
                            rhfPoints = try await rhfObject.fetchPoints(id: rhfID) ?? "--"
                        } catch {
                            ConsoleMessage(type: .data, description: "fetchPoints - \(error.localizedDescription)").error()
                        }
                    }
            }
            .flushLeading()
            CapsuleDivider(horizontal: true)
                .padding(.horizontal, 10)
            VStack(alignment: .leading) {
                Text("Points")
                    .caption(weight: .semibold)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                    .frame(height: 15)
                Text(rhfPoints)
                    .fontSize(24)
                    .fontWeight(.bold)
                    .foregroundStyle(.systemContrast)
            }
            .flushLeading()
        }
        .borderedCellStyle()
        .onAppear {
            // workaround for textfield autofocus on macOS launch
            DispatchQueue.main.async {
                disabled = false
            }
        }
    }
}

struct RHFDropInCell: View {
    
    let dropIn: RHFDropIn
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: getIconFromDropIn(title: dropIn.title.lowercased()))
                .fontSize(22)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background {
                    Circle()
                        .foregroundStyle(.accent)
                }
            VStack(alignment: .leading) {
                Text(dropIn.title)
                    .body()
                    .foregroundStyle(.systemContrast)
                Text("with \(dropIn.instructor)")
                    .body()
                    .foregroundStyle(.gray)
            }
            .flushLeading()
            VStack(alignment: .trailing) {
                Text(dropIn.blockID)
                    .body()
                    .foregroundStyle(.systemContrast)
                Text("\(dropIn.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(dropIn.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))")
                    .body()
                    .foregroundStyle(.gray)
            }
        }
        .borderedCellStyle()
    }
        
    private func getIconFromDropIn(title: String) -> String {
        if title.contains("badminton") { return "figure.badminton" }
        if title.contains("fitness") { return "figure.indoor.cycle" }
        if title.contains("climb") { return "figure.climbing" }
        if title.contains("hike") || title.contains("hiking") { return "figure.hiking" }
        if title.contains("yoga") { return "figure.yoga" }
        return "figure.highintensity.intervaltraining"
    }
}

struct RHFMainView: View {
    
    @EnvironmentObject var rhfObject: RHFObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                RHFPointsView()
                if !rhfObject.dropIns.filter({ $0.date >= Date().toString() }).isEmpty {
                    ForEach(rhfObject.getDropInDates().filter { $0 >= Date().toString() }.sorted { $0 < $1 }, id: \.self) { date in
                        HStack {
                            Text(date.reformatAsDate(newFormat: "EEE, MMM d"))
                                .subheading()
                                .foregroundStyle(date == Date().toString() ? .accent : .systemContrast)
                            Spacer()
                            let rotation = ScheduleObject.getRotation(date: date, scheduleData: scheduleObject.scheduleData)
                            if !rotation.isEmpty {
                                Image(systemName: rotation+".circle")
                                    .body()
                                    .foregroundStyle(date == Date().toString() ? .accent : .systemContrast)
                            }
                        }
                        .flushLeading(padding: true)
                        .padding(.top)
                        ForEach(rhfObject.dropIns.filter { $0.date == date }.sorted { $0.startTime < $1.startTime }, id: \.self) { dropIn in
                            RHFDropInCell(dropIn: dropIn)
                        }
                    }
                } else {
                    Text("No Upcoming Drop-ins")
                        .body()
                        .flushCenter()
                        .padding(.top)
                }
                
                Spacer().frame(height: 30)
            }
            .padding(20)
        }
        .background(.systemWindow)
    }
}
