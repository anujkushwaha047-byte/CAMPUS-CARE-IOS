//
//  CommClubsView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 8/7/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Combine

struct CommunityClubsView: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var clubsObject: ClubsObject
    @EnvironmentObject var userObject: UserObject
    
    @Environment(\.openURL) var openURL
    
    @Binding var searchText: String
    @Binding var selection: String
    
    let newClubFormURL = ""
    
    var body: some View {
        ScrollViewReader { mainScrollView in
            ScrollView {
                LazyVStack {
                    if searchText.isEmpty {
                        LazyVStack(spacing: 10) {
                            if clubsObject.ledClubs.isEmpty == false, let defaultLedClub = clubsObject.ledClubs.first {
                                VStack(spacing: 10) {
                                    Text("Command")
                                        .subheading()
                                        .flushLeading(padding: true)
                                    ClubCommandView(ledClubs: clubsObject.ledClubs, defaultLedClub: defaultLedClub)
                                }
                            }
                            HStack {
                                Text("Your Clubs")
                                    .subheading()
                                    .flushLeading(padding: true)
                                    .padding(.top)
                            }
                            ScrollViewReader { horizontalScrollView in
                                ScrollView(.horizontal) {
                                    HStack(spacing: 10) {
                                        ForEach(clubsObject.clubs.filter({ clubsObject.allJoinedClubs().contains($0.clubID)}), id: \.clubID) { club in
                                            ClubIcon(club: club, selection: $selection)
                                                .id(club.clubID)
                                        }
                                        ForEach(clubsObject.ledClubs, id: \.clubID) { club in
                                            ClubIcon(club: club, selection: $selection)
                                                .id(club.clubID)
                                        }
                                        if clubsObject.allJoinedClubs().contains(selection) == false && clubsObject.ledClubs.map({ $0.clubID }).contains(selection) == false, let club = clubsObject.getClubFromID(clubID: selection) {
                                            ClubIcon(club: club, selection: $selection)
                                                .id(club.clubID)
                                        }
                                        AddClubButton(currentSelection: $selection)
                                            .id("Add Club")
                                    }
                                    .padding(EdgeInsets(top: 5, leading: 4, bottom: 10, trailing: 0))
                                }
                                .scrollIndicators(.never)
                                .onAppear {
                                    horizontalScrollView.scrollTo(selection, anchor: .center)
                                }
                            }
                            if selection == "" {
                                ClubMeetingsView(selection: $selection)
                            } else if selection == "Add Club" {
                                LazyVStack(spacing: 10) {
                                    Button(action: {
                                        if let formURL = URL(string: newClubFormURL) {
                                            openURL(formURL)
                                        }
                                    }, label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "plus.circle.fill")
                                                .renderingMode(.template)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundStyle(.white)
                                                .frame(height: 20)
                                            Text("Create a Club")
                                                .button()
                                                .foregroundStyle(.white)
                                        }
                                        .flushCenter()
                                        .buttonCellStyle()
                                    })
                                    .buttonStyle(.scale)
                                    Spacer().frame(height: 20)
                                    ForEach(clubCategories, id: \.self) { category in
                                        Text(category)
                                            .subheading()
                                            .flushLeading(padding: true)
                                        ForEach(clubsObject.clubs.filter { category.lowercased().contains($0.category) }.sorted { $0.name < $1.name }, id: \.clubID) { club in
                                            ClubCell(club: club, selection: $selection, searchText: $searchText)
                                        }
                                    }
                                }
                            } else {
                                if let wrappedClub = clubsObject.getClubFromID(clubID: selection) {
                                    ClubPage(club: wrappedClub, selection: $selection)
                                        .id(selection)
                                }
                            }
                        }
                    } else {
                        let clubs = searchClubs(searchText)
                        Text("Results (\(clubs.count))")
                            .subheading()
                            .flushLeading()
                        ForEach(clubs, id:\.clubID) { club in
                            ClubCell(club: club, selection: $selection, searchText: $searchText)
                        }
                    }
                    Spacer().frame(height: 30)
                }
                .padding(20)
                .id(selection)
            }
            .frame(maxHeight: 1000)
            .scrollIndicators(.automatic)
            .background(.systemWindow)
        }
        .refreshable {
            await clubsObject.fetchClubs()
            await clubsObject.fetchClubMeetings()
            if let currentUser = userObject.currentUser {
                await clubsObject.fetchLedClubs(user: currentUser)
            }
            await clubsObject.fetchRequestEmails()
        }
    }
    
    private func searchClubs(_ searchText: String) -> [Club] {
        return clubsObject.clubs.filter {
            if $0.name.lowercased().starts(with: searchText.lowercased()) {
                return true
            }
            if $0.nickname.lowercased().starts(with: searchText.lowercased()) {
                return true
            }
            if $0.name.components(separatedBy: " ").count > 1 {
                return $0.name.components(separatedBy: " ")[1].lowercased().starts(with: searchText.lowercased())
            } else if $0.nickname.components(separatedBy: " ").count > 1 {
                return $0.nickname.components(separatedBy: " ")[1].lowercased().starts(with: searchText.lowercased())
            }
            else {
                return false
            }
        }
        .sorted {
            if $0.name.components(separatedBy: " ").count > 1 && $1.name.components(separatedBy: " ").count > 1 {
                return $0.name.components(separatedBy: " ")[1] < $1.name.components(separatedBy: " ")[1]
            } else {
                return false
            }
        }
    }
    
    private struct AddClubButton: View {
        
        @Binding var currentSelection: String
        
        var body: some View {
            Button(action: {
                generateHaptic(.impact(.medium))
                if currentSelection == "Add Club" {
                    currentSelection = ""
                } else {
                    currentSelection = "Add Club"
                }
            }, label: {
                VStack {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.accent)
                        .background(
                            Circle()
                                .foregroundStyle(.accent).opacity(0.25)
                                .frame(width: 80, height: 80, alignment: .center)
                        )
                        .frame(width: 80, height: 80, alignment: .center)
                        .padding(3)
                        .overlay(currentSelection == "Add Club" ?
                                 Circle().stroke(Color.accent, lineWidth: 4)
                                 : Circle().stroke(.clear, lineWidth: 4)
                        )
                    VStack {
                        Text("Add Club")
                            .caption(weight: .medium)
                            .foregroundStyle(.accent)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                    }
                    .frame(width: 80)
                }
            })
            .buttonStyle(.plain)
        }
    }
    
    private struct ClubCell: View {
        
        let club: Club
        
        @Binding var selection: String
        @Binding var searchText: String
        
        var body: some View {
            Button(action: {
                generateHaptic(.impact(.medium))
                searchText = ""
                selection = club.clubID
                // Close keyboard in response to club selection
#if os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
            }, label: {
                VStack {
                    HStack(spacing: 15) {
                        WebImage(url: URL(string: club.imageLink)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .saturation(1.1)
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } placeholder: {
                            Color.systemCellSecondary
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        }
                        .indicator(.activity)
                        Text(club.name)
                            .body(weight: .semibold)
                            .foregroundStyle(.systemContrast)
                        Spacer()
                    }
                }
                .borderedCellStyle()
            })
            .buttonStyle(.plain)
        }
    }
    
    private struct ClubIcon: View {
        @Environment(\.colorScheme) var colorScheme
        
        let club: Club
        
        @Binding var selection: String
        
        var body: some View {
            Button(action: {
                generateHaptic(.impact(.medium))
                if selection == club.clubID {
                    selection = ""
                } else {
                    selection = club.clubID
                }
            }, label: {
                VStack {
                    WebImage(url: URL(string: club.imageLink)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .saturation(1.1)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .padding(3)
                    } placeholder: {
                        Color.systemCellSecondary
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .padding(3)
                    }
                    .indicator(.activity)
    #if os(iOS)
                    .overlay(selection == club.clubID ?
                             Circle().stroke(colorScheme == .light && UIColor(hexString: club.color).luminance > 0.5 ? Color(UIColor(hexString: club.color).shaded(amount: 0.15).saturated(amount: 0.15)) : Color(hexString: club.color), lineWidth: 4)
                             : Circle().stroke(.clear, lineWidth: 4)
                    )
    #else
                    .overlay(selection == club.clubID ?
                             Circle().stroke(colorScheme == .light && NSColor(hexString: club.color).luminance > 0.5 ? Color(NSColor(hexString: club.color).shaded(amount: 0.15).saturated(amount: 0.15)) : Color(hexString: club.color), lineWidth: 4)
                             : Circle().stroke(.clear, lineWidth: 4)
                    )
    #endif
                    VStack {
                        Text(club.nickname == "" ? club.name : club.nickname)
                            .caption(weight: .medium)
    #if os(iOS)
                            .foregroundStyle(selection == club.clubID ? Color(UIColor(hexString: club.color)) : Color.gray)
    #else
                            .foregroundStyle(selection == club.clubID ? Color(NSColor(hexString: club.color)) : Color.gray)
    #endif
                    }
                    .frame(maxWidth: 60)
                }
            })
            .buttonStyle(.plain)
        }
    }
}

struct LeaveClubButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var clubsObject: ClubsObject
    @EnvironmentObject var userObject: UserObject
    
    @Binding var selection: String
    
    var body: some View {
        if clubsObject.allJoinedClubs().contains(selection) {
            Button(action: {
                generateHaptic(.impact(.heavy))
                Task {
                    clubsObject.joinedClubs.removeAll(where: { $0 == selection })
                    clubsObject.hiddenClubs.removeAll(where: { $0 == selection })
                    await clubsObject.leaveClub(clubID: selection, userObject: userObject)
                }
            }, label: {
                let clubColorString = clubsObject.getClubFromID(clubID: selection)?.color ?? Color.accentColor.toP3HexString()
                Image(systemName: "person.fill.badge.minus")
                    .fontSize(23)
                    .foregroundStyle(clubColorString.toClubColor(colorScheme: colorScheme))
            })
            .buttonStyle(.plain)
        }
    }
}

struct ClubMeetingsView : View {
    
    @EnvironmentObject var clubsObject: ClubsObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @Binding var selection: String
    
    var filter: [String]?
    
    var maxMeetings = 20
    
    @State var dates: [String] = []
    @State var meetings: [ClubMeeting] = []
    
    var body: some View {
        VStack {
            ForEach(dates, id: \.self) { date in
                if meetings.isEmpty == false {
                    Text(date.reformatAsDate(newFormat: "EEEE, MMMM d").uppercased())
                        .body()
                        .foregroundStyle(date == Date().toString(format: "yyyy-MM-dd") ? .accent : .systemContrast)
                        .flushLeading(padding: true)
                        .padding(.top, 10)
                    ForEach(meetings.filter({ $0.date == date }), id: \.self) { meeting in
                        if meeting.isBakeSale && filter == nil {
                            BakeSaleCell(meeting: meeting)
                                .borderedCellStyle()
                        } else if let clubID = meeting.clubID, let club = clubsObject.getClubFromID(clubID: clubID) {
                            if let wrappedFilter = filter {
                                if wrappedFilter.contains(clubID) {
                                    ClubMeetingCell(selection: $selection, meeting: meeting, club: club)
                                        .borderedCellStyle()
                                }
                            } else {
                                ClubMeetingCell(selection: $selection, meeting: meeting, club: club)
                                    .borderedCellStyle()
                            }
                        }
                    }
                }
            }
        }
        .task {
            if clubsObject.clubMeetings.isEmpty {
                await clubsObject.fetchClubMeetings()
            }
            getMeetings()
        }
    }
    
    private func getMeetings() {
        if let meetingsArray = Optional(Array(Set(clubsObject.clubMeetings
            .filter({ $0.date.toDate(format: "yyyy-MM-dd") >= (Date().addDays(-1) ?? Date())})))) {
            if let wrappedFilter = filter {
                meetings = Array(meetingsArray.sorted(by: { $0.date.toDate(format: "yyyy-MM-dd") < $1.date.toDate(format: "yyyy-MM-dd") }).filter({ (meeting) -> Bool in
                    if let clubID = meeting.clubID {
                        return wrappedFilter.contains(clubID)
                    } else {
                        return false
                    }
                }).prefix(maxMeetings))
            } else {
                meetings = Array(meetingsArray.sorted(by: { $0.date.toDate(format: "yyyy-MM-dd") < $1.date.toDate(format: "yyyy-MM-dd") }).prefix(maxMeetings))
            }
            
            dates = Array(Set(meetings.map({ $0.date }))).sorted(by: { $0.toDate(format: "yyyy-MM-dd") < $1.toDate(format: "yyyy-MM-dd") })
        }
    }
}

struct ClubMeetingCell: View {
    
    @EnvironmentObject var clubsObject: ClubsObject
    
    @Binding var selection: String
    
    let meeting: ClubMeeting
    let club: Club
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Button(action: {
                    if selection != club.clubID {
                        generateHaptic(.impact(.medium))
                        selection = club.clubID
                    }
                }, label: {
                    WebImage(url: URL(string: club.imageLink)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .saturation(1.1)
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                    } placeholder: {
                        Color(hexString: club.color)
                            .saturation(1.1)
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                    }
                    .indicator(.activity)
                })
                .buttonStyle(.plain)
                
                VStack(spacing: 2) {
                    HStack {
                        Text("\(meeting.title)")
                            .body(weight: .semibold)
                            .foregroundStyle(.systemContrast)
                        Spacer()
                    }
                    HStack {
                        if let startTime = meeting.startTime?.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "HH:mm"), let endTime = meeting.endTime?.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "HH:mm") {
                            if startTime == "12:00" && endTime == "12:00" {
                                Text("All Day")
                                    .body(weight: .medium)
                                    .foregroundStyle(.gray)
                            } else {
                                Text("\(startTime) - \(endTime)")
                                    .body(weight: .medium)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                }
                Spacer()
                if let location = meeting.location, location.isEmpty == false {
                    HStack {
                        Text(location)
                            .body(weight: .medium)
                            .foregroundStyle(.systemContrast)
                    }
                }
            }
        }
    }
}

struct BakeSaleCell: View {
    
    @EnvironmentObject var clubsObject: ClubsObject
    let meeting: ClubMeeting
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                WebImage(url: URL(string: "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .saturation(1.1)
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                } placeholder: {
                    Color(hexString: "#f8aec1") // Pink color of bake sale image
                        .saturation(1.1)
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                }
                .indicator(.activity)
                
                VStack(spacing: 2) {
                    HStack {
                        Text("\(meeting.title)")
                            .body(weight: .semibold)
                            .foregroundStyle(.systemContrast)
                        Spacer()
                    }
                    HStack {
                        Text("All Day")
                            .body(weight: .medium)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
            }
        }
    }
}
