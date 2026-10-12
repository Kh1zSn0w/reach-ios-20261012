import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var plan = ActivityPlan()
    @State private var log = false
    @State private var message = ""
    var body: some View {
        NavigationView {
            Form {
                Section("Home most of the day + gym") {
                    Text("Your daily routine is mostly at home. Gym sessions are calculated separately, so training several times a week does not automatically make your whole day highly active.").font(.system(size: 14)).foregroundColor(Ink.muted)
                    Stepper("Gym sessions per week: \(plan.gymDays)", value: $plan.gymDays, in: 0...7)
                    HStack { Text("Average session minutes"); Spacer(); TextField("Minutes", value: $plan.sessionMinutes, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 85).accessibilityLabel("Average session minutes") }
                    Picker("Session type", selection: $plan.met) {
                        Text("Weights with rests · 3.5 MET").tag(3.5)
                        Text("Squats/deadlifts · 5 MET").tag(5.0)
                        Text("Vigorous lifting · 6 MET").tag(6.0)
                    }
                    Text("Include your normal rests in the session duration. MET values are population estimates, not a measurement of your energy expenditure.").font(.caption).foregroundColor(Ink.muted)
                    if !message.isEmpty { Text(message).foregroundColor(.orange) }
                    Button("Save home + gym plan") {
                        guard plan.sessionMinutes.isFinite, (0...240).contains(plan.sessionMinutes), plan.gymDays == 0 || plan.sessionMinutes > 0 else { message = "Enter the average duration of a gym session, up to 240 minutes."; return }
                        plan.confirmed = true; store.data.profile.activityPlan = plan
                        store.data.profile.maintenanceOverride = nil; store.data.profile.maintenanceUpdated = nil
                        store.save(); dismiss()
                    }.font(.system(size: 16, weight: .semibold))
                }
                Section("Calculation") {
                    LabeledValue(label: "Resting energy (Mifflin–St Jeor)", value: store.data.profile.energyAvailable ? "~\(Int(store.data.profile.bmr)) kcal" : "Adult profile required")
                    LabeledValue(label: "Mostly seated baseline", value: store.data.profile.energyAvailable ? "~\(Int(store.data.profile.bmr * 1.2)) kcal/day" : "—")
                    Text("Starting assumption: resting energy × 1.2. This is a conventional sedentary baseline, not your measured activity level. Use the weight/intake calibration when sufficient logs exist.").font(.caption).foregroundColor(Ink.muted)
                    Text("Net training energy = (MET − 1) × 3.5 × weight(kg) ÷ 200 × minutes. Weekly training energy ÷ 7 is added once to the seated baseline.").font(.system(size: 13)).foregroundColor(Ink.muted)
                    Text("The resting component is subtracted from exercise to reduce double counting. The same weekly average target applies to rest and gym days; logged workouts are not added again.").font(.caption).foregroundColor(Ink.muted)
                    Link("MET source · 2024 Adult Compendium", destination: URL(string: "https://pacompendium.com/conditioning-exercise/")!)
                }
                Section("Actual sessions") {
                    Button("Log a gym session") { log = true }
                    Text("\(store.weekWorkouts.count) sessions · \(Int(store.weekWorkouts.reduce(0) { $0 + $1.minutes })) minutes logged this week").font(.system(size: 14))
                    ForEach(Array((store.data.workouts ?? []).sorted { $0.date > $1.date }.prefix(10))) { workout in
                        HStack { VStack(alignment: .leading, spacing: 4) { Text(workout.kind); Text("\(workout.date.formatted(date: .abbreviated, time: .omitted)) · \(Int(workout.minutes)) min").font(.caption).foregroundColor(Ink.muted) }; Spacer(); Button { store.data.workouts?.removeAll { $0.id == workout.id }; store.save() } label: { Image(systemName: "minus.circle") }.accessibilityLabel("Delete workout") }
                    }
                }
            }.navigationTitle("Activity").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { dismiss() } }
        }.onAppear { plan = store.data.profile.activityPlan ?? ActivityPlan() }.sheet(isPresented: $log) { WorkoutLog() }
    }
}
struct LabeledValue: View {
    var label: String
    var value: String
    var body: some View { HStack(alignment: .top) { Text(label).font(.system(size: 13)).foregroundColor(Ink.muted); Spacer(); Text(value).font(.system(size: 14, weight: .medium)).monospacedDigit().multilineTextAlignment(.trailing) } }
}
struct WorkoutLog: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var minutes = ""
    @State private var met = 3.5
    @State private var date = Date()
    @State private var message = ""
    var kind: String { met == 6 ? "Vigorous lifting" : met == 5 ? "Squats / deadlifts" : "Weights with rests" }
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Session date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                TextField("Duration in minutes", text: $minutes).keyboardType(.decimalPad).accessibilityLabel("Duration in minutes")
                Picker("Type", selection: $met) { Text("Weights with rests").tag(3.5); Text("Squats/deadlifts").tag(5.0); Text("Vigorous lifting").tag(6.0) }
                Text("This records your training history. It does not add calories to your target again.").font(.caption).foregroundColor(Ink.muted)
                if !message.isEmpty { Text(message).foregroundColor(.orange) }
                Button("Save gym session") {
                    guard let value = Double(minutes.replacingOccurrences(of: ",", with: ".")), value.isFinite, (1...240).contains(value) else { message = "Enter a duration from 1 to 240 minutes."; return }
                    if store.data.workouts == nil { store.data.workouts = [] }
                    store.data.workouts?.append(Workout(date: date, minutes: value, met: met, kind: kind)); store.save(); dismiss()
                }
            }.navigationTitle("Log workout").toolbar { Button("Cancel") { dismiss() } }
        }
    }
}
