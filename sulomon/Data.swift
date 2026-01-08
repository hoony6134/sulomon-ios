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
    
    // N:M 관계 설정
    @Relationship(inverse: \DrinkRecord.people)
    var drinks: [DrinkRecord]? = []
    
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

// MARK: - 취기 레벨 Enum 추가
enum IntoxicationFeeling: Int, Codable, CaseIterable {
    case fine = 1      // 완전 멀쩡
    case light = 2     // 약간 취함
    case moderate = 3  // 적당히 취함
    case heavy = 4     // 꽤 취함
    case wasted = 5    // 꽐라
    
    var emoji: String {
        switch self {
        case .fine: return "😃"
        case .light: return "☺️"
        case .moderate: return "🥴"
        case .heavy: return "😵‍💫"
        case .wasted: return "🧟"
        }
    }
    
    var label: String {
        switch self {
        case .fine: return "완전 멀쩡"
        case .light: return "약간 취함"
        case .moderate: return "적당히 취함"
        case .heavy: return "꽤 취함"
        case .wasted: return "꽐라"
        }
    }
}

@Model
final class DrinkRecord: Identifiable {
    var id: UUID?
    var type: AlcoholType?

    // 관계 설정
    @Relationship
    var people: [Person]? = []

    // 공통 메타데이터
    var timestamp: Date?
    var alcoholPercent: Double?
    var units: Double?

    // 섭취 단위 기준
    var alcoholPerUnit: Double?
    var unitML: Double?
    var unitName: String?

    // 선택 메타데이터
    var brand: String?
    var memo: String?
    var healthKitSynced: Bool? = false
    
    // 추가된 취기 데이터
    var feeling: IntoxicationFeeling?

    init(
        id: UUID? = UUID(),
        type: AlcoholType? = AlcoholType.etc,
        people: [Person]? = [],
        timestamp: Date = .now,
        alcoholPercent: Double?,
        units: Double?,
        unitML: Double?,
        unitName: String?,
        alcoholPerUnit: Double?,
        brand: String? = nil,
        memo: String? = nil,
        healthKitSynced: Bool? = false,
        feeling: IntoxicationFeeling? = nil // Init 추가
    ) {
        self.id = id
        self.type = type
        self.people = people
        self.timestamp = timestamp
        self.alcoholPercent = alcoholPercent
        self.units = units
        self.unitML = unitML
        self.unitName = unitName
        self.alcoholPerUnit = alcoholPerUnit
        self.brand = brand
        self.memo = memo
        self.healthKitSynced = healthKitSynced
        self.feeling = feeling
    }
}
