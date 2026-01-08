//
//  PeopleView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    
    @State private var showAddAlert = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            VStack {
                if people.isEmpty {
                    ContentUnavailableView(
                        "등록된 사람이 없습니다",
                        systemImage: "person.3.fill",
                        description: Text("우측 상단의 + 버튼을 눌러\n함께 마시는 사람들을 추가해보세요.")
                    )
                } else {
//                    HStack{
//                        Text("나의 술 메이트")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                        Spacer()
//                    }
//                    .padding(.horizontal)
                    List {
                        ForEach(people) { person in
                            ZStack {
                                // 카드 UI
                                PersonCard(person: person)
                                
                                // 네비게이션 링크 (투명 처리)
                                NavigationLink(destination: PersonDetailView(person: person)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deletePeople)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("나의 술 메이트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        newName = ""
                        showAddAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("새로운 사람 추가", isPresented: $showAddAlert) {
                TextField("이름 입력", text: $newName)
                Button("취소", role: .cancel) { }
                Button("추가") {
                    addPerson()
                }
            } message: {
                Text("함께 마시는 친구나 지인의 이름을 입력하세요.")
            }
        }
    }
    
    private func addPerson() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let newPerson = Person(name: trimmedName)
        modelContext.insert(newPerson)
    }
    
    private func deletePeople(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(people[index])
            }
        }
    }
}

// MARK: - Person Card UI
struct PersonCard: View {
    let person: Person
    
    // 사람 카드는 Indigo/Blue 계열의 단일 테마 사용 (HistoryCard와 통일성 유지)
    private var themeColors: (bg: Color, text: Color) {
        return (Color.indigo.opacity(0.15), Color.indigo.opacity(0.8))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 아이콘 | 이름
            HStack {
                Image(systemName: "person.fill")
                    .font(.headline)
                    .foregroundColor(themeColors.text)
                    .padding(8)
                    .background(themeColors.text.opacity(0.1))
                    .clipShape(Circle())
                
                Text(person.name ?? "이름 없음")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.text)
                
                Spacer()
            }
            
            // 하단: 요약 정보 (함께한 횟수)
            HStack(alignment: .bottom) {
                Text("함께한 기록")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("\(person.drinks?.count ?? 0)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("회")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                }
            }
        }
        .padding(20)
        .background(themeColors.bg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Person Detail View
struct PersonDetailView: View {
    let person: Person
    @Environment(\.modelContext) private var modelContext
    
    // 해당 사람의 기록을 최신순으로 정렬
    private var sortedDrinks: [DrinkRecord] {
        person.drinks?.sorted(by: { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }) ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 헤더 정보
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Color.indigo)
                        }
                    
                    Text(person.name ?? "이름 없음")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastDate = sortedDrinks.first?.timestamp {
                        Text("마지막 만남: \(lastDate.formatted(date: .numeric, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("아직 함께한 기록이 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)

                // 메인 통계 그리드
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    detailInfoCard(title: "총 만남 횟수", value: "\(sortedDrinks.count)회", icon: "calendar", color: .indigo)
                    detailInfoCard(title: "선호 주종", value: getFavoriteDrink(), icon: "star.fill", color: .orange)
                }
                .padding(.horizontal)

                // 함께한 기록 리스트 섹션
                if !sortedDrinks.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("함께한 기록")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(sortedDrinks) { record in
                            // HistoryView의 HistoryCard를 재사용하여 디자인 통일
                            NavigationLink(destination: HistoryDetailView(record: record)) {
                                HistoryCard(record: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                } else {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "list.bullet.clipboard",
                        description: Text("이 사람과 함께한 술자리를 기록해보세요.")
                    )
                    .padding(.top, 40)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Methods
    
    private func getFavoriteDrink() -> String {
        guard !sortedDrinks.isEmpty else { return "-" }
        let counts = Dictionary(grouping: sortedDrinks, by: { $0.type }).mapValues { $0.count }
        if let max = counts.max(by: { $0.value < $1.value }) {
            return max.key?.rawValue ?? "기타"
        }
        return "기타"
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, DrinkRecord.self, configurations: config)
    
    let person = Person(name: "김철수")
    container.mainContext.insert(person)
    
    // 테스트용 기록 추가
    let record = DrinkRecord(
        type: .soju,
        people: [person], // 관계 설정
        timestamp: Date(),
        alcoholPercent: 16.0,
        units: 2,
        unitML: 360,
        unitName: "병",
        alcoholPerUnit: 57.6,
        brand: "참이슬"
    )
    container.mainContext.insert(record)
    
    return PeopleView()
        .modelContainer(container)
}
