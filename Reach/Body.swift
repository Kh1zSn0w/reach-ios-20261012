import SwiftUI

struct BodyView: View {
    @EnvironmentObject var store: Store
    @State private var food = false
    @State private var weigh = false
    @State private var cut = false
    @State private var edit = false
    @State private var review = false
    @State private var history = false
    @State private var activity = false
    var body: some View {
        Page(eyebrow: "", title: "Body", subtitle: "Nutrition, measurements and activity") {
            HStack(spacing: 16) {
                Metric(label: "Calories logged", value: "\(Int(store.calories))", unit: store.data.profile.energyAvailable ? "/ ~\(Int(store.data.profile.target)) kcal" : "kcal today")
                Metric(label: "Protein", value: "\(Int(store.protein))", unit: "g today")
                Metric(label: "Last weight", value: store.data.profile.configured || !store.data.weights.isEmpty ? String(format: "%.1f", store.data.profile.weight) : "—", unit: "kg")
            }.padding(.vertical, 8)
            if store.data.profile.energyAvailable { ProgressView(value: min(store.calories / max(store.data.profile.target, 1), 1)).tint(Ink.blue) }
            HStack { Action(title: "Log food", symbol: "plus") { food = true }; Action(title: "Weigh in", symbol: "plus") { weigh = true } }
            Button("Review daily intake & mark complete") { history = true }.font(.system(size: 13))
            WeightTrend(weights: store.data.weights)
            DailyIntakeChart(meals: store.data.meals, complete: store.data.completedIntakeDays ?? [], target: store.data.profile.energyAvailable ? store.data.profile.target : nil)
            VStack(spacing: 0) {
                NavigationRow(title: "Home + gym activity", detail: store.activityDescription, symbol: "figure.strengthtraining.traditional") { activity = true }
                Divider().overlay(Ink.line)
                Button { cut = true } label: {
                    HStack(spacing: 12) {
                        InkIcon(name: "skull", size: 34)
                        VStack(alignment: .leading, spacing: 4) { Text("Cut Mode").font(.system(size: 15, weight: .medium)); Text("Screening, deficit and daily target").font(.system(size: 12)).foregroundColor(Ink.muted) }
                        Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(Ink.muted)
                    }.padding(.vertical, 12)
                }.buttonStyle(.plain).accessibilityLabel("Open Cut Mode questionnaire")
            }
            energyBreakdown
            if !store.todayMeals.isEmpty {
                SectionHeading(title: "Today’s food")
                ForEach(store.todayMeals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) { Text(meal.name).font(.system(size: 14, weight: .medium)); Text("\(Int(meal.grams)) g · \(Int(meal.protein)) g protein").font(.system(size: 11)).foregroundColor(Ink.muted) }
                        Spacer(); Text("\(Int(meal.calories)) kcal").font(.system(size: 14)).monospacedDigit()
                        Button { store.data.meals.removeAll { $0.id == meal.id }; store.data.completedIntakeDays?.removeAll { Calendar.current.isDate($0, inSameDayAs: meal.date) }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete \(meal.name)")
                    }.padding(.vertical, 9)
                }
            }
            if !store.data.weights.isEmpty {
                SectionHeading(title: "Recent weigh-ins")
                ForEach(Array(store.data.weights.suffix(7).reversed())) { entry in
                    HStack { Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 12)).foregroundColor(Ink.muted); Spacer(); Text(String(format: "%.1f kg", entry.kg)).font(.system(size: 14)).monospacedDigit(); Button { store.data.weights.removeAll { $0.id == entry.id }; if let last = store.data.weights.last { store.data.profile.weight = last.kg }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete weigh-in") }
                }
            }
            Button("Edit profile & measurements") { edit = true }.font(.system(size: 13))
        }.sheet(isPresented: $food) { FoodView() }.sheet(isPresented: $weigh) { WeightView() }.sheet(isPresented: $cut) { CutView() }.sheet(isPresented: $edit) { ProfileView() }.sheet(isPresented: $history) { FoodHistoryView() }.sheet(isPresented: $activity) { ActivityView() }
            .alert("Use the observed maintenance estimate?", isPresented: $review) {
                Button("Cancel", role: .cancel) {}
                Button("Use observed estimate") {
                    guard let observed = store.observedTDEE, store.data.profile.energyAvailable else { return }
                    store.data.profile.maintenanceOverride = observed; store.data.profile.maintenanceUpdated = Date(); store.save()
                }
            } message: { Text("Only use this if all intake was logged and weighing conditions were consistent. It is a simplified energy-balance estimate, affected by water and glycogen. It expires after 28 days; gym calories are not added again.") }
    }
    var energyBreakdown: some View {
        Card {
            SectionHeading(title: "Energy estimate")
            if store.data.profile.energyAvailable {
                LabeledValue(label: "Resting · Mifflin–St Jeor", value: "~\(Int(store.data.profile.bmr)) kcal/day")
                LabeledValue(label: "Maintenance", value: "~\(Int(store.data.profile.tdee)) kcal/day")
                if let plan = store.data.profile.activityPlan, plan.confirmed {
                    LabeledValue(label: "Net gym average · included once", value: "~\(Int(plan.dailyExercise(weight: store.data.profile.weight))) kcal/day")
                } else { Text("Your old activity factor remains active. Confirm the home + gym plan to replace the broad activity categories.").font(.system(size: 12)).foregroundColor(Ink.muted) }
                if let observed = store.observedTDEE {
                    LabeledValue(label: "14-day observed estimate", value: "~\(Int(observed)) kcal/day")
                    Button("Review & use observed estimate") { review = true }.font(.system(size: 13))
                } else {
                    Text("Calibration needs 14 completed intake days and at least 4 distinct weigh-in days each week. A few food entries do not count as complete days.").font(.system(size: 12)).foregroundColor(Ink.muted)
                }
                if let date = store.data.profile.maintenanceUpdated, store.data.profile.tdee != store.data.profile.equationTDEE {
                    Text("Using observed estimate from \(date.formatted(date: .abbreviated, time: .omitted)). Valid for 28 days.").font(.system(size: 11)).foregroundColor(Ink.muted)
                    Button("Return to activity-based estimate") { store.data.profile.maintenanceOverride = nil; store.data.profile.maintenanceUpdated = nil; store.save() }.font(.system(size: 12))
                }
            } else { Text("Complete an adult profile to calculate energy targets. The adult equation is not a calorie prescription for minors or pregnancy.").font(.system(size: 13)).foregroundColor(Ink.muted) }
            Text("These formulas estimate energy needs. Intake labels, logging errors and water-weight changes limit accuracy; the app cannot measure metabolism.").font(.system(size: 11)).foregroundColor(Ink.muted)
        }
    }
}
struct FoodView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var grams = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var date = Date()
    @State private var message = ""
    @State private var lookup = false
    var body: some View {
        NavigationView {
            Form {
                Section("Use the package label or your food database") {
                    Button("Find a packaged food or scan barcode") { lookup = true }
                    TextField("Food name", text: $name)
                    field("Portion weight (g)", text: $grams)
                    field("Calories per 100 g", text: $calories)
                    field("Protein per 100 g (optional)", text: $protein)
                    DatePicker("Date eaten", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    Text("For accuracy: weigh edible portions, match raw vs cooked entries, and include oils, drinks and sauces. Nutrition labels are still estimates.").font(.caption).foregroundColor(Ink.muted)
                }
                if let g = Double(grams), let c = Double(calories), g.isFinite, c.isFinite, g > 0, c >= 0 { Section("This portion") { Text("\(Int(min(g * c / 100, 100000))) kcal").font(.title2) } }
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Button("Add to food log") {
                    guard let g = Double(grams), let c = Double(calories), g.isFinite, c.isFinite, (0.1...5000).contains(g), (0...1000).contains(c), !name.trimmingCharacters(in: .whitespaces).isEmpty else { message = "Add a food name, valid portion weight and calories per 100 g."; return }
                    let p = protein.isEmpty ? 0 : Double(protein)
                    guard let p, p.isFinite, (0...100).contains(p) else { message = "Protein should be between 0 and 100 g per 100 g."; return }
                    store.data.meals.append(Meal(date: date, name: String(name.prefix(120)), grams: g, kcalPer100: c, proteinPer100: p)); store.save(); dismiss()
                }
            }.navigationTitle("Log food").toolbar { Button("Cancel") { dismiss() } }
        }.sheet(isPresented: $lookup) { ProductLookup { product in
            name = product.product_name ?? "Packaged food"
            calories = product.nutriments?.kcal.map { String($0) } ?? ""
            protein = product.nutriments?.protein.map { String($0) } ?? ""
        } }
    }
    func field(_ title: String, text: Binding<String>) -> some View { TextField(title, text: text).keyboardType(.decimalPad).accessibilityLabel(title) }
}
struct WeightView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var value = ""
    @State private var date = Date()
    @State private var message = ""
    var body: some View {
        NavigationView {
            Form {
                Text("Weigh at a consistent time, ideally after the bathroom and before breakfast. Water fluctuations are normal.").foregroundColor(Ink.muted)
                TextField("Weight in kg", text: $value).keyboardType(.decimalPad).accessibilityLabel("Weight in kg")
                DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Button("Save weigh-in") {
                    guard let kg = Double(value), kg.isFinite, (30...350).contains(kg) else { message = "Enter a valid weight from 30–350 kg."; return }
                    store.data.weights.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    store.data.weights.append(WeighIn(date: date, kg: kg)); store.data.weights.sort { $0.date < $1.date }
                    if let last = store.data.weights.last { store.data.profile.weight = last.kg }; store.save(); dismiss()
                }
            }.navigationTitle("Weigh in").toolbar { Button("Cancel") { dismiss() } }
        }.onAppear { value = String(format: "%.1f", store.data.profile.weight) }
    }
}
struct CutView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var intensity = 0.15
    @State private var profile = false
    @State private var sleep = false
    @State private var training = false
    @State private var dizzy = false
    @State private var reviewed = false
    var plan: Profile { var p = store.data.profile; p.intensity = intensity; return p }
    var eligible: Bool { plan.cutEligible && !dizzy && sleep && training }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(spacing: 12) { InkIcon(name: "skull", size: 38); Text("Cut plan").font(.system(size: 22, weight: .semibold)); Spacer() }
                    Text("Review your measurements, health screening and recovery before choosing a deficit.").font(.system(size: 14)).foregroundColor(Ink.muted)
                    Action(title: "Review body & health questions") { profile = true }
                    Toggle("I can protect adequate sleep", isOn: $sleep)
                    Toggle("I can maintain strength training & regular meals", isOn: $training)
                    Toggle("I have dizziness, fainting or severe fatigue", isOn: $dizzy)
                    SectionHeading(title: "Daily deficit")
                    Picker("Deficit", selection: $intensity) {
                        Text("Steady 10%").tag(0.10); Text("Focused 15%").tag(0.15); Text("Intensive 20%").tag(0.20); Text("Aggressive 25%").tag(0.25)
                    }.pickerStyle(.menu)
                    Text("Aggressive is optional, not a requirement. This app caps the estimated deficit at 25% and uses conservative calorie floors. Those limits do not make a plan safe for every person.").font(.system(size: 13)).foregroundColor(Ink.muted)
                    Card {
                        if eligible {
                            Text("Estimated daily target").font(.system(size: 13)).foregroundColor(Ink.muted)
                            Text("~\(Int(plan.target)) kcal").font(.system(size: 36, weight: .medium, design: .rounded))
                            Text("Maintenance estimate: \(Int(plan.tdee)) kcal. Actual deficit: \(Int(plan.tdee - plan.target)) kcal/day. Rough pace: \(String(format: "%.2f", max(0, plan.tdee - plan.target) * 7 / 7700)) kg/week.").font(.system(size: 14)).foregroundColor(Ink.muted)
                            Text("The pace is a rough energy calculation, not a forecast. Reassess after two weeks using weekly means. Rapid loss, worsening performance or obsessive tracking are reasons to ease off and get help.").font(.caption).foregroundColor(Ink.muted)
                            Toggle("I reviewed my measurements and health answers", isOn: $reviewed)
                            Action(title: "Use this cut plan") { store.data.profile.intensity = intensity; store.save(); dismiss() }.disabled(!reviewed)
                        } else {
                            Text("Complete the screening").font(.system(size: 20, weight: .semibold))
                            Text(!plan.cutEligible ? "A calorie deficit is unavailable when your profile is incomplete, you’re under 18, your weight or goal is too low, or a health concern applies. Review your answers and work with a qualified clinician if needed." : dizzy ? "Do not intensify the cut with these symptoms. Pause and get medical advice; fainting or severe symptoms need urgent care." : "Protect sleep and regular meals, and confirm a realistic training plan before starting an intensive cut.").font(.system(size: 14)).foregroundColor(Ink.muted)
                        }
                    }
                    SectionHeading(title: "Weekly review")
                    Text("Weekly: review sleep, hunger, mood, strength and concentration. Persistent coldness, dizziness, menstrual changes, binge urges or compulsive weighing mean the plan needs reassessment.").font(.system(size: 14)).foregroundColor(Ink.muted)
                    Link("Read CDC guidance on gradual weight loss", destination: URL(string: "https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html")!).font(.caption)
                }.padding(24)
            }.background(CanvasBackground()).navigationTitle("Cut Mode").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { dismiss() } }
        }.onAppear { intensity = store.data.profile.intensity }.sheet(isPresented: $profile) { ProfileView() }
    }
}
