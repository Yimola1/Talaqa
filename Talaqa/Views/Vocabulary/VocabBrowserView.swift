import SwiftUI
import SwiftData

struct VocabBrowserView: View {
    @Query(sort: \WordCard.word) private var cards: [WordCard]
    @State private var search = ""
    @State private var filter = 0

    private var filtered: [WordCard] {
        cards.filter { card in
            let matches = search.isEmpty
                || card.word.localizedCaseInsensitiveContains(search)
                || card.meaningAr.contains(search)
            switch filter {
            case 1: return matches && card.isMastered
            case 2: return matches && !card.isMastered
            default: return matches
            }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("التصفية", selection: $filter) {
                    Text("الكل (\(cards.count))").tag(0)
                    Text("متقنة").tag(1)
                    Text("قيد التعلّم").tag(2)
                }
                .pickerStyle(.segmented)
            }
            if filtered.isEmpty {
                ContentUnavailableView("لا توجد كلمات بعد", systemImage: "rectangle.stack",
                                       description: Text("ابدأ جلسة مفردات لإضافة كلمات إلى بنكك."))
            }
            ForEach(filtered) { card in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.word).font(.headline).ltr()
                        Text(card.meaningAr).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if card.isMastered {
                            Label("متقنة", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
                        } else {
                            Text("المراجعة: \(FSRS.format(interval: max(0, card.due.timeIntervalSinceNow)))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    SpeakButton(text: card.word, size: 14)
                }
            }
        }
        .searchable(text: $search, prompt: "ابحث عن كلمة")
        .navigationTitle("بنك كلماتي")
    }
}
