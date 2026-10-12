from pathlib import Path
root=Path(__file__).resolve().parents[1]
(root/'Reach/Theme.swift').write_text(r'''import SwiftUI
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
        }.buttonStyle(.plain)
    }
}
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
''',encoding='utf-8')
app=root/'Reach/App.swift'
source=app.read_text(encoding='utf-8')
start=source.index('struct RootView: View')
end=source.index('struct ProfileView: View')
replacement=r'''struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0
    @State private var onboarding = false
    @State private var tempted = false
    @AppStorage("introSeen") private var introSeen = false
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 1: BodyView()
                case 2: CaffeineView()
                case 3: RecoveryView(tempted: $tempted)
                case 4: FocusView()
                case 5: ResolveView()
                default: TodayView(tab: $tab, tempted: $tempted)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            HStack(spacing: 0) {
                tabButton(0, "Today", "square.grid.2x2")
                tabButton(1, "Body", "figure.strengthtraining.traditional")
                tabButton(2, "Caffeine", "cup.and.saucer")
                tabButton(3, "Relapse", "shield")
                tabButton(4, "Rewire", "timer")
                tabButton(5, "Resolve", "text.quote")
            }.padding(.vertical, 9).padding(.horizontal, 2).glass().padding(.horizontal, 10).padding(.bottom, 5)
        }.background(CanvasBackground()).foregroundColor(Ink.ivory)
            .sheet(isPresented: $onboarding) { ProfileView() }
            .fullScreenCover(isPresented: $tempted) { TemptedView() }
            .onAppear { onboarding = !introSeen && !store.data.profile.configured; introSeen = true }
            .alert("Journal needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("Keep original data", role: .cancel) {}
            } message: { Text(store.error ?? "") }
    }
    func tabButton(_ index: Int, _ title: String, _ symbol: String) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged(); tab = index
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 19, weight: tab == index ? .semibold : .regular))
                Text(title).font(.system(size: 9, weight: tab == index ? .semibold : .regular))
            }.foregroundColor(tab == index ? Ink.blue : Ink.muted).frame(maxWidth: .infinity).frame(minHeight: 44)
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityAddTraits(tab == index ? .isSelected : [])
    }
}

struct TodayView: View {
    @EnvironmentObject var store: Store
    @Binding var tab: Int
    @Binding var tempted: Bool
    @State private var settings = false
    @State private var food = false
    @State private var weigh = false
    @State private var activity = false
    var body: some View {
        Page(eyebrow: "", title: "Today", subtitle: Date().formatted(date: .complete, time: .omitted)) {
            HStack {
                Text(store.data.profile.name.isEmpty ? "Daily overview" : store.data.profile.name).font(.system(size: 15, weight: .medium))
                Spacer()
                Button { settings = true } label: { Image(systemName: "gearshape").font(.system(size: 19)).frame(width: 44, height: 36) }.accessibilityLabel("Your profile & backup")
            }
            HStack(spacing: 14) {
                Metric(label: "Calories", value: "\(Int(store.calories))", unit: store.data.profile.energyAvailable ? "/ ~\(Int(store.data.profile.target)) kcal" : "kcal logged")
                Metric(label: "Protein", value: "\(Int(store.protein))", unit: "g logged")
                Metric(label: "Weight", value: store.weekWeight.map { String(format: "%.1f", $0) } ?? "—", unit: "kg · 7-day mean")
            }.padding(.vertical, 12)
            HStack(spacing: 10) {
                Action(title: "Log food", symbol: "plus") { food = true }
                Action(title: "Weigh in", symbol: "plus") { weigh = true }
            }
            Button { tempted = true } label: {
                HStack { Image(systemName: "hand.raised"); Text("I’m tempted").fontWeight(.semibold); Spacer(); Text("Open support").font(.system(size: 12)).foregroundColor(Ink.muted); Image(systemName: "chevron.right").font(.caption) }
                    .padding(15).background(Ink.surface, in: RoundedRectangle(cornerRadius: 10))
            }.buttonStyle(.plain)
            WeightTrend(weights: store.data.weights)
            Card {
                SectionHeading(title: "Caffeine")
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    HStack {
                        Metric(label: "Estimated remaining", value: "~\(Int(Caffeine.remaining(store.doses, at: context.date, halfLife: store.caffeineConfig.halfLifeHours)))", unit: "mg · elimination model")
                        Metric(label: "Last 24 hours", value: "\(Int(Caffeine.intake(store.doses, at: context.date)))", unit: "mg logged")
                    }
                }
                NavigationRow(title: "ABE & caffeine log", detail: "Dose history, decay curve and bedtime estimate", symbol: "cup.and.saucer") { tab = 2 }
            }
            DailyIntakeChart(meals: store.data.meals, complete: store.data.completedIntakeDays ?? [], target: store.data.profile.energyAvailable ? store.data.profile.target : nil)
            VStack(spacing: 0) {
                NavigationRow(title: "Home + gym", detail: store.activityDescription, symbol: "figure.strengthtraining.traditional") { activity = true }
                Divider().overlay(Ink.line)
                NavigationRow(title: "Focus", detail: "\(store.todayFocus) minutes logged today", symbol: "timer") { tab = 4 }
            }
            SectionHeading(title: "Daily checklist")
            ForEach(["Gym or planned recovery", "One distraction-free focus block", "Read 5 pages", "Phone outside the bedroom"], id: \.self) { habit in
                Button { store.toggle(habit) } label: {
                    HStack(spacing: 12) { Image(systemName: store.done(habit) ? "checkmark.circle.fill" : "circle").foregroundColor(store.done(habit) ? Ink.blue : Ink.muted); Text(habit).font(.system(size: 14)); Spacer() }.padding(.vertical, 8)
                }.buttonStyle(.plain)
            }
        }.sheet(isPresented: $settings) { SettingsView() }
            .sheet(isPresented: $food) { FoodView() }.sheet(isPresented: $weigh) { WeightView() }
            .sheet(isPresented: $activity) { ActivityView() }
    }
}

'''
app.write_text(source[:start]+replacement+source[end:],encoding='utf-8')
print('Rebuilt flat theme, compact navigation and data dashboard')
