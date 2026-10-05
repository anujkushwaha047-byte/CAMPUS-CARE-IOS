//
//  CampusApp_iOS.swift
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

struct CampusApp_iOS: View {
    
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
    
    @AppStorage("notif_prefs_active", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsActive: [String: Bool] = ["class_starts": true, "class_ends": false, "club_starts": true]
    @AppStorage("notif_prefs_minutes", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsMinutes: [String: Int] = ["class_minutes": 5, "club_minutes": 5]
    
    @AppStorage("widget_blocks", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var widgetBlocks = [WidgetBlock]()
    
    var body: some View {
        ZStack {
            if setup && setupScreen == .auth {
                AuthSetupView(setupScreen: $setupScreen)
            } else if setup && setupScreen == .account {
                AccountSetupView(setupScreen: $setupScreen)
            } else if setup && setupScreen == .notifications {
                NotifSetupView(setupScreen: $setupScreen)
            } else if setup && setupScreen == .palettes {
                PaletteSetupView(setupScreen: $setupScreen)
            } else if parentSetup && setupScreen == .parents {
                ParentSetupView(setupScreen: $setupScreen, signInLink: parentSignInLink)
            } else {
                VStack(spacing: 0) {
                    TabView(selection: $selection) {
                        NavigationView {
                            HomeView()
                                .toolbar(.hidden, for: .tabBar)
                                .toolbarBackground(.hidden, for: .tabBar)
                                .ignoresSafeArea(.all, edges: [.bottom])
                        }
                        .tag(TabPageOption.home.id)
                        NavigationView {
                            CommunityView()
                                .toolbar(.hidden, for: .tabBar)
                                .toolbarBackground(.hidden, for: .tabBar)
                                .ignoresSafeArea(.all, edges: [.bottom])
                                .ignoresSafeArea(.keyboard)
                        }
                        .tag(TabPageOption.community.id)
                        NavigationView {
                            ScheduleView_iOS()
                                .toolbar(.hidden, for: .tabBar)
                                .toolbarBackground(.hidden, for: .tabBar)
                                .ignoresSafeArea(.all, edges: [.bottom])
                        }
                        .tag(TabPageOption.schedule.id)
                        NavigationView {
                            SettingsView_iOS()
                                .toolbar(.hidden, for: .tabBar)
                                .toolbarBackground(.hidden, for: .tabBar)
                                .ignoresSafeArea(.all, edges: [.bottom])
                        }
                        .tag(TabPageOption.settings.id)
                    }
                    Spacer().frame(height: 25)
                }
                .background(.systemWindow)
                .ignoresSafeArea(.keyboard)
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach(TabPageOption.allCases, id: \.self) { tabPage in
                            TabButtonView(selection: $selection, tabPage: tabPage)
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .padding(5)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .foregroundStyle(.bar)
                    }
                    .shadow(color: .gray.opacity(0.1), radius: 10, x: 0, y: 0)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.bar, lineWidth: 5)
                    }
                }
                .padding(.horizontal)
                .ignoresSafeArea(.keyboard)
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
                parentSetup = false
            }
        }
        .task {
            if KeychainManager.manager.hasObject(objectID: "campusID"),
               let campusID = KeychainManager.manager.readToken("campusID") {
                await fetchApplicationData(campusID: campusID)
                authManager.state = .signedIn
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background  {
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
    
    struct TabButtonView: View {
        
        @EnvironmentObject var userObject: UserObject
        @EnvironmentObject var authManager: AuthManager
        
        @Binding var selection: String
        let tabPage: TabPageOption
        
        @State var showAlert = false
        
        var body: some View {
            Button {
                if (userObject.currentUser == nil || authManager.state == .parent) && restrictedPages.contains(tabPage.id) {
                    showAlert = true
                } else {
                    generateHaptic(.selection)
                    selection = tabPage.id
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: tabPage.icon)
                        .fontSize(21)
                        .fontWeight(.semibold)
                        .symbolVariant(.fill)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(selection == tabPage.id ? .accent : .systemContrast.opacity(0.75))
                        .frame(height: 25)
                    Text(tabPage.label)
                        .fontSize(10)
                        .foregroundStyle(selection == tabPage.id ? .accent : .systemContrast.opacity(0.75))
                        .lineLimit(1)
                }
                .frame(minWidth: 50, maxWidth: .infinity)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .foregroundStyle(selection == tabPage.id ? .accent.opacity(0.1) : .clear)
                )
            }
            .buttonStyle(.scale)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Sign In"),
                    message: Text("You must authenticate with a College Prep Account to access."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
