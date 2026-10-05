//
//  CampusApp_iPadOS.swift
//  CampusApp
//
//  Created on 5/30/2021
//  Built by Rahim Malik.
//

import SwiftUI
import WidgetKit
import FirebaseAuth

#if os(iOS)
import FirebaseDynamicLinks
#endif

struct CampusApp_iPadOS: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    @EnvironmentObject var rhfObject: RHFObject
    @EnvironmentObject var ccObject: CCObject
    @EnvironmentObject var clubsObject: ClubsObject
    
    @Environment(\.scenePhase) var scenePhase
    
    @State var selection = TabPageOption.home.id
    
    @AppStorage("setup", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var setup = true
    @AppStorage("parentSetup", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var parentSetup = false
    
    @State var setupScreen = PrefOption.auth
    @State var parentSignInLink: String?
    
    @State var showSidebar = true
    @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
    
    @AppStorage("notif_prefs_active", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsActive: [String: Bool] = ["class_starts": true, "class_ends": false, "club_starts": true]
    @AppStorage("notif_prefs_minutes", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsMinutes: [String: Int] = ["class_minutes": 5, "club_minutes": 5]
    
    @AppStorage("widget_blocks", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var widgetBlocks = [WidgetBlock]()
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                if setup && setupScreen == .auth {
                    CenterView(geo: geo, scale: 0.7) {
                        AuthSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .account {
                    CenterView(geo: geo, scale: 0.7) {
                        AccountSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .notifications {
                    CenterView(geo: geo, scale: 0.7) {
                        NotifSetupView(setupScreen: $setupScreen)
                    }
                } else if setup && setupScreen == .palettes {
                    CenterView(geo: geo, scale: 0.7) {
                        PaletteSetupView(setupScreen: $setupScreen)
                    }
                }  else if parentSetup && setupScreen == .parents {
                    ParentSetupView(setupScreen: $setupScreen, signInLink: parentSignInLink)
                } else {
                    NavigationSplitView {
                        SidebarViewiPadOS(showSidebar: $showSidebar, selection: $selection)
                            .toolbar(.hidden)
                    } detail: {
                        switch selection {
                        case TabPageOption.home.rawValue:
                            HomeView()
                        case TabPageOption.community.rawValue:
                            CommunityView()
                        case TabPageOption.schedule.rawValue:
                            ScheduleView_iPadOS()
                        case TabPageOption.settings.rawValue:
                            SettingsView_iPadOS()
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
        .onOpenURL { url in
            for tabPage in TabPageOption.allCases {
                if url.absoluteString.contains(tabPage.id) {
                    selection = tabPage.id
                    break
                }
            }
            if Auth.auth().isSignIn(withEmailLink: url.absoluteString) {
                Task {
                    parentSignInLink = await authManager.getSignInLink(universalLink: url)
                    withAnimation {
                        parentSetup = true
                        setup = false
                        setupScreen = .parents
                    }
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
            } else {
                if KeychainManager.manager.hasObject(objectID: "childCampusID") {
                    do {
                        if let childCampusID = KeychainManager.manager.readToken("childCampusID") {
                            userObject.currentChild = try await UserObject.fetchUser(campusID: childCampusID)
                            authManager.state = .parent
                            await scheduleObject.fetchSchedule()
                            userObject.courses = try await UserObject.fetchCourses(campusID: childCampusID)
                        }
                    } catch {
                        ConsoleMessage(type: .data, description: error.localizedDescription).error()
                    }
                }
                if KeychainManager.manager.hasObject(objectID: "childCampusIDs") {
                    if let ids = KeychainManager.manager.readArray("childCampusIDs") {
                        userObject.childCampusIDs = ids
                        
                        if let first = await UserObject.fetchChildren(ids).first, userObject.currentChild == nil {
                            userObject.currentChild = first
                            authManager.state = .parent
                            await scheduleObject.fetchSchedule()
                            do {
                                userObject.courses = try await UserObject.fetchCourses(campusID: first.campusID)
                            } catch {
                                ConsoleMessage(type: .data, description: "Failed to fetch user courses - \(error)").error()
                            }
                        }
                    }
                }
            }
        }
//        .onChange(of: userObject.currentUser) { user in
//            if user != nil {
//                Task {
//                    if KeychainManager.manager.hasObject(objectID: "campusID"),
//                       let campusID = KeychainManager.manager.readToken("campusID") {
//                        await fetchApplicationData(campusID: campusID)
//                    }
//                }
//            }
//        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .background  {
                Task {
                    let notifManager = NotifManager(userObject: userObject, scheduleObject: scheduleObject, clubsObject: clubsObject, ccObject: ccObject, notifPrefsActive: notifPrefsActive, notifPrefsMinutes: notifPrefsMinutes)
                    await notifManager.generateScheduleNotifications()
                    await notifManager.generateClubNotifications()
                    widgetBlocks = await fetchWidgetBlocks(scheduleObject: scheduleObject, userObject: userObject)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
    
    struct SidebarViewiPadOS: View {
        
        @EnvironmentObject var userObject: UserObject
        
        @Binding var showSidebar: Bool
        @Binding var selection: String
        
        var body: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 1.5) {
                        Text("Campus")
                            .font(.custom("Poppins-Bold", size: 30))
                            .flushLeading(padding: true)
                            .padding(.top, 15)
                            .padding(.bottom, 10)
                        ForEach([TabPageOption.home, TabPageOption.community, TabPageOption.schedule], id: \.self) { tabPage in
                            SidebarButtonView(selection: $selection, tabPage: tabPage)
                        }
                        
                        Text("Classes")
                            .subheading()
                            .flushLeading(padding: true)
                            .padding(.top)
                            .padding(.bottom, 10)
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
                            .padding(.bottom, 10)
                        ForEach(communityCourseIDs, id: \.self) { communityCourseIDs in
                            if let userCourse = userObject.courses.first(where: { $0.courseID == communityCourseIDs }) {
                                CourseButtonView(selection: $selection, icon: "person", course: userCourse)
                            } else {
                                DefaultCourseButtonView(icon: "person", courseID: communityCourseIDs)
                            }
                        }
                        
                        Spacer().frame(height: 25)
                        
                    }
                    .padding(.horizontal, 15)
                }
                Divider()
                SettingsButtonView(selection: $selection)
            }
            .background(.systemCell)
        }
        
        struct SidebarButtonView: View {
            
            @EnvironmentObject var userObject: UserObject
            @EnvironmentObject var authManager: AuthManager
            
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
                    HStack(spacing: 15) {
                        Image(systemName: tabPage.icon)
                            .fontSize(20)
                            .fontWeight(.semibold)
                            .symbolVariant(.fill)
                            .foregroundStyle(selection == tabPage.id ? .white : .accent)
                            .frame(width: 25, height: 20)
                        Text(tabPage.label)
                            .fontSize(18)
                            .fontWeight(.medium)
                            .foregroundStyle(selection == tabPage.id ? .white : .systemContrast)
                        Spacer()
                    }
                    .padding(12.5)
                    .background {
                        RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                            .foregroundColor(selection == tabPage.id ? .accent.opacity(0.75) : .systemContrast.opacity(hovering ? 0.05 : 0))
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
                        message: Text("You must authenticate with a College Prep Account to edit courses."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        
        struct CourseButtonView: View {
            
            @EnvironmentObject var userObject: UserObject
            @EnvironmentObject var authManager: AuthManager
            
            @Binding var selection: String
            
            let icon: String
            let course: UserCourse
            
            @State var showAlert = false
            @State var hovering = false
            @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
            
            var body: some View {
                Button {
                    generateHaptic(.selection)
                    if(userObject.currentUser == nil || authManager.state == .parent) {
                        showAlert = true
                    } else {
                        selection = course.courseID
                    }
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: icon)
                            .fontSize(20)
                            .fontWeight(.semibold)
                            .symbolVariant(.fill)
                            .foregroundStyle(selection == course.courseID ? .white : course.freePeriod ? .gray : course.color.toScheduleIconColor(colorSpace: colorSpace))
                            .frame(width: 25, height: 20)
                        Text(course.freePeriod ? "Free Period" : course.name)
                            .fontSize(18)
                            .fontWeight(.medium)
                            .foregroundStyle(selection == course.courseID ? .white : .systemContrast)
                        Spacer()
                        HStack(spacing: 5) {
                            if course.name != course.courseID {
                                Text(course.courseID)
                                    .fontSize(18)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selection == course.courseID ? .white.opacity(0.75) : .systemContrast.opacity(0.75))
                            }
                            if !course.visibleRotation.isEmpty {
                                Image(systemName: course.visibleRotation+".circle")
                                    .fontSize(18)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selection == course.courseID ? .white.opacity(0.75) : .systemContrast.opacity(0.75))
                            }
                        }
                    }
                    .padding(12.5)
                    .background {
                        RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                            .foregroundColor(selection == course.courseID ? course.color.toScheduleIconColor(colorSpace: colorSpace).opacity(0.75) : .systemContrast.opacity(hovering ? 0.05 : 0))
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
        
        struct DefaultCourseButtonView: View {
            
            let icon: String
            let courseID: String
            
            @State var showAlert = false
            
            var body: some View {
                Button {
                    showAlert = true
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: icon)
                            .fontSize(20)
                            .fontWeight(.semibold)
                            .symbolVariant(.fill)
                            .foregroundStyle(defaultPalette[courseID]?.toP3Color() ?? .accent)
                            .frame(width: 25, height: 20)
                        Text(courseID)
                            .fontSize(18)
                            .fontWeight(.medium)
                            .foregroundStyle(.systemContrast)
                        Spacer()
                    }
                    .padding(12.5)
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
            
            @Binding var selection: String
            let tabPage = TabPageOption.settings
            
            var body: some View {
                Button {
                    generateHaptic(.selection)
                    selection = tabPage.id
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tabPage.icon)
                            .fontSize(18)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                        Text(tabPage.label)
                            .fontSize(18)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                    }
                }
                .buttonStyle(.scale)
                .padding()
                .padding(.trailing, 5)
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
}
