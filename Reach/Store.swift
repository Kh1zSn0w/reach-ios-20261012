import SwiftUI

final class Store: ObservableObject {
    @Published var data = Snapshot()
    @Published var error: String?
    private var unreadable = false
    private var fixtureMode = false
    private let file: URL
    init() {
        file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("reach.json")
        if FileManager.default.fileExists(atPath: file.path) {
            do {
                let decoded = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: file))
                guard decoded.extendedFieldsValid else { throw CocoaError(.coderReadCorrupt) }
                data = decoded
            }
            catch { unreadable = true; self.error = "Your saved journal could not be read. The original file has been kept and writing is disabled. Restore a known REACH backup from Your profile & backup to recover." }
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-fixture") {
            fixtureMode = true; data = Snapshot()
            data.profile.configured = true; data.profile.height = 180; data.profile.weight = 98; data.profile.goal = 90
            data.profile.activityPlan = ActivityPlan(gymDays: 4, sessionMinutes: 60, met: 3.5, confirmed: true)
            let cal = Calendar.current
            for offset in (0..<14).reversed() {
                let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
                data.weights.append(WeighIn(date: day, kg: 98 + Double(offset) * 0.14))
                data.meals.append(Meal(date: day, name: "Sample daily intake", grams: 1000, kcalPer100: 220, proteinPer100: 15))
                data.completedIntakeDays?.append(day)
                if offset < 7 { data.focus.append(FocusSession(date: day, minutes: 10 + offset * 5)) }
            }
            data.caffeine = [CaffeineDose(date: Date().addingTimeInterval(-7 * 3600), name: "ABE Candy Ice Blast", mg: 200), CaffeineDose(date: Date().addingTimeInterval(-2 * 3600), name: "ABE Candy Ice Blast", mg: 100)]
            data.caffeineSettings = CaffeineSettings()
        }
        #endif
    }
    func save() {
        guard !fixtureMode else { return }
        guard !unreadable else { error = "Writing is disabled to preserve your unreadable journal. Restore a known backup in settings."; return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(data).write(to: file, options: [.atomic, .completeFileProtection])
        } catch { self.error = "Your changes could not be saved. Please keep the app open and export a backup." }
    }
    func restore(_ snapshot: Snapshot) {
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                let backup = file.deletingLastPathComponent().appendingPathComponent("reach-before-restore-\(UUID().uuidString).json")
                try FileManager.default.copyItem(at: file, to: backup)
            }
            data = snapshot; unreadable = false; error = nil; save()
        } catch { self.error = "Could not preserve the current journal. Restore was cancelled." }
    }
    var todayMeals: [Meal] { data.meals.filter { Calendar.current.isDateInToday($0.date) } }
    var calories: Double { todayMeals.reduce(0) { $0 + $1.calories } }
    var protein: Double { todayMeals.reduce(0) { $0 + $1.protein } }
    var doses: [CaffeineDose] { data.caffeine ?? [] }
    var caffeineConfig: CaffeineSettings { data.caffeineSettings ?? CaffeineSettings() }
    var weekWorkouts: [Workout] {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        return (data.workouts ?? []).filter { $0.date >= interval.start && $0.date < interval.end && $0.date <= Date() }
    }
    var activityDescription: String {
        guard let plan = data.profile.activityPlan, plan.confirmed else { return "Set your gym schedule and session duration" }
        return "\(plan.gymDays) sessions/week · \(Int(plan.sessionMinutes)) min/session"
    }
    var todayFocus: Int { data.focus.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.minutes } }
    var weekWeight: Double? {
        Fitness.mean(data.weights.filter { $0.date >= Date().addingTimeInterval(-7 * 86400) && $0.date <= Date() }.map(\.kg))
    }
    var observedTDEE: Double? { Fitness.calibratedTDEE(meals: data.meals, weights: data.weights, completeDays: data.completedIntakeDays ?? []) }
    func intakeComplete(_ date: Date) -> Bool { (data.completedIntakeDays ?? []).contains { Calendar.current.isDate($0, inSameDayAs: date) } }
    func toggleIntakeComplete(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if intakeComplete(day) { data.completedIntakeDays?.removeAll { Calendar.current.isDate($0, inSameDayAs: day) } }
        else { if data.completedIntakeDays == nil { data.completedIntakeDays = [] }; data.completedIntakeDays?.append(day) }
        save()
    }
    var dayKey: String { ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date())) }
    func done(_ habit: String) -> Bool { data.habits[dayKey, default: []].contains(habit) }
    func toggle(_ habit: String) {
        if done(habit) { data.habits[dayKey]?.removeAll { $0 == habit } }
        else { data.habits[dayKey, default: []].append(habit) }
        save()
    }
    func favorite(_ id: String) {
        if data.favoriteQuotes.contains(id) { data.favoriteQuotes.removeAll { $0 == id } }
        else { data.favoriteQuotes.append(id) }
        save()
    }
    func export() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("REACH-private-backup.json")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(data).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}
