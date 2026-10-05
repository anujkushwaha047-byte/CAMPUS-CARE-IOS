//
//  PrefsNotifView.swift
//  CampusApp
//
//  Created on 6/30/2024
//  Built by Rahim Malik.
//

import SwiftUI
import FirebaseAuth

struct NotifSetupView: View {
    
    @EnvironmentObject var userObject: UserObject
    @Binding var setupScreen: PrefOption
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Step 2 of 3")
                    .font(.custom("Poppins-Medium", size: 16))
                    .flushCenter()
                Text("Notifications")
                    .font(.custom("Poppins-Bold", size: 24))
                    .flushCenter()
            }
            .padding(.vertical)
            .background(.systemCell)
            Divider()
            
            NotifPrefsView()
            
            Divider()
            Button {
                generateHaptic(.impact(.medium))
                withAnimation {
                    if userObject.currentUser != nil {
                        setupScreen = .palettes
                    } else {
                        setupScreen = .complete
                    }
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

struct NotifPrefsView: View {
    
    @EnvironmentObject var userObject: UserObject
    
    @Environment(\.openURL) var openURL
    
    @AppStorage("notif_prefs_active", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsActive: [String: Bool] = ["class_starts": true, "class_ends": false, "club_starts": true]
    @AppStorage("notif_prefs_minutes", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var notifPrefsMinutes: [String: Int] = ["class_minutes": 5, "club_minutes": 5]
    
    @State private var notifAllowed = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !notifAllowed {
                    Button {
#if os(iOS)
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
#elseif os(macOS)
                        openURL(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
#endif
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .caption()
                                .foregroundStyle(.systemOrange)
                            Text("Campus requires permission to send notifications. You can update these in Settings, then refresh this prompt.")
                                .caption()
                                .flushLeading()
                                .multilineTextAlignment(.leading)
                            Button {
                                Task {
                                    do {
                                        notifAllowed = try await NotifManager.requestAuthorization()
                                    } catch {
                                        ConsoleMessage(type: .internal, description: "NotifManager.requestAuthorization - \(error.localizedDescription)").error()
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.circlepath")
                                    .caption()
                                    .foregroundStyle(.systemOrange)
                            }
                        }
                        .padding()
                        .tintedCellStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical)
                }
                
                Text("Classes")
                    .subheading()
                    .flushLeading(padding: true)
                VStack(spacing: 15) {
                    NotifCell(title: "When Class Starts", isOn: Binding(
                        get: { notifPrefsActive["class_starts"] ?? false },
                        set: { newValue in notifPrefsActive["class_starts"] = newValue }
                    ))
                    CapsuleDivider()
                    NotifCell(title: "When Class Ends", isOn: Binding(
                        get: { notifPrefsActive["class_ends"] ?? false },
                        set: { newValue in notifPrefsActive["class_ends"] = newValue }
                    ))
                    CapsuleDivider()
                    HStack {
                        Text("\(Int(notifPrefsMinutes["class_minutes"] ?? 5)) min before")
                            .body()
                            .foregroundStyle(.accent)
                        Spacer()
                        Stepper("Headstart", value: Binding(
                            get: { notifPrefsMinutes["class_minutes"] ?? 5 },
                            set: { newValue in notifPrefsMinutes["class_minutes"] = newValue }
                        ), in: 0...5)
                        .labelsHidden()
                    }
                    .disabled(notifPrefsActive["class_starts"] == false)
                }
                .disabled(!notifAllowed)
                .borderedCellStyle()
                Text("Get a configurable notification before your next class starts or current class ends.")
                    .caption()
                    .flushLeading(padding: true)
                
                HStack {
                    Text("Clubs")
                        .subheading()
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                VStack(spacing: 15) {
                    NotifCell(title: "When Meeting Starts", isOn: Binding(
                        get: { notifPrefsActive["club_starts"] ?? false },
                        set: { newValue in notifPrefsActive["club_starts"] = newValue }
                    ))
                    CapsuleDivider()
                    HStack {
                        Text("\(Int(notifPrefsMinutes["club_minutes"] ?? 5)) min before")
                            .body()
                            .foregroundStyle(.accent)
                        Spacer()
                        Stepper("Headstart", value: Binding(
                            get: { notifPrefsMinutes["club_minutes"] ?? 5 },
                            set: { newValue in notifPrefsMinutes["club_minutes"] = newValue }
                        ), in: 0...5)
                        .labelsHidden()
                    }
                    .disabled(notifPrefsActive["club_starts"] == false)
                }
                .disabled(!notifAllowed)
                .borderedCellStyle()
                Text("Get a configurable notification before your meetings. You will only receive notifications from clubs you've joined.")
                    .caption()
                    .flushLeading(padding: true)
                
                Spacer().frame(height: 30)
                
            }.padding(20)
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
        .task {
            do {
                _ = try await NotifManager.requestAuthorization()
                notifAllowed = try await NotifManager.requestAuthorization()
            } catch {
                ConsoleMessage(type: .internal, description: "NotifManager.requestAuthorization - \(error.localizedDescription)").error()
            }
        }
    }
    
    struct NotifCell: View {
        var title: String
        @Binding var isOn: Bool
        
        var body: some View {
            HStack {
                Text(title)
                    .body()
                Spacer()
                Toggle(title, isOn: $isOn)
                    .tint(.accent)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}
