//
//  PrefsParentView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 11/29/24.
//

// Firebase Dynamic Links are only available on iOS
#if os(iOS)
import SwiftUI
import SDWebImageSwiftUI

struct ParentPrefsView: View {
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userObject: UserObject
    
    @State var editParents = false
    @State var parents = [String]()
    
    @State var showEmailAlert = false
    @State var emailAlertText = ""
    @State var showEmailTextfield = false
    @State var email = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text("Emails")
                        .subheading()
                        .flushLeading(padding: true)
                    Button {
                        withAnimation {
                            editParents.toggle()
                        }
                    } label: {
                        Text(editParents ? "Done" : "Edit")
                            .button()
                            .foregroundStyle(.accent)
                            .flushTrailing(padding: true)
                    }
                }
                VStack(spacing: 15) {
                    VStack {
                        ForEach(parents, id: \.self) { email in
                            HStack {
                                if editParents {
                                    Button {
                                        generateHaptic(.impact(.medium))
                                        withAnimation {
                                            parents.removeAll(where: { $0 == email })
                                        }
                                        Task {
                                            await userObject.updateUserPreferences(parents: parents)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .body()
                                            .symbolRenderingMode(.multicolor)
                                    }
                                    .buttonStyle(.scale)
                                }
                                ParentCell(email: email)
                            }
                            .borderedCellStyle()
                        }
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
                            Text("Add Parent Email")
                                .body()
                            Spacer()
                        }
                        .borderedCellStyle()
                    }
                    .buttonStyle(.plain)
                    .flushLeading(padding: false)
                    .alert("Enter your parent's email", isPresented: $showEmailTextfield) {
                        TextField("Email", text: $email)
                            .autocorrectionDisabled()
                            .autocorrectionDisabled()
                        Button("OK", action: onEmailSubmit)
                        Button("Cancel", role: .cancel, action: {
                            showEmailTextfield = false
                        })
                    } message: {
                        Text("")
                    }
                    .alert(isPresented: $showEmailAlert) {
                        Alert(title: Text(emailAlertText), message: Text(""), dismissButton: .default(Text("OK"), action: {
                            email = ""
                        }))
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .task {
            if let currentUser = userObject.currentUser {
                parents = currentUser.parents
            }
        }
    }
    
    private struct ParentCell: View {
        
        @EnvironmentObject var authManager: AuthManager
        
        @State var showSentAlert: Bool = false
        
        var email: String
        
        var body: some View {
            HStack {
                Text(email)
                    .body()
                    .flushLeading(padding: false)
                Button {
                    authManager.sendEmailSignInLink(to: email)
                    showSentAlert = true
                } label: {
                    Image(systemName: "paperplane")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.accent)
                        .frame(height: 25)
                }
                .alert(isPresented: $showSentAlert) {
                    Alert(title: Text("Sign-in Link Sent"), message: Text(""), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    private func onEmailSubmit() {
        if email.isValidEmail() && parents.contains(email) == false {
            parents.append(email.lowercased())
            Task {
                await userObject.updateUserPreferences(parents: parents)
                authManager.sendEmailSignInLink(to: email)
            }
            emailAlertText = "A sign-in link has been sent to \(email.lowercased())"
        } else {
            emailAlertText = email.isValidEmail() == false ? "Please enter a valid email" : "Parent already added"
        }
        
        showEmailAlert = true
    }
}

struct ParentSetupView: View {
    
    @AppStorage("parentSetup", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var parentSetup = false
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var authManager: AuthManager
    
    @Binding var setupScreen: PrefOption
    
    let signInLink: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.state != .parent {
                VStack {
                    Text("Step 1 of 2")
                        .font(.custom("Poppins-Medium", size: 16))
                        .flushCenter()
                    Text("Sign In")
                        .font(.custom("Poppins-Bold", size: 24))
                        .flushCenter()
                }
                .padding(.vertical)
                .background(.systemCell)
                Divider()
                if let wrappedSignInLink = signInLink {
                    SignInView(setupScreen: $setupScreen, signInLink: wrappedSignInLink)
                } else {
                    VStack {
                        Spacer()
                        Text("Invalid sign in link. Have your child re-send the sign in link in their app, and make sure to use the lastest one. Each link is one-time use only.")
                            .body()
                        Spacer()
                        Button {
                            userObject.removeUser()
                            authManager.signOut()
                            KeychainManager.manager.clear()
                            generateHaptic(.impact(.medium))
                            parentSetup = false
                            withAnimation {
                                setupScreen = .complete
                            }
                        } label: {
                            Text("Close")
                                .button()
                                .foregroundStyle(.white)
                                .buttonCellStyle()
                        }
                        .buttonStyle(.scale)
                        .padding(20)
                        .background(.systemCell)
                    }
                }
            }
            
            if authManager.state == .parent {
                VStack {
                    Text("Step 2 of 2")
                        .font(.custom("Poppins-Medium", size: 16))
                        .flushCenter()
                    Text("Schedule")
                        .font(.custom("Poppins-Bold", size: 24))
                        .flushCenter()
                }
                .padding(.vertical)
                .background(.systemCell)
                
                Text("Add your child by entering their College Prep email address.")
                    .body()
                    .padding()
                SettingsParentView()
                Divider()
                Button {
                    generateHaptic(.impact(.medium))
                    parentSetup = false
                    setupScreen = .complete
                } label: {
                    Text("Done")
                        .button()
                        .foregroundStyle(.systemContrast)
                        .buttonCellStyle()
                        .disabled(userObject.currentChild == nil)
                }
                .buttonStyle(.scale)
                .padding()
                Button {
                    generateHaptic(.impact(.medium))
                    userObject.removeUser()
                    authManager.signOut()
                    parentSetup = false
                    withAnimation {
                        setupScreen = .complete
                    }
                } label: {
                    Text("Cancel")
                        .button()
                        .foregroundStyle(.systemContrast)
                }
                .buttonStyle(.scale)
                .padding()
            }
        }
        .onAppear {
            parentSetup = true
        }
    }
    
    private struct SignInView: View {

        @EnvironmentObject var userObject: UserObject
        @EnvironmentObject var authManager: AuthManager
        
        @Binding var setupScreen: PrefOption

        var signInLink: String
        
        @State var showAlert: Bool = false
        @State var alertTitle = ""
        @State var alertMessage = ""
        
        @State var loading = false
        
        @State var email: String = ""
        
        var body: some View {
            VStack(spacing: 0) {
                Text("Enter your email address")
                    .subheading()
                    .flushLeading(padding: true)
                TextField("Email", text: $email)
                    .body()
                    .foregroundStyle(.systemContrast)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .borderedCellStyle()
                    .padding(.vertical)
                Text("Use the same one which received the link.")
                    .caption()
                    .flushLeading(padding: true)
            }
            .padding()
            Spacer()
            Divider()
            VStack {
                Button {
                    generateHaptic(.impact(.medium))
                    if email.isValidEmail() == false {
                        alertTitle = "Invalid Email"
                        alertMessage = ""
                        showAlert = true
                    } else {
                        loading = true
                        withAnimation {
                            authManager.handleSignInLink(link: signInLink, for: email) { success in
                                if !success {
                                    alertTitle = "Failed to Sign In"
                                    alertMessage = "If you have received multiple sign-in links, make sure that you are using the most recent one. Links are one-time use only."
                                    showAlert = true
                                } else {
                                    // Parent sucessfully signed in
                                    userObject.removeUser()
                                    KeychainManager.manager.delete("campusID")
                                    authManager.state = .parent
                                }
                                loading = false
                            }
                        }
                    }
                } label: {
                    Text("Continue")
                        .button()
                        .foregroundStyle(.white)
                        .buttonCellStyle()
                        .opacity(loading ? 0.2 : 1)
                        .overlay {
                            if loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.scale)
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
               
                Button {
                    userObject.removeUser()
                    authManager.signOut()
                    KeychainManager.manager.clear()
                    withAnimation {
                        setupScreen = .complete
                    }
                } label: {
                    Text("Cancel")
                        .button()
                        .foregroundStyle(.accent)
                }
                .padding(.bottom)
            }
            .background(.systemCell)
        }
    }
}
#endif
