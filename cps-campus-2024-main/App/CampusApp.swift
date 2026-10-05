//
//  CampusApp.swift
//  CampusApp
//
//  Created on 6/13/2021
//  Built by Rahim Malik.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
//import FirebaseAppCheck
import GoogleSignIn
import SDWebImage

#if os(iOS)
import FirebaseDynamicLinks
#endif

@main
struct CampusApp: App {
    
    @StateObject var authManager = AuthManager()
    @ObservedObject var userObject = UserObject()
    @ObservedObject var scheduleObject = ScheduleObject()
    @ObservedObject var rhfObject = RHFObject()
    @ObservedObject var ccObject = CCObject()
    @ObservedObject var clubsObject = ClubsObject()
    
    @Environment(\.openURL) var openURL
    @State var expirationDate = Date()
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var vSizeClass
    @Environment(\.horizontalSizeClass) var hSizeClass
#endif
    
    init() {
//        let providerFactory = CampusAppCheckProviderFactory()
//        AppCheck.setAppCheckProviderFactory(providerFactory)
//        
        FirebaseApp.configure()
//        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        
        let settings = firestoreDB.settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
        firestoreDB.settings = settings
        
        let cache = SDImageCache(namespace: "tiny")
        cache.config.maxMemoryCost = 10 * 1024 * 1024 // 10MB memory
        cache.config.maxDiskSize = 10 * 1024 * 1024 // 10MB disk
        SDImageCachesManager.shared.addCache(cache)
        SDWebImageManager.defaultImageCache = SDImageCachesManager.shared
        
        resetAppStorage()
        
        do {
            try Auth.auth().useUserAccessGroup(userAccessGroup)
        } catch {
            ConsoleMessage(type: .authentication, description: "Google Sign In - \(error.localizedDescription)").error()
        }
    }
    
    var body: some Scene {
#if os(iOS)
        WindowGroup {
            CampusApp_iOS_iPadOS()
                .environmentObject(authManager)
                .environmentObject(userObject)
                .environmentObject(scheduleObject)
                .environmentObject(rhfObject)
                .environmentObject(ccObject)
                .environmentObject(clubsObject)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
#elseif os(macOS)
        WindowGroup {
            CampusApp_macOS()
                .frame(minWidth: 800, minHeight: 550)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "{path of URL?}"), allowing: Set(arrayLiteral: "*"))
                .environmentObject(authManager)
                .environmentObject(userObject)
                .environmentObject(scheduleObject)
                .environmentObject(rhfObject)
                .environmentObject(ccObject)
                .environmentObject(clubsObject)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .systemServices) {
            }
            CommandGroup(replacing: .appSettings) {
                Button {
                    openURL(URL(string: "cpscampus://settings")!)
                } label: {
                    Text("Preferences...")
                }
                .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button {
                    openURL(URL(string: "")!)
                } label: {
                    Text("Feedback")
                }
            }
        }
#endif
    }
}

#if os(iOS)
struct CampusApp_iOS_iPadOS: View {
    @Environment(\.verticalSizeClass) var vSizeClass
    @Environment(\.horizontalSizeClass) var hSizeClass
    
    var body: some View {
        if vSizeClass == .regular && hSizeClass == .regular {
            CampusApp_iPadOS()
        } else {
            CampusApp_iOS()
        }
    }
}
#endif
