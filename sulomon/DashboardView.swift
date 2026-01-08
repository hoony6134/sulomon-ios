//
//  DashboardView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    // 최신순 정렬 데이터
    @Query(sort: \DrinkRecord.timestamp, order: .reverse) private var records: [DrinkRecord]
    
    // 캘린더용 현재 날짜 상태
    @State private var currentMonth: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack{
                        Text("나의 간")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    // 1. 금주 스트릭 (최상단 강조)
                    SobrietyStreakCard(latestRecord: records.first)
                    
                    // 2. 이번 달 음주 캘린더
                    DashboardCalendarView(currentMonth: $currentMonth, records: records)
                    
                    // 3. 예상 주량 (분석)
                    ToleranceAnalysisCard(records: records)
                    
                    // 4. 최고의 술메이트
                    BestMateCard(records: records)
                    
                    // 5. 최근 음주 기록
                    VStack(alignment: .leading, spacing: 12) {
                        Text("최근 기록")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if let latest = records.first {
                            NavigationLink(destination: HistoryDetailView(record: latest)) {
                                HistoryCard(record: latest) // HistoryView의 카드 재사용
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        } else {
                            Text("아직 기록이 없습니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
//            .background(Color(uiColor: .systemGroupedBackground))
//            .navigationTitle("대시보드")
        }
    }
}

// MARK: - 1. 금주 스트릭 카드
struct SobrietyStreakCard: View {
    let latestRecord: DrinkRecord?
    
    private var daysSinceLastDrink: Int {
        guard let lastDate = latestRecord?.timestamp else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: lastDate)
        let end = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(latestRecord == nil ? "음주 기록을 시작해보세요" : "마지막 술자리로부터")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(daysSinceLastDrink)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.blue)
                    Text("일째")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("금주 중 🍃")
                        .font(.title3)
                }
            }
            Spacer()
        }
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - 2. 캘린더 뷰
struct DashboardCalendarView: View {
    @Binding var currentMonth: Date
    let records: [DrinkRecord]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // 이번 달에 술 마신 날짜들 (Set for O(1) lookup)
    private var drinkingDays: Set<Int> {
        let filtered = records.filter {
            calendar.isDate($0.timestamp ?? Date(), equalTo: currentMonth, toGranularity: .month)
        }
        let days = filtered.compactMap {
            calendar.dateComponents([.day], from: $0.timestamp ?? Date()).day
        }
        return Set(days)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더 (월 이동)
            HStack {
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(.blue)
            }
            
            // 요일 헤더
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let day = calendar.component(.day, from: date)
                        let isDrinkingDay = drinkingDays.contains(day)
                        let isToday = calendar.isDateInToday(date)
                        
                        ZStack {
                            Circle()
                                .fill(isDrinkingDay ? Color.blue.opacity(0.15) : (isToday ? Color.gray.opacity(0.1) : Color.clear))
                            
                            if isDrinkingDay {
                                Image(systemName: "wineglass.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .offset(y: 8)
                            }
                            
                            Text("\(day)")
                                .font(.system(size: 14))
                                .fontWeight(isDrinkingDay || isToday ? .bold : .regular)
                                .foregroundStyle(isDrinkingDay ? .blue : .primary)
                                .offset(y: isDrinkingDay ? -6 : 0)
                        }
                        .frame(height: 40)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // 1일 앞의 빈 날짜들 (일요일=1)
        let leadingSpaces = Array(repeating: nil as Date?, count: firstWeekday - 1)
        
        // 실제 날짜들
        let days = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
        }
        
        return leadingSpaces + days
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

// MARK: - 3. 예상 주량 분석 카드
struct ToleranceAnalysisCard: View {
    let records: [DrinkRecord]
    
    // 주량 계산 로직
    // '적당히 취함(moderate, 3)'으로 기록된 데이터들의 평균 순수 알코올 양을 계산
    // 만약 데이터가 없으면 '약간 취함(light, 2)' 데이터 참고
    private var estimatedSojuCapacity: Double {
        let targetRecords = records.filter { $0.feeling == .moderate }
        let secondaryRecords = records.filter { $0.feeling == .light }
        
        let validRecords = targetRecords.isEmpty ? secondaryRecords : targetRecords
        if validRecords.isEmpty { return 0 }
        
        let totalPureAlcohol = validRecords.reduce(0.0) { partialResult, record in
            let units = record.units ?? 0
            let ml = record.unitML ?? 0
            let percent = record.alcoholPercent ?? 0
            return partialResult + (units * ml * (percent / 100.0))
        }
        
        let averageAlcohol = totalPureAlcohol / Double(validRecords.count)
        
        // 소주 1병 (360ml, 16%) 기준 순수 알코올 = 약 57.6g
        let sojuOneBottleAlcohol = 360.0 * 0.16
        return averageAlcohol / sojuOneBottleAlcohol
    }
    
    private var message: String {
        if estimatedSojuCapacity == 0 {
            return "기록을 더 쌓으면 분석해드릴게요!"
        } else if estimatedSojuCapacity < 1.0 {
            return "술은 분위기로 즐기는 편이네요 🍹"
        } else if estimatedSojuCapacity < 2.0 {
            return "평균적인 주량을 가지고 계시네요 🙂"
        } else {
            return "상당한 애주가시군요! 간 건강 챙기세요 💪"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                Text("예상 주량 (소주 기준)")
                    .font(.headline)
            }
            
            if estimatedSojuCapacity > 0 {
                HStack(alignment: .lastTextBaseline) {
                    Text(String(format: "%.1f", estimatedSojuCapacity))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                    Text("병")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                
                // 간단한 게이지 바
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple)
                            .frame(width: min(geo.size.width * (estimatedSojuCapacity / 3.0), geo.size.width), height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.top, 4)
                
                Text("'적당히 취함' 🥴 상태의 기록을 분석했습니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
            } else {
                Text("데이터가 부족합니다.\n'적당히 취함' 상태로 기록을 남겨보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - 4. 최고의 술메이트 카드
struct BestMateCard: View {
    let records: [DrinkRecord]
    
    private var bestMate: (person: Person, count: Int)? {
        var counts: [Person: Int] = [:]
        
        for record in records {
            if let people = record.people {
                for person in people {
                    counts[person, default: 0] += 1
                }
            }
        }
        
        // 가장 많이 카운트된 사람 찾기
        if let max = counts.max(by: { $0.value < $1.value }) {
            return (max.key, max.value)
        }
        return nil
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.indigo)
                    Text("최고의 술메이트")
                        .font(.headline)
                }
                
                if let mate = bestMate {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                            .padding(8)
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(mate.person.name ?? "이름 없음")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("함께 \(mate.count)회")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("아직 함께 마신 기록이 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    // Preview Setup
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DrinkRecord.self, Person.self, configurations: config)
    
    // Add Dummy Data
    let person = Person(name: "김술친구")
    container.mainContext.insert(person)
    
    let record1 = DrinkRecord(type: .soju, people: [person], timestamp: Date(), alcoholPercent: 16, units: 2, unitML: 360, unitName: "병", alcoholPerUnit: 57.6, feeling: .moderate)
    let record2 = DrinkRecord(type: .beer, people: [person], timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, alcoholPercent: 4.5, units: 3, unitML: 500, unitName: "잔", alcoholPerUnit: 22.5, feeling: .light)
    
    container.mainContext.insert(record1)
    container.mainContext.insert(record2)
    
    return DashboardView()
        .modelContainer(container)
}
