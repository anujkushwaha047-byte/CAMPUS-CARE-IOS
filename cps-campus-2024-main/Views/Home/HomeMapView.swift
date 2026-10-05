//
//  MapHome.swift
//  CampusApp
//
//  Created on 7/26/2024
//  Built by Marcus Gallardo.
//

import SwiftUI

#if os(iOS)
struct HomeMapView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var showMap: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                showMap = true
            } label: {
                Image("Map")
                    .resizable()
                    .scaleEffect(1.4)
                    .scaledToFill()
                    .clipped()
                    .frame(height: 190)
                    .clipped()
            }
            .sheet(isPresented: $showMap) {
                if let url = Bundle.main.url(forResource: colorScheme == .dark ? "Map (Dark)" : "Map (Light)", withExtension: "pdf") {
                    PreviewController(url: url).ignoresSafeArea(.all)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .borderedCellStyle(padding: 0)
        }
    }
}
#endif
