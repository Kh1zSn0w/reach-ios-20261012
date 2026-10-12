import SwiftUI

struct BodyView: View {
    @EnvironmentObject var store: Store
    @State private var food = false
    @State private var weigh = false
    @State private var cut = false
    @State private var edit = false
    @State private var review = false
    @State private var history = false
    var body: some View {
        Page(eyebrow: "01 / Body", title: "Built. Not wished.", subtitle: "Measure honestly. Adjust patiently.") {
            HStack { InkIcon(name: "skull", size: 92); Spacer(); VStack(alignment: .trailing) { Text("DAILY FUEL").font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(Ink.muted); Text("\(Int(store.calories))").font(.system(size: 52, weight: .medium, design: .rounded)); Text(store.data.profile.configured ? "of ~\(Int(store.data.profile.target)) kcal" : "Set your profile to see a target").font(.caption).foregroundColor(Ink.muted) } }
            ProgressView(value: min(store.calories / max(store.data.profile.target, 1), 1)).tint(Ink.blue)
            HStack {
                Metric(label: "Protein", value: "\(Int(store.protein))", unit: "g logged")
                Metric(label: "TDEE", value: store.data.profile.configured ? "\(Int(store.data.profile.tdee))" : "—", unit: "kcal · equation estimate")
                Metric(label: "Weight", value: String(format: "%.1f", store.data.profile.weight), unit: "kg · last entry")
            }.padding(.vertical, 14)
            HStack { Action(title: "Log food", symbol: "plus") { food = true }; Action(title: "Weigh in", symbol: "plus") { weigh = true } }
            Button("Review daily intake & mark complete") { history = true }.font(.system(size: 13)).foregroundColor(Ink.blue)
            Button { cut = true } label: {
                HStack(spacing: 18) {
                    InkIcon(name: "skull", size: 64)
                    VStack(alignment: .leading, spacing: 6) { Text("CUT MODE").font(.system(size: 22, weight: .heavy, design: .serif)); Text("A serious deficit. A deliberate plan.").font(.system(size: 13)).foregroundColor(Ink.muted) }
                    Spacer(); Image(systemName: "arrow.up.right")
                }.padding(.vertical, 22).overlay(alignment: .top) { Rectangle().fill(Ink.muted.opacity(0.25)).frame(height: 1) }.overlay(alignment: .bottom) { Rectangle().fill(Ink.muted.opacity(0.25)).frame(height: 1) }
            }.buttonStyle(.plain).accessibilityLabel("Open Cut Mode questionnaire")
            Card {
                Text("CALIBRATE, DON’T GUESS").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(Ink.blue)
                if let observed = store.observedTDEE {
                    Text("~\(Int(observed)) kcal").font(.system(size: 29, weight: .medium))
                    Text("Observed estimate from 14 completed days of intake logs and two weekly weight means. Water shifts and incomplete logs can distort this.").font(.system(size: 13)).foregroundColor(Ink.muted)
                    Button("Review weekly calibration") { review = true }
                } else {
                    Text("Your body supplies the feedback.").font(.system(size: 22, weight: .medium, design: .serif))
                    Text("Log all food for 14 complete days and at least 4 weigh-ins each week. We’ll compare two weekly means to estimate your actual maintenance. Missing food makes this unreliable.").font(.system(size: 13)).foregroundColor(Ink.muted)
                }
            }
            if !store.todayMeals.isEmpty {
                Text("TODAY’S LOG").font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(Ink.muted)
                ForEach(store.todayMeals) { meal in
                    HStack { VStack(alignment: .leading, spacing: 5) { Text(meal.name).font(.system(size: 16)); Text("\(Int(meal.grams)) g · \(Int(meal.protein)) g protein").font(.caption).foregroundColor(Ink.muted) }; Spacer(); Text("\(Int(meal.calories))").font(.system(size: 19, design: .rounded)); Button { store.data.meals.removeAll { $0.id == meal.id }; store.data.completedIntakeDays?.removeAll { Calendar.current.isDate($0, inSameDayAs: meal.date) }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete \(meal.name)") }.padding(.vertical, 8)
                }
            }
            if !store.data.weights.isEmpty {
                WeightChart(weights: Array(store.data.weights.suffix(30)))
                ForEach(Array(store.data.weights.suffix(7).reversed())) { entry in
                    HStack { Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundColor(Ink.muted); Spacer(); Text(String(format: "%.1f kg", entry.kg)); Button { store.data.weights.removeAll { $0.id == entry.id }; if let last = store.data.weights.last { store.data.profile.weight = last.kg }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete weigh-in") }
                }
            }
            Button("Edit profile & activity") { edit = true }.font(.caption)
        }.sheet(isPresented: $food) { FoodView() }.sheet(isPresented: $weigh) { WeightView() }.sheet(isPresented: $cut) { CutView() }.sheet(isPresented: $edit) { ProfileView() }.sheet(isPresented: $history) { FoodHistoryView() }
            .alert("Calibration review", isPresented: $review) {
                Button("Keep current plan", role: .cancel) {}
            } message: { Text("Compare your observed estimate to the equation and review logging accuracy first. Update activity in your profile if the difference persists for several weeks. The app does not silently change your calorie target.") }
    }
}
struct WeightChart: View {
    var weights: [WeighIn]
    var body: some View {
        Card {
            Text("WEIGHT / RECENT TREND").font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(Ink.muted)
            GeometryReader { geo in
                let low = (weights.map(\.kg).min() ?? 0) - 0.5
                let high = (weights.map(\.kg).max() ?? 1) + 0.5
                Path { path in
                    for (i, entry) in weights.enumerated() {
                        let x = CGFloat(i) / CGFloat(max(weights.count - 1, 1)) * geo.size.width
                        let y = geo.size.height * (1 - CGFloat((entry.kg - low) / (high - low)))
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }.stroke(Ink.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }.frame(height: 85)
            Text("\(weights.count) entries · follow the weekly mean, not one day").font(.caption).foregroundColor(Ink.muted)
        }.accessibilityLabel("Recent weight trend, \(weights.count) entries")
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
                    HStack { InkIcon(name: "skull", size: 105); Spacer(); Text("CUT\nWITH\nCONTROL.").font(.system(size: 32, weight: .black, design: .serif)) }
                    Text("You don’t need the harshest deficit. You need the smallest one that produces a sustainable trend.").foregroundColor(Ink.muted)
                    Action(title: "Review body & health questions") { profile = true }
                    Toggle("I can protect adequate sleep", isOn: $sleep)
                    Toggle("I can maintain strength training & regular meals", isOn: $training)
                    Toggle("I have dizziness, fainting or severe fatigue", isOn: $dizzy)
                    Text("How hard do you want to push?").font(.system(size: 23, weight: .medium, design: .serif))
                    Picker("Deficit", selection: $intensity) {
                        Text("Steady 10%").tag(0.10); Text("Focused 15%").tag(0.15); Text("Intensive 20%").tag(0.20); Text("Aggressive 25%").tag(0.25)
                    }.pickerStyle(.menu)
                    Text("Aggressive is optional, not a requirement. This app caps the estimated deficit at 25% and uses conservative calorie floors. Those limits do not make a plan safe for every person.").font(.system(size: 13)).foregroundColor(Ink.muted)
                    Card {
                        if eligible {
                            Text("ESTIMATED DAILY TARGET").font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(Ink.blue)
                            Text("~\(Int(plan.target)) kcal").font(.system(size: 36, weight: .medium, design: .rounded))
                            Text("Maintenance estimate: \(Int(plan.tdee)) kcal. Actual deficit: \(Int(plan.tdee - plan.target)) kcal/day. Rough pace: \(String(format: "%.2f", max(0, plan.tdee - plan.target) * 7 / 7700)) kg/week.").font(.system(size: 14)).foregroundColor(Ink.muted)
                            Text("The pace is a rough energy calculation, not a forecast. Reassess after two weeks using weekly means. Rapid loss, worsening performance or obsessive tracking are reasons to ease off and get help.").font(.caption).foregroundColor(Ink.muted)
                            Toggle("I reviewed my measurements and health answers", isOn: $reviewed)
                            Action(title: "Use this cut plan") { store.data.profile.intensity = intensity; store.save(); dismiss() }.disabled(!reviewed)
                        } else {
                            Text("Finish the screening first.").font(.system(size: 23, weight: .medium, design: .serif))
                            Text(!plan.cutEligible ? "A calorie deficit is unavailable when your profile is incomplete, you’re under 18, your weight or goal is too low, or a health concern applies. Review your answers and work with a qualified clinician if needed." : dizzy ? "Do not intensify the cut with these symptoms. Pause and get medical advice; fainting or severe symptoms need urgent care." : "Protect sleep and regular meals, and confirm a realistic training plan before starting an intensive cut.").font(.system(size: 14)).foregroundColor(Ink.muted)
                        }
                    }
                    Text("CHECK THE COST, NOT JUST THE SCALE").font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(Ink.blue)
                    Text("Weekly: review sleep, hunger, mood, strength and concentration. Persistent coldness, dizziness, menstrual changes, binge urges or compulsive weighing mean the plan needs reassessment.").font(.system(size: 14)).foregroundColor(Ink.muted)
                    Link("Read CDC guidance on gradual weight loss", destination: URL(string: "https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html")!).font(.caption)
                }.padding(24)
            }.background(CanvasBackground()).navigationTitle("Cut Mode").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { dismiss() } }
        }.onAppear { intensity = store.data.profile.intensity }.sheet(isPresented: $profile) { ProfileView() }
    }
}
