import SwiftUI

final class Store: ObservableObject {
    @Published var data = Snapshot()
    @Published var error: String?
    private let file: URL
    init() {
        file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("reach.json")
        if FileManager.default.fileExists(atPath: file.path) {
            do { data = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: file)) }
            catch { self.error = "Your saved journal could not be read. The original file has been kept. Please export a backup before making changes." }
        }
    }
    func save() {
        guard error == nil else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(data).write(to: file, options: [.atomic, .completeFileProtection])
        } catch { self.error = "Your changes could not be saved. Please keep the app open and export a backup." }
    }
    var todayMeals: [Meal] { data.meals.filter { Calendar.current.isDateInToday($0.date) } }
    var calories: Double { todayMeals.reduce(0) { $0 + $1.calories } }
    var protein: Double { todayMeals.reduce(0) { $0 + $1.protein } }
    var todayFocus: Int { data.focus.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.minutes } }
    var weekWeight: Double? {
        Fitness.mean(data.weights.filter { $0.date >= Date().addingTimeInterval(-7 * 86400) }.map(\.kg))
    }
    var observedTDEE: Double? { Fitness.calibratedTDEE(meals: data.meals, weights: data.weights) }
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
