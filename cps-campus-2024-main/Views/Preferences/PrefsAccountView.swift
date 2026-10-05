//
//  PrefsAccountView.swift
//  CampusApp
//
//  Created on 6/30/2024
//  Built by Rahim Malik.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct AuthSetupView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    
    @Binding var setupScreen: PrefOption
    
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 5) {
                Image(.campusIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22.5, style: .continuous))
                HStack(spacing: 3) {
                    Spacer()
                    Text("Campus")
                        .font(.custom("Poppins-Bold", size: 48))
                    Spacer()
                }
            }
            Text("Sign in with your College Prep Account to access **course customization, palettes, directory, clubs, Common Classroom,** and **RHF** features.")
                .body()
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: 5) {
                Button {
                    generateHaptic(.impact(.medium))
                    authManager.signInWithGoogle()
                } label: {
                    HStack {
                        Image(.googleLogo)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.white)
                            .frame(height: 20)
                        Text("Sign in with Google")
                            .button()
                            .foregroundStyle(.white)
                    }
                    .buttonCellStyle()
                }
                .buttonStyle(.scale)
//                Button {
//                    generateHaptic(.impact(.medium))
//                    authManager.signInAnonymously()
//                } label: {
//                    HStack {
//                        Spacer()
//                        Text("Continue as Parent")
//                            .button()
//                            .foregroundStyle(.accent)
//                        Spacer()
//                    }
//                    .padding()
//                }
//                .buttonStyle(.scale)
            }
        }
        .padding(30)
        .background(.systemWindow)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Account"),
                message: Text("You must authenticate with a College Prep Account registered to an attending student or faculty member."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(authManager.statePublisher) { _ in
            Task {
                if authManager.state == .signedIn {
                    if let wrappedUser = Auth.auth().currentUser {
                        if let campusID = campusIDFromEmail(wrappedUser.email) {
                            do {
                                let user = try await UserObject.fetchUser(campusID: campusID)
                                // user exists in database
                                KeychainManager.manager.saveToken(campusID, tokenID: "campusID")
                                userObject.addUserListener(campusID: user.campusID)
                                withAnimation {
                                    setupScreen = .account
                                }
                            } catch {
                                ConsoleMessage(type: .data, description: "valid email but not found in database").error()
                            }
                        } else {
                            try Auth.auth().signOut()
                            showAlert = true
                        }
                    }
                }
                if authManager.state == .anonymous {
                    if Auth.auth().currentUser != nil {
                        withAnimation {
                            setupScreen = .notifications
                        }
                    }
                }
            }
        }
        .onChange(of: showAlert) { newValue in
                    if newValue == false {
                        authManager.showGoogleSignInWindow()
                    }
                }
        .transition(.slideWithOpacity)
    }
}

struct AccountSetupView: View {
    
    @EnvironmentObject var userObject: UserObject
    
    @Binding var setupScreen: PrefOption
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Step 1 of 3")
                    .font(.custom("Poppins-Medium", size: 16))
                    .flushCenter()
                Text("Account")
                    .font(.custom("Poppins-Bold", size: 24))
                    .flushCenter()
            }
            .padding(.vertical)
            .background(.systemCell)
            Divider()
            
            AccountPrefsView()
            
            Divider()
            Button {
                generateHaptic(.impact(.medium))
                withAnimation {
                    setupScreen = .notifications
                }
            } label: {
                Text("Continue")
                    .button()
                    .foregroundStyle(.white)
                    .buttonCellStyle()
            }
            .buttonStyle(.scale)
            .padding(20)
            .background(.systemCell)
        }
        .transition(.slideWithOpacity)
    }
}

struct AccountPrefsView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            if let wrappedUser = userObject.currentUser {
                AccountPrefsSection(user: wrappedUser)
            } else {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        Image(.campusIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .borderedCellStyle(padding: 0)
                        HStack(spacing: 3) {
                            Spacer()
                            Text("Campus")
                                .font(.custom("Poppins-Bold", size: 36))
                            Spacer()
                        }
                        Text("Sign in with your College Prep Account to access **course customization, palettes, directory, clubs, Common Classroom,** and **RHF** features.")
                            .body()
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical)
                    .borderedCellStyle()
                    Button {
                        generateHaptic(.impact(.medium))
                        authManager.signInWithGoogle()
                    } label: {
                        HStack {
                            Image(.googleLogo)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.white)
                                .frame(height: 20)
                            Text("Sign in with Google")
                                .button()
                                .foregroundStyle(.white)
                        }
                        .buttonCellStyle()
                    }
                    .buttonStyle(.scale)
                    .padding(.top)
                }
                .padding(20)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Invalid Account"),
                        message: Text("You must authenticate with a College Prep Account registered to an attending student or faculty member."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
        .onReceive(authManager.statePublisher) { _ in
            Task {
                if authManager.state == .signedIn {
                    if let wrappedUser = Auth.auth().currentUser {
                        if let campusID = campusIDFromEmail(wrappedUser.email) {
                            do {
                                let user = try await UserObject.fetchUser(campusID: campusID)
                                // user exists in database
                                KeychainManager.manager.saveToken(campusID, tokenID: "campusID")
                                userObject.addUserListener(campusID: user.campusID)
                            } catch {
                                showAlert = true
                                ConsoleMessage(type: .data, description: "valid email but not found in database").error()
                            }
                        } else {
                            try Auth.auth().signOut()
                            authManager.signInAnonymously()
                            showAlert = true
                        }
                    }
                }
            }
        }
        .onChange(of: showAlert) { newValue in
                    if newValue == false {
                        authManager.showGoogleSignInWindow()
                    }
                }
    }
    
    struct AccountPrefsSection: View {
        
        @EnvironmentObject var authManager: AuthManager
        @EnvironmentObject var userObject: UserObject
        
        let user: User
        
        @State private var pronouns = ""
        @State private var bio = ""
        @State private var privacy = [String: Bool]()
        @State private var socials = [String: String]()
        
        @State var editSocials = false
        @State var showBioButton = false
        
        @State var showingKeyboard = false
        @FocusState var isFocused: Bool
        
        var body: some View {
            VStack(spacing: 10) {
                HStack {
                    Text("Profile")
                        .subheading()
                        .flushLeading(padding: true)
                    Button {
                        generateHaptic(.impact(.medium))
                        withAnimation {
                            userObject.removeUser()
                            authManager.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .action()
                            .foregroundStyle(.red)
                            .textCase(.uppercase)
                    }
                    .buttonStyle(.scale)
                }
                .padding(.trailing)
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
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
                    }
                    CapsuleDivider()
                    HStack {
                        Text("Graduation Year")
                            .body()
                        Spacer()
                        Text(user.gradYear)
                            .body()
                    }
                    CapsuleDivider()
                    HStack {
                        Text("Pronouns")
                            .body()
                        Spacer()
                        TextField("Edit", text: $pronouns)
                            .body()
                            .textFieldStyle(.plain)
#if os(iOS)
                            .autocapitalization(.none)
#endif
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.accent)
                            .onSubmit {
                                Task {
                                    await userObject.updateUserPreferences(pronouns: pronouns, bio: bio, privacy: privacy, socials: socials)
                                }
                            }
                    }
                }
                .borderedCellStyle()
                Text("This information, including any pronouns you enter, will be visible to only **students and faculty**.")
                    .caption()
                    .flushLeading(padding: true)
                
                HStack {
                    Text("Bio")
                        .subheading()
                        .flushLeading(padding: true)
                    if showBioButton {
                        Button {
                            generateHaptic(.impact(.medium))
                            showBioButton = false
                            isFocused = false
                            Task {
                                await userObject.updateUserPreferences(pronouns: pronouns, bio: bio, privacy: privacy, socials: socials)
                            }
                        } label: {
                            Text("Done")
                                .action()
                                .foregroundStyle(.accent)
                                .textCase(.uppercase)
                        }
                        .buttonStyle(.scale)
                    }
                    
                }
                .padding(.trailing)
                .padding(.top)
#if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    showBioButton = true
                }
#endif
                VStack(spacing: 15) {
                    TextField("Edit", text: $bio, axis: .vertical)
                        .body()
                        .lineLimit(4)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            Task {
                                await userObject.updateUserPreferences(pronouns: pronouns, bio: bio, privacy: privacy, socials: socials)
                            }
                        }
                }
                .borderedCellStyle()
                Text("Write up a short bio, only visible to other students, so they can get to know you.")
                    .caption()
                    .flushLeading(padding: true)
                
                HStack {
                    Text("Socials")
                        .subheading()
                        .flushLeading(padding: true)
                    Button {
                        generateHaptic(.impact(.medium))
                        withAnimation {
                            editSocials.toggle()
                        }
                    } label: {
                        Text("Edit")
                            .action()
                            .foregroundStyle(.accent)
                            .textCase(.uppercase)
                    }
                    .buttonStyle(.scale)
                }
                .padding(.trailing)
                .padding(.top)
                VStack(spacing: 15) {
                    ForEach(Array(socials.keys).sorted { $0 < $1 }, id: \.self) { key in
                        if let value = socials[key] {
                            HStack(spacing: 10) {
                                if editSocials {
                                    Button {
                                        generateHaptic(.impact(.medium))
                                        socials.removeValue(forKey: key)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .body()
                                            .symbolRenderingMode(.multicolor)
                                    }
                                    .buttonStyle(.scale)
                                }
                                SocialCell(key: key, value: value, socials: $socials)
                            }
                            CapsuleDivider()
                        }
                    }
                    Menu(content: {
                        ForEach(socialOptions, id: \.self) { social in
                            if socials[social] == nil {
                                Button {
                                    socials[social] = ""
                                } label: {
                                    Text(social)
                                        .body()
                                }
                            }
                        }
                    }, label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .body()
                                .foregroundStyle(.accent)
                            Text("Add Social")
                                .body()
                                .foregroundStyle(.accent)
                                .flushLeading()
                        }
                    })
                }
                .borderedCellStyle()
                Text("Add any socials that **only students** can use to keep in touch with you.")
                    .caption()
                    .flushLeading(padding: true)
                
                Text("Privacy")
                    .subheading()
                    .flushLeading(padding: true)
                    .padding(.top)
                VStack(spacing: 15) {
                    PrivacyCell(
                        title: "Hide Profile Picture",
                        isOn: Binding(
                            get: { privacy["hide_image"] ?? false },
                            set: { newValue in privacy["hide_image"] = newValue }
                        )
                    )
                    CapsuleDivider()
                    PrivacyCell(
                        title: "Hide Classes",
                        isOn: Binding(
                            get: { privacy["hide_classes"] ?? false },
                            set: { newValue in privacy["hide_classes"] = newValue }
                        )
                    )
                }
                .borderedCellStyle()
                
                Text("Hide your profile picture and classes from **other students and faculty** at school.")
                    .caption()
                    .flushLeading(padding: true)
                
                Spacer().frame(height: 30)
                
            }
            .padding(20)
            .onAppear {
                if let wrappedUser = userObject.currentUser {
                    pronouns = wrappedUser.pronouns
                    bio = wrappedUser.bio
                    socials = wrappedUser.socials
                    privacy = wrappedUser.privacy
                }
            }
            .onChange(of: userObject.currentUser) { _ in
                if let wrappedUser = userObject.currentUser {
                    pronouns = wrappedUser.pronouns
                    bio = wrappedUser.bio
                    socials = wrappedUser.socials
                    privacy = wrappedUser.privacy
                }
            }
            .onChange(of: socials) { _ in
                Task {
                    await userObject.updateUserPreferences(pronouns: pronouns, bio: bio, privacy: privacy, socials: socials)
                }
            }
            .onChange(of: privacy) { _ in
                Task {
                    await userObject.updateUserPreferences(pronouns: pronouns, bio: bio, privacy: privacy, socials: socials)
                }
            }
        }
        
        struct SocialCell: View {
            let key: String
            @State var value: String
            @Binding var socials: [String: String]
            
            var body: some View {
                HStack {
                    Text(key)
                        .body()
                    Spacer()
                    TextField("Edit", text: $value)
                        .body()
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
#if os(iOS)
                        .autocapitalization(.none)
#endif
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.accent)
                        .onSubmit {
                            socials[key] = value
                        }
                }
            }
        }
        
        struct PrivacyCell: View {
            let title: String
            @Binding var isOn: Bool
            
            var body: some View {
                HStack {
                    Text(title)
                        .body()
                    Spacer()
                    Toggle(title, isOn: $isOn)
                        .toggleStyle(.switch)
                        .tint(.accent)
                        .labelsHidden()
                }
            }
        }
    }
}
