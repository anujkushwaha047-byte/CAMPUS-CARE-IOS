//
//  SchedWidgetView.swift
//  CampusWidget
//
//  Created on 6/30/2024
//  Built by Rahim Malik.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

//TODO: Test
struct ScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    
    @AppStorage("widget_blocks", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var widgetBlocks = [WidgetBlock]()
    @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3

    var body: some View {
        VStack {
            // Today
            if let blocks = Optional(widgetBlocks.filter { $0.date == entry.date.toString() }.sorted { $0.startTime < $1.startTime }), let first = blocks.first {
                WidgetContentView(date: entry.date.toString(), blocks: blocks, rotation: first.rotation)
            }
            // Tomorrow
            else if let tomorrow = entry.date.addDays(1)?.toString(), let blocks = Optional(widgetBlocks.filter { $0.date == tomorrow }.sorted { $0.startTime < $1.startTime }), let first = blocks.first {
                WidgetContentView(date: tomorrow, blocks: blocks, rotation: first.rotation)
            }
            // No Classes
            else {
                VStack(alignment: .leading) {
                    Text(entry.date.toString(format: "EEE, MMM d"))
                        .fontSize(14)
                        .fontWeight(.semibold)
                        .foregroundStyle(.accent)
                        .textCase(.uppercase)
                    Text("No Classes")
                        .fontSize(14)
                        .fontWeight(.semibold)
                        .foregroundStyle(.systemContrast.opacity(0.75))
                        .textCase(.uppercase)
                }
                .flushLeading()
            }
        }
    }
    
    struct WidgetContentView: View {
        
        let date: String
        let blocks: [WidgetBlock]
        let rotation: String
        
        @Environment(\.widgetFamily) var family
        @Environment(\.colorScheme) var colorScheme
        
        @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
        
        var body: some View {
            let limit = family == .systemLarge ? 8 : 4
            
            HStack {
                Text(date.reformatAsDate(newFormat: "EEE, MMM d"))
                    .fontSize(14)
                    .fontWeight(.semibold)
                    .foregroundStyle(date == Date().toString() ? .accent : .systemContrast.opacity(0.75))
                    .textCase(.uppercase)
                Spacer()
                if !rotation.isEmpty {
                    Image(systemName: rotation+".circle")
                        .fontSize(14)
                        .fontWeight(.semibold)
                        .foregroundStyle(date == Date().toString() ? .accent : .systemContrast.opacity(0.75))
                }
            }
            .flushLeading()
            
            if family == .systemLarge {
                VStack(spacing: 5) {
                    ForEach(blocks, id: \.self) { block in
                        HStack {
                            Capsule()
                                .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                .frame(width: 4)
                            HStack {
                                Text(block.title)
                                    .fontSize(13)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                    .flushLeading()
                                Text("\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))")
                                    .fontSize(13)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                            }
                            .padding(3)
                            .background(block.color.isEmpty ? .systemCellSecondary : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme).opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(3)
                    }
                }
            } else {
                VStack(spacing: 0.5) {
                    ForEach(blocks.indices, id: \.self) { index in
                        if index < limit {
                            let block = blocks[index]
                            HStack {
                                Capsule()
                                    .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                    .frame(width: 4)
                                HStack {
                                    Text(block.title)
                                        .fontSize(13)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                        .flushLeading()
                                    if family == .systemSmall {
                                        Text("\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))")
                                            .fontSize(13)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                    } else {
                                        Text("\(block.startTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm")) - \(block.endTime.reformatAsDate(currentFormat: "HH:mm:ss", newFormat: "h:mm"))")
                                            .fontSize(13)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .foregroundStyle(block.color.isEmpty ? .systemContrast.opacity(0.75) : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme))
                                    }
                                }
                                .padding(3)
                                .background(block.color.isEmpty ? .systemCellSecondary : block.color.toScheduleCellColor(colorSpace: colorSpace, colorScheme: colorScheme).opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(3)
                        }
                    }
                    if blocks.count > limit {
                        if blocks.count - limit == 1 {
                            Text("+\(blocks.count - limit) Class")
                                .fontSize(13)
                                .fontWeight(.medium)
                                .foregroundStyle(.gray)
                        } else {
                            Text("+\(blocks.count - limit) Classes")
                                .fontSize(13)
                                .fontWeight(.medium)
                                .foregroundStyle(.gray)
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.top, -10)
            }
        }
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "CampusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                ScheduleWidgetEntryView(entry: entry)
                    .accentColor(.accent)
                    .containerBackground(.widgetBackground, for: .widget)
            } else {
                ScheduleWidgetEntryView(entry: entry)
                    .accentColor(.accent)
                    .padding()
                    .background(.widgetBackground)
            }
        }
        .configurationDisplayName("Schedule")
        .description("Check today's classes at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
