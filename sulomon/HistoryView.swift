//
//  HistoryView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext // 삭제를 위한 컨텍스트 추가
    @AppStorage("historyBadge") var historyBadge = false
    
    // 최신 기록이 위로 오도록 정렬
    @Query(sort: \DrinkRecord.timestamp, order: .reverse) private var records: [DrinkRecord]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if records.isEmpty {
                    ContentUnavailableView(
                        "기록된 내역이 없습니다",
                        systemImage: "wineglass",
                        description: Text("'추가' 탭에서 첫 번째 음주 기록을 남겨보세요.")
                    )
                } else {
                    // MARK: - List로 변경하여 스와이프 삭제 지원
                    List {
                        ForEach(records) { record in
                            ZStack {
                                // 카드 UI
                                HistoryCard(record: record)
                                
                                // 네비게이션 링크 (투명하게 처리하여 카드 전체 클릭 효과 및 화살표 숨김)
                                NavigationLink(value: record) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // 카드 간 간격 조정
                            .listRowSeparator(.hidden) // 리스트 구분선 제거
                            .listRowBackground(Color.clear) // 리스트 셀 배경 투명화
                        }
                        .onDelete(perform: deleteItems) // 스와이프 삭제 동작 연결
                    }
                    .listStyle(.plain) // 기본 리스트 스타일 제거
                    .scrollContentBackground(.hidden) // 리스트 전체 배경 투명화 (ZStack 배경 보이게)
                }
            }
//            .navigationTitle("기록") // 타이틀이 필요하면 주석 해제
            .navigationDestination(for: DrinkRecord.self) { record in
                HistoryDetailView(record: record)
            }
        }
        .onAppear{
            historyBadge = false
        }
    }
    
    // MARK: - 삭제 로직
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

// MARK: - History Card UI
struct HistoryCard: View {
    let record: DrinkRecord
    
    // 주류 타입별 테마 색상 (배경용, 텍스트용)
    private var themeColors: (bg: Color, text: Color) {
        switch record.type {
        case .soju:      return (Color.green.opacity(0.15), Color.green.opacity(0.8))
        case .beer:      return (Color.yellow.opacity(0.2), Color.orange.opacity(0.8))
        case .somac:     return (Color.brown.opacity(0.15), Color.brown.opacity(0.8))
        case .wine:      return (Color.purple.opacity(0.15), Color.purple.opacity(0.8))
        case .fruitSoju: return (Color.pink.opacity(0.15), Color.pink.opacity(0.8))
        case .liquor:    return (Color.indigo.opacity(0.15), Color.indigo.opacity(0.8))
        case .highball:  return (Color.blue.opacity(0.15), Color.blue.opacity(0.8))
        default:         return (Color.gray.opacity(0.15), Color.gray.opacity(0.8))
        }
    }
    
    // 브랜드 + 단위 텍스트 생성 (e.g. "처음처럼 1.5병")
    private var descriptionText: String {
        let brandName = record.brand ?? (record.type?.rawValue ?? "기타")
        // units가 1.0, 2.0 등 정수면 소수점 제거, 아니면 소수점 표시
        let unitString: String = {
            let u = record.units ?? 0
            return u.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", u) : String(format: "%.1f", u)
        }()
        let unitName = record.unitName ?? "단위"
        return "\(brandName) \(unitString)\(unitName)"
    }
    
    private var formattedDate: String {
        guard let date = record.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 a h:mm" // e.g. 1월 6일 오후 10:30
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 종류 | 날짜
            HStack {
                Text(record.type?.rawValue ?? "기타")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.text) // 종류별 전경색
                    .cornerRadius(8)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 하단: 설명(브랜드+단위) | 하트
            HStack(alignment: .bottom) {
                Text(descriptionText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // HealthKit 연동 여부에 따른 하트
                Image(systemName: (record.healthKitSynced == true) ? "checkmark.circle.fill" : "heart.slash.fill")
                    .font(.title3)
                    .foregroundColor((record.healthKitSynced == true) ? themeColors.text : .gray.opacity(0.5))
            }
        }
        .padding(20)
        .background(themeColors.bg) // 종류별 배경색
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - History Detail View
struct HistoryDetailView: View {
    let record: DrinkRecord
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 헤더 정보
                VStack(spacing: 8) {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: iconName)
                                .font(.largeTitle)
                                .foregroundStyle(iconColor)
                        }
                    
                    Text(record.type?.rawValue ?? "기타")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let date = record.timestamp {
                        Text(date.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)

                // 메인 통계 그리드
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    detailInfoCard(title: "총 알코올 양", value: String(format: "%.1f mL", calculateTotalAlcohol()), icon: "drop.fill", color: .blue)
                    detailInfoCard(title: "마신 양", value: "\(formatUnits()) \(record.unitName ?? "단위")", icon: "mug.fill", color: .orange)
                    detailInfoCard(title: "도수", value: String(format: "%.1f %%", record.alcoholPercent ?? 0), icon: "percent", color: .green)
                    detailInfoCard(title: "1단위 용량", value: String(format: "%.0f mL", record.unitML ?? 0), icon: "ruler", color: .purple)
                }
                .padding(.horizontal)

                // 상세 정보 섹션
                VStack(alignment: .leading, spacing: 20) {
                    detailRow(label: "브랜드", value: record.brand ?? "기록 없음")
                    detailRow(label: "단위당 순수 알코올", value: String(format: "%.1f mL", record.alcoholPerUnit ?? 0))
                    
                    HStack {
                        Text("HealthKit 동기화")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if record.healthKitSynced == true {
                            Label("동기화됨", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Label("동기화 안됨", systemImage: "xmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    if let memo = record.memo, !memo.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("메모")
                                .font(.headline)
                            Text(memo)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(20)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Detail Helpers
    
    private func formatUnits() -> String {
        let u = record.units ?? 0
        return u.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", u) : String(format: "%.1f", u)
    }
    
    private func calculateTotalAlcohol() -> Double {
        let units = record.units ?? 0
        let ml = record.unitML ?? 0
        let percent = record.alcoholPercent ?? 0
        return units * ml * (percent / 100.0)
    }
    
    private var iconName: String {
        switch record.type {
        case .beer, .somac: return "mug.fill"
        case .wine, .liquor, .highball: return "wineglass.fill"
        default: return "waterbottle.fill"
        }
    }
    
    // MARK: - 색상 로직 수정 (HistoryCard와 일치)
    private var iconColor: Color {
        switch record.type {
        case .soju:      return .green
        case .beer:      return .orange
        case .somac:     return .brown
        case .wine:      return .purple
        case .fruitSoju: return .pink
        case .liquor:    return .indigo
        case .highball:  return .blue
        default:         return .gray
        }
    }
    
    private func detailInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(height: 100)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DrinkRecord.self, configurations: config)
    
    let dummy = DrinkRecord(
        type: .soju,
        timestamp: Date(),
        alcoholPercent: 16.0,
        units: 1.5,
        unitML: 360,
        unitName: "병",
        alcoholPerUnit: 57.6,
        brand: "처음처럼",
        memo: "친구들과 즐거운 시간",
        healthKitSynced: true
    )
    container.mainContext.insert(dummy)
    
    return HistoryView()
        .modelContainer(container)
}
