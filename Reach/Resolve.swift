import SwiftUI

struct ResolveView: View {
    @EnvironmentObject var store: Store
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("quoteCursor") private var cursor = 0
    @State private var category = "All"
    @State private var favorites = false
    @State private var sharing = false
    let categories = ["All", "Faith", "Stoic", "Power", "Resolve", "Discipline", "Attention", "Recovery", "Courage"]
    var library: [Quote] { allQuotes.filter { (category == "All" || $0.category == category) && (!favorites || store.data.favoriteQuotes.contains($0.id)) } }
    var current: Quote? { library.isEmpty ? nil : library[abs(cursor % library.count)] }
    var body: some View {
        Page(eyebrow: "04 / Resolve", title: "Words with\nweight.", subtitle: "\(allQuotes.count) reminders. Read one. Put it to work.") {
            HStack { InkIcon(name: "sword", size: 88); Spacer(); Button { favorites.toggle(); cursor = 0 } label: { Label(favorites ? "Favorites" : "All quotes", systemImage: favorites ? "heart.fill" : "heart").font(.system(size: 12)).foregroundColor(Ink.blue) } }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { ForEach(categories, id: \.self) { item in
                    Button { category = item; cursor = 0 } label: { Text(item).font(.system(size: 12, weight: .medium)).padding(.horizontal, 13).padding(.vertical, 9).background(category == item ? Ink.blue.opacity(0.3) : .white.opacity(0.04), in: Capsule()).foregroundColor(category == item ? Ink.ivory : Ink.muted) }.buttonStyle(.plain)
                } }
            }
            if let q = current {
                VStack(alignment: .leading, spacing: 28) {
                    Text(String(format: "%03d / %03d", abs(cursor % library.count) + 1, library.count)).font(.system(size: 11, design: .monospaced)).tracking(3).foregroundColor(Ink.blue)
                    if !q.arabic.isEmpty {
                        Text(q.arabic).font(.custom("GeezaPro-Bold", size: 32)).lineSpacing(15).multilineTextAlignment(.trailing).frame(maxWidth: .infinity, alignment: .trailing).environment(\.layoutDirection, .rightToLeft)
                    }
                    Text(q.words).font(.system(size: 34, weight: .semibold, design: .serif)).lineSpacing(7).fixedSize(horizontal: false, vertical: true)
                    Text(q.source.uppercased()).font(.system(size: 10, design: .monospaced)).tracking(1.3).foregroundColor(Ink.muted)
                    if !q.url.isEmpty { Link("Read in context ↗", destination: URL(string: q.url)!).font(.caption) }
                }.padding(.vertical, 22).id(q.id).transition(.opacity)
                HStack {
                    Button { if cursor > 0 { cursor -= 1 } } label: { Image(systemName: "arrow.left").frame(width: 50, height: 50).glass() }.accessibilityLabel("Previous quote")
                    Spacer()
                    Button { store.favorite(q.id) } label: { Image(systemName: store.data.favoriteQuotes.contains(q.id) ? "heart.fill" : "heart").frame(width: 50, height: 50).glass() }.accessibilityLabel("Favorite quote")
                    Button { sharing = true } label: { Image(systemName: "square.and.arrow.up").frame(width: 50, height: 50).glass() }.accessibilityLabel("Share quote")
                    Spacer()
                    Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { cursor += 1 } } label: { Image(systemName: "arrow.right").frame(width: 50, height: 50).glass() }.accessibilityLabel("Next quote")
                }
                Text("Make it concrete: choose one action this line asks of you today.").font(.system(size: 14)).foregroundColor(Ink.muted).padding(.top, 20)
            } else { Text("Favorite a few lines to build your own collection.").foregroundColor(Ink.muted) }
            Text("REACH originals are labeled. Translations convey meanings. Historical quotes link to their context; power maxims are prompts for reflection, not instructions to harm or manipulate people.").font(.system(size: 12)).foregroundColor(Ink.muted)
        }.sheet(isPresented: $sharing) { if let q = current { ShareSheet(items: [(q.arabic.isEmpty ? "" : q.arabic + "\n\n") + q.words + "\n\n" + q.source]) } }
    }
}
