//
//  SchedExportView.swift
//  CampusApp
//
//  Created on 5/30/2023
//  Built by Rahim Malik.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct ScheduleExportView: View {
    
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    @State private var showPortraitPDF = false
    @State private var showLandscapePDF = false
    
    let startDate = String("2024-08-19").toDate()
    let endDate = String("2025-05-30").toDate()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
                VStack(spacing: 15) {
                    Button {
                        generateHaptic(.notification(.success))
                        showPortraitPDF = true
                        presentPrintPreview(content: renderSchedule(portrait: true), portrait: true)
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait")
                                .body()
                                .foregroundStyle(.accent)
                                .frame(width: 25, height: 25)
                            Text("Export as Portrait PDF")
                                .body()
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    CapsuleDivider()
                    Button {
                        generateHaptic(.notification(.success))
                        showLandscapePDF = true
                        presentPrintPreview(content: renderSchedule(portrait: false), portrait: false)
                    } label: {
                        HStack {
                            Image(systemName: "rectangle")
                                .body()
                                .foregroundStyle(.accent)
                                .frame(width: 25, height: 25)
                            Text("Export as Landscape PDF")
                                .body()
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .borderedCellStyle()
                
                Text("Holidays")
                    .subheading()
                    .flushLeading(padding: true)
                    .padding(.top)
                VStack(spacing: 15) {
                    let holidays = scheduleObject.holidays.sorted(by: { $0.dates.first ?? "1" < $1.dates.first ?? "2" })
                    
                    ForEach(holidays, id: \.holidayID) { holiday in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(holiday.title)
                                    .body()
                                    .multilineTextAlignment(.leading)
                                if let first = holiday.dates.first, let last = holiday.dates.last {
                                    if first == last {
                                        Text(first.reformatAsDate(newFormat: "EEE, MMM d, yyyy"))
                                            .body()
                                            .foregroundStyle(.systemContrast.opacity(0.5))
                                    } else {
                                        Text("\(first.reformatAsDate(newFormat: "EEE, MMM d, yyyy")) -\n\(last.reformatAsDate(newFormat: "EEE, MMM d, yyyy"))")
                                            .body()
                                            .foregroundStyle(.systemContrast.opacity(0.5))
                                    }
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .flushLeading()
                            Button {
                                if let first = holiday.dates.first, let last = holiday.dates.last {
                                    if let account = userObject.currentUser?.campusID {
                                        openURL(createGCalEvent(startDate: first, endDate: last, account: account+"@thecollegepreparatoryschool.org"))
                                    } else {
                                        openURL(createGCalEvent(startDate: first, endDate: last))
                                    }
                                }
                            } label: {
                                Image(systemName: "calendar.badge.plus")
                                    .body()
                                    .foregroundStyle(.accent)
                            }
                            .buttonStyle(.scale)
                        }
                        if holiday != holidays.last {
                            CapsuleDivider()
                        }
                    }
                }
                .borderedCellStyle()
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
    }
    
    @MainActor func renderSchedule(portrait: Bool) -> Data {
        let url = URL.documentsDirectory.appending(path: "CPS Schedule.pdf")
        var box = CGRect(x: 0, y: 0, width: portrait ? 612 : 792, height: portrait ? 792 : 612)
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return Data()
        }
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            pdf.beginPDFPage(nil)
            let renderer = ImageRenderer(content: ScheduleExportWrapper(date: currentDate, portrait: portrait, portraitSection: portrait ? 1 : 0)
                .environmentObject(scheduleObject).environmentObject(userObject))
            renderer.render { size, context in
                context(pdf)
            }
            pdf.endPDFPage()
            
            if portrait {
                pdf.beginPDFPage(nil)
                let renderer2 = ImageRenderer(content: ScheduleExportWrapper(date: currentDate, portrait: true, portraitSection: 2)
                    .environmentObject(scheduleObject).environmentObject(userObject))
                renderer2.render { size, context in
                    context(pdf)
                }
                pdf.endPDFPage()
            }
            
            currentDate = currentDate.addDays(7) ?? currentDate
        }
        
        pdf.closePDF()
        
        do {
            return try Data(contentsOf: url)
        } catch {
            ConsoleMessage(type: .internal, description: "renderSchedule - \(error.localizedDescription)").error()
            return Data()
        }
    }
    
#if os(iOS)
    fileprivate func presentPrintPreview(content: Data, portrait: Bool) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.orientation = portrait ? .portrait : .landscape
        printInfo.jobName = "CPS Schedule"
        printController.printInfo = printInfo
        
        if let pdfDocument = PDFDocument(data: content) {
            printController.printingItem = pdfDocument.dataRepresentation()
            
            printController.present(animated: true, completionHandler: { (controller, completed, error) in
                if !completed, let error = error {
                    ConsoleMessage(type: .internal, description: "printFailure - \(error.localizedDescription)").error()
                }
            })
        }
    }
#elseif os(macOS)
    fileprivate func presentPrintPreview(content: Data, portrait: Bool) {
        
        let printInfo = NSPrintInfo.shared
        printInfo.orientation = portrait ? .portrait : .landscape
        
        let scale: PDFPrintScalingMode = .pageScaleNone
        
        if let document = PDFDocument(data: content) {
            let printOperation = document.printOperation(for: printInfo, scalingMode: scale, autoRotate: true)
            
            DispatchQueue.main.async {
                printOperation?.run()
            }
        }
    }
#endif
}

fileprivate struct ScheduleExportWrapper: View {
    
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    let date: Date
    let portrait: Bool
    let portraitSection: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if portrait {
                    if portraitSection == 1 {
                        createSchedulePages(for: [2, 3, 4])
                    } else {
                        createSchedulePages(for: [5, 6, 7])
                    }
                } else {
                    createSchedulePages(for: [2, 3, 4, 5, 6, 7])
                }
            }
        }
        .padding()
        .frame(width: portrait ? 612 : 792, alignment: .center)
        .frame(height: portrait ? 792 : 600, alignment: .bottom)
        .background(.white)
    }
    
    fileprivate func createSchedulePages(for weekdays: [Int]) -> some View {
        ForEach(weekdays, id: \.self) { weekday in
            if let pageDate = date.startOfWeek()?.addDays(weekday - 1)?.toString(),
               let sundayDate = date.startOfWeek()?.addDays(7)?.toString() {
                if weekday == 7 {
                    VStack(alignment: .leading, spacing: 10) {
                        ExportPageHeader(date: pageDate, rotation: "")
                        Color.gray.opacity(0)
                            .exportCellStyle(color: .gray)
                        ExportPageHeader(date: sundayDate, rotation: "")
                        VStack(alignment: .trailing) {
                            Spacer()
                            Text("2024-2025 CPS Schedule")
                                .fontSize(5)
                                .foregroundStyle(.gray)
                            Text("Designed by Rahim Malik in California")
                                .fontSize(5)
                                .foregroundStyle(.gray)
                        }
                        .multilineTextAlignment(.trailing)
                        .flushTrailing()
                        .exportCellStyle(color: .gray)
                    }
                } else {
                    ScheduleExportPage(date: pageDate, rotation: ScheduleObject.getRotation(date: pageDate, scheduleData: scheduleObject.scheduleData))
                }
            }
        }
    }
}

fileprivate struct ScheduleExportPage: View {
    
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    let date: String
    let rotation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ExportPageHeader(date: date, rotation: rotation)
                .padding(.bottom, 5)
            if let holiday = scheduleObject.holidays.first(where: { $0.dates.contains(date) }) {
                VStack(alignment: .leading) {
                    Text(holiday.title)
                        .scheduleLabel()
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .flushLeading()
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .exportCellStyle(color: .gray)
            } else if let blocks = Optional(scheduleObject.blocks.filter { $0.dates.contains(date) }.sorted { $0.startTime < $1.startTime }), !blocks.isEmpty {
                VStack(spacing: 10) {
                    ForEach(blocks, id: \.blockID) { block in
                        ScheduleExportCell(block: block, date: date, rotation: rotation)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Color.gray.opacity(0)
                    .exportCellStyle(color: .gray)
            }
        }
    }
}

fileprivate struct ExportPageHeader: View {
    
    let date: String
    let rotation: String
    
    var body: some View {
        VStack {
            HStack {
                Text("\(date.reformatAsDate(newFormat: "EEE")), \(date.reformatAsDate(newFormat: "MMM d"))")
                    .scheduleHeader()
                    .fontWeight(.semibold)
                    .foregroundStyle(.black.opacity(0.75))
                    .textCase(.uppercase)
                Spacer()
                if !rotation.isEmpty {
                    Image(systemName: rotation+".circle")
                        .scheduleHeader()
                        .fontWeight(.medium)
                        .foregroundStyle(.black.opacity(0.75))
                        .textCase(.uppercase)
                        .padding(.trailing, 2)
                }
            }
        }
    }
}

fileprivate struct ScheduleExportCell: View {
    
    @EnvironmentObject var userObject: UserObject
    @EnvironmentObject var scheduleObject: ScheduleObject
    
    let block: Block
    let date: String
    let rotation: String
    
    var body: some View {
        let (title, time, backgroundColor) = getProperties(block: block, date: date, rotation: rotation)
        
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .scheduleLabel()
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
            Text(time)
                .scheduleLabel()
                .fontWeight(.medium)
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .flushLeading()
        .exportCellStyle(color: backgroundColor)
    }
    
    func getProperties(block: Block, date: String, rotation: String) -> (String, String, Color) {
        if let compass = userObject.courses.first(where: { $0.courseID == "Compass" }),
           ScheduleObject.isCompass(block: block, date: date, compass: compass, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return (
                compass.name,
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                compass.color.toP3Color()
            )
        } else if ScheduleObject.isOpen(block: block, date: date, gradYear: userObject.currentUser?.gradYear, scheduleData: scheduleObject.scheduleData) {
            return (
                "Open",
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                .gray
            )
        } else if block.type == .course, let course = userObject.courses.first(where: { $0.courseID == block.title }) {
            if ScheduleObject.isFreePeriod(course: course, rotation: rotation) {
                return (
                    "Free Period",
                    "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                    .gray
                )
            } else {
                return (
                    course.name,
                    "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                    course.color.toP3Color()
                )
            }
        } else {
            return (
                block.title,
                "\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))",
                defaultPalette[block.title]?.toP3Color() ?? .gray
            )
        }
    }
}


extension Text {
    fileprivate func scheduleLabel() -> some View {
        return self.fontSize(8)
    }
    
    fileprivate func scheduleHeader() -> some View {
        return self.fontSize(10)
    }
}

extension Image {
    fileprivate func scheduleHeader() -> some View {
        return self.fontSize(10)
    }
}

extension View {
    fileprivate func exportCellStyle(color: Color) -> some View {
        return self.frame(maxHeight: .infinity, alignment: .top)
                   .padding(7.5)
                   .background(color.opacity(0.1))
                   .overlay {
                       RoundedRectangle(cornerRadius: 0)
                           .stroke(Color(color.toDynamicColor().shaded(amount: 0.15)), lineWidth: 3)
                   }
    }
}
