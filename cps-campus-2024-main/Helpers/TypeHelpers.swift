//
//  TypeHelpers.swift
//  CampusApp, CampusWidget
//
//  Created on 6/19/2021
//  Built by Rahim Malik.
//

import SwiftUI
import DynamicColor
#if APP
import FirebaseFirestore
#endif

// MARK: - Navigation

/// An enumeration of all possible tab page options, each with a raw string value.
enum TabPageOption: String, CaseIterable, Identifiable, Codable {
    
    case home = "home"
#if os(iOS)
    case community = "community"
#else
    case directory = "directory"
    case clubs = "clubs"
#endif
    case schedule = "schedule"
    case settings = "settings"
    
    var id: String {
        self.rawValue
    }
    
    var label: String {
        switch self {
        case .home: "Home"
#if os(macOS)
        case .directory: "Directory"
        case .clubs: "Clubs"
#else
        case .community: "Community"
#endif
        case .schedule: "Schedule"
        case .settings: "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: "house"
#if os(macOS)
        case .directory: "person.2"
        case .clubs: "theatermask.and.paintbrush"
#else
        case .community: "person.2"
#endif
        case .schedule: "calendar"
        case .settings: "gear"
        }
    }
}

/// An enumeration representing the different preference options in the app.
enum PrefOption: String, Codable, Hashable {
    case auth
    case notifications
    case account
    case palettes
    case complete
    case parents
    
    /// Decodes a `PrefOption` instance from a decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: `DecodingError.dataCorruptedError` if the raw value is unknown.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "auth":
            self = .auth
        case "notifications":
            self = .notifications
        case "profile":
            self = .account
        case "palettes":
            self = .palettes
        case "complete":
            self = .complete
        case "parent":
            self = .parents
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown setup option: \(rawValue)")
        }
    }
    
    /// Encodes the `PrefOption` instance to an encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if any value throws an error during encoding.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auth:
            try container.encode("auth")
        case .notifications:
            try container.encode("notifications")
        case .account:
            try container.encode("profile")
        case .palettes:
            try container.encode("palettes")
        case .complete:
            try container.encode("complete")
        case .parents:
            try container.encode("parent")
        }
    }
}

/// An enumeration representing the different schedule modes in the app (for iOS).
enum ScheduleOption: String, Codable, CaseIterable {
    case week
    case month
}

/// An enumeration representing the different community modes in the app.
enum CommunityOption: String, Codable, CaseIterable {
    case directory
    case clubs
    case sports
}

// MARK: - Date Helpers

/// Converts a `Date` object to a string representation using the specified date format.
/// - Parameters:
///   - date: The date to be converted to a string.
///   - format: The date format string used for conversion.
/// - Returns: A string representation of the date according to the specified format.
func convertDateToString(date: Date, format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
}

/// Converts a string to a `Date` object using the specified date format.
/// - Parameters:
///   - string: The string to be converted to a date.
///   - format: The date format string used for conversion.
/// - Returns: A `Date` object. If the string cannot be parsed, returns the current date.
func convertStringToDate(string: String, format: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.date(from: string) ?? Date()
}

// MARK: - Date Extensions

extension Date {
    /// Converts the `Date` object to a string representation using the specified date format.
    /// - Parameter format: The date format string used for conversion. Defaults to "yyyy-MM-dd".
    /// - Returns: A string representation of the date according to the specified format.
    func toString(format: String = "yyyy-MM-dd") -> String {
        return convertDateToString(date: self, format: format)
    }
    
    /// Computes the start date of the week containing the `Date` object.
    /// - Returns: A `Date` object representing the start of the week, or `nil` if it cannot be calculated.
    func startOfWeek() -> Date? {
        return systemCalendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }
    
    /// Adds a specified number of days to the `Date` object.
    /// - Parameter days: The number of days to add.
    /// - Returns: A `Date` object representing the new date, or `nil` if it cannot be calculated.
    func addDays(_ days: Int) -> Date? {
        return systemCalendar.date(byAdding: .day, value: days, to: self)
    }
    
    /// Adds a specified number of weeks to the `Date` object.
    /// - Parameter weeks: The number of weeks to add.
    /// - Returns: A `Date` object representing the new date, or `nil` if it cannot be calculated.
    func addWeeks(_ weeks: Int) -> Date? {
        return systemCalendar.date(byAdding: .weekOfYear, value: weeks, to: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Converts the string to a `Date` object using the specified date format.
    /// - Parameter format: The date format string used for conversion. Defaults to "yyyy-MM-dd".
    /// - Returns: A `Date` object. If the string cannot be parsed, returns the current date.
    func toDate(format: String = "yyyy-MM-dd") -> Date {
        return convertStringToDate(string: self, format: format)
    }
    
    /// Reformats the string from the current date format to a new date format.
    /// - Parameters:
    ///   - currentFormat: The current date format of the string. Defaults to "yyyy-MM-dd".
    ///   - newFormat: The new date format to convert to.
    /// - Returns: A string representation of the date according to the new format.
    func reformatAsDate(currentFormat: String = "yyyy-MM-dd", newFormat: String) -> String {
        return convertDateToString(date: convertStringToDate(string: self, format: currentFormat), format: newFormat)
    }
}

extension String {
    /// Checks if the given string is a valid email address
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: self)
    }
}

// MARK: - Color Helpers

enum ColorSpaceOption: String, CaseIterable {
//    case sRGB = "sRGB"
    case displayP3 = "display_P3"
//    case dynamicSRGB = "dynamic_sRGB"
    case dynamicDisplayP3 = "dynamic_display_P3"
}

/// Extension to initialize `Color` from `DynamicColor`.
extension Color {
    /// Initializes a `Color` object from a `DynamicColor`.
    /// - Parameter dynamicColor: The `DynamicColor` to convert to `Color`.
    init(dynamicColor: DynamicColor) {
        self = Color(dynamicColor)
    }
}

/// Extension to provide foreground style with `DynamicColor` to `View`.
extension View {
    /// Applies a foreground style with a `DynamicColor` to the view.
    /// - Parameter dynamicColor: The `DynamicColor` to use for the foreground style.
    /// - Returns: A view with the applied foreground style.
    func foregroundStyle(_ dynamicColor: DynamicColor) -> some View {
        self.foregroundStyle(Color(dynamicColor: dynamicColor))
    }
}

/// Extension to convert a string to `Color` and `DynamicColor`.
extension String {
    /// Converts a hexadecimal color string to a `Color` object in the Display P3 color space.
    /// - Returns: A `Color` object. If the string cannot be parsed, returns gray.
    func toP3Color() -> Color {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return .black
        }
        
        let length = hexSanitized.count
        
        let red, green, blue, alpha: Double
        switch length {
        case 6: // RGB (24-bit)
            red = Double((rgb & 0xFF0000) >> 16) / 255.0
            green = Double((rgb & 0x00FF00) >> 8) / 255.0
            blue = Double(rgb & 0x0000FF) / 255.0
            alpha = 1.0
        case 8: // ARGB (32-bit)
            alpha = Double((rgb & 0xFF000000) >> 24) / 255.0
            red = Double((rgb & 0x00FF0000) >> 16) / 255.0
            green = Double((rgb & 0x0000FF00) >> 8) / 255.0
            blue = Double(rgb & 0x000000FF) / 255.0
        default:
            return Color.gray
        }
        
        return Color(.displayP3, red: red, green: green, blue: blue, opacity: alpha)
    }
    
//    /// Converts a hexadecimal color string to a `Color` object in the sRGB color space.
//    /// - Returns: A `Color` object. If the string cannot be parsed, returns gray.
//    func toSRGBColor() -> Color {
//        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
//        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
//        
//        var rgb: UInt64 = 0
//        
//        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
//            return .black
//        }
//        
//        let length = hexSanitized.count
//        
//        let red, green, blue, alpha: Double
//        switch length {
//        case 6: // RGB (24-bit)
//            red = Double((rgb & 0xFF0000) >> 16) / 255.0
//            green = Double((rgb & 0x00FF00) >> 8) / 255.0
//            blue = Double(rgb & 0x0000FF) / 255.0
//            alpha = 1.0
//        case 8: // ARGB (32-bit)
//            alpha = Double((rgb & 0xFF000000) >> 24) / 255.0
//            red = Double((rgb & 0x00FF0000) >> 16) / 255.0
//            green = Double((rgb & 0x0000FF00) >> 8) / 255.0
//            blue = Double(rgb & 0x000000FF) / 255.0
//        default:
//            return Color.gray
//        }
//        
//        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
//    }
    
    /// Converts a hexadecimal color string to a `DynamicColor` object.
    /// - Returns: A `DynamicColor` object.
    func toDynamicColor() -> DynamicColor {
        return DynamicColor(self.toP3Color())
    }
}

/// Extension to convert a `Color` to a hexadecimal string and `DynamicColor`.
extension Color {
    /// Converts the `Color` object to a hexadecimal string representation in the Display P3 color space.
    /// - Returns: A hexadecimal string representation of the color.
    func toP3HexString() -> String {
#if os(iOS)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
#elseif os(macOS)
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
#endif
        
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components.count >= 4 ? components[3] : 1.0
        
        let redInt = Int(red * 255)
        let greenInt = Int(green * 255)
        let blueInt = Int(blue * 255)
        let alphaInt = Int(alpha * 255)
        
        if alphaInt == 255 {
            return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
        } else {
            return String(format: "#%02X%02X%02X%02X", alphaInt, redInt, greenInt, blueInt)
        }
    }
    
//    /// Converts the `Color` object to a hexadecimal string representation in the sRGB color space.
//    /// - Returns: A hexadecimal string representation of the color.
//    func toSRGBHexString() -> String {
//#if os(iOS)
//        guard let components = UIColor(self).cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components, components.count >= 3 else {
//            return "#000000"
//        }
//#elseif os(macOS)
//        guard let components = NSColor(self).cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components, components.count >= 3 else {
//            return "#000000"
//        }
//#endif
//        
//        let red = components[0]
//        let green = components[1]
//        let blue = components[2]
//        let alpha = components.count >= 4 ? components[3] : 1.0
//        
//        let redInt = Int(red * 255)
//        let greenInt = Int(green * 255)
//        let blueInt = Int(blue * 255)
//        let alphaInt = Int(alpha * 255)
//        
//        if alphaInt == 255 {
//            return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
//        } else {
//            return String(format: "#%02X%02X%02X%02X", alphaInt, redInt, greenInt, blueInt)
//        }
//    }
    
    /// Converts the `Color` object to a `DynamicColor` object.
    /// - Returns: A `DynamicColor` object.
    func toDynamicColor() -> DynamicColor {
        return DynamicColor(self)
    }
}

// MARK: - Array Helpers

/// Extension on `Array` to get previous element if it exists.
extension Array where Element: Equatable {
    /// Returns the element that comes before the specified element in the array.
    /// - Parameter element: The element whose preceding element is to be found.
    /// - Returns: The element before the specified element, or `nil` if the element is not found or it is the first element in the array.
    func element(before element: Element) -> Element? {
        guard let index = firstIndex(of: element), index > 0 else {
            return nil
        }
        return self[index - 1]
    }
}

// MARK: - Conformance Extensions

/// Extension on `Encodable` to convert it to a dictionary.
extension Encodable {
    /// Converts an encodable object to a dictionary.
    /// - Returns: A dictionary representation of the encodable object.
    func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            let data = try encoder.encode(self)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            return dictionary
        } catch {
            ConsoleMessage(type: .data, description: "toDictionary - \(error.localizedDescription)").error()
            return [:]
        }
    }
}

/// `@retroactive`
/// Extension on `Dictionary` to conform to `RawRepresentable` where the key is `String` and the value is `Codable`. Used for User Defaults.
extension Swift.Dictionary: Swift.RawRepresentable where Key == String, Value: Codable {
    /// Initializes a dictionary from its raw value string.
    /// - Parameter rawValue: The raw value string representing the dictionary.
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String: Value].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    /// The raw value string representation of the dictionary.
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return result
    }
}

/// `@retroactive`
/// Extension on `Array` to conform to `RawRepresentable` where the element is `Codable`. Used for User Defaults.
extension Swift.Array: Swift.RawRepresentable where Element: Codable {
    /// Initializes an array from its raw value string.
    /// - Parameter rawValue: The raw value string representing the array.
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    /// The raw value string representation of the array.
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

/// `@retroactive`
/// /// Extension on `Date` to conform to `RawRepresentable` where the element is `Codable`. Used for User Defaults.
extension Foundation.Date: Swift.RawRepresentable {
    /// A string representation of the date in ISO 8601 format.
    /// This computed property uses an `ISO8601DateFormatter` to convert a `Date` instance into a string representation.
    public var rawValue: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    /// Initializes a `Date` instance from a string representation in ISO 8601 format.
    /// - Parameter rawValue: A string representation of a date in ISO 8601 format.
    /// This initializer uses an `ISO8601DateFormatter` to convert a string representation of a date into a `Date` instance.
    /// If the string cannot be converted to a valid date, the initializer returns `nil`.
    public init?(rawValue: String) {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: rawValue) else {
            return nil
        }
        self = date
    }
}
