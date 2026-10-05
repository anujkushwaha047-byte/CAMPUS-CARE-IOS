//
//  UserKeychain.swift
//  CampusApp
//
//  Created on 5/30/2024
//  Built by Rahim Malik.
//

import AuthenticationServices

/// `KeychainManager` provides a simple interface for saving, updating, reading, and deleting entries in the iOS Keychain.
class KeychainManager {
    
    /// The service name used for the Keychain entries.
    private(set) var serviceName = ""
    
    // MARK: - Keychain Interface
    
    /// A shared instance of `KeychainManager` for singleton access.
    static var manager = KeychainManager()
    
    /// Saves a token to the Keychain.
    /// - Parameters:
    ///   - token: The token to be saved.
    ///   - tokenID: The unique identifier for the token.
    func saveToken(_ token: String, tokenID: String) {
        
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecValueData: Data(token.utf8),
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: tokenID
        ] as CFDictionary
        
        let status = SecItemAdd(keychainQuery, nil)
        
        if status == errSecDuplicateItem {
            updateToken(token, tokenID: tokenID)
        }
    }
    
    /// Updates an existing token in the Keychain.
    /// - Parameters:
    ///   - token: The new token value.
    ///   - tokenID: The unique identifier for the token.
    func updateToken(_ token: String, tokenID: String) {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: tokenID
        ] as CFDictionary
        
        let updatedData = [kSecValueData: Data(token.utf8)] as CFDictionary
        SecItemUpdate(keychainQuery, updatedData)
    }
    
    /// Reads a token from the Keychain.
    /// - Parameter tokenID: The unique identifier for the token.
    /// - Returns: The token value if it exists, otherwise `nil`.
    func readToken(_ tokenID: String) -> String? {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: tokenID,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(keychainQuery, &result)
        
        if let wrappedResult = result as? Data {
            return String(decoding: wrappedResult, as: UTF8.self)
        } else {
            return nil
        }
    }
    
    /// Saves a string array to the Keychain.
    /// - Parameters:
    ///   - array: The array to be saved.
    ///   - arrayID: The unique identifier for the array.
    func saveArray(_ array: Array<String>, arrayID: String) {
        
        do {
            let arrayData = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: true)
            
            let keychainQuery = [
                kSecUseDataProtectionKeychain: true,
                kSecValueData: arrayData,
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: arrayID
            ] as CFDictionary
            
            let status = SecItemAdd(keychainQuery, nil)
            
            if status == errSecDuplicateItem {
                updateArray(array, arrayID: arrayID)
            }
        } catch {
            ConsoleMessage(type: .data, description: "saveArray - \(error.localizedDescription)").error()
        }
    }
    
    /// Updates an existing array in the Keychain.
    /// - Parameters:
    ///   - array: The new array value.
    ///   - arrayID: The unique identifier for the array.
    func updateArray(_ array: Array<String>, arrayID: String) {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: arrayID
        ] as CFDictionary
        
        do {
            let updatedData = [kSecValueData: try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: true)] as CFDictionary
            SecItemUpdate(keychainQuery, updatedData)
        } catch {
            ConsoleMessage(type: .data, description: "updateArray - \(error.localizedDescription)").error()
        }
    }
    
    /// Reads a string array from the Keychain.
    /// - Parameter arrayID: The unique identifier for the array.
    /// - Returns: The array if it exists, otherwise `nil`.
    func readArray(_ arrayID: String) -> Array<String>? {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: arrayID,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(keychainQuery, &result)
        
        do {
            if let wrappedResult = result as? Data {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: wrappedResult) as? Array<String>
            } else {
                return nil
            }
        } catch {
            ConsoleMessage(type: .data, description: "updateArray - \(error.localizedDescription)").error()
        }
        
        return nil
    }
    
    /// Deletes an object from the Keychain.
    /// - Parameter tokenID: The unique identifier for the object.
    func delete(_ objectID: String) {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: objectID
        ] as CFDictionary
        
        SecItemDelete(keychainQuery)
    }
    
    /// Checks if an object exists in the Keychain.
    /// - Parameter tokenID: The unique identifier for the object.
    /// - Returns: `true` if the object exists, otherwise `false`.
    func hasObject(objectID: String) -> Bool {
        let keychainQuery = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: objectID
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQuery, &result)
        return status == errSecSuccess
    }
    
    /// Removes all Campus-created entries stored in the the keychain.
    func clear() {
        [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity].forEach {
            let status = SecItemDelete([
                kSecClass: $0,
                kSecAttrSynchronizable: kSecAttrSynchronizableAny
                ] as CFDictionary)
            
            if status != errSecSuccess && status != errSecItemNotFound {
                ConsoleMessage(type: .data, description: "clear - Error clearing keychain").error()
            }
        }
    }
}
