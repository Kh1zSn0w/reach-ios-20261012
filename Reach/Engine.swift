import Foundation

struct Profile: Codable {
    var name = ""
    var age = 25
    var height = 175.0
    var weight = 80.0
    var goal = 75.0
    var sex = "Male"
    var activity = 1.375
    var intensity = 0.15
    var medicalRisk = false
    var eatingRisk = false
    var pregnant = false
    var configured = false
    var activityPlan: ActivityPlan?
    var maintenanceOverride: Double?
    var maintenanceUpdated: Date?
    var bmi: Double { weight / pow(height / 100, 2) }
    var bmr: Double { 10 * weight + 6.25 * height - 5 * Double(age) + (sex == "Male" ? 5 : -161) }
    var equationTDEE: Double {
        if let plan = activityPlan { return bmr * 1.2 + plan.dailyExercise(weight: weight) }
        return bmr * activity
    }
    var tdee: Double {
        if let value = maintenanceOverride, let updated = maintenanceUpdated,
           Date().timeIntervalSince(updated) >= 0, Date().timeIntervalSince(updated) < 28 * 86400,
           value.isFinite, (1200...5000).contains(value) { return value }
        return equationTDEE
    }
    var energyAvailable: Bool { configured && age >= 18 && !pregnant }
    var cutEligible: Bool { configured && age >= 18 && bmi >= 20 && goal / pow(height / 100, 2) >= 18.5 && goal < weight && !medicalRisk && !eatingRisk && !pregnant }
    var floor: Double { sex == "Male" ? 1500 : 1200 }
    var target: Double { cutEligible ? max(floor, tdee * (1 - min(intensity, 0.25))) : tdee }
}

struct Meal: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var name: String
    var grams: Double
    var kcalPer100: Double
    var proteinPer100: Double
    var calories: Double { grams * kcalPer100 / 100 }
    var protein: Double { grams * proteinPer100 / 100 }
}
struct WeighIn: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var kg: Double
}
struct CheckIn: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var trigger: String
    var action: String
    var lapse: Bool
    var urge: Int
}
struct FocusSession: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var minutes: Int
}
struct Snapshot: Codable {
    var profile = Profile()
    var meals: [Meal] = []
    var weights: [WeighIn] = []
    var checkIns: [CheckIn] = []
    var focus: [FocusSession] = []
    var habits: [String: [String]] = [:]
    var favoriteQuotes: [String] = []
    var start = Date()
    var completedIntakeDays: [Date]? = []
    var caffeine: [CaffeineDose]?
    var caffeineSettings: CaffeineSettings?
    var workouts: [Workout]?
    var extendedFieldsValid: Bool {
        if let plan = profile.activityPlan {
            guard (0...7).contains(plan.gymDays), plan.sessionMinutes.isFinite, (0...240).contains(plan.sessionMinutes), [3.5, 5.0, 6.0].contains(plan.met),
                  !plan.confirmed || plan.gymDays == 0 || plan.sessionMinutes > 0 else { return false }
        }
        if let value = profile.maintenanceOverride { guard value.isFinite, (1200...5000).contains(value) else { return false } }
        if let config = caffeineSettings {
            guard config.halfLifeHours.isFinite, (2...12).contains(config.halfLifeHours), (0...23).contains(config.bedtimeHour), (0...59).contains(config.bedtimeMinute),
                  config.abeCaffeine.isFinite, (1...500).contains(config.abeCaffeine), [10.5, 12.5].contains(config.abeServingGrams) else { return false }
        }
        guard (caffeine ?? []).allSatisfy({ $0.mg.isFinite && (0.1...2000).contains($0.mg) }),
              (workouts ?? []).allSatisfy({ $0.minutes.isFinite && (1...240).contains($0.minutes) && [3.5, 5.0, 6.0].contains($0.met) }) else { return false }
        return true
    }
}

struct ActivityPlan: Codable {
    var gymDays = 0
    var sessionMinutes = 0.0
    var met = 3.5
    var confirmed = false
    func dailyExercise(weight: Double) -> Double {
        guard confirmed else { return 0 }
        return Fitness.netExerciseCalories(weight: weight, minutes: sessionMinutes, met: met) * Double(gymDays) / 7
    }
}
struct Workout: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var minutes: Double
    var met: Double
    var kind: String
}
struct CaffeineDose: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var name: String
    var mg: Double
}
struct CaffeineSettings: Codable {
    var halfLifeHours = 5.0
    var bedtimeHour = 23
    var bedtimeMinute = 0
    var abeCaffeine = 200.0
    var abeServingGrams = 12.5
    var abeLabelConfirmed = false
}
enum Caffeine {
    // First-order elimination, assuming the logged dose is available at ingestion.
    // This is a load estimate, not measured blood concentration or an absorption model.
    static func remaining(_ doses: [CaffeineDose], at date: Date, halfLife: Double) -> Double {
        guard halfLife.isFinite, halfLife > 0 else { return 0 }
        return doses.filter { $0.date <= date }.reduce(0) { total, dose in
            guard dose.mg.isFinite, dose.mg >= 0 else { return total }
            return total + dose.mg * pow(0.5, date.timeIntervalSince(dose.date) / (3600 * halfLife))
        }
    }
    static func intake(_ doses: [CaffeineDose], at date: Date) -> Double {
        doses.filter { $0.date <= date && $0.date > date.addingTimeInterval(-86400) }.reduce(0) { $0 + $1.mg }
    }
    static func nextBedtime(settings: CaffeineSettings, after date: Date) -> Date {
        Calendar.current.nextDate(after: date, matching: DateComponents(hour: settings.bedtimeHour, minute: settings.bedtimeMinute), matchingPolicy: .nextTime) ?? date.addingTimeInterval(86400)
    }
    static func below(_ threshold: Double, doses: [CaffeineDose], after date: Date, halfLife: Double) -> Date? {
        guard threshold > 0, halfLife > 0 else { return nil }
        let current = remaining(doses, at: date, halfLife: halfLife)
        if current <= threshold { return date }
        return date.addingTimeInterval(halfLife * 3600 * log2(current / threshold))
    }
}

enum Fitness {
    static func netExerciseCalories(weight: Double, minutes: Double, met: Double) -> Double {
        guard weight.isFinite, minutes.isFinite, met.isFinite, weight > 0, minutes >= 0 else { return 0 }
        return max(0, met - 1) * 3.5 * weight / 200 * minutes
    }
    static func mean(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
    // Require complete intake days and two weeks of weigh-ins before offering calibration.
    static func calibratedTDEE(meals: [Meal], weights: [WeighIn], completeDays: [Date] = [], now: Date = Date()) -> Double? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let start = cal.date(byAdding: .day, value: -14, to: today),
              let middle = cal.date(byAdding: .day, value: -7, to: today) else { return nil }
        let food = meals.filter { $0.date >= start && $0.date < today }
        let days = Set(food.map { cal.startOfDay(for: $0.date) })
        let confirmed = Set(completeDays.filter { $0 >= start && $0 < today }.map { cal.startOfDay(for: $0) })
        guard days.count == 14, confirmed.count == 14 else { return nil }
        let first = weights.filter { $0.date >= start && $0.date < middle }.map(\.kg)
        let second = weights.filter { $0.date >= middle && $0.date < today }.map(\.kg)
        let firstDays = Set(weights.filter { $0.date >= start && $0.date < middle }.map { cal.startOfDay(for: $0.date) })
        let secondDays = Set(weights.filter { $0.date >= middle && $0.date < today }.map { cal.startOfDay(for: $0.date) })
        guard firstDays.count >= 4, secondDays.count >= 4, let a = mean(first), let b = mean(second) else { return nil }
        let estimate = food.reduce(0) { $0 + $1.calories } / 14 - (b - a) * 7700 / 7
        guard estimate.isFinite, estimate >= 1200, estimate <= 5000 else { return nil }
        return estimate
    }
}

struct Quote: Identifiable {
    var id: String
    var words: String
    var arabic: String = ""
    var source: String
    var url: String = ""
    var category: String
}
let quotes: [Quote] = [
    Quote(id: "q945", words: "So, surely with hardship comes ease.", arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", source: "Qur’an 94:5 · English meaning", url: "https://quran.com/94/5", category: "Faith"),
    Quote(id: "q5339", words: "A person will only have what they strive for.", arabic: "وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ", source: "Qur’an 53:39 · English meaning", url: "https://quran.com/53/39", category: "Faith"),
    Quote(id: "q1311", words: "Allah does not change a people’s condition until they change what is in themselves.", arabic: "إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّىٰ يُغَيِّرُوا مَا بِأَنفُسِهِمْ", source: "Qur’an 13:11 · excerpt, English meaning", url: "https://quran.com/13/11", category: "Faith"),
    Quote(id: "epictetus", words: "First say to yourself what you would be; and then do what you have to do.", source: "Epictetus · Discourses, Book III, chapter 23", url: "https://www.gutenberg.org/ebooks/10661", category: "Stoic"),
    Quote(id: "sun7", words: "Ponder and deliberate before you make a move.", source: "Sun Tzu · The Art of War, VII.21 · Lionel Giles translation", url: "https://www.gutenberg.org/files/132/132-h/132-h.htm", category: "Warrior"),
    Quote(id: "sun11", words: "On desperate ground, fight.", source: "Sun Tzu · The Art of War, XI.14 · Lionel Giles translation", url: "https://www.gutenberg.org/files/132/132-h/132-h.htm", category: "Warrior"),
    Quote(id: "power29", words: "Plan all the way to the end.", source: "Robert Greene · The 48 Laws of Power, Law 29", category: "Power"),
    Quote(id: "power9", words: "Win through your actions, never through argument.", source: "Robert Greene · The 48 Laws of Power, Law 9", category: "Power"),
    Quote(id: "reach1", words: "The version of you that you respect is built when nobody is watching.", source: "REACH · original", category: "Resolve"),
    Quote(id: "reach2", words: "You don’t need to feel ready. You need to keep the promise you made when you were.", source: "REACH · original", category: "Resolve"),
    Quote(id: "reach3", words: "An urge can shout. It still cannot move your hands without your permission.", source: "REACH · original", category: "Resolve"),
    Quote(id: "reach4", words: "Your next ten minutes are still yours. Take them back.", source: "REACH · original", category: "Resolve"),
    Quote(id: "reach5", words: "Stop rehearsing a different life. Do one difficult thing in this one.", source: "REACH · original", category: "Resolve"),
    Quote(id: "reach6", words: "A setback is a page. Don’t turn it into your identity.", source: "REACH · original", category: "Resolve")
]
