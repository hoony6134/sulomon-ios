//
//  HealthKitManager.swift
//  sulomon
//
//  Created by 임정훈 on 1/7/26.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // 알코올 섭취량(잔/병 수)을 저장하기 위한 타입
    // iOS 15+ 부터 .numberOfAlcoholicBeverages 사용 가능
    private let alcoholType = HKQuantityType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)!
    
    private init() {}
    
    /// HealthKit 사용 가능 여부 확인 및 권한 요청
    /// - Returns: 권한 요청 프로세스가 성공적으로 완료되었는지 여부
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return false
        }
        
        let typesToShare: Set = [alcoholType]
        let typesToRead: Set<HKObjectType> = [] // 읽기 권한이 필요하다면 추가
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 알코올 섭취 횟수(Units) 저장
    /// - Parameters:
    ///   - units: 마신 개수 (e.g., 1.5)
    ///   - date: 마신 날짜
    func saveAlcoholUnits(units: Double, date: Date) async throws {
        // 권한 상태 확인 (쓰기 권한은 authorizationStatus로 정확히 알 수 없으나, 요청 후 로직 수행)
        // 실제로는 requestAuthorization을 먼저 호출한 뒤 이 함수를 호출해야 함.
        
        let quantity = HKQuantity(unit: .count(), doubleValue: units)
        let sample = HKQuantitySample(type: alcoholType, quantity: quantity, start: date, end: date)
        
        do {
            try await healthStore.save(sample)
            print("Successfully saved \(units) units to HealthKit.")
        } catch {
            print("Failed to save to HealthKit: \(error.localizedDescription)")
            throw error
        }
    }
}
