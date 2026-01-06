//
//  Data.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import Foundation
import SwiftData

@Model
final class Person: Identifiable {
    var id: UUID?
    var name: String?
    
    init(id: UUID? = UUID(), name: String? = "알 수 없음") {
        self.id = id
        self.name = name
    }
}

enum AlcoholType: String, Codable, CaseIterable {
    case soju = "소주"
    case beer = "맥주"
    case somac = "소맥"
    case wine = "와인"
    case fruitSoju = "과일소주"
    case liquor = "양주"
    case highball = "하이볼"
    case etc = "기타"
    
    static var allCases: [AlcoholType] = [.soju, .beer, .somac, .wine, .fruitSoju, .liquor, .highball, .etc]
}

@Model
final class DrinkRecord: Identifiable {
    var id: UUID?
    var type: AlcoholType?

    // 공통 메타데이터
    var timestamp: Date?
    var alcoholPercent: Double?      // 도수 (%)
    var units: Double?

    // 섭취 단위 기준
    var alcoholPerUnit: Double?  // 잔당 순수 알코올 양 (mL)
    var unitML: Double?        // 한 잔 기준 용량 (mL)
    var unitName: String?

    // 선택 메타데이터
    var brand: String?
    var memo: String?
    var healthKitSynced: Bool? = false

    init(
        id: UUID? = UUID(),
        type: AlcoholType? = AlcoholType.etc,
        timestamp: Date = .now,
        alcoholPercent: Double?,
        units: Double?,
        unitML: Double?,
        unitName: String?,
        alcoholPerUnit: Double?,
        brand: String? = nil,
        memo: String? = nil,
        healthKitSynced: Bool? = false
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.alcoholPercent = alcoholPercent
        self.units = units
        self.unitML = unitML
        self.unitName = unitName
        self.alcoholPerUnit = alcoholPerUnit
        self.brand = brand
        self.memo = memo
        self.healthKitSynced = healthKitSynced
    }
}
