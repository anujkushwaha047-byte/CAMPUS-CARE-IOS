//
//  CampusApp_macOS.swift
//  CampusApp
//
//  Created on 5/30/2021
//  Built by Rahim Malik.
//

import SwiftUI
import WidgetKit
//import DeviceCheck

struct CampusApp_macOS: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    @EnvironmentObject var rhfObject: RHFObject
    @EnvironmentObject var ccObject: CCObject
    @EnvironmentObject var clubsObject: ClubsObject
    
    @State var selection = TabPageOption.home.id
    
    @AppStorage("setup", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var setup = true
    @State var setupScreen = PrefOption.auth
    
    @State var showSidebar = true
    @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
    
    @AppStorage("notif_prefs_active", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsActive: [String: Bool] = ["class_starts": true, "class_ends": false, "club_starts": true]
    @AppStorage("notif_prefs_minutes", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsMinutes: [String: Int] = ["class_minutes": 5, "club_minutes": 5]
    
    @AppStorage("widget_blocks", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var widgetBlocks = [WidgetBlock]()
    
    // defaultClubID allows CommunityView_macOS to have a specific club opened when it appears
    @State var defaultClubID: String = ""
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                if setup && setupScreen == .auth {
                    CenterView(geo: geo, scale: 0.8) {
                        AuthSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .account {
                    CenterView(geo: geo, scale: 0.8) {
                        AccountSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .notifications {
                    CenterView(geo: geo, scale: 0.8) {
                        NotifSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .palettes {
                    CenterView(geo: geo, scale: 0.8) {
                        PaletteSetupView(setupScreen: $setupScreen)
                    }
                } else {
                    NavigationSplitView {
                        SidebarViewmacOS(showSidebar: $showSidebar, selection: $selection)
                    } detail: {
                        switch selection {
                        case TabPageOption.home.rawValue:
                            HomeView_macOS()
                        case TabPageOption.directory.rawValue:
                            CommunityView_macOS { club in
                                defaultClubID = club.clubID
                                selection = TabPageOption.clubs.id
                            }
                        case TabPageOption.clubs.rawValue:
                            CommunityView_macOS(defaultClubID: $defaultClubID)
                        case TabPageOption.schedule.rawValue:
                            ScheduleView_macOS()
                        case TabPageOption.settings.rawValue:
                            SettingsView_macOS()
                        default:
                            if let userCourse = userObject.courses.first(where: { $0.courseID == selection }) {
                                StackView(userCourse.courseID) {
                                    SettingsCourseView(course: userCourse, color: userCourse.color.toP3Color())
                                }
                                .id(userCourse.courseID)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: setup ? 800 : .zero, maxWidth: .infinity, minHeight: setup ? 600 : .zero, maxHeight: .infinity)
        .background(VisualEffectView().ignoresSafeArea())
        .onOpenURL { url in
            for tabPage in TabPageOption.allCases {
                if url.absoluteString.contains(tabPage.id) {
                    selection = tabPage.id
                    break
                }
            }
        }
        .onChange(of: setupScreen) { _ in
            if setupScreen == .complete {
                setup = false
            }
        }
        .task {
            if KeychainManager.manager.hasObject(objectID: "campusID"),
               let campusID = KeychainManager.manager.readToken("campusID") {
                await fetchApplicationData(campusID: campusID)
            }
        }
        .onChange(of: userObject.currentUser) { _ in
            if userObject.currentUser != nil {
                Task {
                    if KeychainManager.manager.hasObject(objectID: "campusID"),
                       let campusID = KeychainManager.manager.readToken("campusID") {
                        await fetchApplicationData(campusID: campusID)
                    }
                }
            }
        }
        // Detect when the window moves to an inactive state and then regenerate notifications
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            Task {
                do {
                    if let wrappedUser = userObject.currentUser {
                        try await ccObject.fetchUserCC(user: wrappedUser)
                    }
                } catch {
                    ConsoleMessage(type: .data, description: "Error checking CC: \(error)").error()
                }
                let notifManager = NotifManager(userObject: userObject, scheduleObject: scheduleObject, clubsObject: clubsObject, ccObject: ccObject, notifPrefsActive: notifPrefsActive, notifPrefsMinutes: notifPrefsMinutes)
                await notifManager.generateScheduleNotifications()
                await notifManager.generateClubNotifications()
                widgetBlocks = await fetchWidgetBlocks(scheduleObject: scheduleObject, userObject: userObject)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private func fetchApplicationData(campusID: String) async {
        do {
            let user = try await UserObject.fetchUser(campusID: campusID)
            userObject.currentUser = user
            userObject.addUserListener(campusID: user.campusID)
            await userObject.addCourseListener()
            await scheduleObject.fetchSchedule()
            await clubsObject.fetchRequestEmails()
            await clubsObject.fetchLedClubs(user: user)
            await clubsObject.fetchJoinedClubs(user: user)
            await clubsObject.fetchClubMeetings()
            await clubsObject.fetchClubs()
            await rhfObject.fetchDropIns()
            do {
                try await ccObject.fetchUserCC(user: user)
            } catch {
                ConsoleMessage(type: .data, description: "fetchUserCC - \(error.localizedDescription)").error()
            }
        } catch {
            ConsoleMessage(type: .data, description: "fetchUser - \(error.localizedDescription)").error()
        }
    }
    
    struct SidebarViewmacOS: View {
        
        @EnvironmentObject var userObject: UserObject
        
        @Binding var showSidebar: Bool
        @Binding var selection: String
        
        var body: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 1.5) {
                        
                        Spacer().frame(height: 15)
                        
                        ForEach([TabPageOption.home, TabPageOption.directory, TabPageOption.clubs, TabPageOption.schedule], id: \.self) { tabPage in
                            SidebarButtonView(selection: $selection, tabPage: tabPage)
                        }
                        
                        Text("Classes")
                            .subheading()
                            .flushLeading(padding: true)
                            .padding(.top)
                            .padding(.bottom, 5)
                        ForEach(classCourseIDs, id: \.self) { classCourseID in
                            if let userCourse = userObject.courses.first(where: { $0.courseID == classCourseID }) {
                                CourseButtonView(selection: $selection, icon: "book.closed", course: userCourse)
                            } else {
                                DefaultCourseButtonView(icon: "book.closed", courseID: classCourseID)
                            }
                        }
                        
                        Text("Community")
                            .subheading()
                            .flushLeading(padding: true)
                            .padding(.top)
                            .padding(.bottom, 5)
                        ForEach(communityCourseIDs, id: \.self) { communityCourseIDs in
                            if let userCourse = userObject.courses.first(where: { $0.courseID == communityCourseIDs }) {
                                CourseButtonView(selection: $selection, icon: "person", course: userCourse)
                            } else {
                                DefaultCourseButtonView(icon: "person", courseID: communityCourseIDs)
                            }
                        }
                        
                        Spacer().frame(height: 15)
                        
                    }
                    .padding(.horizontal, 15)
                }
                .scrollIndicators(.never)
                Divider()
                SettingsButtonView(selection: $selection)
            }
            .frame(minWidth: 250)
        }
        
        struct SidebarButtonView: View {
            
            @EnvironmentObject var userObject: UserObject
            
            @Binding var selection: String
            let tabPage: TabPageOption
            
            @State var showAlert = false
            @State var hovering = false
            
            var body: some View {
                Button {
                    if userObject.currentUser == nil && restrictedPages.contains(tabPage.id) {
                        showAlert = true
                    } else {
                        generateHaptic(.selection)
                        selection = tabPage.id
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tabPage.icon)
                            .fontSize(15)
                            .fontWeight(.semibold)
                            .foregroundStyle(selection == tabPage.id ? .white : .accent)
                            .frame(width: 25, height: 20)
                        Text(tabPage.label)
                            .fontSize(13)
                            .fontWeight(.medium)
                            .foregroundStyle(selection == tabPage.id ? .white : .systemContrast)
                        Spacer()
                    }
                    .padding(7.5)
                    .background {
                        RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                            .foregroundColor(selection == tabPage.id ? .accent.opacity(0.5) : .systemContrast.opacity(hovering ? 0.05 : 0))
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                }
                .buttonStyle(.scale)
                .onHover { value in
                    hovering = value
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Sign In"),
                        message: Text("You must authenticate with a College Prep Account to access."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        
        struct CourseButtonView: View {
            
            @Binding var selection: String
            
            let icon: String
            let course: UserCourse
            
            @State var hovering = false
            
            @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
            
            var body: some View {
                Button {
                    generateHaptic(.selection)
                    selection = course.courseID
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .fontSize(15)
                            .fontWeight(.semibold)
                            .foregroundStyle(selection == course.courseID ? .white : course.freePeriod ? .gray : course.color.toScheduleIconColor(colorSpace: colorSpace))
                            .frame(width: 20, height: 20)
                        Text(course.freePeriod ? "Free Period" : course.name)
                            .fontSize(13)
                            .fontWeight(.medium)
                            .foregroundStyle(selection == course.courseID ? .white : .systemContrast)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 5) {
                            if course.name != course.courseID {
                                Text(course.courseID)
                                    .fontSize(13)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selection == course.courseID ? .white.opacity(0.5) : .systemContrast.opacity(0.5))
                            }
                            if !course.visibleRotation.isEmpty {
                                Image(systemName: course.visibleRotation+".circle")
                                    .fontSize(13)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selection == course.courseID ? .white.opacity(0.5) : .systemContrast.opacity(0.5))
                            }
                        }
                    }
                    .padding(7.5)
                    .background(
                        RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                            .foregroundColor(selection == course.courseID ? course.color.toScheduleIconColor(colorSpace: colorSpace).opacity(0.5) : .systemContrast.opacity(hovering ? 0.05 : 0))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                }
                .buttonStyle(.scale)
                .onHover { value in
                    hovering = value
                }
            }
        }
        
        struct DefaultCourseButtonView: View {
            
            let icon: String
            let courseID: String
            
            @State var showAlert = false
            
            var body: some View {
                Button {
                    showAlert = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .fontSize(15)
                            .fontWeight(.semibold)
                            .foregroundStyle(defaultPalette[courseID]?.toP3Color() ?? .accent)
                            .frame(width: 20, height: 20)
                        Text(courseID)
                            .fontSize(13)
                            .fontWeight(.medium)
                            .foregroundStyle(.systemContrast)
                        Spacer()
                    }
                    .padding(7.5)
                    .contentShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
                }
                .buttonStyle(.plain)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Sign In"),
                        message: Text("You must authenticate with a College Prep Account to edit courses."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        
        struct SettingsButtonView: View {
            
            @EnvironmentObject var userObject: UserObject
            
            @Binding var selection: String
            @State private var showAlert = false
            
            let tabPage = TabPageOption.settings
            
            var body: some View {
                Button {
                    generateHaptic(.selection)
                    selection = tabPage.id
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tabPage.icon)
                            .fontSize(14)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                        Text(tabPage.label)
                            .fontSize(14)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                    }
                }
                .buttonStyle(.scale)
                .padding()
                .padding(.trailing, 5)
                .padding(.bottom, 5)
            }
        }
    }
}
