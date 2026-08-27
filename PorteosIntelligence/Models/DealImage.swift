import Foundation
import SwiftData
import AppKit

// MARK: - DealImageLabel

enum DealImageLabel: String, Codable, CaseIterable {
    case before    = "BEFORE"
    case after     = "AFTER"
    case site      = "SITE"
    case render    = "RENDER"
    case floorPlan = "FLOOR_PLAN"
    case aerial    = "AERIAL"
    case other     = "OTHER"
}

// MARK: - DealImage

@Model
final class DealImage {

    var id:            UUID
    var imageData:     Data
    var thumbnailData: Data     // 200×200 max, generated on insert
    var label:         String   // DealImageLabel.rawValue
    var caption:       String
    var isHero:        Bool
    var sortOrder:     Int
    var createdAt:     Date

    init(
        imageData: Data,
        label:     DealImageLabel = .other,
        caption:   String        = "",
        isHero:    Bool          = false,
        sortOrder: Int           = 0
    ) {
        self.id            = UUID()
        self.imageData     = imageData
        self.thumbnailData = DealImage.makeThumbnail(from: imageData)
        self.label         = label.rawValue
        self.caption       = caption
        self.isHero        = isHero
        self.sortOrder     = sortOrder
        self.createdAt     = Date()
    }

    static func makeThumbnail(from data: Data) -> Data {
        guard let src = NSImage(data: data) else { return data }
        let side: CGFloat = 200
        let scale = min(side / src.size.width, side / src.size.height)
        let newSize = CGSize(width: src.size.width * scale, height: src.size.height * scale)
        let img = NSImage(size: newSize)
        img.lockFocus()
        src.draw(in: NSRect(origin: .zero, size: newSize))
        img.unlockFocus()
        return img.tiffRepresentation.flatMap {
            NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        } ?? data
    }
}
