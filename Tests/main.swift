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
let epoch = Date(timeIntervalSince1970: 1_600_000_000)
let dose = CaffeineDose(date: epoch, name: "Label verified", mg: 200)
check(Caffeine.remaining([dose], at: epoch, halfLife: 5) == 200, "Caffeine dose at ingestion")
check(abs(Caffeine.remaining([dose], at: epoch.addingTimeInterval(5 * 3600), halfLife: 5) - 100) < 0.001, "Caffeine halves after one half-life")
check(abs(Caffeine.remaining([dose], at: epoch.addingTimeInterval(10 * 3600), halfLife: 5) - 50) < 0.001, "Caffeine quarter after two half-lives")
let secondDose = CaffeineDose(date: epoch.addingTimeInterval(5 * 3600), name: "Second dose", mg: 100)
check(abs(Caffeine.remaining([dose, secondDose], at: epoch.addingTimeInterval(10 * 3600), halfLife: 5) - 100) < 0.001, "Multiple doses superpose by their own timestamps")
check(Caffeine.remaining([dose], at: epoch.addingTimeInterval(-1), halfLife: 5) == 0, "Future doses excluded")
check(Caffeine.intake([dose], at: epoch.addingTimeInterval(86400)) == 0, "Rolling 24-hour boundary")
check(Caffeine.remaining([dose], at: epoch, halfLife: 0) == 0, "Invalid half-life rejected")
check(abs(Caffeine.below(50, doses: [dose], after: epoch, halfLife: 5)!.timeIntervalSince(epoch) - 10 * 3600) < 0.01, "Threshold projection solves exponential decay")
check(abs(Fitness.netExerciseCalories(weight: 100, minutes: 60, met: 3.5) - 262.5) < 0.001, "Net MET calories subtract resting energy")
check(Fitness.netExerciseCalories(weight: 100, minutes: 60, met: 1) == 0, "Resting MET does not add exercise calories")
var active = Profile(); active.configured = true; active.activityPlan = ActivityPlan(gymDays: 4, sessionMinutes: 60, met: 3.5, confirmed: true)
let addition = Fitness.netExerciseCalories(weight: active.weight, minutes: 60, met: 3.5) * 4 / 7
check(abs(active.tdee - (active.bmr * 1.2 + addition)) < 0.001, "Home baseline plus weekly net training, no broad activity multiplier")
active.maintenanceOverride = 2500; active.maintenanceUpdated = Date()
check(active.tdee == 2500, "Observed maintenance replaces, rather than stacks with, exercise estimate")
active.maintenanceUpdated = Date().addingTimeInterval(-29 * 86400)
check(abs(active.tdee - active.equationTDEE) < 0.001, "Stale maintenance calibration expires")
var upgraded = Snapshot(); upgraded.caffeine = [dose]; upgraded.caffeineSettings = CaffeineSettings(); upgraded.workouts = [Workout(minutes: 60, met: 3.5, kind: "Weights")]
let upgradedRoundTrip = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(upgraded))
check(upgradedRoundTrip.caffeine?.first?.mg == 200 && upgradedRoundTrip.workouts?.first?.minutes == 60, "New journals survive backup round trip")
var oldObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as! [String: Any]
for key in ["caffeine", "caffeineSettings", "workouts"] { oldObject.removeValue(forKey: key) }
var oldProfile = oldObject["profile"] as! [String: Any]
for key in ["activityPlan", "maintenanceOverride", "maintenanceUpdated"] { oldProfile.removeValue(forKey: key) }; oldObject["profile"] = oldProfile
let migrated = try JSONDecoder().decode(Snapshot.self, from: JSONSerialization.data(withJSONObject: oldObject))
check(migrated.meals.first?.calories == 300 && migrated.checkIns.first?.trigger == "Stress" && migrated.caffeine == nil && migrated.profile.activityPlan == nil, "Version 1.0 journal migrates without losing profile, food or check-ins")
upgraded.caffeineSettings?.halfLifeHours = .nan; check(!upgraded.extendedFieldsValid, "Invalid imported caffeine settings rejected")
print("\(checks) checks passed; \(allQuotes.count) quotes")
