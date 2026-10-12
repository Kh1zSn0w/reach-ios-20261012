import SwiftUI
import UIKit

struct RecoveryView: View {
    @EnvironmentObject var store: Store
    @Binding var tempted: Bool
    @State private var journal = false
    var body: some View {
        Page(eyebrow: "", title: "Relapse support", subtitle: "Urge tools and private check-ins") {
            HStack { Metric(label: "Urges interrupted", value: "\(store.data.checkIns.filter { !$0.lapse }.count)", unit: "self-reported"); Metric(label: "Check-ins", value: "\(store.data.checkIns.count)", unit: "journal entries") }
            Action(title: "I’m tempted", symbol: "hand.raised.fill") { tempted = true }
            Text("Porn, compulsive masturbation, doomscrolling, or another habit you want to change. Choose your boundary without turning a struggle into shame.").font(.system(size: 14)).foregroundColor(Ink.muted)
            Card {
                SectionHeading(title: "Managing triggers")
                tip("01", "Change the room", "Get out of bed, open the door, and move somewhere less private. Put the phone out of reach.")
                tip("02", "Name the real need", "Bored, lonely, stressed, tired? Choose a response to that need: sleep, a walk, a real conversation or a short task.")
                tip("03", "Remove the easy route", "Use Screen Time adult-site restrictions, unfollow trigger accounts, and keep your phone outside the bathroom and bedroom.")
            }
            Action(title: "Log a check-in or setback", symbol: "square.and.pencil") { journal = true }
            Card {
                SectionHeading(title: "After a setback")
                Text("Close the trigger, eat and sleep normally, write what happened, and change one part of the setup. A lapse does not erase the choices you made before it.").font(.system(size: 14)).foregroundColor(Ink.muted)
            }
            SectionHeading(title: "Recent check-ins")
            if store.data.checkIns.isEmpty { Text("Your journal starts with the next honest check-in.").font(.system(size: 14)).foregroundColor(Ink.muted) }
            ForEach(Array(store.data.checkIns.suffix(10).reversed())) { entry in
                VStack(alignment: .leading, spacing: 7) {
                    HStack { Text(entry.lapse ? "Setback / learned from" : "Urge / interrupted").font(.system(size: 14, weight: .semibold)); Spacer(); Button { store.data.checkIns.removeAll { $0.id == entry.id }; store.save() } label: { Image(systemName: "minus.circle").foregroundColor(Ink.muted) }.accessibilityLabel("Delete check-in") }
                    Text(entry.trigger).font(.system(size: 14))
                    Text(entry.action).font(.system(size: 13)).foregroundColor(Ink.muted)
                    Text("\(entry.date.formatted(date: .abbreviated, time: .shortened)) · urge \(entry.urge)/10").font(.system(size: 10, design: .monospaced)).foregroundColor(Ink.muted)
                }.padding(.vertical, 12)
            }
            Text("If the behavior feels out of control, causes distress or affects your life, a qualified therapist can help with CBT or other treatment. Sexual thoughts or masturbation alone do not establish an addiction.").font(.system(size: 13)).foregroundColor(Ink.muted)
            Link("Treatment options · Mayo Clinic", destination: URL(string: "https://www.mayoclinic.org/diseases-conditions/compulsive-sexual-behavior/diagnosis-treatment/drc-20360453")!).font(.caption)
        }.sheet(isPresented: $journal) { CheckInView() }
    }
    func tip(_ number: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 13) { Text(number).font(.system(size: 12, design: .monospaced)).foregroundColor(Ink.blue); VStack(alignment: .leading, spacing: 6) { Text(title).font(.system(size: 16, weight: .semibold)); Text(body).font(.system(size: 13)).foregroundColor(Ink.muted) } }
    }
}

struct CheckInView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var trigger = ""
    @State private var action = ""
    @State private var lapse = false
    @State private var urge = 5
    var body: some View {
        NavigationView {
            Form {
                Text("Write facts, not insults. This is information for your next decision.").foregroundColor(Ink.muted)
                Toggle("A setback happened", isOn: $lapse)
                Stepper("Urge intensity: \(urge)/10", value: $urge, in: 0...10)
                TextField("What triggered it?", text: $trigger)
                TextField("What helped, or what will change next time?", text: $action)
                Button("Save private check-in") {
                    store.data.checkIns.append(CheckIn(trigger: String(trigger.prefix(1000)), action: String(action.prefix(1000)), lapse: lapse, urge: urge)); store.save(); dismiss()
                }.disabled(trigger.trimmingCharacters(in: .whitespaces).isEmpty || action.trimmingCharacters(in: .whitespaces).isEmpty)
            }.navigationTitle("Check in").toolbar { Button("Cancel") { dismiss() } }
        }
    }
}

struct TemptedView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var step = 0
    @State private var start = Date()
    @State private var urge = 5
    @State private var trigger = ""
    @State private var choice = "Take a walk"
    @State private var showJournal = false
    @State private var completed = false
    let choices = ["Take a walk", "Call someone I trust", "Read or pray", "Make tea and leave my phone", "Start a small task"]
    var body: some View {
        ZStack {
            CanvasBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack { Text("Step \(step + 1) of 4").font(.system(size: 13, weight: .medium)).foregroundColor(Ink.muted); Spacer(); Button("Close") { dismiss() }.font(.caption) }
                    if step == 0 {
                        Text("Pause the urge").font(.system(size: 28, weight: .semibold))
                        Text("Close the triggering tab or app. Stand up. Put your phone down for a moment. You don’t have to solve your whole life right now.").foregroundColor(Ink.muted)
                        Stepper("How strong is the urge? \(urge)/10", value: $urge, in: 0...10)
                        TextField("What set it off? (optional)", text: $trigger).padding(16).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        Action(title: "I’ve stepped away") { advance() }
                    } else if step == 1 {
                        Text("Breathe slowly").font(.system(size: 28, weight: .semibold))
                        Text("Breathe gently. In for 4, out for 6. Notice where the urge sits in your body. Let the feeling be there without feeding it. If paced breathing feels uncomfortable, breathe normally.").foregroundColor(Ink.muted)
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            let elapsed = max(0, Int(timeline.date.timeIntervalSince(start)))
                            let inhale = elapsed % 10 < 4
                            ZStack {
                                Circle().stroke(Ink.blue.opacity(0.2), lineWidth: 1).frame(width: 210, height: 210)
                                Circle().fill(Ink.blue.opacity(0.10)).frame(width: inhale ? 175 : 135, height: inhale ? 175 : 135).animation(reduceMotion ? nil : .easeInOut(duration: 3), value: inhale)
                                VStack(spacing: 8) { Text(inhale ? "Breathe in" : "Breathe out").font(.system(size: 24, weight: .medium)); Text("\(max(0, 90 - elapsed))s").font(.system(size: 13, design: .monospaced)).foregroundColor(Ink.muted) }
                            }.frame(maxWidth: .infinity).padding(.vertical, 15)
                        }
                        Text("No need to force the urge to disappear. Practice not acting on it.").font(.system(size: 14)).foregroundColor(Ink.muted)
                        Action(title: "Next: change my environment") { advance() }
                    } else if step == 2 {
                        Text("Change your environment").font(.system(size: 28, weight: .semibold))
                        Text("Leave the private space. Drink water. Find five things you can see, four you can feel, three you can hear, two you can smell, and one you can taste.").foregroundColor(Ink.muted)
                        Text("Choose what you’ll do instead:").fontWeight(.semibold)
                        ForEach(choices, id: \.self) { item in
                            Button { choice = item } label: { HStack { Image(systemName: choice == item ? "checkmark.circle.fill" : "circle").foregroundColor(Ink.blue); Text(item); Spacer() }.padding(.vertical, 10) }.buttonStyle(.plain)
                        }
                        Action(title: "Commit to ten minutes") { advance() }
                    } else {
                        Text("Follow your chosen action").font(.system(size: 28, weight: .semibold))
                        Text(choice).font(.system(size: 20, weight: .medium)).foregroundColor(Ink.blue)
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            let remaining = max(0, 600 - Int(timeline.date.timeIntervalSince(start)))
                            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60)).font(.system(size: 58, weight: .light, design: .monospaced)).monospacedDigit()
                            Text(remaining > 0 ? "Leave the phone and do the action. Return to check in." : "Ten minutes completed. Check in with yourself.").font(.system(size: 14)).foregroundColor(Ink.muted)
                        }
                        Text("If the urge returns, repeat the pause or ask someone you trust for company. A timer cannot guarantee the feeling goes away.").font(.system(size: 14)).foregroundColor(Ink.muted)
                        if !completed {
                            Action(title: "I interrupted the urge") {
                                store.data.checkIns.append(CheckIn(trigger: trigger.isEmpty ? "Urge interrupted" : String(trigger.prefix(1000)), action: choice, lapse: false, urge: urge)); store.save(); completed = true
                            }
                            Button("I had a setback. Help me reset.") { showJournal = true }.font(.system(size: 14)).foregroundColor(Ink.muted)
                        } else {
                            Text("Check-in saved").font(.system(size: 20, weight: .semibold))
                            Action(title: "Back to my day") { dismiss() }
                        }
                    }
                }.padding(28).padding(.top, 15)
            }
        }.foregroundColor(Ink.ivory).sheet(isPresented: $showJournal) { CheckInView() }
    }
    func advance() { step += 1; start = Date(); UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}
