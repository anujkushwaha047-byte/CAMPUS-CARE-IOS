//
//  CommView.swift
//  CampusApp
//
//  Created on 7/20/2021
//  Built by Rahim Malik.
//

import SwiftUI

#if os(iOS)
struct CommunityView: View {
    
    @State var communityMode = CommunityOption.directory
    @State var searchText = ""
    @State var directorySelection: User? = nil
    @State var clubsSelection: String = ""
    @FocusState var isFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CommunityHeader(communityMode: $communityMode, searchText: $searchText, clubsSelection: $clubsSelection, isFocused: $isFocused)
                if communityMode == .directory {
                    CommunityDirectoryView(searchText: searchText) { user in
                        directorySelection = user
                    }
                }
                if communityMode == .clubs {
                    CommunityClubsView(searchText: $searchText, selection: $clubsSelection)
                }
                Spacer().frame(height: 30)
            }
            if let user = directorySelection {
                StackView(user.name) {
                    CommunityDirectoryPage(user: user) { club in
                        generateHaptic(.impact(.medium))
                        directorySelection = nil
                        searchText = ""
                        communityMode = .clubs
                        clubsSelection = club.clubID
                    }
                } toolbar: {
                    Button {
                        generateHaptic(.impact(.medium))
                        directorySelection = nil
                        searchText = ""
                    } label: {
                        Text("Done")
                            .body()
                            .foregroundStyle(.accent)
                    }
                    .buttonStyle(.plain)
                    .flushTrailing()
                }
            }
        }
        .background(.systemWindow)
    }
    
    struct CommunityHeader: View {
        
        @Binding var communityMode: CommunityOption
        @Binding var searchText: String
        @Binding var clubsSelection: String
        @FocusState.Binding var isFocused: Bool
        
        @State var showSearch = false
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text("Community")
                        .heading()
                        .flushLeading(padding: true)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .overlay {
                            if communityMode == .clubs {
                                LeaveClubButton(selection: $clubsSelection)
                                    .flushTrailing(padding: true)
                            }
                        }
                }
                HStack {
                    if showSearch {
                        HStack(spacing: 7.5) {
                            Image(systemName: "magnifyingglass")
                                .fontSize(16)
                                .fontWeight(.medium)
                                .foregroundStyle(.accent)
                                .frame(height: 20)
                            TextField(communityMode == .clubs ? "Search for club" : "Search for students or faculty", text: $searchText)
                                .fontSize(16)
                                .fontWeight(.medium)
                                .foregroundStyle(.accent)
                                .submitLabel(.search)
                                .focused($isFocused)
                        }
                        .padding(.horizontal, 2.5)
                        .borderedCellStyle(padding: 12.5, cornerRadius: 15)
                    } else {
                        Button {
                            generateHaptic(.selection)
                            showSearch = true
                        } label: {
                            HStack(spacing: 7.5) {
                                Image(systemName: "magnifyingglass")
                                    .fontSize(16)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)
                                    .frame(height: 20)
                                Text("Search")
                                    .fontSize(16)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)
                                    .submitLabel(.search)
                                    .focused($isFocused)
                                    .onAppear {
                                        isFocused = true
                                    }
                            }
                            .padding(.horizontal, 2.5)
                            .borderedCellStyle(padding: 12.5, cornerRadius: 15)
                        }
                        .buttonStyle(.scale)
                    }
                    Button {
                        generateHaptic(.selection)
                        showSearch = false
                        communityMode = .directory
                    } label: {
                        CommunityHeaderCell(icon: "person.crop.circle", label: "Directory", expanded: communityMode == .directory, showSearch: showSearch)
                    }
                    .buttonStyle(.scale)
                    Button {
                        generateHaptic(.selection)
                        showSearch = false
                        communityMode = .clubs
                    } label: {
                        CommunityHeaderCell(icon: "theatermask.and.paintbrush", label: "Clubs", expanded: communityMode == .clubs, showSearch: showSearch)
                    }
                    .buttonStyle(.scale)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .onChange(of: showSearch) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFocused = true
                    }
                }
                .onChange(of: communityMode) { _ in
                    searchText = ""
                }
                Divider()
            }
        }
        
        struct CommunityHeaderCell: View {
            
            let icon: String
            let label: String
            let expanded: Bool
            var showSearch: Bool
            
            var body: some View {
                if expanded && !showSearch {
                    HStack(spacing: 7.5) {
                        Image(systemName: icon)
                            .fontSize(16)
                            .fontWeight(.medium)
                            .symbolVariant(.fill)
                            .foregroundStyle(.accent)
                        Text(label)
                            .fontSize(16)
                            .fontWeight(.medium)
                            .textCase(.uppercase)
                            .foregroundStyle(.accent)
                    }
                    .frame(height: 20)
                    .flushCenter()
                    .borderedCellStyle(color: .accent.opacity(0.15), padding: 12.5, cornerRadius: 15)
                } else {
                    HStack {
                        Image(systemName: icon)
                            .fontSize(16)
                            .fontWeight(.medium)
                            .symbolVariant(.fill)
                            .foregroundStyle(.accent)
                    }
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 2.5)
                    .borderedCellStyle(color: expanded ? .accent.opacity(0.15) : .systemCell, padding: 12.5, cornerRadius: 15)
                }
            }
        }
    }
}
#endif

#if os(macOS)
struct CommunityView_macOS: View {
    
    @State var communityMode: CommunityOption
    
    // defaultClubID allows CommunityView_macOS to have a specific club opened when it appears
    var defaultClubID: Binding<String>? = nil
    
    let openClub: ((Club) -> ())?
    @State var searchText = ""
    @State var clubsSelection = ""
    
    @State var directoryWindows: [NSWindow] = []
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var clubsObject: ClubsObject
    
    // Show clubs view with certain certain club on appear
    // Or, show club home by passing in empty string
    init(defaultClubID: Binding<String>) {
        communityMode = .clubs
        self.defaultClubID = defaultClubID
        openClub = nil
    }
    
    // From directory view, show certain club
    init(openClub: @escaping (Club) -> ()) {
        communityMode = .directory
        self.openClub = openClub
    }
    
    var body: some View {
        StackView(communityMode == .directory ? "Directory" : "Clubs") {
            VStack(spacing: 0) {
                if communityMode == .directory {
                    CommunityDirectoryView(searchText: searchText) { user in
                        let directoryWindow = CommunityDirectoryPage(user: user) { club in
                            searchText = ""
                            
                            openClub?(club)
                        }
                        .environmentObject(userObject)
                        .environmentObject(clubsObject)
                        .frame(minWidth: 500, minHeight: 700)
                        .openInWindow(title: user.name, isClear: false, sender: self)
                        
                        directoryWindows.append(directoryWindow)
                    }
                    .onDisappear {
                        for directoryWindow in directoryWindows {
                            directoryWindow.close()
                        }
                        
                        directoryWindows = []
                    }
                }
                if communityMode == .clubs {
                    CommunityClubsView(searchText: $searchText, selection: $clubsSelection)
                        .id(clubsSelection)
                        .onAppear {
                            if let defaultClubID = defaultClubID {
                                clubsSelection = defaultClubID.wrappedValue
                            }
                        }
                }
            }
            .background(.systemWindow)
        } toolbar: {
            HStack {
                HStack(spacing: 7.5) {
                    Image(systemName: "magnifyingglass")
                        .fontSize(14)
                        .fontWeight(.medium)
                        .foregroundStyle(.accent)
                    TextField(communityMode == .directory ? "Search for students or faculty" : "Search for clubs or meetings", text: $searchText)
                        .fontSize(14)
                        .fontWeight(.medium)
                        .foregroundStyle(.accent)
                        .textFieldStyle(.plain)
                }
                .borderedCellStyle(padding: 7.5, cornerRadius: 10)
                .frame(width: 350)
                if communityMode == .clubs {
                    LeaveClubButton(selection: $clubsSelection)
                }
            }
            .flushTrailing(padding: true)
        }
    }
}
#endif
