import Foundation

var checks = 0
func check(_ condition: Bool, _ name: String) { precondition(condition, name); checks += 1; print("PASS: \(name)") }
var p = Profile(); p.configured = true
check(abs(p.bmr - 1773.75) < 0.01, "Mifflin–St Jeor male calculation")
check(abs(p.tdee - 2438.90625) < 0.01, "Activity factor applied once")
check(p.cutEligible, "Eligible adult screened profile")
p.age = 17; check(!p.cutEligible, "No automated deficit for minors"); p.age = 25
p.eatingRisk = true; check(!p.cutEligible, "Eating history disables cut"); p.eatingRisk = false
p.pregnant = true; check(!p.cutEligible, "Pregnancy disables cut"); p.pregnant = false
p.medicalRisk = true; check(!p.cutEligible, "Health concerns disable cut"); p.medicalRisk = false
p.goal = 45; check(!p.cutEligible, "Underweight goal disables cut"); p.goal = 75
p.intensity = 0.9; check(p.target >= p.tdee * 0.75 && p.target >= p.floor, "Deficit cap and calorie floor")
p.sex = "Female"; check(abs(p.bmr - 1607.75) < 0.01, "Female equation coefficient")
let food = Meal(name: "Example", grams: 150, kcalPer100: 200, proteinPer100: 20)
check(food.calories == 300 && food.protein == 30, "Weight-based calories and protein")
check(Fitness.calibratedTDEE(meals: [], weights: []) == nil, "Incomplete logs do not calibrate")
let calendar = Calendar.current; let today = calendar.startOfDay(for: Date())
var meals: [Meal] = []; var weights: [WeighIn] = []
for day in 1...14 {
    let date = calendar.date(byAdding: .day, value: -day, to: today)!
    meals.append(Meal(date: date, name: "Complete day", grams: 100, kcalPer100: 2200, proteinPer100: 100))
    weights.append(WeighIn(date: date, kg: 80))
}
check(Fitness.calibratedTDEE(meals: meals, weights: weights) == nil, "Unconfirmed intake days reject calibration")
let completeDays = meals.map(\.date)
check(abs(Fitness.calibratedTDEE(meals: meals, weights: weights, completeDays: completeDays)! - 2200) < 0.1, "Stable weight yields logged maintenance")
meals.removeLast(); check(Fitness.calibratedTDEE(meals: meals, weights: weights, completeDays: completeDays) == nil, "Missing intake day rejects calibration")
check(allQuotes.count >= 230, "Hundreds of quotes bundled")
check(Set(allQuotes.map(\.id)).count == allQuotes.count, "Unique quote identities")
check(Set(allQuotes.map(\.words)).count == allQuotes.count, "No duplicate quote text")
var snapshot = Snapshot(); snapshot.profile = p; snapshot.meals = [food]; snapshot.checkIns = [CheckIn(trigger: "Stress", action: "Walk", lapse: false, urge: 4)]
let roundTrip = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(snapshot))
check(roundTrip.meals[0].calories == 300 && roundTrip.checkIns[0].trigger == "Stress", "Private backup round trip")
print("\(checks) checks passed; \(allQuotes.count) quotes")
