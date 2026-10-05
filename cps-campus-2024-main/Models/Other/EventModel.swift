//
//  EventModel.swift
//  CampusApp
//
//  Created on 7/12/2024
//  Built by Rahim Malik.
//

import Foundation


func createGCalEvent(
    title: String = "",
    location: String = "",
    startDate: String,
    endDate: String,
    startTime: String = "",
    endTime: String = "",
    account: String = "0"
) -> URL {
    var url = "https://www.calendar.google.com"
    if startTime.isEmpty && endTime.isEmpty {
        let startDateString = startDate.reformatAsDate(newFormat: "YYYYMMdd")
        let endDateString = endDate.reformatAsDate(newFormat: "YYYYMMdd")
        
#if os(iOS)
        url = "https://www.google.com/calendar/u/0"
#elseif os(macOS)
        url = "https://www.google.com/calendar/u/\(account)"
#endif
        url += "/event?action=TEMPLATE&dates=\(startDateString)/\(endDateString)"
        url += "&text=\(title.replacingOccurrences(of: " ", with: "+"))"
        url += "&location=\(location.replacingOccurrences(of: " ", with: "+"))"
    } else {
        let startDateString = (startDate + " " + startTime).reformatAsDate(currentFormat: "yyyy-MM-dd HH:mm:ss", newFormat: "YYYYMMdd'T'HHmmss")
        let endDateString = (endDate + " " + endTime).reformatAsDate(currentFormat: "yyyy-MM-dd HH:mm:ss", newFormat: "YYYYMMdd'T'HHmmss")

#if os(iOS)
        url = "https://www.google.com/calendar/u/0"
#elseif os(macOS)
        url = "https://www.google.com/calendar/u/\(account)"
#endif
        url += "/event?action=TEMPLATE&dates=\(startDateString)%2F\(endDateString)"
        url += "&text=\(title.replacingOccurrences(of: " ", with: "+"))"
        url += "&location=\(location.replacingOccurrences(of: " ", with: "+"))"
    }
    return URL(string: url) ?? URL(string: "https://www.calendar.google.com")!
}
