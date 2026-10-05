//
//  SettingsView.swift
//  CampusApp
//
//  Created on 6/17/2024
//  Built by Rahim Malik.
//

import SwiftUI
import SDWebImageSwiftUI

// MARK: - iOS

#if os(iOS)
struct SettingsView_iOS: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .heading()
                .flushLeading(padding: true)
                .padding(.horizontal)
                .padding(.vertical, 10)
            Divider()
            if authManager.state == .parent {
                SettingsParentView()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        SettingsAccountView()
                        SettingsGeneralView()
                        SettingsClassesView()
                        SettingsCommunityView()
                        Spacer().frame(height: 30)
                    }
                    .padding(20)
                }
            }
        }
        .background(.systemWindow)
    }
    
    struct SettingsAccountView: View {
        @EnvironmentObject var userObject: UserObject
        
        var body: some View {
            NavigationLink {
                StackView("Account", backButton: true) {
                    AccountPrefsView()
                }
            } label: {
                if let wrappedUser = userObject.currentUser {
                    HStack(spacing: 15) {
                        WebImage(url: URL(string: wrappedUser.imageLink)) { image in
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
                        VStack(spacing: 2) {
                            HStack {
                                Text(wrappedUser.name)
                                    .body()
                                    .foregroundStyle(.systemContrast)
                                Spacer()
                            }
                            HStack {
                                Text(wrappedUser.campusID + "@college-prep.org")
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
                } else {
                    SettingsPrefButton(label: "Account", icon: "person.crop.circle.fill", color: .accent)
                }
            }
            .borderedCellStyle()
        }
    }
    
    struct SettingsGeneralView: View {
        @EnvironmentObject var userObject: UserObject
        
        var body: some View {
            Text("General")
                .subheading()
                .flushLeading(padding: true)
                .padding(.top)
            VStack(spacing: 15) {
                NavigationLink {
                    StackView("Notifications", backButton: true) {
                        NotifPrefsView()
                    }
                } label: {
                    SettingsPrefButton(label: "Notifications", icon: "bell.badge.fill", color: .accent)
                }
                if userObject.currentUser != nil {
                    CapsuleDivider()
                    NavigationLink {
                        StackView("Palettes", backButton: true) {
                            PalettePrefsView()
                        }
                    } label: {
                        SettingsPrefButton(label: "Palettes", icon: "swatchpalette.fill", color: .accent)
                    }
                }
//                if let currentUser = userObject.currentUser, currentUser.gradYear.lowercased().trimmingCharacters(in: [" "]) != "faculty" {
//                    CapsuleDivider()
//                    NavigationLink {
//                        StackView("Parents", backButton: true) {
//                            ParentPrefsView()
//                        }
//                    } label: {
//                        SettingsPrefButton(label: "Parents", icon: "figure.and.child.holdinghands", color: .accent)
//                    }
//                }
            }
            .borderedCellStyle()
        }
    }
    
    struct SettingsClassesView: View {
        @EnvironmentObject var userObject: UserObject
        
        var body: some View {
            Text("Classes")
                .subheading()
                .flushLeading(padding: true)
                .padding(.top)
            VStack(spacing: 15) {
                ForEach(classCourseIDs, id: \.self) { classCourseID in
                    if let userCourse = userObject.courses.first(where: { $0.courseID == classCourseID }) {
                        NavigationLink {
                            StackView(userCourse.courseID, backButton: true) {
                                SettingsCourseView(course: userCourse, color: userCourse.color.toP3Color())
                            }
                        } label: {
                            SettingsCourseButton(icon: "book.closed.fill", course: userCourse)
                        }
                        if userCourse.courseID != classCourseIDs.last {
                            CapsuleDivider()
                        }
                    } else {
                        SettingsDefaultCourseButton(icon: "book.closed.fill", courseID: classCourseID)
                        if classCourseID != classCourseIDs.last {
                            CapsuleDivider()
                        }
                    }
                }
            }
            .borderedCellStyle()
        }
    }
    
    struct SettingsCommunityView: View {
        @EnvironmentObject var userObject: UserObject
        
        var body: some View {
            Text("Community")
                .subheading()
                .flushLeading(padding: true)
                .padding(.top)
            VStack(spacing: 15) {
                ForEach(communityCourseIDs, id: \.self) { communityCourseID in
                    if let userCourse = userObject.courses.first(where: { $0.courseID == communityCourseID }) {
                        NavigationLink {
                            StackView(userCourse.courseID, backButton: true) {
                                SettingsCourseView(course: userCourse, color: userCourse.color.toP3Color())
                            }
                        } label: {
                            SettingsCourseButton(icon: "person.fill", course: userCourse)
                        }
                        if userCourse.courseID != communityCourseIDs.last {
                            CapsuleDivider()
                        }
                    } else {
                        SettingsDefaultCourseButton(icon: "person.fill", courseID: communityCourseID)
                        if communityCourseID != communityCourseIDs.last {
                            CapsuleDivider()
                        }
                    }
                }
            }
            .borderedCellStyle()
        }
    }
    
    struct SettingsPrefButton: View {
        
        let label: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .fontSize(21)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .frame(width: 35, height: 30)
                Text(label)
                    .body()
                    .foregroundStyle(.systemContrast)
                    .flushLeading()
                Image(systemName: "chevron.right")
                    .body()
                    .foregroundStyle(color)
            }
        }
    }
    
    struct SettingsCourseButton: View {
        
        let icon: String
        let course: UserCourse
        
        @Environment(\.colorScheme) var colorScheme
        @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .fontSize(21)
                    .fontWeight(.semibold)
                    .foregroundStyle(course.freePeriod ? .gray : course.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                    .frame(width: 35, height: 30)
                Text(course.freePeriod ? "Free Period" : course.name)
                    .body()
                    .foregroundStyle(.systemContrast)
                    .flushLeading()
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    if course.name != course.courseID {
                        Text(course.courseID)
                            .body()
                            .foregroundStyle(.systemContrast.opacity(0.5))
                    }
                    if !course.visibleRotation.isEmpty {
                        Image(systemName: course.visibleRotation + ".circle")
                            .body(weight: .medium)
                            .foregroundStyle(.systemContrast.opacity(0.5))
                    }
                }
                .padding(.trailing, 5)
                Image(systemName: "chevron.right")
                    .body()
                    .foregroundStyle(course.freePeriod ? .gray : course.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
            }
        }
    }
    
    struct SettingsDefaultCourseButton: View {
        
        let icon: String
        let courseID: String
        
        @State var showAlert = false
        
        var body: some View {
            Button {
                showAlert = true
            } label: {
                HStack {
                    Image(systemName: icon)
                        .fontSize(21)
                        .fontWeight(.semibold)
                        .foregroundStyle(defaultPalette[courseID]?.toP3Color() ?? .accent)
                        .frame(width: 30, height: 30)
                    Text(courseID)
                        .body()
                        .foregroundStyle(.systemContrast)
                        .flushLeading()
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Sign In"),
                    message: Text("You must authenticate with a College Prep Account edit courses."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct SettingsParentView: View {
    
    @AppStorage("parentSetup", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var parentSetup = false
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    
    @State var children: [User] = []
    @State var loading = false
    
    @State var editChildren = false
    
    @State var showEmailAlert = false
    @State var emailAlertText = ""
    @State var showEmailTextfield = false
    @State var email = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !parentSetup {
                    HStack {
                        Text("Schedule")
                            .subheading()
                            .flushLeading(padding: true)
                        if authManager.state == .parent {
                            Button {
                                generateHaptic(.impact(.medium))
                                withAnimation {
                                    userObject.removeChildren()
                                    KeychainManager.manager.clear()
                                    authManager.state = .signedOut
                                }
                            } label: {
                                Text("Sign Out")
                                    .action()
                                    .foregroundStyle(.red)
                                    .textCase(.uppercase)
                            }
                            .buttonStyle(.scale)
                            .flushTrailing(padding: true)
                        }
                    }
                }
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ForEach(children, id: \.self) { child in
                        SettingsChildButton(child: child)
                    }
                    Button {
                        showEmailTextfield = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.accent)
                                .frame(height: 25)
                            Text("Add Child Email")
                                .body()
                            Spacer()
                        }
                        .borderedCellStyle()
                    }
                    .buttonStyle(.plain)
                    .flushCenter()
                    .alert("", isPresented: $showEmailTextfield) {
                        TextField("Email", text: $email)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                        Button("OK", action: onEmailSubmit)
                        Button("Cancel", role: .cancel, action: {
                            showEmailTextfield = false
                        })
                    } message: {
                        Text("Enter your child's College Prep email")
                    }
                    .alert(isPresented: $showEmailAlert) {
                        Alert(title: Text(emailAlertText), message: Text(""), dismissButton: .default(Text("OK"), action: {
                            email = ""
                        }))
                    }
                    Text("If your child has given you access, you can view their schedule but not edit it.")
                        .caption()
                        .flushLeading(padding: true)
                }
            }
            .padding(20)
            .task {
                loading = true
                children = await UserObject.fetchChildren(userObject.childCampusIDs)
                loading = false
            }
        }
        .scrollIndicators(.never)
        .task {
            await loadKeychainData()
        }
        Spacer()
    }
    
    private func onEmailSubmit() {
        if let campusID = campusIDFromEmail(email), email.isValidEmail() && userObject.childCampusIDs.contains(campusID) == false {
            Task {
                do {
                    // This fetchUser call must be made to verify that the user is a parent of the campus ID
                    // If it fails, then the catch block will be executed
                    let _ = try await UserObject.fetchUser(campusID: campusID)
                    userObject.childCampusIDs.append(campusID)
                    children = await UserObject.fetchChildren(userObject.childCampusIDs)
                    emailAlertText = "Child added"
                } catch {
                    emailAlertText = "Your child has not added you as a parent"
                }
                
                showEmailAlert = true
            }
        } else {
            if email.isValidEmail() == false {
                emailAlertText = "Invalid email"
            } else if email.contains("college-prep.org") == false || email.contains( "thecollegepreparatoryschool.org") == false {
                emailAlertText = "Please enter a College Prep email"
            } else {
                emailAlertText = "Child already added"
            }
            
            showEmailAlert = true
        }
    }
    
    private func loadKeychainData() async {
        do {
            if let childCampusID = KeychainManager.manager.readToken("childCampusID") {
                userObject.currentChild = try await UserObject.fetchUser(campusID: childCampusID)
            }
            if let childCampusIDs = KeychainManager.manager.readArray("childCampusIDs") {
                userObject.childCampusIDs = childCampusIDs
            }
        } catch {
            ConsoleMessage(type: .data, description: "loadKeychainData (in SettingsParentView) failed - \(error)").error()
        }
    }
}

struct SettingsChildButton: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    var child: User
    
    var body: some View {
        Button {
            generateHaptic(.impact(.medium))
            userObject.currentChild = child
            Task {
                await scheduleObject.fetchSchedule()
                do {
                    userObject.courses = try await UserObject.fetchCourses(campusID: child.campusID)
                } catch {
                    ConsoleMessage(type: .data, description: "Failed to fetch user courses - \(error)").error()
                }
            }
        } label: {
            HStack(spacing: 15) {
                if child.privacy["hide_image", default: false] || child.imageLink.isEmpty {
                    Color.systemCellSecondary
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                } else {
                    WebImage(url: URL(string: child.imageLink)) { image in
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
                Text(child.name)
                    .body()
                    .foregroundStyle(.systemContrast)
                    .flushLeading()
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: (userObject.currentChild == child) ? "checkmark.circle.fill" : "circle")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.accent)
                        .frame(height: 25)
                }
            }
            .flushLeading()
        }
        .buttonStyle(.plain)
        .flushCenter()
        .flushCenter()
        .borderedCellStyle()
    }
}
#endif


// MARK: - iPadOS

struct SettingsView_iPadOS: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var authManager: AuthManager
    @State var selection = PrefOption.account
    
    var body: some View {
        if authManager.state == .parent {
#if os(iOS)
            SettingsParentView()
#endif
        } else {
            StackView("", centeredToolbar: true) {
                VStack(spacing: 0) {
                    switch selection {
                    case .notifications:
                        NotifPrefsView()
                    case .palettes:
                        PalettePrefsView()
//#if os(iOS)
//                    case .parents:
//                        ParentPrefsView()
//#endif
                    default:
                        AccountPrefsView()
                    }
                }
            } toolbar: {
                Picker("Preferences", selection: $selection) {
                    Text("Account").tag(PrefOption.account)
                    Text("Notifications").tag(PrefOption.notifications)
                    if userObject.currentUser != nil {
                        Text("Palettes").tag(PrefOption.palettes)
#if os(iOS)
//                        Text("Parents").tag(PrefOption.parents)
#endif
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 400)
            }
        }
    }
}

// MARK: - macOS

typealias SettingsView_macOS = SettingsView_iPadOS
