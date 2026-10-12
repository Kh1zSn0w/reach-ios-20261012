import SwiftUI

struct FoodHistoryView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var logFood = false
    var meals: [Meal] { store.data.meals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } }
    var body: some View {
        NavigationView {
            List {
                Section {
                    DatePicker("Review date", selection: $date, in: ...Date(), displayedComponents: .date)
                    Text("\(Int(meals.reduce(0) { $0 + $1.calories })) kcal · \(Int(meals.reduce(0) { $0 + $1.protein })) g protein").font(.title3)
                    Text("Mark complete only after logging everything you ate and drank, including oils and sauces. Calibration uses 14 consecutive completed days before today.").font(.caption).foregroundColor(Ink.muted)
                    Button {
                        store.toggleIntakeComplete(date)
                    } label: { Label(store.intakeComplete(date) ? "Intake confirmed complete" : "Mark this day’s intake complete", systemImage: store.intakeComplete(date) ? "checkmark.circle.fill" : "circle") }.disabled(meals.isEmpty)
                }
                Section("Food entries") {
                    if meals.isEmpty { Text("No food logged for this date.").foregroundColor(Ink.muted) }
                    ForEach(meals) { meal in
                        HStack {
                            VStack(alignment: .leading, spacing: 5) { Text(meal.name); Text("\(Int(meal.grams)) g · \(Int(meal.calories)) kcal").font(.caption).foregroundColor(Ink.muted) }
                            Spacer()
                            Button {
                                store.data.meals.removeAll { $0.id == meal.id }
                                store.data.completedIntakeDays?.removeAll { Calendar.current.isDate($0, inSameDayAs: meal.date) }
                                store.save()
                            } label: { Image(systemName: "minus.circle") }.accessibilityLabel("Delete \(meal.name)")
                        }
                    }
                    Button("Add an entry (choose its date in the form)") { logFood = true }
                }
            }.navigationTitle("Daily intake").toolbar { Button("Done") { dismiss() } }
        }.sheet(isPresented: $logFood) { FoodView() }
    }
}
