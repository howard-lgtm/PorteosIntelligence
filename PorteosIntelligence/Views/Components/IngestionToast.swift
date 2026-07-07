import SwiftUI

// MARK: - IngestionToastData

struct IngestionToastData: Identifiable {
    let id           = UUID()
    let dealID:       UUID
    let propertyName: String
    let location:     String
    let price:        Double
    let source:       String
    let isDuplicate:  Bool
    var progressCurrent: Int = 1
    var progressTotal:   Int = 1
}

// MARK: - ToastManager

@Observable @MainActor
final class ToastManager {
    static let shared = ToastManager()
    private init() {}

    var current: IngestionToastData?

    func show(_ toast: IngestionToastData) {
        current = toast
        Task {
            try? await Task.sleep(for: .seconds(4))
            if current?.id == toast.id { current = nil }
        }
    }

    func dismiss() { current = nil }
}

// MARK: - IngestionToastView
// Figma img_00_7 — IMPORTING header, title, progress bar, status line.

struct IngestionToastView: View {

    let toast: IngestionToastData
    var onSelectDeal: () -> Void = {}

    @State private var progress: Double = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("IMPORTING")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)

                Spacer()

                Button { ToastManager.shared.dismiss() } label: {
                    Text("×")
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 10)

            Text(toast.propertyName.uppercased())
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(2)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignTokens.dividerStructural)
                        .frame(height: 2)
                    Rectangle()
                        .fill(DesignTokens.statusInfo)
                        .frame(width: geo.size.width * progress, height: 2)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 10)

            Text("\(toast.progressCurrent) of \(toast.progressTotal) documents processed")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
        .onTapGesture { onSelectDeal() }
        .onAppear {
            let target = Double(toast.progressCurrent) / Double(max(toast.progressTotal, 1))
            withAnimation(.linear(duration: 2.5)) { progress = target }
        }
    }
}

// MARK: - Preview

#Preview {
    IngestionToastView(
        toast: IngestionToastData(
            dealID: UUID(),
            propertyName: "Lisbon Office Block A",
            location: "Lisbon",
            price: 45_200_000,
            source: "idealista",
            isDuplicate: false,
            progressCurrent: 2,
            progressTotal: 7
        )
    )
    .padding(20)
    .background(DesignTokens.canvasBase)
}
