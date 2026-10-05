//
//  CommDirectView.swift
//  CampusApp
//
//  Created on 7/20/2021
//  Built by Rahim Malik.
//

import SwiftUI
import SDWebImageSwiftUI

struct CommunityDirectoryView: View {
    
    var searchText: String
    
    @State var users = [User]()
    @State var filterBy = [seniorGradYear, juniorGradYear, sophGradYear, freshGradYear, "Faculty"].joined(separator: ",")
    @State var groupByFirst = true
    @FocusState var isFocused: Bool
    
    let openDirectoryPage: (User) -> ()
    
    let alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if searchText.isEmpty {
                            LazyVStack(spacing: 10) {
                                HStack {
                                    Text("Filter by")
                                        .body()
                                        .flushLeading()
                                    Spacer()
                                    Picker("", selection: $filterBy) {
                                        Text("Everyone").tag([seniorGradYear, juniorGradYear, sophGradYear, freshGradYear, "Faculty"].joined(separator: ","))
                                        Text("Students").tag([seniorGradYear, juniorGradYear, sophGradYear, freshGradYear].joined(separator: ","))
                                        Text("Faculty").tag("Faculty")
                                        Divider()
                                        ForEach([seniorGradYear, juniorGradYear, sophGradYear, freshGradYear], id: \.self) { gradYear in
                                            Text(gradYear).tag(gradYear)
                                        }
                                    }
                                    .labelsHidden()
                                }
                                .padding(.leading, 5)
                                CapsuleDivider()
                                HStack {
                                    Text("Group by")
                                        .body()
                                        .flushLeading()
                                    Spacer()
                                    Picker("", selection: $groupByFirst) {
                                        Text("First Name").tag(true)
                                        Text("Last Name").tag(false)
                                    }
                                    .labelsHidden()
                                }
                                .padding(.leading, 5)
                            }
                            .borderedCellStyle(padding: 15)
                            .padding(.bottom)
                            ForEach(alphabet, id: \.self) { letter in
                                Text(letter)
                                    .subheading()
                                    .flushLeading(padding: true)
                                let directory = filterDirectory(letter: letter)
                                if !directory.isEmpty {
                                    LazyVStack(spacing: 10) {
                                        ForEach(directory, id: \.campusID) { user in
                                            CommunityDirectoryButton(user: user) {
                                                openDirectoryPage(user)
                                            }
                                            if user != directory.last {
                                                CapsuleDivider()
                                            }
                                        }
                                    }.borderedCellStyle()
                                }
                            }
                    } else {
                        ForEach(searchDirectory(searchText), id: \.campusID) { user in
                            CommunityDirectoryButton(user: user) {
                                openDirectoryPage(user)
//                                selection = user
                            }
                                .borderedCellStyle()
                        }
                    }
                }
                .padding(20)
                .id("content")
                .ignoresSafeArea(.keyboard)
                .task {
                    do {
                        try await users = UserObject.fetchAllUsers()
                    } catch {
                        ConsoleMessage(type: .data, description: "fetchAllUsers - \(error.localizedDescription)").log()
                    }
                }
                .onChange(of: searchText) { _ in
                    withAnimation {
                        proxy.scrollTo("content", anchor: .top)
                    }
                }
                .onChange(of: isFocused) { _ in
                    if isFocused == true {
                        withAnimation {
                            proxy.scrollTo("content", anchor: .top)
                        }
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
    
    func filterDirectory(letter: String) -> [User] {
        if groupByFirst {
            return users
                .filter {
                    $0.name.starts(with: letter)
                }
                .filter { filterBy.contains($0.gradYear) }
                .sorted {
                    if $0.name.components(separatedBy: " ").count > 1 && $1.name.components(separatedBy: " ").count > 1 {
                        return $0.name.components(separatedBy: " ")[1] < $1.name.components(separatedBy: " ")[1]
                    } else {
                        return false
                    }
                }
        } else {
            return users
                .filter {
                    if $0.name.components(separatedBy: " ").count > 1 {
                        return $0.name.components(separatedBy: " ")[1].starts(with: letter)
                    } else {
                        return $0.name.starts(with: letter)
                    }
                }
                .filter { filterBy.contains($0.gradYear) }
                .sorted {
                    if $0.name.components(separatedBy: " ").count > 1 && $1.name.components(separatedBy: " ").count > 1 {
                        return $0.name.components(separatedBy: " ")[1] < $1.name.components(separatedBy: " ")[1]
                    } else {
                        return false
                    }
                }
        }
    }
    
    func searchDirectory(_ searchText: String) -> [User] {
        return users
            .filter {
                if $0.name.lowercased().starts(with: searchText.lowercased()) {
                    return true
                }
                if $0.name.components(separatedBy: " ").count > 1 {
                    return $0.name.components(separatedBy: " ")[1].lowercased().starts(with: searchText.lowercased())
                } else {
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
    
    struct CommunityDirectoryButton: View {
        
        var user: User
        var openDirectoryPage: () -> ()
        
        var body: some View {
            Button {
#if os(iOS)
                dismissKeyboard()
                withAnimation {
                    generateHaptic(.impact(.medium))
                    openDirectoryPage()
                }
#elseif os(macOS)
                openDirectoryPage()
#endif
            } label: {
                HStack(spacing: 15) {
                    if user.privacy["hide_image", default: false] || user.imageLink.isEmpty {
                        Color.systemCellSecondary
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                    } else {
                        WebImage(url: URL(string: user.imageLink)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } placeholder: {
                            Color.systemCellSecondary
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        }
                        .indicator(.activity)
                    }
                    VStack(spacing: 2) {
                        HStack {
                            Text(user.name)
                                .body()
                                .foregroundStyle(.systemContrast)
                            Spacer()
                        }
                        HStack {
                            Text(user.campusID + "@college-prep.org")
                                .body()
                                .foregroundStyle(.gray)
                                .lineLimit(1).truncationMode(.tail)
                            Spacer()
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .body()
                        .foregroundStyle(.accent)
                }
                .flushLeading()
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

struct CommunityDirectoryPage: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var clubsObject: ClubsObject
    
    @Environment(\.openURL) var openURL
    
    var user: User
    var openClubPage: (Club) -> ()
    
    @State var courses: [UserCourse] = []
    
    let columns2 = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if userObject.currentUser?.campusID == user.campusID {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.fill")
                            .caption()
                            .foregroundStyle(.accent)
                        Text("You're seeing a preview of what others see on your directory page")
                            .caption()
                            .flushLeading()
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .tintedCellStyle(.accent)
                    .padding(.vertical)
                }
                
                Text("Profile")
                    .subheading()
                    .flushLeading(padding: true)
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        if user.privacy["hide_image", default: false] || user.imageLink.isEmpty {
                            Color.systemCellSecondary
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } else {
                            WebImage(url: URL(string: user.imageLink)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 55, height: 55)
                                    .clipShape(Circle())
                            } placeholder: {
                                Color.systemCellSecondary
                                    .frame(width: 55, height: 55)
                                    .clipShape(Circle())
                            }
                            .indicator(.activity)
                        }
                        VStack(spacing: 2) {
                            HStack {
                                Text(user.name)
                                    .body()
                                    .foregroundStyle(.systemContrast)
                                Spacer()
                            }
                            Button {
                                if let url = URL(string: "mailto:\(user.campusID)@college-prep.org") {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Text(user.campusID + "@college-prep.org")
                                        .body()
                                        .foregroundStyle(.accent)
                                        .lineLimit(1).truncationMode(.tail)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    CapsuleDivider()
                    HStack {
                        Text("Graduation Year")
                            .body()
                        Spacer()
                        Text(user.gradYear)
                            .body()
                    }
                    if !user.pronouns.isEmpty {
                        CapsuleDivider()
                        HStack {
                            Text("Pronouns")
                                .body()
                            Spacer()
                            Text(user.pronouns)
                                .body()
                        }
                    }
                }
                .borderedCellStyle()
                
                if !user.bio.isEmpty {
                    Text("Bio")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    Text(user.bio)
                        .body()
                        .flushLeading()
                        .multilineTextAlignment(.leading)
                        .borderedCellStyle()
                }
                
                let socials = user.socials.filter { !$0.value.isEmpty }.sorted { $0.key < $1.key }
                if !socials.isEmpty && userObject.currentUser?.gradYear.lowercased().contains("faculty") == false {
                    Text("Socials")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    VStack(spacing: 15) {
                        ForEach(socials, id: \.key) { social in
                            Menu {
                                if social.key == "Phone" {
                                    if let phone = URL(string: "tel:\(social.value)") {
                                        Button {
                                            openURL(phone)
                                        } label: {
                                            Label("Call \u{22}\(user.name)\u{22}", systemImage: "phone")
                                        }
                                    }
                                    if let sms = URL(string: "sms:\(social.value)") {
                                        Button {
                                            openURL(sms)
                                        } label: {
                                            Label("Text \u{22}\(user.name)\u{22}", systemImage: "message")
                                        }
                                    }
                                }
                                Divider()
                                Button {
                                    copyStringToPasteboard(social.value)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            } label: {
                                HStack {
                                    Text(social.key)
                                        .body()
                                    Text(social.value)
                                        .foregroundStyle(.accent)
                                        .flushTrailing()
                                }
                            }
                            .buttonStyle(.plain)
                            if let last = socials.last, social != last {
                                CapsuleDivider()
                            }
                        }
                    }
                    .borderedCellStyle()
                    Text("Socials are visible only to other students, never faculty.")
                        .caption()
                        .flushLeading(padding: true)
                }
                
                if let hideClasses = userObject.currentUser?.privacy["hide_classes", default: true], !hideClasses {
                    if !courses.isEmpty {
                        Text("Classes")
                            .subheading()
                            .flushLeading(padding: true)
                            .padding(.top)
                        LazyVGrid(columns: columns2, spacing: 10) {
                            ForEach(courses, id: \.courseID) { course in
                                DirectoryCourseCell(course: course)
                            }
                        }
                        .borderedCellStyle()
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.raised.fill")
                            .caption()
                            .foregroundStyle(.orange)
                        Text("You cannot see another's classes when you are currently hiding yours")
                            .caption()
                            .flushLeading()
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .tintedCellStyle(.yellow)
                    .padding(.top)
                }
                
                if user.clubs.isEmpty == false {
                    let ledClubs = clubsObject.clubs.filter { club in
                        club.leaders.contains(user.campusID)
                    }
                    
                    let joinedClubs = user.clubs.compactMap { clubID in
                        clubsObject.getClubFromID(clubID: clubID)
                    }
                    
                    let clubs = Set(ledClubs + joinedClubs).sorted { $0.name < $1.name }
                    
                    Text("Clubs")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    LazyVStack(spacing: 15) {
                        ForEach(clubs, id: \.clubID) { club in
                            Button {
                                openClubPage(club)
                            } label: {
                                HStack(spacing: 10) {
                                    AsyncImage(url: URL(string: club.imageLink)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color(hexString: club.color)
                                            .scaledToFill()
                                    }
                                    .clipShape(Circle())
                                    .saturation(1.1)
                                    .frame(width: 55, height: 55)
                                    Text(club.name)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if ledClubs.contains(club) {
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(Color.yellow)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if club.clubID != clubs.last?.clubID {
                                CapsuleDivider()
                            }
                        }
                    }
                    .borderedCellStyle()
                    Text("Anonymously-followed affinity spaces are never visible above, but visible to the leaders of those clubs.")
                        .caption()
                        .flushLeading(padding: true)
                }
                
                Spacer().frame(height: 30)
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
        .task {
            do {
                courses = try await UserObject.fetchCourses(campusID: user.campusID)
                courses = courses.filter { classCourseIDs.contains($0.courseID) }
                if let compass = courses.first(where: { $0.courseID == "Compass" }) {
                    courses.append(compass)
                }
            } catch {
                ConsoleMessage(type: .data, description: "fetchCourses - \(error.localizedDescription)").log()
            }
        }
    }
    
    struct DirectoryCourseCell: View {
        
        let course: UserCourse
        
        var body: some View {
            HStack {
                if course.courseID == "Compass", !course.compassBlock.isEmpty {
                    HStack(spacing: 0) {
                        Image(systemName: "\(String(course.compassBlock.prefix(1))).square.fill".lowercased())
                            .body()
                            .foregroundStyle(course.color.toScheduleIconColor(colorSpace: .displayP3))
                        Image(systemName: "\(course.visibleRotation).square.fill".lowercased())
                            .body()
                            .foregroundStyle(course.color.toScheduleIconColor(colorSpace: .displayP3))
                    }
                    Text(course.name)
                        .body()
                        .lineLimit(2)
                } else {
                    HStack(spacing: 0) {
                        Image(systemName: "\(String(course.courseID.prefix(1))).square.fill".lowercased())
                            .body()
                            .foregroundStyle(course.freePeriod ? .gray : course.color.toScheduleIconColor(colorSpace: .displayP3))
                        if !course.visibleRotation.isEmpty {
                            Image(systemName: "\(course.visibleRotation).square.fill".lowercased())
                                .body()
                                .foregroundStyle(course.freePeriod ? .gray : course.color.toScheduleIconColor(colorSpace: .displayP3))
                        }
                    }
                    Text(course.freePeriod ? "Free Period" : course.name)
                        .body()
                        .lineLimit(2)
                }
            }
            .flushLeading()
        }
    }
}
