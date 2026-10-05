//
//  PrefsPaletteView.swift
//  CampusApp
//
//  Created on 6/30/2024
//  Built by Rahim Malik.
//

import SwiftUI
import FirebaseAuth
import DynamicColor
#if os(iOS)
import ColorThiefSwift
import PhotosUI
#endif

struct PaletteSetupView: View {
    
    @EnvironmentObject var userObject: UserObject
    @Binding var setupScreen: PrefOption
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Step 3 of 3")
                    .font(.custom("Poppins-Medium", size: 16))
                    .flushCenter()
                Text("Palettes")
                    .font(.custom("Poppins-Bold", size: 24))
                    .flushCenter()
            }
            .padding(.vertical)
            .background(.systemCell)
            Divider()
            
            PalettePrefsView()
            
            Divider()
            VStack(spacing: 10) {
                Button {
                    generateHaptic(.impact(.medium))
                    withAnimation {
                        setupScreen = .complete
                    }
                } label: {
                    Text("Continue")
                        .button()
                        .foregroundStyle(.white)
                        .buttonCellStyle()
                }
                .buttonStyle(.scale)
                .background(.systemCell)
                Text("If you've colored your courses on a different device, continue without reselecting.")
                    .caption()
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .padding(20)
            .background(.systemCell)
        }
        .transition(.slideWithOpacity)
    }
}

struct PalettePrefsView: View {
    
    @EnvironmentObject var userObject: UserObject
    
    @State var palettes = [Palette]()
    @State var customPalettes = [Palette]()
    
    @State var selection = "Yours"
    @State var collections = ["Yours", "All"]
    
    @State var createPalette = false
    @State var publishPalette = false
    @State var alertPalette: Palette?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ScrollView(.horizontal) {
                    HStack {
                        Spacer().frame(width: 20)
                        ForEach(collections, id: \.self) { collection in
                            Button {
                                generateHaptic(.selection)
                                selection = collection
                            } label: {
                                HStack {
                                    Text(collection)
                                        .caption(weight: .semibold)
                                        .foregroundStyle(selection == collection ? .white : .systemContrast)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background {
                                    if selection == collection {
                                        return Capsule()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(Color.accent.toDynamicColor().shaded(amount: 0.15)), Color(Color.accent.toDynamicColor().tinted(amount: 0.15))]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    } else {
                                        return Capsule()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.systemCellSecondary, .systemCellSecondary]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                }
                            }
                            .buttonStyle(.scale)
                        }
                        
                        Spacer().frame(width: 20)
                    }
                }
                .scrollIndicators(.never)
                .padding(.horizontal, -20)
                .padding(.bottom)
                
                if selection == "Yours" {
#if os(iOS)
                    Button {
                        generateHaptic(.impact(.medium))
                        createPalette.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .body()
                                .foregroundStyle(.white)
                            Text("Create Palette")
                                .button()
                                .foregroundStyle(.white)
                        }
                        .buttonCellStyle()
                    }
                    .buttonStyle(.scale)
                    .sheet(isPresented: $createPalette) {
                        StackView("Create Palette", cancelButton: true) {
                            AddPaletteView(palette: userObject.generatePaletteFromCourses(), customPalettes: $customPalettes)
                        }
                    }
#endif
                    if customPalettes.isEmpty {
                        #if os(iOS)
                        Text("You haven't created any palettes. Make one!")
                            .body()
                            .foregroundStyle(.systemContrast.opacity(0.5))
                            .flushCenter()
                            .multilineTextAlignment(.center)
                            .padding(.top)
                        #else
                        Text("You haven't created any palettes.")
                            .body()
                            .foregroundStyle(.systemContrast.opacity(0.5))
                            .flushCenter()
                        #endif
                    } else {
                        ForEach(customPalettes, id: \.self) { palette in
                            PaletteCell(palette: palette, showCreator: false)
                            HStack(spacing: 20) {
                                Spacer()
                                Button {
                                    Task {
                                        do {
                                            generateHaptic(.impact(.medium))
                                            try await userObject.removeCustomPalette(palette)
                                            customPalettes = try await userObject.fetchCustomPalettes()
                                        } catch {
                                            ConsoleMessage(type: .data, description: "removeCustomPalette - \(error.localizedDescription)").error()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "minus.circle.fill")
                                            .action()
                                            .foregroundStyle(.red)
                                        Text("Remove")
                                            .action()
                                            .foregroundStyle(.red)
                                            .textCase(.uppercase)
                                    }
                                }
                                .buttonStyle(.scale)
                                
                                if palette.campusID == userObject.currentUser?.campusID {
                                    Button {
                                        Task {
                                            do {
                                                generateHaptic(.impact(.medium))
                                                if palettes.filter( { $0.colors == palette.colors }).count == 0 {
                                                    publishPalette = true
                                                    alertPalette = palette
                                                } else {
                                                    try await userObject.unpublishPalette(palette)
                                                    palettes = try await fetchPalettes()
                                                }
                                            } catch {
                                                ConsoleMessage(type: .data, description: "unpublishPalette - \(error.localizedDescription)").error()
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: palettes.filter({ $0.colors == palette.colors }).count == 0 ? "icloud.and.arrow.up.fill" : "xmark.icloud.fill")
                                                .action()
                                                .foregroundStyle(palettes.filter( { $0.colors == palette.colors }).count == 0 ? .accent : .red)
                                            Text(palettes.filter( { $0.colors == palette.colors }).count == 0 ? "Publish" : "Unpublish")
                                                .action()
                                                .foregroundStyle(palettes.filter( { $0.colors == palette.colors }).count == 0 ? .accent : .red)
                                                .textCase(.uppercase)
                                        }
                                    }
                                    .buttonStyle(.scale)
                                    .alert("Publish Palette", isPresented: $publishPalette, presenting: alertPalette, actions: { palette in
                                        Button("Publish") {
                                            Task {
                                                do {
                                                    try await userObject.publishPalette(palette, anonymous: false)
                                                    palettes = try await fetchPalettes()
                                                } catch {
                                                    ConsoleMessage(type: .data, description: "publishPalette - \(error.localizedDescription)").error()
                                                }
                                            }
                                        }
                                        Button("Publish Anonymously") {
                                            Task {
                                                do {
                                                    try await userObject.publishPalette(palette, anonymous: true)
                                                    palettes = try await fetchPalettes()
                                                } catch {
                                                    ConsoleMessage(type: .data, description: "publishPalette - \(error.localizedDescription)").error()
                                                }
                                            }
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }, message: { _ in
                                        Text("Your name will never be visible to anyone besides students and faculty at the school.")
                                    })
                                }
                            }
                            .flushLeading(padding: true)
                            .padding(.vertical, 2.5)
                        }
                    }
                    
                } else {
                    ForEach(palettes.filter { selection == "All" ? true : $0.collection == selection }, id: \.self) { palette in
                        PaletteCell(palette: palette, showCreator: true)
                    }
                }
                
                Spacer().frame(height: 30)
                
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
        .task {
            do {
                palettes = try await fetchPalettes()
                collections = Array(Set(collections + palettes.map { $0.collection }))
                collections.sort { lhs, rhs in
                    switch (lhs, rhs) {
                    case ("Yours", _):
                        return true
                    case (_, "Yours"):
                        return false
                    case ("Classic", _):
                        return rhs != "Yours"
                    case (_, "Classic"):
                        return lhs == "Yours"
                    case (_, "New"):
                        return lhs != "All"
                    case ("New", _):
                        return rhs == "All"
                    case (_, "All"):
                        return true
                    case ("All", _):
                        return false
                    default:
                        return lhs < rhs
                    }
                }
                selection = collections.first ?? selection
                customPalettes = try await userObject.fetchCustomPalettes()
            } catch {
                ConsoleMessage(type: .data, description: "fetchPalettes - \(error.localizedDescription)").error()
            }
        }
    }
    
    struct PaletteCell: View {
        
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var userObject: UserObject
        
        let palette: Palette
        let showCreator: Bool // false if in Yours collection
        
        let columns4 = [
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5)
        ]
        
        var body: some View {
            VStack {
                Button {
                    Task {
                        generateHaptic(.impact(.medium))
                        await userObject.recolorCourses(palette)
                    }
                } label: {
                    ZStack {
                        LazyVGrid(columns: columns4, spacing: 2.5) {
                            ForEach(palette.colors.indices, id: \.self) { index in
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? palette.colors[index].toDynamicColor().shaded(amount: 0.15) : palette.colors[index].toDynamicColor().tinted(amount: 0.15))
                                    .frame(height: 50)
                            }
                            Rectangle()
                                .foregroundStyle(.systemCell)
                                .frame(height: 50)
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Text(palette.name.isEmpty ? "Untitled" : palette.name)
                                        .body(weight: .semibold)
                                        .foregroundStyle(.systemContrast)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .flushLeading()
                                }
                            }
                        }
                        .padding(10)
                    }
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 17.5, style: .continuous))
                    .borderedCellStyle(padding: 0, cornerRadius: 17.5)
                }
                .buttonStyle(.scale)
                
                if showCreator && !palette.creator.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .action()
                            .foregroundStyle(.systemContrast.opacity(0.5))
                        Text(palette.creator)
                            .caption()
                            .foregroundStyle(.systemContrast.opacity(0.5))
                    }
                    .flushLeading(padding: true)
                    .padding(.vertical, 2.5)
                }
            }
        }
    }
    
#if os(iOS)
    struct AddPaletteView: View {
        
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.presentationMode) var presentationMode
        
        @State var palette: Palette
        @Binding var customPalettes: [Palette]
        @EnvironmentObject var userObject: UserObject
        
        @State var colorItems: [(id: UUID, color: Color)] = [
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white),
            (id: UUID(), color: Color.white)
        ]
        
        let columns4 = [
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5),
            GridItem(.flexible(), spacing: 2.5)
        ]
        
        @State var selectedPhoto: PhotosPickerItem?
        @State var sampleImage: Image?
        
        var body: some View {
            NavigationView {
                VStack {
                    Text("Customize your palette before saving it to your custom collection, where you can publish it for others to use.")
                        .body()
                        .foregroundStyle(.gray)
                        .flushLeading(padding: true)
                        .padding(.top)
                    
                    TextField("Name", text: $palette.name)
                        .heading()
                        .textFieldStyle(.plain)
                        .flushLeading(padding: true)
                        .padding(.vertical)
                    LazyVGrid(columns: columns4, spacing: 2.5) {
                        ForEach($colorItems, id: \.id) { $item in
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(item.color)
                                    .frame(height: 65)
                                ColorPicker("Color", selection: $item.color, supportsOpacity: false)
                                    .buttonStyle(.plain)
                                    .labelsHidden()
                            }
                        }
                        Rectangle()
                            .foregroundStyle(.systemCell)
                            .frame(height: 65)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .body()
                                .foregroundStyle(.accent)
                            Text("Generate from Photo")
                                .button()
                                .foregroundStyle(.accent)
                        }
                        .padding()
                        .flushCenter()
                    }
                    
                    Spacer()
                    Button {
                        Task {
                            generateHaptic(.notification(.success))
                            palette.colors = colorItems.map { $0.color.toP3HexString() }
                            do {
                                try await userObject.updateCustomPalette(palette)
                                customPalettes = try await userObject.fetchCustomPalettes()
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                ConsoleMessage(type: .data, description: "updateCustomPalette - \(error.localizedDescription)").error()
                            }
                        }
                    } label: {
                        Text("Save Palette")
                            .button()
                            .foregroundStyle(.white)
                            .buttonCellStyle()
                    }
                    .disabled(palette.name.isEmpty)
                    .opacity(palette.name.isEmpty ? 0.5 : 1)
                }
                .padding(20)
                .background(.systemWindow)
                .onChange(of: selectedPhoto) { _ in
                    Task {
                        if let decodedImage = try? await selectedPhoto?.loadTransferable(type: Image.self) {
                            sampleImage = decodedImage
                            if let uiImage = ImageRenderer(content: sampleImage).uiImage {
                                if let generatedColors = ColorThief.getPalette(from: uiImage, colorCount: 9)?
                                    .map({ (id: UUID(), color: Color($0.makePlatformNativeColor())) }) {
                                    colorItems = generatedColors
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    if palette.colors.count == colorItems.count {
                        colorItems = palette.colors.map { (id: UUID(), color: $0.toP3Color()) }
                    }
                }
            }
        }
    }
#endif
}
