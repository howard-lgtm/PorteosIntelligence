import SwiftUI

// MARK: - BadgeState

enum BadgeState {
    case optimal
    case watch
    case degraded
    case pending
}

// MARK: - StatusBadge

struct StatusBadge: View {

    let text: String
    let state: BadgeState

    private var semanticColor: Color {
        switch state {
        case .optimal:  return DesignTokens.statusGo
        case .watch:    return DesignTokens.statusWarn
        case .degraded: return DesignTokens.statusCritical
        case .pending:  return DesignTokens.statusWarn
        }
    }

    var body: some View {
        Text(text.uppercased())
            .porteosMeta()
            .foregroundStyle(semanticColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(semanticColor.opacity(0.10))
            .overlay {
                Rectangle().strokeBorder(semanticColor, lineWidth: DesignTokens.dividerWidth)
            }
            .clipShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 8) {
        StatusBadge(text: "Viable",   state: .optimal)
        StatusBadge(text: "Review",   state: .watch)
        StatusBadge(text: "Critical", state: .degraded)
        StatusBadge(text: "Pending",  state: .pending)
    }
    .padding(16)
    .background(DesignTokens.canvasBase)
}
