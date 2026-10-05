//
//  ClubPageView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 9/4/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ClubPage: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var clubsObject: ClubsObject
    
    let club: Club
    
    @State var leaders = [User]()
    @State var members = [User]()
    
    @Binding var selection: String
    
    let columns2 = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            if clubsObject.allJoinedClubs().contains(club.clubID) == false && clubsObject.ledClubs.contains(where: { $0.clubID == club.clubID }) == false {
                VStack {
                    Button(action: {
                        Task {
                            await clubsObject.joinClub(clubID: club.clubID, isAnonymous: false, userObject: userObject)
                            clubsObject.joinedClubs.append(club.clubID)
                            if let currentUser = userObject.currentUser, members.contains(currentUser) == false {
                                members.append(currentUser)
                            }
                        }
                        generateHaptic(.impact(.heavy))
                    }, label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .body(weight: .semibold)
                                .foregroundStyle(.systemContrast)
                            Text("Join Club")
                                .body(weight: .semibold)
                                .foregroundStyle(.systemContrast)
                        }
                        .flushCenter(padding: true)
                        .buttonCellStyle(color: club.color.toClubColor(colorScheme: colorScheme))
                    })
                    .buttonStyle(.plain)
                    if club.category.lowercased().contains("affinities") {
                        Button(action: {
                            Task {
                                await clubsObject.joinClub(clubID: club.clubID, isAnonymous: true, userObject: userObject)
                                clubsObject.hiddenClubs.append(club.clubID)
                            }
                            generateHaptic(.impact(.heavy))
                        }, label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus.circle.fill")
                                    .body(weight: .semibold)
                                    .foregroundStyle(.systemContrast)
                                Text("Join Club Anonymously")
                                    .body(weight: .semibold)
                                    .foregroundStyle(.systemContrast)
                            }
                            .flushCenter(padding: true)
                            .buttonCellStyle(color: club.color.toClubColor(colorScheme: colorScheme))
                        })
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom)
            }
            
            HStack(spacing: 5) {
                Text(club.nickname == "" ? club.name : club.nickname)
                    .subheading()
                    .flushLeading(padding: true)
                    .lineLimit(2)
                    .foregroundStyle(.systemContrast)
                Text("#\(club.category)")
                    .body()
                    .foregroundStyle(club.color.toClubColor(colorScheme: colorScheme))
                    .flushTrailing(padding: true)
            }
            Text(club.description)
                .textSelection(.enabled)
                .flushLeading()
                .borderedCellStyle(cornerRadius: 15)
            
            ClubMeetingsView(selection: $selection, filter: [club.clubID], maxMeetings: 3)
                .padding(.bottom)
            if leaders.isEmpty == false {
                HStack {
                    Text("Leaders (\(leaders.count))")
                        .subheading()
                        .flushLeading(padding: true)
                        .overlay {
                            if leaders.count > 1 {
                                Menu {
                                    Button(action: {
                                        var emails = [String]()
                                        for leader in leaders {
                                            emails.append(leader.campusID+"@college-prep.org")
                                        }
                                        generateHaptic(.impact(.medium))
                                        copyStringToPasteboard(emails.joined(separator: ","))
                                    }, label: {
                                        Label("Copy Emails", systemImage: "paperplane")
                                    })
                                    .buttonStyle(.plain)
                                } label: {
                                    Image(systemName: "paperplane")
                                        .font(.title2)
                                        .foregroundStyle(club.color.toClubColor(colorScheme: colorScheme))
                                }
                                .frame(maxWidth: 50)
                                .flushTrailing(padding: true)
                            }
                        }
                }
                LazyVStack(spacing: 15) {
                    ForEach(leaders, id: \.self) { leader in
                        VStack {
                            Button(action: {
                                generateHaptic(.impact(.medium))
                                if let url = URL(string: "mailto:\(leader.campusID+"@college-prep.org")") {
                                    openURL(url)
                                }
                            }, label: {
                                VStack {
                                    HStack(spacing: 15) {
                                        if leader.privacy["hide_image", default: false] || leader.imageLink.isEmpty {
                                            Color.systemCellSecondary
                                                .frame(width: 55, height: 55)
                                                .clipShape(Circle())
                                            
                                        } else {
                                            WebImage(url: URL(string: leader.imageLink)) { image in
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
                                                Text(leader.gradYear == "Faculty" ? leader.name : leader.name+" '"+leader.gradYear.dropFirst(2))
                                                    .body(weight: .medium)
                                                    .foregroundStyle(.systemContrast)
                                                Spacer()
                                            }
                                            HStack {
                                                Text(leader.campusID+"@college-prep.org")
                                                    .foregroundStyle(club.color.toClubColor(colorScheme: colorScheme))
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Spacer()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            })
                            .buttonStyle(.plain)
                            if leader != leaders.last {
                                CapsuleDivider()
                            }
                        }
                    }
                }
                .borderedCellStyle()
                .padding(.bottom, 20)
            }
            if members.isEmpty == false {
                Text("Members (\(String(members.count)))")
                    .subheading()
                    .flushLeading(padding: true)
                LazyVStack(spacing: 10) {
                    ForEach(members, id: \.self) { member in
                        HStack(spacing: 15) {
                            if member.privacy["hide_image", default: false] || member.imageLink.isEmpty {
                                Color.systemCellSecondary
                                    .frame(width: 55, height: 55)
                                    .clipShape(Circle())
                            } else {
                                WebImage(url: URL(string: member.imageLink)) { image in
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
                                    Text(member.name)
                                        .body()
                                        .foregroundStyle(.systemContrast)
                                    Spacer()
                                }
                                HStack {
                                    Text(member.campusID + "@college-prep.org")
                                        .body()
                                        .foregroundStyle(.gray)
                                        .lineLimit(1).truncationMode(.tail)
                                    Spacer()
                                }
                            }
                        }
                        .flushLeading()
                        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        if member != members.last {
                            CapsuleDivider()
                        }
                    }
                }
                .borderedCellStyle()
                .onChange(of: clubsObject.joinedClubs) { newList in
                    if newList.contains(club.clubID) == false, let currentUser = userObject.currentUser {
                        members.removeAll(where: { $0.campusID == currentUser.campusID })
                    }
                }
            }
        }
        .task {
            await fetchLeaders()
            await fetchMembers()
        }
    }
    
    private func fetchLeaders() async {
        if let wrappedLeaders = await clubsObject.fetchClubLeaders(club: club) {
            leaders = wrappedLeaders.sorted(by: { $0.gradYear < $1.gradYear })
        }
    }
    
    private func fetchMembers() async {
        if let wrappedMembers = await clubsObject.fetchClubMembers(club: club) {
            members = wrappedMembers.sorted(by: {$0.name < $1.name})
        }
    }
}
