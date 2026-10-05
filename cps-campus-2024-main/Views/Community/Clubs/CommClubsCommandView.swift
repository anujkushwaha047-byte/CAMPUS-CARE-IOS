//
//  ClubCommandView.swift
//  CampusApp
//
//  Created by Marcus Gallardo on 9/4/24.
//

import SwiftUI

struct ClubCommandView: View {
    
    @EnvironmentObject var clubsObject: ClubsObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    let ledClubs: [Club]
    let defaultLedClub: Club
    
    let columns2 = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        LazyVGrid(columns: columns2) {
            ClubCommandButton("Add Meeting", icon: "calendar.badge.plus") {
                AddMeetingView(selectedClub: defaultLedClub.clubID, isBakeSale: false)
                    .environmentObject(clubsObject)
                    .environmentObject(scheduleObject)
            }
#if os(macOS)
            ClubCommandButton("Add Bake Sale", icon: "birthday.cake.fill") {
                AddMeetingView(selectedClub: defaultLedClub.clubID, isBakeSale: true)
                    .environmentObject(clubsObject)
                    .environmentObject(scheduleObject)
            }
#else
            ClubCommandButton("Add \nBake Sale", icon: "birthday.cake.fill") {
                AddMeetingView(selectedClub: defaultLedClub.clubID, isBakeSale: true)
                    .environmentObject(clubsObject)
                    .environmentObject(scheduleObject)
            }
#endif
//            ClubCommandButton("Add Link", icon: "link.circle") {
//                Text("Test")
//            }
//            ClubCommandButton("Show QR Code", icon: "qrcode") {
//                Text("Test")
//            }
        }
    }
    
    private struct ClubCommandButton<Content: View>: View {
        
        let text: String
        let icon: String
        let content: Content
        
        @State var showSheet: Bool = false
        
        init(_ text: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
            self.text = text
            self.icon = icon
            self.content = content()
        }
        
        var body: some View {
            #if os(iOS)
            Button {
                showSheet.toggle()
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.accent)
                        .symbolVariant(.fill)
                        .frame(width: 40, height: 35)
                    Text(text)
                        .body(weight: .semibold)
                        .foregroundStyle(.systemContrast)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .frame(height: 30)
                .borderedCellStyle()
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .buttonStyle(.plain)
            .sheet(isPresented: $showSheet) {
                StackView(text.replacingOccurrences(of: "\n", with: ""), fontSize: 18, cancelButton: true) {
                    content
                }
            }
            #else
                Button(action: {
                content
                    .frame(minWidth: 500, minHeight: 700)
                    .openInWindow(title: text, isClear: false, sender: self)
                }, label: {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundStyle(.accent)
                            .symbolVariant(.fill)
                            .frame(width: 40, height: 35)
                        Text(text)
                            .body(weight: .semibold)
                            .foregroundStyle(.systemContrast)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Spacer()
                    }
                    .frame(height: 30)
                    .borderedCellStyle()
                })
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .buttonStyle(.plain)
            #endif
        }
    }
}
