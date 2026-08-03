import SwiftUI
import SwiftData
import AppKit
import PhotosUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers

// MARK: - DealMediaGalleryView

struct DealMediaGalleryView: View {

    @Bindable var deal: PropertyDeal
    @Environment(\.modelContext) private var ctx

    @State private var selectedLabel:      DealImageLabel?    = nil
    @State private var selectedImageIDs:   Set<UUID>          = []
    @State private var showFileImporter:   Bool               = false
    @State private var photosPickerItems:  [PhotosPickerItem] = []
    @State private var editingImage:       DealImage?         = nil
    @State private var isCapturingAerial:  Bool               = false

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            fullWidthDivider
            heroSlot
            fullWidthDivider
            labelFilterChips
            fullWidthDivider
            thumbnailGrid
            fullWidthDivider
            if !selectedImageIDs.isEmpty { batchActionBar }
            fullWidthDivider
            addButtonsBar
        }
        .background(DesignTokens.surfacePanel)
        .clipShape(Rectangle())
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.jpeg, .png, .heic, .tiff],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onChange(of: photosPickerItems) { _, items in
            Task { @MainActor in
                await handlePhotoPicker(items)
            }
        }
        .sheet(item: $editingImage) { img in
            CaptionEditorSheet(image: img) { caption in
                img.caption = caption
                try? ctx.save()
            }
        }
    }

    // MARK: Header Bar

    private var headerBar: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text("deal --media --asset=\"\(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)\"")
                .porteosModuleCmd()
                .foregroundStyle(DesignTokens.accentRust)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Hero Slot

    private var heroSlot: some View {
        let hero = deal.images.first(where: { $0.isHero })
        return ZStack {
            DesignTokens.canvasBase
            if let h = hero, let img = NSImage(data: h.imageData) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        Text("HERO")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.canvasBase)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignTokens.accentRust)
                            .clipShape(Rectangle())
                            .padding(6)
                    }
            } else {
                VStack(spacing: 8) {
                    Text("+")
                        .font(.system(size: 28, weight: .ultraLight, design: .monospaced))
                        .foregroundStyle(DesignTokens.textDim)
                    Text("// DROP HERO IMAGE")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Rectangle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                        .foregroundStyle(DesignTokens.dividerStructural)
                        .padding(8)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(Rectangle())
    }

    // MARK: Label Filter Chips

    private var labelFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                filterChip(title: "ALL", isActive: selectedLabel == nil) {
                    selectedLabel = nil
                    selectedImageIDs = []
                }
                ForEach(DealImageLabel.allCases, id: \.self) { lbl in
                    filterChip(title: lbl.rawValue, isActive: selectedLabel == lbl) {
                        selectedLabel = (selectedLabel == lbl) ? nil : lbl
                        selectedImageIDs = []
                    }
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 6)
        }
        .background(DesignTokens.surfacePanel)
    }

    private func filterChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .porteosMeta()
                .foregroundStyle(isActive ? DesignTokens.canvasBase : DesignTokens.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isActive ? DesignTokens.accentRust : DesignTokens.surfaceElevated)
                .overlay(
                    Rectangle().strokeBorder(
                        isActive ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                        lineWidth: DesignTokens.dividerWidth
                    )
                )
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Thumbnail Grid

    @ViewBuilder
    private var thumbnailGrid: some View {
        let shown = filteredImages
        if shown.isEmpty {
            HStack {
                Text("// NO IMAGES")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 20)
            .background(DesignTokens.surfacePanel)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 4) {
                    ForEach(shown, id: \.id) { img in
                        thumbnailCell(img)
                    }
                }
                .padding(DesignTokens.blockGutter)
            }
            .frame(minHeight: 80, maxHeight: 300)
        }
    }

    private func thumbnailCell(_ img: DealImage) -> some View {
        let thumbData = img.thumbnailData.isEmpty ? img.imageData : img.thumbnailData
        let thumb     = NSImage(data: thumbData)

        return ZStack(alignment: .bottomLeading) {
            if let thumb {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
            } else {
                Rectangle()
                    .fill(DesignTokens.surfaceElevated)
                    .frame(width: 80, height: 80)
            }

            // Label badge
            Text(shortLabel(img.label))
                .porteosMeta()
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(DesignTokens.canvasBase.opacity(0.85))
                .clipShape(Rectangle())
                .padding(2)

            // Hero star
            if img.isHero {
                Text("★")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.accentRust)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(3)
            }
        }
        .frame(width: 80, height: 80)
        .overlay(
            Rectangle().strokeBorder(
                selectedImageIDs.contains(img.id) ? DesignTokens.accentRust
                    : img.isHero                  ? DesignTokens.accentRust.opacity(0.5)
                    :                               DesignTokens.dividerStructural,
                lineWidth: selectedImageIDs.contains(img.id) ? 2 : DesignTokens.dividerWidth
            )
        )
        .clipShape(Rectangle())
        .onTapGesture {
            if selectedImageIDs.contains(img.id) {
                selectedImageIDs.remove(img.id)
            } else {
                selectedImageIDs.insert(img.id)
            }
        }
        .contextMenu {
            Button("Set as Hero")  { setHero(img) }
            Divider()
            Button("Edit Caption") { editingImage = img }
            Menu("Change Label") {
                ForEach(DealImageLabel.allCases, id: \.self) { lbl in
                    Button(lbl.rawValue) { changeLabel(img, to: lbl) }
                }
            }
            Divider()
            Button("Delete", role: .destructive) { deleteImage(img) }
        }
    }

    // MARK: Add Buttons Bar

    private var addButtonsBar: some View {
        HStack(spacing: 6) {
            Button { showFileImporter = true } label: {
                Text("[ + FROM FILES ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.horizontal, 8)
                    .frame(height: DesignTokens.rowHeightButton)
                    .background(DesignTokens.surfaceElevated)
                    .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)

            PhotosPicker(selection: $photosPickerItems, matching: .images) {
                Text("[ + FROM PHOTOS ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.horizontal, 8)
                    .frame(height: DesignTokens.rowHeightButton)
                    .background(DesignTokens.surfaceElevated)
                    .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { captureAerial() } label: {
                let capturing = isCapturingAerial
                Text(capturing ? "[ ↗ ... ]" : "[ ↗ AERIAL ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(capturing ? DesignTokens.textDim : DesignTokens.accentRust)
                    .padding(.horizontal, 8)
                    .frame(height: DesignTokens.rowHeightButton)
                    .background(DesignTokens.surfaceElevated)
                    .overlay(Rectangle().strokeBorder(
                        capturing ? DesignTokens.dividerStructural : DesignTokens.accentRust.opacity(0.5),
                        lineWidth: DesignTokens.dividerWidth
                    ))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isCapturingAerial || !deal.hasPlottableCoordinates)

            Spacer(minLength: 0)

            Text("\(deal.images.count) IMAGES")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Aerial Capture

    private func captureAerial() {
        guard let lat = deal.latitude, let lon = deal.longitude, lat != 0 || lon != 0 else { return }
        isCapturingAerial = true
        let opts = MKMapSnapshotter.Options()
        opts.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            latitudinalMeters: 300,
            longitudinalMeters: 300
        )
        opts.size    = CGSize(width: 800, height: 600)
        opts.mapType = .satelliteFlyover
        MKMapSnapshotter(options: opts).start(with: DispatchQueue.main) { snap, _ in
            isCapturingAerial = false
            guard let snap else { return }
            let img = snap.image
            if let data = img.tiffRepresentation {
                let nextOrder = (deal.images.map(\.sortOrder).max() ?? -1) + 1
                let di = DealImage(
                    imageData: data,
                    label:     .aerial,
                    caption:   "Aerial",
                    isHero:    deal.images.isEmpty,
                    sortOrder: nextOrder
                )
                deal.images.append(di)
                try? ctx.save()
            }
        }
    }

    // MARK: File Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { continue }
            let nextOrder = (deal.images.map(\.sortOrder).max() ?? -1) + 1
            let di = DealImage(
                imageData: data,
                label:     inferLabel(from: url.lastPathComponent),
                isHero:    deal.images.isEmpty,
                sortOrder: nextOrder
            )
            deal.images.append(di)
        }
        try? ctx.save()
    }

    // MARK: Photos Picker

    @MainActor
    private func handlePhotoPicker(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let nextOrder = (deal.images.map(\.sortOrder).max() ?? -1) + 1
            let di = DealImage(
                imageData: data,
                label:     .other,
                isHero:    deal.images.isEmpty,
                sortOrder: nextOrder
            )
            deal.images.append(di)
        }
        try? ctx.save()
        photosPickerItems = []
    }

    // MARK: Batch Action Bar

    private var batchActionBar: some View {
        HStack(spacing: 8) {
            Text("\(selectedImageIDs.count) SELECTED")
                .porteosMeta()
                .foregroundStyle(DesignTokens.accentRust)

            Spacer()

            Menu {
                ForEach(DealImageLabel.allCases, id: \.self) { lbl in
                    Button(lbl.rawValue) { batchChangeLabel(to: lbl) }
                }
            } label: {
                Text("[ LABEL ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural,
                                                      lineWidth: DesignTokens.dividerWidth))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                batchDelete()
            } label: {
                Text("[ DELETE ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusCritical)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(Rectangle().strokeBorder(DesignTokens.statusCritical.opacity(0.4),
                                                      lineWidth: DesignTokens.dividerWidth))
            }
            .buttonStyle(.plain)

            Button {
                selectedImageIDs = []
            } label: {
                Text("[ ✕ ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural,
                                                      lineWidth: DesignTokens.dividerWidth))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 6)
        .background(DesignTokens.accentRust.opacity(0.06))
        .animation(.easeInOut(duration: 0.15), value: selectedImageIDs.isEmpty)
    }

    // MARK: Actions

    private func setHero(_ img: DealImage) {
        for i in deal.images { i.isHero = false }
        img.isHero = true
        try? ctx.save()
    }

    private func changeLabel(_ img: DealImage, to lbl: DealImageLabel) {
        img.label = lbl.rawValue
        try? ctx.save()
    }

    private func deleteImage(_ img: DealImage) {
        if img.isHero {
            deal.images.first(where: { $0.id != img.id })?.isHero = true
        }
        deal.images.removeAll { $0.id == img.id }
        ctx.delete(img)
        try? ctx.save()
    }

    private func batchChangeLabel(to lbl: DealImageLabel) {
        deal.images
            .filter { selectedImageIDs.contains($0.id) }
            .forEach { $0.label = lbl.rawValue }
        try? ctx.save()
        selectedImageIDs = []
    }

    private func batchDelete() {
        let targets = deal.images.filter { selectedImageIDs.contains($0.id) }
        let wasHeroDeleted = targets.contains { $0.isHero }
        targets.forEach { img in
            deal.images.removeAll { $0.id == img.id }
            ctx.delete(img)
        }
        if wasHeroDeleted {
            deal.images.first?.isHero = true
        }
        try? ctx.save()
        selectedImageIDs = []
    }

    // MARK: Helpers

    private var filteredImages: [DealImage] {
        let sorted = deal.images.sorted { $0.sortOrder < $1.sortOrder }
        guard let lbl = selectedLabel else { return sorted }
        return sorted.filter { $0.label == lbl.rawValue }
    }

    private func inferLabel(from filename: String) -> DealImageLabel {
        let lower = filename.lowercased()
        if lower.contains("before")  { return .before    }
        if lower.contains("after")   { return .after     }
        if lower.contains("site")    { return .site      }
        if lower.contains("render")  { return .render    }
        if lower.contains("floor")   { return .floorPlan }
        if lower.contains("aerial")  { return .aerial    }
        return .other
    }

    private func shortLabel(_ raw: String) -> String {
        switch raw {
        case DealImageLabel.floorPlan.rawValue: return "FP"
        default:                                return String(raw.prefix(3))
        }
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }
}

// MARK: - CaptionEditorSheet

private struct CaptionEditorSheet: View {

    let image:   DealImage
    let onSave:  (String) -> Void

    @State private var caption: String
    @Environment(\.dismiss) private var dismiss

    init(image: DealImage, onSave: @escaping (String) -> Void) {
        self.image  = image
        self.onSave = onSave
        _caption    = State(initialValue: image.caption)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("// EDIT_CAPTION")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)

            TextField("Caption", text: $caption)
                .font(DesignTokens.TypeScale.rowValue)
                .foregroundStyle(DesignTokens.textPrimary)
                .textFieldStyle(.plain)
                .padding(8)
                .background(DesignTokens.canvasBase)
                .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())

            HStack {
                Button("[ CANCEL ]") { dismiss() }
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .buttonStyle(.plain)

                Spacer()

                Button("[ SAVE ]") {
                    onSave(caption)
                    dismiss()
                }
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.canvasBase)
                .padding(.horizontal, 12)
                .frame(height: DesignTokens.rowHeightButton)
                .background(DesignTokens.accentRust)
                .clipShape(Rectangle())
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(DesignTokens.surfacePanel)
        .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, DealImage.self, configurations: config)
    let deal      = PropertyDeal(
        propertyName: "Lisbon Office Block A",
        latitude:     38.717,
        longitude:    -9.142
    )
    container.mainContext.insert(deal)
    return DealMediaGalleryView(deal: deal)
        .frame(width: 480, height: 700)
        .background(DesignTokens.surfacePanel)
        .modelContainer(container)
}
