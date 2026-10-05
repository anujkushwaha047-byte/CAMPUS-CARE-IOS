//
//  SettingsCourseView.swift
//  CampusApp
//
//  Created on 6/24/2024
//  Built by Rahim Malik.
//

import SwiftUI

struct SettingsCourseView: View {
    
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var userObject: UserObject
    
    @State var course: UserCourse
    @State var color: Color
    @State var palettes = false
    
    @FocusState private var focused: Bool
    
    @AppStorage("color_space", store: UserDefaults(suiteName: "group.com.TheCollegePreparatorySchool.ScheduleApp")) var colorSpace = ColorSpaceOption.dynamicDisplayP3
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    TextField("Name", text: course.freePeriod ? .constant("Free Period") : $course.name)
                        .heading()
                        .textFieldStyle(.plain)
                        .flushLeading()
                        .foregroundStyle(course.freePeriod ? .gray : .systemContrast)
                        .focused($focused)
                        .disabled(course.freePeriod)
                        .onSubmit {
                            Task {
                                await userObject.updateCourse(course)
                            }
                        }
                    Button {
                        generateHaptic(.impact(.medium))
                        if course.freePeriod {
                            course.freePeriod = false
                            Task {
                                await userObject.updateCourse(course)
                            }
                        } else {
                            focused = true
                        }
                    } label: {
                        Text("Edit")
                            .action()
                            .foregroundStyle(.accent)
                            .textCase(.uppercase)
                    }
                    .buttonStyle(.scale)
                }
                .padding(.horizontal)
                if !noTeacherRoomCourseIDs.contains(course.courseID) {
                    VStack(spacing: 15) {
                        TextField("Teacher", text: $course.teacher)
                            .body()
                            .textFieldStyle(.plain)
                            .disabled(course.freePeriod)
                            .onSubmit {
                                Task {
                                    await userObject.updateCourse(course)
                                }
                            }
                        CapsuleDivider()
                        TextField("Room", text: $course.room)
                            .body()
                            .textFieldStyle(.plain)
                            .disabled(course.freePeriod)
                            .onSubmit {
                                Task {
                                    await userObject.updateCourse(course)
                                }
                            }
                    }
                    .borderedCellStyle()
                }
                
                if classCourseIDs.contains(course.courseID) {
                    Text("Display")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    VStack(spacing: 15) {
                        HStack {
                            Text("Always Free Period")
                                .body()
                                .flushLeading()
                            Spacer()
                            Toggle("Always Free Period", isOn: $course.freePeriod)
                                .toggleStyle(.switch)
                                .tint(.accent)
                                .labelsHidden()
                                .onChange(of: course.freePeriod) { _ in
                                    Task {
                                        await userObject.updateCourse(course)
                                    }
                                }
                        }
                        CapsuleDivider()
                        HStack {
                            Text("Rotations")
                                .body()
                                .flushLeading()
                            Spacer()
                            Picker(course.visibleRotation, selection: $course.visibleRotation) {
                                Text("All Rotations").tag("")
                                if rotation1and3CourseIDs.contains(course.courseID) {
                                    Text("Day 1").tag("1")
                                    Text("Day 3").tag("3")
                                } else if rotation2and4CourseIDs.contains(course.courseID) {
                                    Text("Day 2").tag("2")
                                    Text("Day 4").tag("4")
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .onChange(of: course.visibleRotation) { _ in
                                Task {
                                    await userObject.updateCourse(course)
                                }
                            }
                        }
                    }
                    .borderedCellStyle()
                    Text("Configure for which rotations **\(course.name)** will be displayed. All other rotations will be displayed as a **Free Period.**")
                        .caption()
                        .flushLeading(padding: true)
                    
                    // override warning and notices
                    if let compass = userObject.courses.first(where: {$0.courseID == "Compass" && $0.compassBlock == course.courseID}) {
                        if compass.visibleRotation == course.visibleRotation {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .caption()
                                    .foregroundStyle(.orange)
                                Text("**\(compass.name)** is currently using this block and rotation so **\(course.name)** will never be displayed")
                                    .caption()
                                    .flushLeading()
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .tintedCellStyle(.yellow)
                            .padding(.top)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .caption()
                                    .foregroundStyle(compass.color.toP3Color())
                                Text("**\(compass.name)** will be displayed instead of \(course.freePeriod ? "Free Period" : course.name) on **\(compass.visibleRotation.isEmpty ? "All Rotations": "Day "+compass.visibleRotation)**")
                                    .caption()
                                    .flushLeading()
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .tintedCellStyle(compass.color.toP3Color())
                            .padding(.top)
                        }
                    }
                }
                
                if course.courseID == "Compass" {
                    Text("Display")
                        .subheading()
                        .flushLeading(padding: true)
                        .padding(.top)
                    VStack(spacing: 15) {
                        HStack {
                            Text("Block")
                                .body()
                                .flushLeading()
                            Spacer()
                            Picker(course.compassBlock, selection: $course.compassBlock) {
                                Text("None").tag("")
                                ForEach(classCourseIDs, id: \.self) { classCourseID in
                                    Text(classCourseID).tag(classCourseID)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .onChange(of: course.compassBlock) { _ in
                                Task {
                                    course.visibleRotation = ""
                                    await userObject.updateCourse(course)
                                }
                            }
                        }
                        if !course.compassBlock.isEmpty {
                            CapsuleDivider()
                            HStack {
                                Text("Rotation")
                                    .body()
                                    .flushLeading()
                                Spacer()
                                Picker(course.visibleRotation, selection: $course.visibleRotation) {
                                    Text("All Rotations").tag("")
                                    if rotation1and3CourseIDs.contains(course.compassBlock) {
                                        Text("Day 1").tag("1")
                                        Text("Day 3").tag("3")
                                    } else if rotation2and4CourseIDs.contains(course.compassBlock) {
                                        Text("Day 2").tag("1")
                                        Text("Day 4").tag("3")
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .onChange(of: course.visibleRotation) { _ in
                                    Task {
                                        await userObject.updateCourse(course)
                                    }
                                }
                            }
                        }
                    }
                    .borderedCellStyle()
                    Text("Configure for which rotations **\(course.name)** will be displayed. All other rotations will be displayed as a **Free Period.**")
                        .caption()
                        .flushLeading(padding: true)
                    
                    // override warnings and notices
                    if let otherCourse = userObject.courses.first(where: {$0.courseID == course.compassBlock}) {
                        if otherCourse.visibleRotation == course.visibleRotation {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .caption()
                                    .foregroundStyle(.orange)
                                Text("**\(course.name)** is currently overriding your **\(course.compassBlock)** course on **\(course.visibleRotation.isEmpty ? "All Rotations": "Day "+course.visibleRotation)** so **\(otherCourse.name)** will never be displayed")
                                    .caption()
                                    .flushLeading()
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .tintedCellStyle(.yellow)
                            .padding(.top)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .caption()
                                    .foregroundStyle(course.color.toP3Color())
                                Text("**\(course.name)** will be displayed instead of \(otherCourse.freePeriod ? "Free Period" : otherCourse.name) on **\(course.visibleRotation.isEmpty ? "All Rotations": "Day "+course.visibleRotation)**")
                                    .caption()
                                    .flushLeading()
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .tintedCellStyle(course.color.toP3Color())
                            .padding(.top)
                        }
                    }
                }
                
                // override warnings and notices
                if course.courseID == "Advising" || course.courseID == "X-Block" {
                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                            .caption()
                            .foregroundStyle(course.color.toP3Color())
                        Text(course.courseID == "Advising" ? "**Open** will be displayed on Thursdays when you have free time instead of **Advising**" : "**Open** will be displayed on Mondays when you have free time instead of **X-Block**")
                            .caption()
                            .flushLeading()
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .tintedCellStyle(course.color.toP3Color())
                    .padding(.top)
                }
                
                Text("Style")
                    .subheading()
                    .flushLeading(padding: true)
                    .padding(.top)
                VStack(spacing: 15) {
                    HStack {
                        Text("Color")
                            .body()
                            .flushLeading()
                        Spacer()
                        ColorPicker("Color", selection: course.freePeriod ? .constant(.gray) : $color, supportsOpacity: false)
                            .buttonStyle(.plain)
                            .labelsHidden()
                            .opacity(course.freePeriod ? 0.5 : 1)
                            .disabled(course.freePeriod)
                            .onChange(of: color) { _ in
                                Task {
                                    course.color = color.toP3HexString()
                                    await userObject.updateCourse(course)
                                }
                            }
                    }
                    CapsuleDivider()
                    HStack {
#if os(iOS)
                        Text("Color Space")
                            .body()
                        Picker("Color Space", selection: $colorSpace) {
                            Text("Display P3").tag(ColorSpaceOption.displayP3)
                            Text("Dynamic Display P3").tag(ColorSpaceOption.dynamicDisplayP3)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .flushTrailing()
#elseif os(macOS)
                        Text("Color Space")
                            .body()
                            .flushLeading()
                        Spacer()
                        Picker("Color Space", selection: $colorSpace) {
                            Text("Display P3").tag(ColorSpaceOption.displayP3)
                            Text("Dynamic Display P3").tag(ColorSpaceOption.dynamicDisplayP3)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
#endif
                    }
                    CapsuleDivider()
#if os(iOS)
                    Button {
                        palettes.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "swatchpalette.fill")
                                .body()
                                .foregroundStyle(.accent)
                            Text("Palettes")
                                .body()
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $palettes) {
                        StackView("Palettes", backButton: false, cancelButton: true, isSheet: true) {
                            PalettePrefsView()
                        }
                    }
#elseif os(macOS)
                    Button {
                        openURL(URL(string: "cpscampus://settings")!)
                    } label: {
                        HStack {
                            Image(systemName: "swatchpalette.fill")
                                .body()
                                .foregroundStyle(.accent)
                            Text("Palettes")
                                .body()
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
#endif
                }
                .borderedCellStyle()
                Text("Dynamic Display P3 will automatically adjust the luminance of some courses for better readability.")
                    .caption()
                    .flushLeading(padding: true)
                
                Spacer().frame(height: 30)
                
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .background(.systemWindow)
        .onDisappear {
            Task {
                await userObject.updateCourse(course)
            }
        }
    }
}
