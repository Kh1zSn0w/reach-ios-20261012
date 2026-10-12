from pathlib import Path
root=Path(__file__).resolve().parents[1]
file=root/'Reach/Body.swift'
source=file.read_text(encoding='utf-8')
end=source.index('struct FoodView: View')
replacement=r'''import SwiftUI

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
'''
file.write_text(replacement+source[end:],encoding='utf-8')
print('Rebuilt Body screen around actual charts and transparent energy calculations')
