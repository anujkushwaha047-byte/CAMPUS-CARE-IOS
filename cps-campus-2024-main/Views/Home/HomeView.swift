//
//  HomeView.swift
//  CampusApp
//
//  Created on 7/11/2021
//  Built by Rahim Malik.
//

import SwiftUI

#if os(iOS)
struct HomeView: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var ccObject: CCObject
    
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("home_arrangement_12.0", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var arrangement: [HomePageItem] = defaultHomePage
    @AppStorage("home_quicklinks_12.0", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var quickLinks: [QuickLink] = defaultQuickLinks
    
    @State var showEditMode: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HomeHeader(arrangement: $arrangement, quickLinks: $quickLinks)
            ScrollView {
                VStack(spacing: 10) {
                    HomeNowView()
                    if userObject.currentUser != nil {
                        ForEach(arrangement, id: \.self) { item in
                            if item.id == "Map" && item.visible {
                                HomeMapView()
                            }
                            if item.id == "RHF" && item.visible {
                                HomeRHFView()
                            }
                            if item.id == "Links" && item.visible && !quickLinks.filter({ $0.visible }).isEmpty {
                                HomeQLView()
                            }
                        }
                    }
                    HomeAcknowView()
                    Spacer().frame(height: 30)
                }
                .padding(20)
            }
            .scrollIndicators(.never)
        }
        .background(.systemWindow)
    }
    
    struct HomeHeader: View {
        
        @EnvironmentObject var authManager: AuthManager
        
        @Binding var arrangement: [HomePageItem]
        @Binding var quickLinks: [QuickLink]
        
        @State private var showEditMode = false
        
        var body: some View {
            Group {
                HStack {
                    Text("Home")
                        .heading()
                        .flushLeading(padding: true)
                    if authManager.state != .parent {
                        Button {
                            generateHaptic(.impact(.medium))
                            showEditMode.toggle()
                        } label: {
                            Text("Edit")
                                .action()
                                .foregroundStyle(.accent)
                                .textCase(.uppercase)
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider()
            }
            .sheet(isPresented: $showEditMode) {
                StackView("Customize") {
                    HomeConfigView(arrangement: $arrangement, quickLinks: $quickLinks)
                }
            }
        }
    }
}
#endif

#if os(macOS)
struct HomeView_macOS: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var ccObject: CCObject
    
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("home_arrangement_12.0", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var arrangement: [HomePageItem] = defaultHomePage
    @AppStorage("home_quicklinks_12.0", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var quickLinks: [QuickLink] = defaultQuickLinks
    
    @State var showEditMode: Bool = false
    
    var body: some View {
        StackView("Home") {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 10) {
                        HomeNowView()
                        ForEach(arrangement, id: \.self) { item in
                            if item.id == "RHF" && item.visible {
                                HomeRHFView()
                            }
                            if item.id == "Links" && item.visible && !quickLinks.filter({ $0.visible }).isEmpty {
                                HomeQLView()
                            }
                        }
                        HomeAcknowView()
                    }
                    .padding(20)
                }
                .scrollIndicators(.never)
            }
            .background(.systemWindow)
        } toolbar: {
            Button {
                generateHaptic(.impact(.medium))
                showEditMode.toggle()
            } label: {
                Text("Edit")
                    .action()
                    .foregroundStyle(.accent)
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .frame(height: 35)
                    .toolbarHoverEffect()
            }
            .buttonStyle(.scale)
            .popover(isPresented: $showEditMode) {
                HomeConfigView(arrangement: $arrangement, quickLinks: $quickLinks)
                    .frame(width: 300, height: 375)
            }
            .flushTrailing()
        }
    }
}
#endif
