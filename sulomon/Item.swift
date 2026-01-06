//
//  Item.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
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
