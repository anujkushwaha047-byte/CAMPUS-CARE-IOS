//
//  HomeQLView.swift
//  CampusApp
//
//  Created on 7/26/2024
//  Built by Marcus Gallardo, Rahim Malik.
//

import SwiftUI

struct QuickLink: Codable, Hashable, Identifiable {
    var id: String
    var label: String
    var icon: String
    var visible: Bool
}

struct HomeQLView: View {
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("home_quicklinks_12.0", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var quickLinks: [QuickLink] = defaultQuickLinks
    
    @State var showMap: Bool = false
    
    let columns2 = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Your Links")
                .subheading()
                .flushLeading(padding: true)
                .padding(.vertical)
            
            LazyVGrid(columns: columns2) {
                ForEach(quickLinks.filter { $0.visible }, id: \.self) { quickLink in
                    Button(action: {
                        if quickLink.id == "Map" {
#if os(iOS)
                            showMap.toggle()
#elseif os(macOS)
                            if let url = Bundle.main.url(forResource: colorScheme == .dark ? "Map (Dark)" : "Map (Light)" , withExtension: "pdf") {
                                let panel = NSSavePanel()
                                panel.nameFieldStringValue = colorScheme == .dark ? "Map (Dark)" : "Map (Light)"
                                panel.allowedContentTypes = [.pdf]
                                
                                panel.begin { response in
                                    if response == .OK, let saveURL = panel.url {
                                        do {
                                            try FileManager.default.copyItem(at: url, to: saveURL)
                                        } catch {
                                            ConsoleMessage(type: .data, description: "PDF Save Error: \(error)").error()
                                        }
                                    }
                                }
                            }
#endif
                        } else {
                            if let wrappedURL = URL(string: quickLink.id) {
                                openURL(wrappedURL)
                            }
                        }
                    }, label: {
                        HStack {
                            Image(systemName: quickLink.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(.accent)
                                .symbolVariant(.fill)
                                .frame(width: 40, height: 35)
                            Text(quickLink.label)
                                .body(weight: .semibold)
                                .foregroundStyle(.systemContrast)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer()
                        }
                        .frame(height: 30)
                        .borderedCellStyle()
                    })
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .contextMenu {
                        if quickLink.id != "Map" {
                            Button {
                                copyStringToPasteboard(quickLink.id)
                            } label: {
                                Label("Copy Link", systemImage: "doc.on.doc")
                            }
                            Button {
                                if let wrappedURL = URL(string: quickLink.id) {
                                    openURL(wrappedURL)
                                }
                            } label: {
                                Label("Open Link", systemImage: "arrow.up.forward.app")
                            }
                        }
                    }
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $showMap) {
            if let url = Bundle.main.url(forResource: colorScheme == .dark ? "Map (Dark)" : "Map (Light)", withExtension: "pdf") {
                PreviewController(url: url).ignoresSafeArea(.all)
            }
        }
#endif
    }
}
