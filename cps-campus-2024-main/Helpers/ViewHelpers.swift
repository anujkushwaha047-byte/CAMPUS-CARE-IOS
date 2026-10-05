//
//  ViewHelpers.swift
//  CampusApp, CampusWidget
//
//  Created on 6/19/2021
//  Built by Rahim Malik.
//

import SwiftUI
import DynamicColor
#if canImport(UIKit)
import UIKit
import QuickLook
#endif

// MARK: - View Styling

/// Extension on `Button` to provide custom button styles.
extension Button {
    /// Enum defining different button style types.
    enum ButtonStyleType {
        case scale
    }
    
    /// Applies a specific button style based on the provided `ButtonStyleType`.
    /// - Parameter style: The type of button style to apply.
    /// - Returns: A modified button with the specified style.
    func buttonStyle(_ style: ButtonStyleType) -> some View {
        switch style {
        case .scale:
            return self.buttonStyle(ScaleButtonStyle())
        }
    }
    
    /// Custom button style that scales the button when pressed.
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }
}

/// Extension on `View` to provide common styling utilities.
extension View {
    /// Applies a bordered cell style to the view.
    /// - Parameters:
    ///   - color: The background color of the cell (default is `.systemCell`).
    ///   - borderColor: The color of the cell border (default is `.systemContrast.opacity(0.1)`).
    ///   - padding: The padding around the cell content (default is `17.5`).
    ///   - cornerRadius: The corner radius of the cell (default is `15`).
    /// - Returns: A view with a bordered cell style.
    func borderedCellStyle(
        color: Color = .systemCell,
        borderColor: Color = .systemContrast.opacity(0.1),
        padding: CGFloat = 17.5,
        cornerRadius: CGFloat = 15
    ) -> some View {
        return self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .foregroundStyle(color)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
    }
    
    /// Applies a colored cell style to the view.
    /// - Parameters:
    ///   - color: The background color of the cell.
    ///   - padding: The padding around the cell content (default is `12.5`).
    ///   - cornerRadius: The corner radius of the cell (default is `15`).
    /// - Returns: A view with a colored cell style.
    func coloredCellStyle(
        _ color: Color,
        padding: CGFloat = 12.5,
        cornerRadius: CGFloat = 15
    ) -> some View {
        return self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .foregroundStyle(color)
            }
    }
    
    /// Applies a button cell style with a specified background color.
    /// - Parameters:
    ///   - color: The background color of the button (default is `.accent`).
    ///   - padding: The padding around the button content (default is `17.5`).
    ///   - cornerRadius: The corner radius of the button (default is `20`).
    /// - Returns: A view with a button cell style.
    func buttonCellStyle(
        color: Color = .accent,
        padding: CGFloat = 17.5,
        cornerRadius: CGFloat = 20
    ) -> some View {
        return self
            .flushCenter()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(color.toDynamicColor().shaded(amount: 0.15)), Color(color.toDynamicColor().tinted(amount: 0.15))]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }
    
    /// Applies a tinted cell style with a semi-transparent overlay and shadow.
    /// - Parameter color: The tint color applied to the cell.
    /// - Returns: A view with a tinted cell style.
    func tintedCellStyle(_ color: Color) -> some View {
        return self
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundStyle(color.opacity(0.25))
            }
    }
}

/// Custom view representing a horizontal divider.
struct CapsuleDivider: View {
    
    var horizontal: Bool = false
    
    var body: some View {
        if horizontal {
            Capsule()
                .frame(width: 1)
                .foregroundStyle(.systemContrast.opacity(0.1))
        } else {
            Capsule()
                .frame(height: 1)
                .foregroundStyle(.systemContrast.opacity(0.1))
        }
    }
}

/// Extension on `View` to provide horizontal flush alignment utilities.
extension View {
    /// Aligns the view's content to the leading edge horizontally.
    /// - Parameter padding: Determines if padding should be applied (default is `false`).
    /// - Returns: A view with content flushed to the leading edge.
    func flushLeading(padding: Bool = false) -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, padding ? 15 : 0)
    }
    
    /// Aligns the view's content to the center horizontally.
    /// - Parameter padding: Determines if padding should be applied (default is `false`).
    /// - Returns: A view with content centered horizontally.
    func flushCenter(padding: Bool = false) -> some View {
        self.frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, padding ? 15 : 0)
    }
    
    /// Aligns the view's content to the trailing edge horizontally.
    /// - Parameter padding: Determines if padding should be applied (default is `false`).
    /// - Returns: A view with content flushed to the trailing edge.
    func flushTrailing(padding: Bool = false) -> some View {
        self.frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, padding ? 15 : 0)
    }
}

// MARK: - Text Styling

/// Extension for styling Text views with various font sizes and weights.
extension Text {
    /// Sets the font size of the Text view.
    /// - Parameter size: The desired font size.
    /// - Returns: A Text view with the specified font size.
    func fontSize(_ size: CGFloat) -> some View {
        self.font(.system(size: size))
    }
    
    /// Sets the heading style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is bold).
    /// - Returns: A Text view styled as a heading.
    func heading(weight: Font.Weight = .bold) -> some View {
#if os(iOS)
        self.font(.custom("Poppins-Bold", size: 32))
            .fontWeight(weight)
#elseif os(macOS)
        self.font(.custom("Poppins-Bold", size: 30))
            .fontWeight(weight)
#endif
    }
    
    /// Sets the subheading style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is semibold).
    /// - Returns: A Text view styled as a subheading.
    func subheading(weight: Font.Weight = .semibold) -> some View {
#if os(iOS)
        self.font(.custom("Poppins-SemiBold", size: 23))
            .fontWeight(weight)
#elseif os(macOS)
        self.font(.custom("Poppins-SemiBold", size: 17))
            .fontWeight(weight)
#endif
    }
    
    /// Sets the body style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is medium).
    /// - Returns: A Text view styled as a body text.
    func body(weight: Font.Weight = .medium) -> some View {
#if os(iOS)
        self.fontSize(17)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(15)
            .fontWeight(weight)
#endif
    }
    
    /// Sets the action style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is semibold).
    /// - Returns: A Text view styled as an action text.
    func action(weight: Font.Weight = .semibold) -> some View {
#if os(iOS)
        self.fontSize(15)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(13)
            .fontWeight(weight)
#endif
    }
    
    /// Sets the caption style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is light).
    /// - Returns: A Text view styled as a caption text.
    func caption(weight: Font.Weight = .light) -> some View {
#if os(iOS)
        self.fontSize(15)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(13)
            .fontWeight(weight)
#endif
    }
    
    /// Sets the button style font for the Text view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is semibold).
    /// - Returns: A Text view styled as a button text.
    func button(weight: Font.Weight = .semibold) -> some View {
#if os(iOS)
        self.fontSize(17)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(15)
            .fontWeight(weight)
#endif
    }
}

/// Extension for styling TextField views with various font sizes.
extension TextField {
    /// Sets the font size of the TextField view.
    /// - Parameter size: The desired font size.
    /// - Returns: A TextField view with the specified font size.
    func fontSize(_ size: CGFloat) -> some View {
        self.font(.system(size: size))
    }
    
    /// Sets the heading style font for the TextField view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is bold).
    /// - Returns: A TextField view styled as a heading.
    func heading(weight: Font.Weight = .bold) -> some View {
#if os(iOS)
        self.font(.custom("Poppins-Bold", size: 32))
            .fontWeight(weight)
#elseif os(macOS)
        self.font(.custom("Poppins-Bold", size: 30))
            .fontWeight(weight)
#endif
    }
    
    /// Sets the body style font for the TextField view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is medium).
    /// - Returns: A TextField view styled as a body text.
    func body(weight: Font.Weight = .medium) -> some View {
#if os(iOS)
        self.fontSize(17)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(15)
            .fontWeight(weight)
#endif
    }
}

/// Extension for styling Image views with various font sizes.
extension Image {
    /// Sets the font size of the Image view.
    /// - Parameter size: The desired font size.
    /// - Returns: An Image view with the specified font size.
    func fontSize(_ size: CGFloat) -> some View {
        self.font(.system(size: size))
    }
    
    /// Sets the body style font for the Image view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is semibold).
    /// - Returns: An Image view styled as a body text.
    func body(weight: Font.Weight = .semibold) -> some View {
#if os(iOS)
        self.fontSize(19)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(17)
            .fontWeight(weight)
#endif
    }
    
    /// Sets the action style font for the Image view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is semibold).
    /// - Returns: An Image view styled as an action text.
    func action(weight: Font.Weight = .semibold) -> some View {
#if os(iOS)
        self.fontSize(17)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(15)
            .fontWeight(weight)
#endif
    }
    
    /// Sets the caption style font for the Image view.
    /// - Parameters:
    ///   - weight: The font weight to apply (default is light).
    /// - Returns: An Image view styled as a caption text.
    func caption(weight: Font.Weight = .medium) -> some View {
#if os(iOS)
        self.fontSize(15)
            .fontWeight(weight)
#elseif os(macOS)
        self.fontSize(13)
            .fontWeight(weight)
#endif
    }
}

// MARK: Animations and Color

/// Extension for defining custom transition animations.
extension AnyTransition {
    /// Returns an asymmetric transition that slides with opacity.
    static var slideWithOpacity: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

/// A view modifier that applies a hover effect to a toolbar item.
struct ToolbarHoverEffect: ViewModifier {
    @State private var isHovered: Bool = false
    
    /// The body of the view modifier.
    /// - Parameter content: The content view to which the modifier is applied.
    /// - Returns: A view with a hover effect applied.
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                    .foregroundStyle(isHovered ? .gray.opacity(0.2) : .clear)
            }
            .onHover { hovering in
                withAnimation {
                    self.isHovered = hovering
                }
            }
    }
}

extension View {
    /// Applies a hover effect to the view, typically used for toolbar items.
    /// - Returns: A view with a hover effect.
    func toolbarHoverEffect() -> some View {
        self.modifier(ToolbarHoverEffect())
    }
}

/// Extension for adjusting Color properties.
extension String {
    func toScheduleIconColor(colorSpace: ColorSpaceOption) -> Color {
        switch colorSpace {
        case .displayP3:
            return self.toP3Color()
        case .dynamicDisplayP3:
            let dynamicColor = self.toP3Color().toDynamicColor()
            if dynamicColor.luminance > 0.5 {
                return Color(dynamicColor.shaded(amount: (1 - dynamicColor.luminance) / 1.5))
            } else if dynamicColor.luminance < 0.2 {
                return Color(dynamicColor.tinted(amount: dynamicColor.luminance / 1))
            } else {
                return self.toP3Color()
            }
        }
    }
    
    func toScheduleTextColor(colorSpace: ColorSpaceOption, colorScheme: ColorScheme) -> Color {
        switch colorSpace {
        case .displayP3:
            return .systemContrast
        case .dynamicDisplayP3:
            var dynamicColor = self.toP3Color().toDynamicColor()
            if dynamicColor.luminance > 0.5 {
                dynamicColor = dynamicColor.shaded(amount: (1 - dynamicColor.luminance) / 3)
            } else if dynamicColor.luminance < 0.2 {
                dynamicColor = dynamicColor.tinted(amount: dynamicColor.luminance / 3)
            }
            if colorScheme == .dark {
                return Color(dynamicColor.tinted(amount: 0.75))
            } else {
                return Color(dynamicColor.shaded(amount: 0.55))
            }
        }
    }
    
    func toScheduleCellColor(colorSpace: ColorSpaceOption, colorScheme: ColorScheme) -> Color {
        switch colorSpace {
        case .displayP3:
            let dynamicColor = self.toP3Color().toDynamicColor()
            if colorScheme == .dark {
                return Color(dynamicColor.shaded(amount: 0.15))
            } else {
                return Color(dynamicColor.tinted(amount: 0.15))
            }
        case .dynamicDisplayP3:
            var dynamicColor = self.toP3Color().toDynamicColor()
            if dynamicColor.luminance > 0.5 {
                dynamicColor = dynamicColor.shaded(amount: (1 - dynamicColor.luminance) / 3)
            } else if dynamicColor.luminance < 0.2 {
                dynamicColor = dynamicColor.tinted(amount: dynamicColor.luminance / 3)
            }
            if colorScheme == .dark {
                return Color(dynamicColor.shaded(amount: 0.15))
            } else {
                return Color(dynamicColor.tinted(amount: 0.15))
            }
        }
    }
    
    func toClubColor(colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        return (colorScheme == .light && NSColor(hexString: self).luminance > 0.5 ? Color(NSColor(hexString: self).shaded(amount: 0.15).saturated(amount: 0.15)) : Color(hexString: self))
        #else
        return (colorScheme == .light && UIColor(hexString: self).luminance > 0.5 ? Color(UIColor(hexString: self).shaded(amount: 0.15).saturated(amount: 0.15)) : Color(hexString: self))
            
        #endif
    }
}

// MARK: - View Builders

/// Custom view representing a centered content view with optional scaling.
struct CenterView<Content: View>: View {
    let content: Content
    let geo: GeometryProxy
    let scale: CGFloat
    
    /// Initializes a centered view with optional scaling.
    /// - Parameters:
    ///   - geo: The geometry proxy to determine size and position.
    ///   - scale: The scaling factor for width and height of the content.
    ///   - content: The content to display within the centered view.
    init(geo: GeometryProxy, scale: CGFloat, @ViewBuilder content: () -> Content) {
        self.geo = geo
        self.scale = scale
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            content
                .frame(width: geo.size.width * scale, height: geo.size.height * scale, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .borderedCellStyle(padding: 0)
            Spacer()
        }
        .flushCenter()
#if os(iOS)
        .background(.systemCell)
#endif
    }
}

/// Custom stack view with optional toolbar and navigation controls.
struct StackView<Content: View, Toolbar: View>: View {
    let title: String
    let fontSize: CGFloat
    var backButton: Bool
    var cancelButton: Bool
    var isSheet: Bool
    let content: Content
    let toolbar: Toolbar?
    let centeredToolbar: Bool
    @State var isFullScreen: Bool
    
    @Environment(\.presentationMode) private var presentationMode
    
    /// Initializes a stack view with title, back button, and cancel button options.
    /// - Parameters:
    ///   - title: The title displayed at the top of the stack view.
    ///   - fontSize: The font size of the title. Defaults to 20.
    ///   - backButton: Whether to show a back button. Off by default.
    ///   - cancelButton: Whether to show a cancel button. Off by default.
    ///   - content: The main content displayed within the stack view.
    ///   - toolbar: Optional toolbar content displayed at the top right. Empty by default.
    init(_ title: String, fontSize: CGFloat = 20, backButton: Bool = false, cancelButton: Bool = false, isSheet: Bool = false, @ViewBuilder content: @escaping () -> Content) where Toolbar == EmptyView {
        self.title = title
        self.fontSize = fontSize
        self.backButton = backButton
        self.cancelButton = cancelButton
        self.isSheet = isSheet
        self.content = content()
        self.toolbar = nil
        self.isFullScreen = false
        self.centeredToolbar = false
    }
    
    /// Initializes a stack view with title, back button, cancel button options, and a custom toolbar.
    /// - Parameters:
    ///   - title: The title displayed at the top of the stack view.
    ///   - fontSize: The font size of the title. Defaults to 20.
    ///   - backButton: Whether to show a back button. Off by default.
    ///   - cancelButton: Whether to show a cancel button. Off by default.
    ///   - content: The main content displayed within the stack view.
    ///   - toolbar: Custom toolbar content displayed at the top right.
    init(_ title: String, fontSize: CGFloat = 20, backButton: Bool = false, cancelButton: Bool = false, isSheet: Bool = false, centeredToolbar: Bool = false, @ViewBuilder content: @escaping () -> Content, @ViewBuilder toolbar: @escaping () -> Toolbar) {
        self.title = title
        self.fontSize = fontSize
        self.backButton = backButton
        self.cancelButton = cancelButton
        self.isSheet = isSheet
        self.content = content()
        self.toolbar = toolbar()
        self.isFullScreen = false
        self.centeredToolbar = centeredToolbar
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
#if os(iOS)
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: fontSize))
                    .flushCenter()
                    .frame(maxWidth: 250)
#endif
                HStack {
                    if backButton {
                        Button {
                            generateHaptic(.impact(.medium))
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .body()
                                .foregroundStyle(.accent)
#if os(macOS)
                                .padding(.horizontal, 10)
                                .frame(height: 35)
                                .toolbarHoverEffect()
#endif
                        }
                        .buttonStyle(.plain)
                    } else if cancelButton || isSheet {
                        Button {
                            generateHaptic(.impact(.medium))
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                                .body()
                                .foregroundStyle(.accent)
                        }
                        .padding(.leading, 5)
                        .buttonStyle(.plain)
                    }
#if os(macOS)
                    Text(title)
                        .subheading()
                        .flushLeading()
                        .padding(.leading)
#endif
                    Spacer()
                    if let toolbarView = toolbar, !centeredToolbar {
                        toolbarView
                            .padding(.trailing)
                    }
                }
                if let toolbarView = toolbar, centeredToolbar {
                    toolbarView
                }
            }
#if os(iOS)
            .padding()
#elseif os(macOS)
            .padding(.horizontal)
            .frame(height: 55)
#endif
            .background(.systemCell)
            Divider()
            content
        }
        .toolbar(.hidden)
        .navigationBarBackButtonHidden(true)
#if os(iOS)
        .background(.systemWindow)
#elseif os(macOS)
        .padding(.top, isFullScreen ? 0 : -25)
        .detectFullScreen(isFullScreen: $isFullScreen)
#endif
    }
}


// MARK: - Haptics

#if os(iOS)

/// Enum defining different types of haptic feedback on iOS.
enum FeedbackType {
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
}

/// Generates haptic feedback based on the specified `FeedbackType`.
/// - Parameter type: The type of haptic feedback to generate.
func generateHaptic(_ type: FeedbackType) {
    switch type {
    case .selection:
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    case .impact(let style):
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    case .notification(let notificationType):
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(notificationType)
    }
}

#elseif os(macOS)

enum FeedbackType {
    case selection
    case impact(DummyImpactFeedbackStyle)
    case notification(DummyNotificationFeedbackType)
}

/// Dummy enumeration for impact feedback styles on macOS.
enum DummyImpactFeedbackStyle {
    case light, medium, heavy, soft, rigid
}

/// Dummy enumeration for notification feedback types on macOS.
enum DummyNotificationFeedbackType {
    case success, warning, error
}

/// Dummy function for generating haptic feedback on macOS.
/// - Parameter type: The type of haptic feedback to generate (no-op on macOS).
func generateHaptic(_ type: FeedbackType) { }

#endif

// MARK: - Pasteboard

/// Copies the given string to the correct platform-specific pasteboard.
/// - Parameter string: The string to copy to the pasteboard.
func copyStringToPasteboard(_ string: String) {
#if os(iOS) && APP
    let pasteboard = UIPasteboard.general
    pasteboard.string = string
#elseif os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(string, forType: NSPasteboard.PasteboardType.string)
#endif
}

// MARK: - Platform Specific

#if os(iOS) && APP

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

/// Struct representing a visual effect blur view for iOS.
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

/// Extension on `UINavigationController` to handle gesture delegate for back navigation.
extension UIKit.UINavigationController: UIKit.UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

/// Enum representing different device interface types for iOS.
enum DeviceInterfaceType {
    case dynamicIsland
    case notch
    case none
}

/// Extension on `UIDevice` to determine the current device interface type.
extension UIDevice {
    var interfaceType: DeviceInterfaceType {
        guard let window = (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow}) else {
            return .none
        }
        if window.safeAreaInsets.top >= 51 && userInterfaceIdiom == .phone {
            return .dynamicIsland
        } else if window.safeAreaInsets.top >= 44 {
            return .notch
        } else if window.safeAreaInsets.left > 0 || window.safeAreaInsets.right > 0 {
            return .none
        }
        return .none
    }
}

struct PreviewController: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: context.coordinator,
            action: #selector(context.coordinator.dismiss)
        )
        
        let navigationController = UINavigationController(rootViewController: controller)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: QLPreviewControllerDataSource {
        let parent: PreviewController
        
        init(parent: PreviewController) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            return parent.url as NSURL
        }
        
        @objc func dismiss() {
            parent.dismiss()
        }
    }
}

#elseif os(macOS)

/// Extension on `View` to open the view in a new window on macOS.
extension View {
    /// Opens the view in a new window with the specified title and sender.
    /// - Parameters:
    ///   - title: The title of the window.
    ///   - isClear: Determines if the window should be clear (not used here).
    ///   - sender: The sender initiating the window opening.
    /// - Returns: The opened `NSWindow` instance.
    @discardableResult
    func openInWindow(title: String, isClear: Bool, sender: Any?) -> NSWindow {
        let controller = NSHostingController(rootView: self)
        let window = NSWindow(contentViewController: controller)
        window.contentViewController = controller
        window.title = title
        window.titleVisibility = .visible
        window.titlebarSeparatorStyle = .line
        window.makeKeyAndOrderFront(sender)
        return window
    }
    
    func window() -> NSWindow? {
        NSApplication.shared.windows.first { $0.isKeyWindow }
    }
    
    func detectFullScreen(isFullScreen: Binding<Bool>) -> some View {
        self.modifier(FullScreenDetector(isFullScreen: isFullScreen))
    }
}

/// Toggles the sidebar visibility on macOS.
func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
}

/// Custom NSView subclass that accepts first responder status for focusing.
class FocusNSView: NSView {
    override var acceptsFirstResponder: Bool {
        return true
    }
}

/// Struct representing a visual effect view for macOS.
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct FullScreenDetector: ViewModifier {
    @Binding var isFullScreen: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateFullScreenStatus()
                NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window(), queue: .main) { _ in
                    isFullScreen = true
                }
                NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification, object: window(), queue: .main) { _ in
                    isFullScreen = false
                }
            }
    }
    
    private func updateFullScreenStatus() {
        if let window = window() {
            isFullScreen = window.styleMask.contains(.fullScreen)
        }
    }
    
    private func window() -> NSWindow? {
        NSApplication.shared.windows.first { $0.isKeyWindow }
    }
}

#endif
