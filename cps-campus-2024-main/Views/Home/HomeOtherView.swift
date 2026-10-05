//
//  HomeOtherView.swift
//  CampusApp
//
//  Created on 7/26/2024
//  Built by Marcus Gallardo, Rahim Malik.
//

import SwiftUI

// MARK: - Configure View

struct HomePageItem: Hashable, Codable {
    let id: String
    let icon: String
    var visible: Bool
}

struct HomeConfigView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var arrangement: [HomePageItem]
    @Binding var quickLinks: [QuickLink]
    
    var body: some View {
        List {
            Section(header: Text("**Home Page**")) {
                ForEach($arrangement, id: \.self) { $item in
                    HomeConfigCell(item: $item)
                        .listRowInsets(EdgeInsets())
                }
                .onMove(perform: moveHomePageItem)
            }
            Section(header: Text("**QuickLinks**")) {
                ForEach($quickLinks, id: \.self) { $quickLink in
                    QLConfigCell(quickLink: $quickLink)
                        .listRowInsets(EdgeInsets())
                }
                .onMove(perform: moveQuickLink)
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
#elseif os(macOS)
        .listStyle(.sidebar)
#endif
    }
    
    func moveHomePageItem(from source: IndexSet, to destination: Int) {
        arrangement.move(fromOffsets: source, toOffset: destination)
    }
    
    func moveQuickLink(from source: IndexSet, to destination: Int) {
        quickLinks.move(fromOffsets: source, toOffset: destination)
    }
    
    struct HomeConfigCell: View {
        
        @Binding var item: HomePageItem
        
        var body: some View {
#if os(iOS)
            HStack {
                Image(systemName: item.icon)
                    .body()
                    .symbolVariant(.fill)
                    .frame(width: 35)
                Text(item.id)
                    .body()
                    .flushLeading()
                Toggle("", isOn: $item.visible)
                    .labelsHidden()
                    .tint(.accent)
            }
            .padding(.leading, 5)
            .padding(10)
#elseif os(macOS)
            HStack {
                Image(systemName: item.icon)
                    .fontWeight(.semibold)
                    .symbolVariant(.fill)
                    .foregroundStyle(.systemContrast)
                    .frame(width: 20, alignment: .leading)
                Text(item.id)
                    .fontWeight(.medium)
                    .foregroundStyle(.systemContrast)
                    .flushLeading()
                Toggle("", isOn: $item.visible)
                    .labelsHidden()
                    .tint(.accent)
            }
            .padding(5)
#endif
        }
    }
    
    struct QLConfigCell: View {
        
        @Binding var quickLink: QuickLink
        
        var body: some View {
#if os(iOS)
            HStack {
                Image(systemName: quickLink.icon)
                    .body()
                    .symbolVariant(.fill)
                    .frame(width: 35)
                Text(quickLink.label)
                    .body()
                    .flushLeading()
                Toggle("", isOn: $quickLink.visible)
                    .labelsHidden()
                    .tint(.accent)
            }
            .padding(.leading, 5)
            .padding(10)
#elseif os(macOS)
            HStack {
                Image(systemName: quickLink.icon)
                    .fontWeight(.semibold)
                    .symbolVariant(.fill)
                    .foregroundStyle(.systemContrast)
                    .frame(width: 20, alignment: .leading)
                Text(quickLink.label)
                    .fontWeight(.medium)
                    .foregroundStyle(.systemContrast)
                    .flushLeading()
                Toggle("", isOn: $quickLink.visible)
                    .labelsHidden()
                    .tint(.accent)
            }
            .padding(5)
#endif
        }
    }
}

// MARK: - Acknowledgments View

struct HomeAcknowView: View {
    
    @State var showCredits = false
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Designed by Rahim Malik in California")
                .fontSize(14)
                .foregroundStyle(.systemContrast.opacity(0.75))
            HStack(spacing: 0) {
                Text("With the iTeam • ")
                    .fontSize(14)
                    .foregroundStyle(.systemContrast.opacity(0.75))
                Button {
                    showCredits = true
                } label: {
                    Text("Acknowledgements")
                        .fontSize(14)
                        .foregroundStyle(.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .padding(.top, 10)
        .padding(.bottom, 10)
#if os(iOS)
        .sheet(isPresented: $showCredits) {
            StackView("Acknowledgements") {
                HomeAcknowSheet()
            }
        }
#elseif os(macOS)
        .popover(isPresented: $showCredits, arrowEdge: .bottom) {
            HomeAcknowSheet()
                .frame(width: 300, height: 300)
        }
#endif
    }
    
    struct HomeAcknowSheet: View {
        
        @Environment(\.openURL) var openURL
        
        var body: some View {
            ScrollView {
                VStack(spacing: 10) {
                    Text("iTeam Contributions")
                        .subheading()
                        .flushLeading(padding: true)
                    VStack(spacing: 15) {
                        ForEach(iteamContributions, id: \.self) { name in
                            Text(name)
                                .foregroundStyle(.systemContrast)
                                .flushLeading()
                            if name != iteamContributions.last {
                                CapsuleDivider()
                            }
                        }
                    }
                    .borderedCellStyle()
                    
                    Text("Faculty Contributions")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    VStack(spacing: 15) {
                        ForEach(facultyContributions, id: \.self) { name in
                            Text(name)
                                .foregroundStyle(.systemContrast)
                                .flushLeading()
                            if name != facultyContributions.last {
                                CapsuleDivider()
                            }
                        }
                    }
                    .borderedCellStyle()
                    
                    Text("External Contributions")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    VStack(spacing: 15) {
                        ForEach(externalContributions, id: \.name) { package in
                            Button {
                                openURL(package.link)
                            } label: {
                                Text(package.name)
                                    .foregroundStyle(.accent)
                                    .flushLeading()
                            }
                            .buttonStyle(.plain)
                            if package.name != externalContributions.last?.name {
                                CapsuleDivider()
                            }
                        }
                    }
                    .borderedCellStyle()
                }
                .padding(20)
            }
        }
    }
}
