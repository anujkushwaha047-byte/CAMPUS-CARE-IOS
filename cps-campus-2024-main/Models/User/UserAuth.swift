//
//  UserAuth.swift
//  CampusApp
//
//  Created on 5/30/2024
//  Built by Rahim Malik.
//

import Combine
import CryptoKit
//import DeviceCheck
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

#if os(iOS)
import FirebaseDynamicLinks
#endif
//import FirebaseAppCheck

// MARK: Device Authentication

/// A custom `AppCheckProviderFactory` for creating App Check providers for Firebase.
//class CampusAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
//    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
//#if DEBUG
//        return AppCheckDebugProvider(app: app)
//#else
//#if os(iOS)
//        return AppAttestProvider(app: app)
//#elseif os(macOS)
//        return DeviceCheckProvider(app: app)
//#else
//        return nil
//#endif
//#endif
//    }
//}

// MARK: User Authentication

/// `AuthManager` handles authentication for the app using Apple and Google sign-in.
class AuthManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    
    // MARK: - Auth Implementation
    
    /// Authenticates a Google user.
    private func authenticateGoogleUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            ConsoleMessage(type: .authentication, description: "Google Sign In - \(error.localizedDescription)").error()
            return
        }
        
        if let userWrapped = user {
            let credential = GoogleAuthProvider.credential(withIDToken: userWrapped.idToken!.tokenString, accessToken: userWrapped.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [unowned self] (_, error) in
                if let error = error {
                    ConsoleMessage(type: .authentication, description: "Google Sign In - \(error.localizedDescription)").error()
                } else {
                    state = .signedIn
                }
            }
        } else {
            showGoogleSignInWindow()
        }
    }
    
    // MARK: - Auth Interface
    
    /// Represents the sign-in state.
    enum SignInState {
        case signedIn
        case signedOut
        case anonymous
        case parent
    }
    
    /// The current sign-in state.
    @Published var state: SignInState = .signedOut {
        didSet {
            statePublisher.send()
        }
    }
    
    /// Publisher for the sign-in state changes.
    let statePublisher = PassthroughSubject<Void, Never>()
    
    /// Initiates the sign-in with Google process.
    func signInWithGoogle() {
        var tempUser: FirebaseAuth.User?
        do {
            try tempUser = Auth.auth().getStoredUser(forAccessGroup: userAccessGroup)
        } catch let error as NSError {
            ConsoleMessage(type: .authentication, description: "Error getting stored user: \(error)").error()
        }
        
        if let tempUser = tempUser {
            Auth.auth().updateCurrentUser(tempUser) { [unowned self] error in
                if let error = error {
                    ConsoleMessage(type: .authentication, description: "Google Sign In - \(error.localizedDescription)").error()
                } else {
                    state = .signedIn
                }
            }
        } else {
            showGoogleSignInWindow()
        }
    }
    
    /// Displays the window from which the user may sign in with Google.
    func showGoogleSignInWindow() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let configuration = GIDConfiguration(clientID: clientID, serverClientID: nil, hostedDomain: "thecollegepreparatoryschool.org", openIDRealm: nil)
        
#if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.configuration = configuration
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] user, error in
            authenticateGoogleUser(for: user?.user, with: error)
        }
#elseif os(macOS)
        GIDSignIn.sharedInstance.configuration = configuration
        GIDSignIn.sharedInstance.signIn(withPresenting: NSApp.windows.first!) { [unowned self] user, error in
            authenticateGoogleUser(for: user?.user, with: error)
        }
#endif
    }
    
    /// Initiates the anonymous sign-in process.
    func signInAnonymously() {
        Auth.auth().signInAnonymously { [unowned self] (authResult, error) in
            if let error = error {
                ConsoleMessage(type: .authentication, description: "Anonymous Sign In - \(error.localizedDescription)").error()
            } else {
                state = .anonymous
            }
        }
    }
    
    /// Signs out the current user.
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.state = .signedOut
        } catch {
            ConsoleMessage(type: .authentication, description: "signOut - \(error.localizedDescription)").error()
        }
    }
    
    // All of the following methods are meant for parent sign in using Firebase Dynamic Links
    // Firebase Dynamic Links are only available on iOS
#if os(iOS)
    /// Sends an email sign-in link to the given email.
    func sendEmailSignInLink(to email: String) {
        let actionCodeSettings = ActionCodeSettings()
        
        actionCodeSettings.url = URL(string: "")
        
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: email,
                                   actionCodeSettings: actionCodeSettings) { error in
            if let error = error {
                ConsoleMessage(type: .data, description: "sendSignInLink - \(error.localizedDescription)").error()
            }
        }
    }
    
    /// Handles sign in via email link.
    func handleSignInLink(link: String, for email: String, handler: @escaping (_ succes: Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, link: link) { user, error in
            if let wrappedError = error {
                ConsoleMessage(type: .data, description: "handleSignInLink - \(wrappedError)").error()
            } else {
                self.state = .parent
                handler(true)
            }
            handler(false)
        }
    }
    
    /// Retrieves the email sign in link from the Firebase Dynamic Link parsed from the provided univseral link.
    func getSignInLink(universalLink: URL) async -> String? {
        await withCheckedContinuation { continuation in
            DynamicLinks.dynamicLinks().handleUniversalLink(universalLink) { dynamicLink, error in
                if let wrappedError = error {
                    ConsoleMessage(type: .data, description: "failed to parse dynamic link: \(wrappedError)").error()
                } else {
                    ConsoleMessage(type: .data, description: "failed to parse dynamic link, but no error returned").error()
                }
                
                continuation.resume(returning: dynamicLink?.url?.absoluteString)
            }
        }
    }
#endif
}
