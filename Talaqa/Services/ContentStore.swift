import Foundation

/// Loads the bundled learning content (JSON files in Resources/Content).
final class ContentStore {
    static let shared = ContentStore()

    let vocabulary: [VocabItem]
    let lessons: [GrammarLesson]
    let placement: [PlacementQuestion]
    let scenarios: [Scenario]
    let stories: [Story]
    let shadowing: [ShadowingItem]

    private init() {
        let loadedLessons: [GrammarLesson] = Self.load("grammar")
        let loadedScenarios: [Scenario] = Self.load("scenarios")
        let loadedStories: [Story] = Self.load("stories")
        vocabulary = Self.load("vocabulary")
        lessons = loadedLessons.sorted { $0.level < $1.level }
        placement = Self.load("placement")
        scenarios = loadedScenarios.sorted { $0.level < $1.level }
        stories = loadedStories.sorted { $0.level < $1.level }
        shadowing = Self.load("shadowing")
    }

    private static func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("⚠️ Missing content file: \(name).json")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("⚠️ Failed to decode \(name).json: \(error)")
            return []
        }
    }

    func nextLesson(for level: CEFRLevel, completed: Set<String>) -> GrammarLesson? {
        lessons.first { $0.level <= level.next && !completed.contains($0.id) }
    }

    struct ShadowingGroup: Identifiable {
        let focus: String
        let focusAr: String
        let items: [ShadowingItem]
        var id: String { focus }
    }

    func shadowingGroups(upTo level: CEFRLevel = .c2) -> [ShadowingGroup] {
        var order: [String] = []
        var map: [String: [ShadowingItem]] = [:]
        for item in shadowing where item.level <= level {
            if map[item.focus] == nil { order.append(item.focus) }
            map[item.focus, default: []].append(item)
        }
        return order.compactMap { key in
            guard let items = map[key], let first = items.first else { return nil }
            return ShadowingGroup(focus: key, focusAr: first.focusAr, items: items)
        }
    }
}
