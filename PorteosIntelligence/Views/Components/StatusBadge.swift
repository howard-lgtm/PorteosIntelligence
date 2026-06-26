import SwiftUI

// MARK: - BadgeState

enum BadgeState {
    case optimal    // green  — threshold met / healthy
    case watch      // amber  — soft alert / approaching threshold
    case degraded   // red    — threshold breached / critical
    case pending    // amber  — awaiting data / in progress
}

// MARK: - StatusBadge
// Small pill badge for state indicators.
// Sharp rectangle (corner radius: 0), 1px semantic border,
// 10% opacity semantic background tint.

struct StatusBadge: View {

    let text: String
    let state: BadgeState

    // MARK: Semantic Colors

    private var semanticColor: Color {
        switch state {
        case .optimal:  return Color(hex: "#10B981")   // green
        case .watch:    return Color(hex: "#F59E0B")   // amber
        case .degraded: return Color(hex: "#EF4444")   // red
        case .pending:  return Color(hex: "#F59E0B")   // amber (same as watch)
        }
    }

    // MARK: Body

    var body: some View {
        Text(text.uppercased())
            .font(.custom("JetBrains Mono", size: 10).weight(.bold))
            .foregroundStyle(semanticColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(semanticColor.opacity(0.10))
            .overlay {
                Rectangle().strokeBorder(semanticColor, lineWidth: 1)
            }
            .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        StatusBadge(text: "Viable",    state: .optimal)
        StatusBadge(text: "Review",    state: .watch)
        StatusBadge(text: "Critical",  state: .degraded)
        StatusBadge(text: "Pending",   state: .pending)
    }
    .padding(16)
    .background(Color(hex: "#0F1115"))
}
