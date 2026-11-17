import SwiftUI

enum Theme {
    static let primary = Color(red: 0.36, green: 0.31, blue: 0.93)
    static let secondary = Color(red: 0.62, green: 0.36, blue: 0.96)
    static let success = Color.green
    static let danger = Color.red
    static let flame = Color.orange
    static let gradient = LinearGradient(colors: [primary, secondary],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// English content is laid out left-to-right inside the Arabic UI.
    func ltr() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isEnabled ? color : Color.gray.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SpeakButton: View {
    let text: String
    var slow = false
    var size: CGFloat = 20

    var body: some View {
        Button {
            SpeechService.shared.speak(text, slow: slow)
        } label: {
            Image(systemName: slow ? "tortoise.fill" : "speaker.wave.2.fill")
                .font(.system(size: size))
                .foregroundStyle(Theme.primary)
                .padding(8)
                .background(Theme.primary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(slow ? "استمع ببطء" : "استمع")
    }
}

struct LevelBadge: View {
    let level: CEFRLevel

    var body: some View {
        Text(level.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.primary.opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.primary)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = .white

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = Theme.primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Wraps children onto multiple lines (used for tappable words in stories and word-order exercises).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct FeedbackBanner: View {
    let correct: Bool
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(correct ? Theme.success : Theme.danger)
            if !detail.isEmpty {
                Text(detail).font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background((correct ? Theme.success : Theme.danger).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
