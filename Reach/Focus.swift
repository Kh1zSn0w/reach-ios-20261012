import SwiftUI
import UIKit

struct FocusView: View {
    @EnvironmentObject var store: Store
    @State private var timer = false
    @State private var minutes = 10
    @State private var week = 1
    let habits = ["No short-form feeds before noon", "Read 5 pages without switching", "20 minutes outside or moving", "Protect a consistent bedtime", "Single-task one ordinary activity"]
    var body: some View {
        Page(eyebrow: "", title: "Attention", subtitle: "Focus sessions and a progressive practice plan") {
            HStack { Metric(label: "Today", value: "\(store.todayFocus)", unit: "focused minutes"); Metric(label: "Completed", value: "\(store.data.focus.count)", unit: "sessions") }
            Text("Your attention isn’t permanently broken. Reduce the constant switching, build tolerable periods of focus, and protect sleep. There’s no proven instant dopamine reset.").font(.system(size: 14)).foregroundColor(Ink.muted)
            Card {
                SectionHeading(title: "Start a session")
                Picker("Focus duration", selection: $minutes) { Text("5 min").tag(5); Text("10 min").tag(10); Text("20 min").tag(20); Text("30 min").tag(30) }.pickerStyle(.segmented)
                Text("Pick a specific task, leave your phone beyond reach, and write distracting thoughts on paper instead of switching apps.").font(.system(size: 13)).foregroundColor(Ink.muted)
                Action(title: "Start focus session", symbol: "play.fill") { timer = true }
            }
            FocusHistory(sessions: store.data.focus)
            SectionHeading(title: "Four-week practice plan")
            Picker("Training week", selection: $week) { ForEach(1...4, id: \.self) { Text("Week \($0)").tag($0) } }.pickerStyle(.segmented)
            VStack(alignment: .leading, spacing: 14) {
                Text(weekTitle).font(.system(size: 18, weight: .semibold))
                Text(weekBody).font(.system(size: 15)).foregroundColor(Ink.muted)
            }.padding(.vertical, 12)
            ForEach(habits, id: \.self) { habit in
                Button { store.toggle(habit) } label: { HStack(spacing: 12) { Image(systemName: store.done(habit) ? "checkmark.circle.fill" : "circle").foregroundColor(Ink.blue); Text(habit).font(.system(size: 14)); Spacer() }.padding(.vertical, 10) }.buttonStyle(.plain)
            }
            Card {
                SectionHeading(title: "Handling distractions")
                Text("Say ‘I’m looking for stimulation.’ Put the distraction on a list. Return to the smallest next step. The return is the repetition you’re training.").font(.system(size: 14)).foregroundColor(Ink.muted)
            }
            SectionHeading(title: "Session totals")
            HStack { Metric(label: "Sessions", value: "\(store.data.focus.count)", unit: "completed"); Metric(label: "Total", value: "\(store.data.focus.reduce(0) { $0 + $1.minutes })", unit: "focused minutes") }
            Text("Adults generally need 7–9 hours of sleep. If concentration problems persist or affect school, work or daily life, talk to a clinician; sleep issues, anxiety, depression or ADHD may be involved.").font(.system(size: 13)).foregroundColor(Ink.muted)
            Link("Sleep guidance · NIH", destination: URL(string: "https://www.nhlbi.nih.gov/health/sleep/how-much-sleep")!).font(.caption)
        }.fullScreenCover(isPresented: $timer) { FocusTimer(minutes: minutes) }
    }
    var weekTitle: String { ["", "01. Clear the noise.", "02. Extend the hold.", "03. Build tolerance.", "04. Keep what works."][week] }
    var weekBody: String {
        ["", "Start with one 5–10 minute block daily. Turn off nonessential notifications, remove feed shortcuts, and keep the first 30 minutes after waking free of scrolling. Observe your baseline screen time.", "Aim for two 10–15 minute blocks when comfortable. Read on paper. Take breaks without feeds. Choose one window for messages instead of checking every few minutes.", "Work toward 20–25 minutes on one task. Try a quiet walk without audio. Leave empty moments empty. Increase slowly; forcing exhaustion does not train attention well.", "Keep a realistic minimum you can repeat on difficult days. Compare your completed blocks and screen-time patterns with week one. Adjust the environment instead of relying on willpower alone."][week]
    }
}
struct FocusTimer: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    var minutes: Int
    @State private var end = Date()
    @State private var remaining = 0
    @State private var paused = false
    @State private var saved = false
    @State private var task = ""
    @State private var running = false
    @State private var abandoned = false
    var body: some View {
        ZStack {
            CanvasBackground()
            VStack(spacing: 28) {
                HStack { Text("Focus session").font(.system(size: 15, weight: .medium)); Spacer(); Button("End") { if running && !saved { abandoned = true } else { dismiss() } } }
                Spacer()
                if !running {
                    Text("Choose a task").font(.system(size: 26, weight: .semibold))
                    TextField("What will you work on?", text: $task).padding(17).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    Text("\(minutes) minutes. Phone down. Begin.").foregroundColor(Ink.muted)
                    Action(title: "Begin", symbol: "play.fill") { end = Date().addingTimeInterval(Double(minutes * 60)); remaining = minutes * 60; running = true; UIApplication.shared.isIdleTimerDisabled = true }.disabled(task.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Text(task).font(.system(size: 22, weight: .medium)).multilineTextAlignment(.center)
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        let seconds = paused ? remaining : max(0, Int(ceil(end.timeIntervalSince(timeline.date))))
                        Text(String(format: "%02d:%02d", seconds / 60, seconds % 60)).font(.system(size: 66, weight: .light, design: .monospaced)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                        if seconds == 0 {
                            if saved { Text("Session saved.").foregroundColor(Ink.blue) }
                            else { Action(title: "Finish & log session", symbol: "checkmark") { store.data.focus.append(FocusSession(minutes: minutes)); store.save(); saved = true; UIApplication.shared.isIdleTimerDisabled = false; UINotificationFeedbackGenerator().notificationOccurred(.success) } }
                        } else {
                            Button(paused ? "Resume" : "Pause") {
                                if paused { end = Date().addingTimeInterval(Double(remaining)); paused = false; UIApplication.shared.isIdleTimerDisabled = true }
                                else { remaining = seconds; paused = true; UIApplication.shared.isIdleTimerDisabled = false }
                            }.foregroundColor(Ink.blue)
                        }
                    }
                    Text("If your mind drifts, gently bring it back. That counts as practice.").foregroundColor(Ink.muted).font(.system(size: 14)).multilineTextAlignment(.center)
                }
                Spacer()
                Text("The timer pauses when you leave REACH. Locking your phone also pauses it. Keep REACH open and place it face down.").font(.system(size: 11)).foregroundColor(Ink.muted).multilineTextAlignment(.center)
            }.padding(28)
        }.foregroundColor(Ink.ivory)
            .onChange(of: scenePhase) { phase in
                if phase != .active && running && !paused { remaining = max(0, Int(ceil(end.timeIntervalSinceNow))); paused = true; UIApplication.shared.isIdleTimerDisabled = false }
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .alert("End this focus block?", isPresented: $abandoned) {
                Button("Keep going", role: .cancel) {}
                Button("End without logging", role: .destructive) { dismiss() }
            } message: { Text("Only completed focus blocks are logged. Start shorter next time if needed.") }
    }
}
