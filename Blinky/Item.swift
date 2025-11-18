//
//  Item.swift
//  Blinky
//
//  Created by MacOS on 18/11/25.
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
