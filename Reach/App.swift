import SwiftUI
import UIKit
import UniformTypeIdentifiers

@main struct ReachApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).preferredColorScheme(.dark).tint(Ink.blue)
        }
    }
}
struct RootView: View {
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

struct ProfileView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var profile = Profile()
    @State private var message = ""
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Profile").font(.system(size: 22, weight: .semibold))
                    Text("These values produce a starting estimate, not a measurement of your metabolism. All entries stay on this device.").foregroundColor(Ink.muted)
                    TextField("Your name (optional)", text: $profile.name)
                }
                Section("Body measurements") {
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 13...100)
                    number("Height in cm", value: $profile.height)
                    number("Current weight in kg", value: $profile.weight)
                    number("Goal weight in kg", value: $profile.goal)
                    Picker("Equation coefficient", selection: $profile.sex) { Text("Male").tag("Male"); Text("Female").tag("Female") }
                    Text("Mifflin–St Jeor uses sex-based coefficients. Hormone therapy and individual differences can reduce its accuracy.").font(.caption).foregroundColor(Ink.muted)
                }
                Section("Activity") {
                    Text("Home most of the day + gym").font(.system(size: 15, weight: .medium))
                    Text("Save your profile, then use the dedicated Activity section to enter gym frequency, duration and type. Existing calorie settings stay in place until you confirm the new plan.").font(.caption).foregroundColor(Ink.muted)
                }
                Section("Before setting a deficit") {
                    Toggle("Medical condition or relevant medication", isOn: $profile.medicalRisk)
                    Toggle("Current or past eating disorder", isOn: $profile.eatingRisk)
                    Toggle("Pregnant or breastfeeding", isOn: $profile.pregnant)
                    Text("If any applies, or you’re under 18, Cut Mode will ask you to work with a qualified clinician instead of generating a deficit.").font(.caption).foregroundColor(Ink.muted)
                }
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Section { Button("Save my profile") { save() }.font(.system(size: 16, weight: .bold)) }
            }.navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.onAppear { profile = store.data.profile }.preferredColorScheme(.dark)
    }
    func number(_ title: String, value: Binding<Double>) -> some View {
        HStack { Text(title); Spacer(); TextField(title, value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 95).accessibilityLabel(title) }
    }
    func save() {
        guard profile.height.isFinite, profile.weight.isFinite, profile.goal.isFinite,
              (120...230).contains(profile.height), (30...350).contains(profile.weight), (30...350).contains(profile.goal) else {
            message = "Enter a height from 120–230 cm and weights from 30–350 kg."; return
        }
        profile.configured = true
        if profile.age != store.data.profile.age || profile.height != store.data.profile.height || profile.sex != store.data.profile.sex {
            profile.maintenanceOverride = nil; profile.maintenanceUpdated = nil
        }
        store.data.profile = profile
        if store.data.weights.isEmpty { store.data.weights.append(WeighIn(kg: profile.weight)) }
        store.save(); dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var edit = false
    @State private var activity = false
    @State private var exportURL: URL?
    @State private var sharing = false
    @State private var importing = false
    @State private var importSnapshot: Snapshot?
    @State private var confirmImport = false
    @State private var message = ""
    var body: some View {
        NavigationView {
            List {
                Section("Your profile") { Button("Edit measurements & safety screening") { edit = true }; Button("Home + gym activity") { activity = true } }
                Section("Private by design") {
                    Text("No account. No analytics. No ads. Your food, body and recovery journal stay on your device, protected by iOS file protection. Device backups may include this data.")
                    Button("Export private backup") {
                        do { exportURL = try store.export(); sharing = true } catch { message = "Could not prepare your backup." }
                    }
                    Button("Restore a REACH backup") { importing = true }
                    Text("Exports contain sensitive journal entries. Share only with someone you trust.").font(.caption).foregroundColor(Ink.muted)
                }
                Section("What REACH can do") {
                    Text("Calorie and TDEE values are estimates. Food label values and weighed portions are usually more useful than guesses. Weight changes also include water and glycogen.")
                    Text("Urge support and focus training are self-help tools. They do not diagnose addiction, treat ADHD, guarantee abstinence, or promise a brain reset.")
                    Text("REACH cannot block other apps. Use iPhone Settings → Screen Time → Content & Privacy Restrictions for adult-site restrictions. A trusted person can hold the passcode if you choose.")
                }
                Section("References") {
                    Link("CDC · realistic weight loss", destination: URL(string: "https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html")!)
                    Link("NIDDK · Body Weight Planner", destination: URL(string: "https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner")!)
                    Link("Mayo Clinic · compulsive behavior support", destination: URL(string: "https://www.mayoclinic.org/diseases-conditions/compulsive-sexual-behavior/diagnosis-treatment/drc-20360453")!)
                    Link("NIH · sleep needs", destination: URL(string: "https://www.nhlbi.nih.gov/health/sleep/how-much-sleep")!)
                    Link("Mifflin–St Jeor · original study", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/2305711/")!)
                }
                if !message.isEmpty { Text(message) }
                Section { Text("Version 1.1").font(.caption).foregroundColor(Ink.muted) }
            }.navigationTitle("Settings").toolbar { Button("Done") { dismiss() } }
        }.sheet(isPresented: $edit) { ProfileView() }
            .sheet(isPresented: $activity) { ActivityView() }
            .sheet(isPresented: $sharing) { if let url = exportURL { ShareSheet(items: [url]) } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get(); let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let bytes = try Data(contentsOf: url)
                    guard bytes.count <= 20_000_000 else { message = "This backup is too large."; return }
                    let snapshot = try JSONDecoder().decode(Snapshot.self, from: bytes)
                    let p = snapshot.profile
                    guard (120...230).contains(p.height), (30...350).contains(p.weight), (13...100).contains(p.age),
                          (30...350).contains(p.goal), ["Male", "Female"].contains(p.sex),
                          (0...0.25).contains(p.intensity), [1.2,1.375,1.55,1.725].contains(p.activity),
                          snapshot.meals.allSatisfy({ $0.grams.isFinite && $0.grams > 0 && $0.grams <= 5000 && $0.kcalPer100.isFinite && (0...1000).contains($0.kcalPer100) && $0.proteinPer100.isFinite && (0...100).contains($0.proteinPer100) }),
                          snapshot.weights.allSatisfy({ $0.kg.isFinite && (30...350).contains($0.kg) }),
                          snapshot.focus.allSatisfy({ (1...120).contains($0.minutes) }),
                          snapshot.checkIns.allSatisfy({ (0...10).contains($0.urge) }), snapshot.extendedFieldsValid else { message = "This backup contains invalid values."; return }
                    importSnapshot = snapshot; confirmImport = true
                } catch { message = "That file isn’t a readable REACH backup." }
            }
            .alert("Replace this device’s journal?", isPresented: $confirmImport) {
                Button("Cancel", role: .cancel) {}
                Button("Restore", role: .destructive) { if let snapshot = importSnapshot { store.restore(snapshot) } }
            } message: { Text("Export your current journal first if you want to keep it. Restoring replaces its entries.") }
    }
}
