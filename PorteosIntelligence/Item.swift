//
//  Item.swift
//  PorteosIntelligence
//
//  Created by Howard Duffy on 2026-06-25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
