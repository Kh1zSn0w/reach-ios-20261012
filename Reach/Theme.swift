import SwiftUI
import UIKit

enum Ink {
    static let blue = Color(red: 0.25, green: 0.48, blue: 1)
    static let ivory = Color(red: 0.94, green: 0.93, blue: 0.87)
    static let muted = Color(red: 0.57, green: 0.63, blue: 0.73)
    static let background = Color(red: 0.02, green: 0.035, blue: 0.065)
}
struct Glass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content.background(Color(red: 0.07, green: 0.10, blue: 0.16), in: RoundedRectangle(cornerRadius: 26))
            } else {
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular.tint(Color.blue.opacity(0.10)), in: RoundedRectangle(cornerRadius: 26))
            } else { fallback(content) }
            #else
            fallback(content)
            #endif
            }
        }
    }
    func fallback(_ content: Content) -> some View {
        content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(LinearGradient(colors: [.white.opacity(0.20), Ink.blue.opacity(0.1), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
    }
}
extension View { func glass() -> some View { modifier(Glass()) } }
struct CanvasBackground: View {
    var body: some View {
        ZStack {
            Ink.background
            RadialGradient(colors: [Ink.blue.opacity(0.19), .clear], center: .topTrailing, startRadius: 5, endRadius: 430)
            Canvas { context, size in
                for i in stride(from: 0, to: Int(size.height), by: 7) {
                    var path = Path(); path.move(to: CGPoint(x: 0, y: i)); path.addLine(to: CGPoint(x: size.width, y: CGFloat(i) - 45))
                    context.stroke(path, with: .color(.white.opacity(0.013)), lineWidth: 0.5)
                }
            }
        }.ignoresSafeArea()
    }
}
struct InkIcon: View {
    var name: String
    var size: CGFloat = 68
    var body: some View { Image(name).resizable().scaledToFit().frame(width: size, height: size).accessibilityHidden(true) }
}
struct Page<Content: View>: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(eyebrow.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(4).foregroundColor(Ink.blue)
                    Text(title.uppercased()).font(.custom("BebasNeue-Regular", size: 48, relativeTo: .largeTitle)).tracking(0.8).foregroundColor(Ink.ivory)
                    Text(subtitle).font(.system(size: 14)).foregroundColor(Ink.muted).fixedSize(horizontal: false, vertical: true)
                }.padding(.top, 24)
                content
                Text("REACH / BUILD YOURSELF").font(.system(size: 9, design: .monospaced)).tracking(3).foregroundColor(Ink.muted.opacity(0.5)).padding(.vertical, 16)
            }.padding(.horizontal, 22).padding(.bottom, 100).frame(maxWidth: 650)
        }.background(CanvasBackground())
    }
}
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 16) { content }.frame(maxWidth: .infinity, alignment: .leading).padding(22).glass() }
}
struct Action: View {
    var title: String
    var symbol: String = "arrow.up.right"
    var action: () -> Void
    var body: some View {
        Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); action() } label: {
            HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol) }.font(.system(size: 15)).padding(17).foregroundColor(Ink.ivory).background(Ink.blue.opacity(0.25), in: RoundedRectangle(cornerRadius: 17)).overlay(RoundedRectangle(cornerRadius: 17).stroke(Ink.blue.opacity(0.5)))
        }.buttonStyle(.plain)
    }
}
struct Metric: View {
    var label: String
    var value: String
    var unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5).foregroundColor(Ink.muted)
            Text(value).font(.system(size: 28, weight: .medium, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            Text(unit).font(.system(size: 11)).foregroundColor(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
