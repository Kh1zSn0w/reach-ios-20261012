import SwiftUI

struct ChartPoint: Identifiable {
    var date: Date
    var value: Double
    var id: Date { date }
}
struct ChartMarker { var date: Date; var title: String }
struct LinePlot: View {
    var points: [ChartPoint]
    var secondary: [ChartPoint] = []
    var lower: [ChartPoint] = []
    var upper: [ChartPoint] = []
    var start: Date
    var end: Date
    var unit: String
    var color: Color = Ink.blue
    var zeroBased = false
    var timeLabels = false
    var markers: [ChartMarker] = []
    @State private var selected: ChartPoint?
    var low: Double { zeroBased ? 0 : ((points + secondary).map(\.value).min() ?? 0) - 0.5 }
    var high: Double { max(low + 1, max((points + secondary).map(\.value).max() ?? 1, upper.map(\.value).max() ?? 0) + (zeroBased ? 10 : 0.5)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectionLabel).font(.system(size: 12, weight: .medium)).monospacedDigit().foregroundColor(Ink.muted).frame(height: 16, alignment: .leading)
            HStack(spacing: 8) {
                VStack(alignment: .trailing) { Text(number(high)); Spacer(); Text(number((low + high) / 2)); Spacer(); Text(number(low)) }.font(.system(size: 10)).foregroundColor(Ink.muted).frame(width: 34).padding(.vertical, 2)
                GeometryReader { geometry in
                    Canvas { context, size in
                        for fraction in [0.0, 0.5, 1.0] {
                            var line = Path(); line.move(to: CGPoint(x: 0, y: size.height * fraction)); line.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                            context.stroke(line, with: .color(Ink.line), lineWidth: 1)
                        }
                        for marker in markers where marker.date >= start && marker.date <= end {
                            let x = position(ChartPoint(date: marker.date, value: low), size: size).x
                            var line = Path(); line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(line, with: .color(Ink.muted.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                            context.draw(Text(marker.title).font(.system(size: 10)).foregroundColor(Ink.muted), at: CGPoint(x: min(x + 3, size.width - 30), y: 2), anchor: .topLeading)
                        }
                        if !lower.isEmpty, lower.count == upper.count {
                            var band = Path()
                            for (i, point) in upper.enumerated() { let p = position(point, size: size); if i == 0 { band.move(to: p) } else { band.addLine(to: p) } }
                            for point in lower.reversed() { band.addLine(to: position(point, size: size)) }
                            band.closeSubpath(); context.fill(band, with: .color(color.opacity(0.10)))
                        }
                        if !secondary.isEmpty { context.stroke(path(secondary, size: size), with: .color(Ink.muted), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])) }
                        context.stroke(path(points, size: size), with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        if points.count <= 35 {
                            for point in points { let p = position(point, size: size); context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(color)) }
                        }
                        if let point = selected {
                            let p = position(point, size: size)
                            var line = Path(); line.move(to: CGPoint(x: p.x, y: 0)); line.addLine(to: CGPoint(x: p.x, y: size.height))
                            context.stroke(line, with: .color(Ink.muted), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(color))
                        }
                    }.contentShape(Rectangle()).simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { value in
                        guard abs(value.translation.height) <= abs(value.translation.width) + 8 else { return }
                        let fraction = min(1, max(0, value.location.x / max(geometry.size.width, 1)))
                        let date = start.addingTimeInterval(Double(fraction) * end.timeIntervalSince(start))
                        selected = points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
                    })
                }
            }.frame(height: 150)
            HStack { Text(label(start)); Spacer(); Text(label(end)) }.font(.system(size: 10)).foregroundColor(Ink.muted).padding(.leading, 42)
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(unit) chart with \(points.count) logged points. \(points.last.map { "Latest value \(number($0.value)) \(unit)" } ?? "No entries")")
    }
    var selectionLabel: String {
        guard let point = selected ?? (timeLabels ? nil : points.last) else { return "Touch the chart to inspect" }
        return "\(point.date.formatted(date: timeLabels ? .omitted : .abbreviated, time: timeLabels ? .shortened : .omitted)) · \(String(format: timeLabels ? "%.0f" : "%.1f", point.value)) \(unit)"
    }
    func number(_ value: Double) -> String { String(format: zeroBased ? "%.0f" : "%.1f", value) }
    func label(_ date: Date) -> String { date.formatted(date: timeLabels ? .omitted : .abbreviated, time: timeLabels ? .shortened : .omitted) }
    func position(_ point: ChartPoint, size: CGSize) -> CGPoint {
        let x = max(0, min(1, point.date.timeIntervalSince(start) / max(1, end.timeIntervalSince(start))))
        let y = max(0, min(1, (point.value - low) / max(1, high - low)))
        return CGPoint(x: 3 + CGFloat(x) * max(0, size.width - 6), y: 3 + CGFloat(1 - y) * max(0, size.height - 6))
    }
    func path(_ values: [ChartPoint], size: CGSize) -> Path {
        Path { path in for (i, point) in values.enumerated() { let p = position(point, size: size); if i == 0 { path.move(to: p) } else { path.addLine(to: p) } } }
    }
}

struct WeightTrend: View {
    var weights: [WeighIn]
    @State private var days = 30
    var end: Date { Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 3600) }
    var start: Date { Calendar.current.date(byAdding: .day, value: -(days - 1), to: end)! }
    var visible: [WeighIn] { weights.filter { $0.date >= start.addingTimeInterval(-12 * 3600) && $0.date <= Date() }.sorted { $0.date < $1.date } }
    var points: [ChartPoint] { visible.map { ChartPoint(date: Calendar.current.startOfDay(for: $0.date).addingTimeInterval(12 * 3600), value: $0.kg) } }
    var means: [ChartPoint] {
        points.map { point in
            let values = weights.filter { $0.date <= point.date.addingTimeInterval(12 * 3600) && $0.date >= point.date.addingTimeInterval(-6.5 * 86400) }.map(\.kg)
            return ChartPoint(date: point.date, value: Fitness.mean(values) ?? point.value)
        }
    }
    var body: some View {
        Card {
            SectionHeading(title: "Weight trend", detail: "kg")
            Picker("Weight chart range", selection: $days) { Text("7 days").tag(7); Text("30 days").tag(30); Text("90 days").tag(90) }.pickerStyle(.segmented)
            if points.isEmpty {
                Text("No weigh-ins in this range.").font(.system(size: 14)).foregroundColor(Ink.muted).frame(maxWidth: .infinity, minHeight: 110)
            } else {
                LinePlot(points: points, secondary: means, start: start, end: end, unit: "kg")
                HStack(spacing: 16) { Label("Weigh-in", systemImage: "circle.fill").foregroundColor(Ink.blue); Label("7-day mean", systemImage: "line.diagonal").foregroundColor(Ink.muted) }.font(.system(size: 10))
                Text(points.count == 1 ? "One recorded measurement. Add more to establish a trend." : "Touch the chart to inspect a measurement. Dates use their actual spacing.").font(.system(size: 11)).foregroundColor(Ink.muted)
            }
        }.accessibilityIdentifier("weightTrend")
    }
}

struct DayValue: Identifiable { var date: Date; var value: Double; var logged: Bool; var id: Date { date } }
struct BarPlot: View {
    var days: [DayValue]
    var unit: String
    var target: Double? = nil
    @State private var selected: DayValue?
    var high: Double { max(1, max(days.map(\.value).max() ?? 0, target ?? 0) * 1.15) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selected { Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)) · \(selected.logged ? "\(Int(selected.value)) \(unit)" : "Not logged")").font(.system(size: 12, weight: .medium)) }
            ZStack(alignment: .topLeading) {
                VStack { Divider().overlay(Ink.line); Spacer(); Divider().overlay(Ink.line); Spacer(); Divider().overlay(Ink.line) }
                if let target {
                    GeometryReader { geo in
                        Path { p in let y = geo.size.height * (1 - target / high); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y)) }.stroke(Ink.muted.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(days) { day in
                        Button { selected = day } label: {
                            VStack { Spacer(minLength: 0); RoundedRectangle(cornerRadius: 3).fill(day.logged ? Ink.blue : Ink.line).frame(height: day.logged ? max(3, CGFloat(day.value / high) * 125) : 3) }.frame(maxWidth: .infinity).frame(height: 125)
                        }.buttonStyle(.plain).accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.logged ? "\(Int(day.value)) \(unit)" : "not logged")")
                    }
                }.padding(.horizontal, 3)
            }.frame(height: 125)
            HStack { ForEach(days) { day in Text(day.date.formatted(.dateTime.weekday(.narrow))).frame(maxWidth: .infinity) } }.font(.system(size: 10)).foregroundColor(Ink.muted)
            if let target { Text("Dashed line: ~\(Int(target)) \(unit) target").font(.system(size: 10)).foregroundColor(Ink.muted) }
        }
    }
}
struct DailyIntakeChart: View {
    var meals: [Meal]
    var complete: [Date]
    var target: Double?
    var values: [DayValue] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let entries = meals.filter { cal.isDate($0.date, inSameDayAs: date) }
            return DayValue(date: date, value: entries.reduce(0) { $0 + $1.calories }, logged: !entries.isEmpty || complete.contains { cal.isDate($0, inSameDayAs: date) })
        }
    }
    var body: some View {
        Card {
            SectionHeading(title: "Calorie history", detail: "Last 7 days")
            if meals.isEmpty { Text("Log food to build your history. Empty days are not treated as zero intake.").font(.system(size: 13)).foregroundColor(Ink.muted) }
            BarPlot(days: values, unit: "kcal", target: target)
            Text("Bars show logged intake, not a measurement of everything you ate. Mark complete days in the daily log.").font(.system(size: 11)).foregroundColor(Ink.muted)
        }.accessibilityIdentifier("calorieHistory")
    }
}
struct FocusHistory: View {
    var sessions: [FocusSession]
    var values: [DayValue] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let entries = sessions.filter { cal.isDate($0.date, inSameDayAs: date) }
            return DayValue(date: date, value: Double(entries.reduce(0) { $0 + $1.minutes }), logged: !entries.isEmpty)
        }
    }
    var body: some View { Card { SectionHeading(title: "Focus history", detail: "Last 7 days"); BarPlot(days: values, unit: "min"); Text("Completed sessions only.").font(.system(size: 11)).foregroundColor(Ink.muted) } }
}
