import SwiftUI

struct CaffeineView: View {
    @EnvironmentObject var store: Store
    @State private var log = false
    @State private var settings = false
    @State private var method = false
    var body: some View {
        Page(eyebrow: "", title: "Caffeine", subtitle: "ABE Candy Ice Blast and other logged sources") {
            TimelineView(.periodic(from: .now, by: 60)) { context in summary(at: context.date) }
            HStack { Action(title: "Log caffeine", symbol: "plus") { log = true }; Button { settings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 46, height: 46).background(Ink.surface, in: RoundedRectangle(cornerRadius: 9)) }.accessibilityLabel("Caffeine settings") }
            CaffeineCurve(doses: store.doses, halfLife: store.caffeineConfig.halfLifeHours, config: store.caffeineConfig)
            Card {
                SectionHeading(title: "ABE Candy Ice Blast")
                LabeledValue(label: "Caffeine per serving", value: "\(Int(store.caffeineConfig.abeCaffeine)) mg")
                LabeledValue(label: "Serving mass", value: String(format: "%.1f g", store.caffeineConfig.abeServingGrams))
                Text("Current manufacturer listing: 200 mg per 12.5 g. Older 315 g tubs may use 10.5 g. Check your tub; half a weighed serving contains half its labeled caffeine. Other stimulants are not included in this caffeine-only model.").font(.system(size: 12)).foregroundColor(Ink.muted)
                Button("Review my ABE label") { settings = true }.font(.system(size: 13))
                Link("Manufacturer’s product label", destination: URL(string: "https://appliednutrition.uk/products/abe-all-black-everything-375g")!).font(.system(size: 12))
            }
            SectionHeading(title: "Dose history")
            if store.doses.isEmpty { Text("No caffeine logged. Add the time and labeled amount actually consumed.").font(.system(size: 13)).foregroundColor(Ink.muted) }
            ForEach(Array(store.doses.sorted { $0.date > $1.date }.prefix(30))) { dose in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) { Text(dose.name).font(.system(size: 14, weight: .medium)); Text(dose.date.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 11)).foregroundColor(Ink.muted) }
                    Spacer(); Text("\(Int(dose.mg)) mg").font(.system(size: 14)).monospacedDigit().accessibilityIdentifier("caffeineDoseRow")
                    Button { store.data.caffeine?.removeAll { $0.id == dose.id }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete caffeine dose")
                }.padding(.vertical, 9)
            }
            Button("Model, assumptions & sources") { method = true }.font(.system(size: 13))
        }.sheet(isPresented: $log) { CaffeineLog() }.sheet(isPresented: $settings) { CaffeineSettingsView() }.sheet(isPresented: $method) { CaffeineMethod() }
    }
    func summary(at now: Date) -> some View {
        let config = store.caffeineConfig
        let amount = Caffeine.remaining(store.doses, at: now, halfLife: config.halfLifeHours)
        let bedtime = Caffeine.nextBedtime(settings: config, after: now)
        let atBed = Caffeine.remaining(store.doses, at: bedtime, halfLife: config.halfLifeHours)
        let recent = Caffeine.intake(store.doses, at: now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Metric(label: "Estimated remaining", value: store.doses.isEmpty ? "—" : amount < 1 ? "<1" : "~\(Int(amount.rounded()))", unit: "mg · modeled, not measured"); Metric(label: "Last 24 hours", value: "\(Int(recent))", unit: "mg consumed / logged") }
            Card {
                LabeledValue(label: "At bedtime · \(bedtime.formatted(date: .omitted, time: .shortened))", value: store.doses.isEmpty ? "No doses" : atBed < 1 ? "<1 mg estimated" : "~\(Int(atBed.rounded())) mg estimated")
                LabeledValue(label: "Half-life assumption", value: String(format: "%.1f hours", config.halfLifeHours))
                Text("Assumes no further caffeine. This is not a prediction that you can sleep, a blood test, or a safe-to-dose indicator.").font(.system(size: 11)).foregroundColor(Ink.muted)
            }
            if recent > 400 { Text("You logged more than the FDA’s general 400 mg/day adult reference. That reference is not a target or a personalized safe limit. ABE’s manufacturer states no more than one serving daily.").font(.system(size: 12)).foregroundColor(Ink.amber) }
            if !store.data.profile.configured || store.data.profile.age < 18 || store.data.profile.pregnant || store.data.profile.medicalRisk {
                Text("Adult caffeine guidance may not apply to you. Children, pregnancy, medications and medical conditions need individual advice; the app does not recommend a dose.").font(.system(size: 12)).foregroundColor(Ink.muted)
            }
        }
    }
}

struct CaffeineCurve: View {
    var doses: [CaffeineDose]
    var halfLife: Double
    var config: CaffeineSettings
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let start = now.addingTimeInterval(-6 * 3600)
            let bed = Caffeine.nextBedtime(settings: config, after: now)
            let end = max(now.addingTimeInterval(18 * 3600), bed.addingTimeInterval(2 * 3600))
            let times = (0...96).map { start.addingTimeInterval(Double($0) / 96 * end.timeIntervalSince(start)) }
            let main = times.map { ChartPoint(date: $0, value: Caffeine.remaining(doses, at: $0, halfLife: halfLife)) }
            let fast = times.map { ChartPoint(date: $0, value: Caffeine.remaining(doses, at: $0, halfLife: 3)) }
            let slow = times.map { ChartPoint(date: $0, value: Caffeine.remaining(doses, at: $0, halfLife: 7)) }
            Card {
                SectionHeading(title: "Caffeine curve", detail: "mg")
                if doses.isEmpty { Text("Add a dose to see the curve.").font(.system(size: 13)).foregroundColor(Ink.muted) }
                LinePlot(points: main, lower: fast, upper: slow, start: start, end: end, unit: "mg", color: Ink.amber, zeroBased: true, timeLabels: true, markers: [ChartMarker(date: now, title: "Now"), ChartMarker(date: bed, title: "Bed")])
                Text("Line: your selected half-life. Shaded band: 3–7 hour sensitivity example, not a confidence interval. Real metabolism can fall outside it. Recent doses may still be absorbing for up to ~2 hours.").font(.system(size: 11)).foregroundColor(Ink.muted)
            }.accessibilityIdentifier("caffeineCurve")
        }
    }
}
struct CaffeineLog: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var source = "ABE Candy Ice Blast"
    @State private var mode = "Servings"
    @State private var amount = "1"
    @State private var name = ""
    @State private var date = Date()
    @State private var verified = false
    @State private var message = ""
    var milligrams: Double? {
        guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")), value.isFinite, value > 0 else { return nil }
        if source == "Other caffeine" { return value }
        return mode == "Grams" ? value / store.caffeineConfig.abeServingGrams * store.caffeineConfig.abeCaffeine : value * store.caffeineConfig.abeCaffeine
    }
    var body: some View {
        NavigationView {
            Form {
                Section("Actually consumed") {
                    Picker("Source", selection: $source) { Text("ABE Candy Ice Blast").tag("ABE Candy Ice Blast"); Text("Other caffeine").tag("Other caffeine") }
                    DatePicker("Time consumed", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    if source == "ABE Candy Ice Blast" {
                        Picker("Measure by", selection: $mode) { Text("Servings").tag("Servings"); Text("Grams").tag("Grams") }.pickerStyle(.segmented)
                        Text("Preset: \(Int(store.caffeineConfig.abeCaffeine)) mg per \(String(format: "%.1f", store.caffeineConfig.abeServingGrams)) g. Weigh powder for accuracy; scoop volumes vary.").font(.caption).foregroundColor(Ink.muted)
                        Toggle("This caffeine/serving value matches my tub", isOn: $verified)
                    } else {
                        TextField("Drink or product name", text: $name)
                        Text("Enter labeled caffeine in milligrams. Coffee varies widely, so the app does not assign an exact amount from ‘one cup’.").font(.caption).foregroundColor(Ink.muted)
                    }
                    TextField(source == "Other caffeine" ? "Caffeine in mg" : mode == "Grams" ? "Powder grams consumed" : "Servings consumed", text: $amount).keyboardType(.decimalPad).accessibilityLabel("Caffeine amount")
                    if let mg = milligrams, mg <= 10000 { Text("This entry: \(Int(mg.rounded())) mg caffeine").font(.system(size: 18, weight: .semibold)) }
                }
                Text("ABE’s manufacturer states no more than one serving daily. Log what actually happened; this screen is not a suggestion to take more. If you have chest pain, severe palpitations, fainting or seizures after caffeine, seek urgent medical help.").font(.caption).foregroundColor(Ink.muted)
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Button("Save caffeine dose") {
                    guard let mg = milligrams, mg.isFinite, (0.1...2000).contains(mg), source != "ABE Candy Ice Blast" || verified,
                          source != "Other caffeine" || !name.trimmingCharacters(in: .whitespaces).isEmpty else { message = "Enter a valid amount, check the ABE label, or name the other source."; return }
                    if store.data.caffeine == nil { store.data.caffeine = [] }
                    store.data.caffeine?.append(CaffeineDose(date: date, name: source == "Other caffeine" ? String(name.prefix(100)) : source, mg: mg))
                    var config = store.caffeineConfig; config.abeLabelConfirmed = verified || config.abeLabelConfirmed; store.data.caffeineSettings = config
                    store.save(); dismiss()
                }.disabled(source == "ABE Candy Ice Blast" && !verified)
            }.navigationTitle("Log caffeine").navigationBarTitleDisplayMode(.inline).toolbar { Button("Cancel") { dismiss() } }
        }.onAppear { verified = store.caffeineConfig.abeLabelConfirmed }
    }
}
struct CaffeineSettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var config = CaffeineSettings()
    @State private var bed = Date()
    @State private var message = ""
    var body: some View {
        NavigationView {
            Form {
                Section("Your model") {
                    HStack { Text("Half-life in hours"); Spacer(); TextField("Half-life", value: $config.halfLifeHours, format: .number).keyboardType(.decimalPad).frame(width: 75).multilineTextAlignment(.trailing) }
                    Text("5 hours is a starting population assumption. Changing it does not calibrate your actual metabolism. Smoking, pregnancy, liver disease, medication and genetics can change clearance significantly.").font(.caption).foregroundColor(Ink.muted)
                    DatePicker("Usual bedtime", selection: $bed, displayedComponents: .hourAndMinute)
                }
                Section("Your ABE tub") {
                    Picker("Serving size", selection: $config.abeServingGrams) { Text("Current 375 g tub · 12.5 g").tag(12.5); Text("Older 315 g tub · 10.5 g").tag(10.5) }
                    HStack { Text("Caffeine per serving (mg)"); Spacer(); TextField("Caffeine per serving", value: $config.abeCaffeine, format: .number).keyboardType(.decimalPad).frame(width: 75).multilineTextAlignment(.trailing) }
                    Toggle("I checked these values against my label", isOn: $config.abeLabelConfirmed)
                    Text("Changing the preset affects future entries only. Historical doses retain the milligrams logged at the time.").font(.caption).foregroundColor(Ink.muted)
                }
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Button("Save caffeine settings") {
                    guard config.halfLifeHours.isFinite, (2...12).contains(config.halfLifeHours), config.abeCaffeine.isFinite, (1...500).contains(config.abeCaffeine) else { message = "Use a half-life from 2–12 hours and a valid labeled caffeine amount."; return }
                    let components = Calendar.current.dateComponents([.hour, .minute], from: bed)
                    config.bedtimeHour = components.hour ?? 23; config.bedtimeMinute = components.minute ?? 0
                    store.data.caffeineSettings = config; store.save(); dismiss()
                }
            }.navigationTitle("Caffeine settings").navigationBarTitleDisplayMode(.inline).toolbar { Button("Cancel") { dismiss() } }
        }.onAppear { config = store.caffeineConfig; bed = Calendar.current.date(bySettingHour: config.bedtimeHour, minute: config.bedtimeMinute, second: 0, of: Date()) ?? Date() }
    }
}
struct CaffeineMethod: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                Section("Formula") {
                    Text("Remaining caffeine = Σ dose × 2^(−elapsed hours / half-life hours). Each dose keeps its own timestamp. Doses in the future are excluded. Last-24-hour intake is separate from remaining caffeine.")
                    Text("The model assumes caffeine is available from ingestion and ignores the absorption phase. It may overstate immediate systemic caffeine. It does not measure blood concentration, caffeine sensitivity, sleep quality or other pre-workout ingredients.")
                }
                Section("Uncertainty") {
                    Text("Half-life varies substantially between people. The adjustable value is an assumption. The 3–7 hour shaded band illustrates sensitivity only; it is not the full biological range or a validated confidence interval.")
                    Text("The FDA’s 400 mg/day reference applies to most healthy adults and is not a universal safe limit or permission to add another dose. Pregnancy, age, medication and medical conditions need individual advice.")
                }
                Section("Sources") {
                    Link("ABE manufacturer · 375 g formulation", destination: URL(string: "https://appliednutrition.uk/products/abe-all-black-everything-375g")!)
                    Link("ABE manufacturer · older 315 g formulation", destination: URL(string: "https://connect.appliednutrition.uk/product/abe-all-black-everything-pre-workout-copy/")!)
                    Link("FDA · caffeine guidance", destination: URL(string: "https://www.fda.gov/consumers/consumer-updates/spilling-beans-how-much-caffeine-too-much")!)
                    Link("Oral caffeine pharmacokinetics · primary study", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/6832208/")!)
                    Link("National Academies · caffeine pharmacology", destination: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK223808/")!)
                }
            }.navigationTitle("Caffeine model").toolbar { Button("Done") { dismiss() } }
        }
    }
}
