import SwiftUI
import UIKit

enum Ink {
    static let blue = Color(red: 0.32, green: 0.57, blue: 0.94)
    static let ivory = Color(red: 0.93, green: 0.94, blue: 0.95)
    static let muted = Color(red: 0.57, green: 0.61, blue: 0.67)
    static let background = Color(red: 0.035, green: 0.043, blue: 0.055)
    static let surface = Color(red: 0.065, green: 0.078, blue: 0.10)
    static let line = Color.white.opacity(0.09)
    static let amber = Color(red: 0.88, green: 0.65, blue: 0.32)
}
struct Glass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    func body(content: Content) -> some View {
        Group {
            #if compiler(>=6.2)
            if #available(iOS 26.0, *), !reduceTransparency {
                content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            } else { content.background(Ink.surface, in: RoundedRectangle(cornerRadius: 14)) }
            #else
            content.background(Ink.surface, in: RoundedRectangle(cornerRadius: 14))
            #endif
        }
    }
}
extension View { func glass() -> some View { modifier(Glass()) } }
struct CanvasBackground: View {
    var body: some View { Ink.background.ignoresSafeArea() }
}
struct InkIcon: View {
    var name: String
    var size: CGFloat = 34
    var body: some View {
        Image(name).resizable().scaledToFit()
            .mask(Image(name).resizable().scaledToFit().brightness(-0.07).luminanceToAlpha())
            .frame(width: size, height: size).accessibilityHidden(true)
    }
}
struct Page<Content: View>: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.system(size: 28, weight: .semibold)).foregroundColor(Ink.ivory)
                    if !subtitle.isEmpty { Text(subtitle).font(.system(size: 13)).foregroundColor(Ink.muted).fixedSize(horizontal: false, vertical: true) }
                }.padding(.top, 16)
                content
            }.padding(.horizontal, 18).padding(.bottom, 24).frame(maxWidth: 650)
        }.background(CanvasBackground())
    }
}
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
struct Action: View {
    var title: String
    var symbol: String = "arrow.up.right"
    var action: () -> Void
    var body: some View {
        Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); action() } label: {
            HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol).font(.system(size: 14, weight: .semibold)) }
                .font(.system(size: 15)).padding(.horizontal, 14).frame(minHeight: 46)
                .foregroundColor(Ink.ivory).background(Color(red: 0.12, green: 0.24, blue: 0.40), in: RoundedRectangle(cornerRadius: 9))
        }.buttonStyle(.plain)
    }
}
struct Metric: View {
    var label: String
    var value: String
    var unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 12)).foregroundColor(Ink.muted)
            Text(value).font(.system(size: 26, weight: .semibold)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Text(unit).font(.system(size: 11)).foregroundColor(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct SectionHeading: View {
    var title: String
    var detail: String = ""
    var body: some View { HStack { Text(title).font(.system(size: 17, weight: .semibold)); Spacer(); if !detail.isEmpty { Text(detail).font(.system(size: 12)).foregroundColor(Ink.muted) } } }
}
struct NavigationRow: View {
    var title: String
    var detail: String
    var symbol: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundColor(Ink.blue).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 15, weight: .medium)); if !detail.isEmpty { Text(detail).font(.system(size: 12)).foregroundColor(Ink.muted) } }
                Spacer(); Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundColor(Ink.muted)
            }.padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityHint(detail)
    }
}
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
