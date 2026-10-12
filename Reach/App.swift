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
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case 1: BodyView()
                case 2: RecoveryView(tempted: $tempted)
                case 3: FocusView()
                case 4: ResolveView()
                default: TodayView(tab: $tab, tempted: $tempted)
                }
            }
            HStack(spacing: 0) {
                tabButton(0, "Today", "hand", "hand.raised")
                tabButton(1, "Body", "skull", "figure.strengthtraining.traditional")
                tabButton(2, "Relapse", "shield", "shield")
                tabButton(3, "Rewire", "eye", "eye")
                tabButton(4, "Resolve", "sword", "bolt")
            }.padding(.vertical, 10).padding(.horizontal, 5).glass().padding(.horizontal, 16).padding(.bottom, 6)
        }.foregroundColor(Ink.ivory)
            .sheet(isPresented: $onboarding) { ProfileView() }
            .fullScreenCover(isPresented: $tempted) { TemptedView() }
            .onAppear { onboarding = !store.data.profile.configured }
            .alert("Journal needs attention", isPresented: Binding(get: { store.error != nil }, set: { _ in })) {
                Button("Keep original data", role: .cancel) {}
            } message: { Text(store.error ?? "") }
    }
    func tabButton(_ index: Int, _ title: String, _ image: String, _ fallback: String) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            tab = index
        } label: {
            VStack(spacing: 2) {
                InkIcon(name: image, size: 32).opacity(tab == index ? 1 : 0.55)
                Text(title).font(.system(size: 9, weight: tab == index ? .bold : .regular)).foregroundColor(tab == index ? Ink.ivory : Ink.muted)
                Capsule().fill(tab == index ? Ink.blue : .clear).frame(width: 12, height: 2)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityAddTraits(tab == index ? .isSelected : [])
    }
}

struct TodayView: View {
    @EnvironmentObject var store: Store
    @Binding var tab: Int
    @Binding var tempted: Bool
    @State private var settings = false
    var body: some View {
        Page(eyebrow: Date().formatted(date: .abbreviated, time: .omitted), title: "Take yourself\nback.", subtitle: "One honest day. Then another.") {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("REACH").font(.system(size: 13, weight: .heavy, design: .monospaced)).tracking(7)
                    Text(store.data.profile.name.isEmpty ? "Your work starts here." : "Your work starts here, \(store.data.profile.name).").font(.system(size: 18, weight: .medium, design: .serif))
                    Button("Your profile & backup") { settings = true }.font(.system(size: 12)).foregroundColor(Ink.blue)
                }
                Spacer()
                InkIcon(name: "hand", size: 115)
            }.padding(.bottom, 12)
            HStack {
                Metric(label: "Fuel", value: "\(Int(store.calories))", unit: "kcal logged today")
                Metric(label: "Focus", value: "\(store.todayFocus)", unit: "minutes reclaimed")
                Metric(label: "Weight", value: store.weekWeight.map { String(format: "%.1f", $0) } ?? "—", unit: "kg · 7-day mean")
            }.padding(.vertical, 20).overlay(alignment: .top) { Rectangle().fill(Ink.muted.opacity(0.2)).frame(height: 1) }.overlay(alignment: .bottom) { Rectangle().fill(Ink.muted.opacity(0.2)).frame(height: 1) }
            Card {
                Text("BEFORE THE SPIRAL").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(3).foregroundColor(Ink.blue)
                Text("You still have a choice.").font(.system(size: 25, weight: .medium, design: .serif))
                Text("Pause the urge. Put distance between you and the trigger. Let’s get through the next few minutes.").foregroundColor(Ink.muted).font(.system(size: 14))
                Action(title: "I’m tempted", symbol: "hand.raised.fill") { tempted = true }
            }
            Text("TODAY’S NON-NEGOTIABLES").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(Ink.muted)
            ForEach(["Move for 20 minutes", "One distraction-free focus block", "Read 5 pages", "Phone outside the bedroom"], id: \.self) { habit in
                Button { store.toggle(habit) } label: {
                    HStack(spacing: 13) {
                        Image(systemName: store.done(habit) ? "checkmark.circle.fill" : "circle").foregroundColor(store.done(habit) ? Ink.blue : Ink.muted)
                        Text(habit).font(.system(size: 15)); Spacer()
                    }.padding(.vertical, 10)
                }.buttonStyle(.plain)
            }
            Button { tab = 4 } label: {
                HStack { Text("Your next ten minutes are still yours. Take them back.").font(.system(size: 24, weight: .medium, design: .serif)); Spacer(); InkIcon(name: "sword", size: 55) }
                    .padding(.vertical, 18)
            }.buttonStyle(.plain)
        }.sheet(isPresented: $settings) { SettingsView() }
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
                    Text("Build a plan around your real life.").font(.system(size: 26, weight: .bold, design: .serif))
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
                Section("Your usual activity") {
                    Picker("Activity", selection: $profile.activity) {
                        Text("Mostly seated").tag(1.2)
                        Text("Light · 1–3 active days/week").tag(1.375)
                        Text("Moderate · 3–5 days/week").tag(1.55)
                        Text("High · 6–7 days/week").tag(1.725)
                    }
                    Text("Include your usual exercise here. The app doesn’t add exercise calories again.").font(.caption).foregroundColor(Ink.muted)
                }
                Section("Before setting a deficit") {
                    Toggle("Medical condition or relevant medication", isOn: $profile.medicalRisk)
                    Toggle("Current or past eating disorder", isOn: $profile.eatingRisk)
                    Toggle("Pregnant or breastfeeding", isOn: $profile.pregnant)
                    Text("If any applies, or you’re under 18, Cut Mode will ask you to work with a qualified clinician instead of generating a deficit.").font(.caption).foregroundColor(Ink.muted)
                }
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Section { Button("Save my profile") { save() }.fontWeight(.bold) }
            }.navigationTitle("Your starting point").navigationBarTitleDisplayMode(.inline)
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
        store.data.profile = profile
        if store.data.weights.isEmpty { store.data.weights.append(WeighIn(kg: profile.weight)) }
        store.save(); dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var edit = false
    @State private var exportURL: URL?
    @State private var sharing = false
    @State private var importing = false
    @State private var importSnapshot: Snapshot?
    @State private var confirmImport = false
    @State private var message = ""
    var body: some View {
        NavigationView {
            List {
                Section("Your profile") { Button("Edit measurements & safety screening") { edit = true } }
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
                Section { Text("REACH 1.0 · Made for the work.").font(.caption).foregroundColor(Ink.muted) }
            }.navigationTitle("Your space").toolbar { Button("Done") { dismiss() } }
        }.sheet(isPresented: $edit) { ProfileView() }
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
                          (0...0.25).contains(p.intensity), [1.2,1.375,1.55,1.725].contains(p.activity),
                          snapshot.meals.allSatisfy({ $0.grams.isFinite && $0.grams > 0 && $0.grams <= 5000 && $0.kcalPer100.isFinite && (0...1000).contains($0.kcalPer100) }) else { message = "This backup contains invalid values."; return }
                    importSnapshot = snapshot; confirmImport = true
                } catch { message = "That file isn’t a readable REACH backup." }
            }
            .alert("Replace this device’s journal?", isPresented: $confirmImport) {
                Button("Cancel", role: .cancel) {}
                Button("Restore", role: .destructive) { if let snapshot = importSnapshot { store.data = snapshot; store.save() } }
            } message: { Text("Export your current journal first if you want to keep it. Restoring replaces its entries.") }
    }
}
