//
//  HistoryView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("historyBadge") var historyBadge = false
    
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
                    List {
                        ForEach(records) { record in
                            ZStack {
                                HistoryCard(record: record)
                                NavigationLink(value: record) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationDestination(for: DrinkRecord.self) { record in
                HistoryDetailView(record: record)
            }
        }
        .onAppear{
            historyBadge = false
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

// MARK: - History Card UI (기존 유지)
struct HistoryCard: View {
    let record: DrinkRecord
    
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
    
    private var descriptionText: String {
        let brandName = record.brand ?? (record.type?.rawValue ?? "기타")
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
        formatter.dateFormat = "M월 d일 a h:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.type?.rawValue ?? "기타")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.text)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom) {
                Text(descriptionText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: (record.healthKitSynced == true) ? "checkmark.circle.fill" : "heart.slash.fill")
                    .font(.title3)
                    .foregroundColor((record.healthKitSynced == true) ? themeColors.text : .gray.opacity(0.5))
            }
        }
        .padding(20)
        .background(themeColors.bg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - History Detail View (수정됨)
struct HistoryDetailView: View {
    // 수정을 위해 @Bindable 사용 (iOS 17+)
    @Bindable var record: DrinkRecord
    
    // 날짜 수정 시트 상태
    @State private var isEditingDate = false
    @State private var tempDate = Date()
    @State private var showHealthKitAlert = false
    
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
                    
                    // 날짜 표시 및 수정 버튼
                    if let date = record.timestamp {
                        HStack(spacing: 6) {
                            Text(date.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                tempDate = date
                                isEditingDate = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // 기분(Feeling) 이모지 표시 (데이터에 있다면)
                    if let feeling = record.feeling {
                        Text("\(feeling.emoji) \(feeling.label)")
                            .font(.headline)
                            .padding(.top, 4)
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
                    
                    // 함께한 사람 표시 추가
                    if let people = record.people, !people.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("함께한 사람")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(people) { person in
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .font(.caption)
                                            Text(person.name ?? "이름 없음")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }

                    Divider()
                    
                    // HealthKit 상태 표시
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
        // 날짜 수정 Sheet
        .sheet(isPresented: $isEditingDate) {
            NavigationStack {
                VStack {
                    DatePicker("날짜 및 시간", selection: $tempDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("날짜 수정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isEditingDate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            updateDateAndHealthKit()
                            isEditingDate = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("HealthKit 업데이트", isPresented: $showHealthKitAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("날짜가 변경되어 HealthKit에 새로운 기록이 추가되었습니다.\n(기존 데이터는 수동 삭제가 필요할 수 있습니다)")
        }
    }
    
    // MARK: - Update Logic
    private func updateDateAndHealthKit() {
        // 1. SwiftData 날짜 업데이트 (자동 저장됨)
        record.timestamp = tempDate
        
        // 2. HealthKit 연동 상태라면 업데이트 시도
        // 주의: 기존 HealthKit 데이터를 삭제할 UUID가 없으므로, 새로운 날짜로 데이터를 추가하는 방식을 사용합니다.
        if record.healthKitSynced == true, let units = record.units, units > 0 {
            Task {
                do {
                    // 권한 확인
                    let authorized = try await HealthKitManager.shared.requestAuthorization()
                    if authorized {
                        // 변경된 날짜로 새로 저장
                        try await HealthKitManager.shared.saveAlcoholUnits(units: units, date: tempDate)
                        
                        await MainActor.run {
                            showHealthKitAlert = true
                        }
                    }
                } catch {
                    print("HealthKit Update Error: \(error)")
                }
            }
        }
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
    
    private var iconColor: Color {
        switch record.type {
        case .soju: return .green
        case .beer: return .orange
        case .wine: return .purple
        case .somac: return .brown
        case .fruitSoju: return .pink
        case .liquor: return .indigo
        case .highball: return .blue
        default: return .blue
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
    let container = try! ModelContainer(for: DrinkRecord.self, Person.self, configurations: config)
    
    let person1 = Person(name: "김철수")
    let person2 = Person(name: "이영희")
    container.mainContext.insert(person1)
    container.mainContext.insert(person2)
    
    let dummy = DrinkRecord(
        type: .soju,
        people: [person1, person2],
        timestamp: Date(),
        alcoholPercent: 16.0,
        units: 1.5,
        unitML: 360,
        unitName: "병",
        alcoholPerUnit: 57.6,
        brand: "처음처럼",
        memo: "친구들과 즐거운 시간",
        healthKitSynced: true,
        feeling: .moderate
    )
    container.mainContext.insert(dummy)
    
    return HistoryView()
        .modelContainer(container)
}
