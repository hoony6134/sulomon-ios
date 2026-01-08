//
//  RecordStep2View.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

struct RecordStep2View: View {
    @AppStorage("historyBadge") var historyBadge: Bool = false
    
    // MARK: - SwiftData Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // 모든 사람 데이터 가져오기
    @Query private var allPeople: [Person]
    
    // 선택된 사람 관리
    @State private var selectedPeople: Set<Person> = []
    
    // 선택된 기분 관리
    @State private var selectedFeeling: IntoxicationFeeling? = nil

    // MARK: - External Data / Bindings
    @State var type: AlcoholType
    @State var alcoholPercent: Double = 0.0
    @State var brand: String? = nil
    
    // MARK: - Internal UI Layout
    private let twoColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private let adaptiveColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]

    // MARK: - Preset Models (AlcoholPreset, UnitPreset) - 생략 없이 포함
    private struct AlcoholPreset: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let percent: Double
        let brand: String?
    }

    private var presets: [AlcoholPreset]? {
        switch type {
        case .soju:
            return [
                .init(title: "처음처럼", percent: 16.0, brand: "처음처럼"),
                .init(title: "참이슬", percent: 16.0, brand: "참이슬"),
                .init(title: "참이슬 오리지널", percent: 20.1, brand: "참이슬 오리지널"),
                .init(title: "진로", percent: 16.0, brand: "진로"),
                .init(title: "새로", percent: 16.0, brand: "새로"),
                .init(title: "기타", percent: alcoholPercent == 0 ? 16.0 : alcoholPercent, brand: nil)
            ]
        case .beer:
            return [
                .init(title: "카스 프레시", percent: 4.5, brand: "카스 프레시"),
                .init(title: "카스 라이트", percent: 4.0, brand: "카스 라이트"),
                .init(title: "테라", percent: 4.6, brand: "테라"),
                .init(title: "테라 라이트", percent: 4.0, brand: "테라 라이트"),
                .init(title: "켈리", percent: 4.5, brand: "켈리"),
                .init(title: "크러쉬", percent: 4.5, brand: "크러쉬"),
                .init(title: "기타", percent: alcoholPercent == 0 ? 4.5 : alcoholPercent, brand: nil)
            ]
        case .fruitSoju:
            return [
                .init(title: "새로 다래", percent: 12.0, brand: "새로 다래"),
                .init(title: "새로 살구", percent: 12.0, brand: "새로 살구"),
                .init(title: "자몽에 이슬", percent: 13.0, brand: "자몽에 이슬"),
                .init(title: "청포도에 이슬", percent: 13.0, brand: "청포도에 이슬"),
                .init(title: "기타", percent: alcoholPercent == 0 ? 12.0 : alcoholPercent, brand: nil)
            ]
        default:
            return nil
        }
    }

    private struct UnitPreset: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let ml: Double
        let isOther: Bool
    }

    private var unitPresets: [UnitPreset] {
        switch type {
        case .soju, .fruitSoju:
            return [
                .init(title: "병", ml: 360, isOther: false),
                .init(title: "잔", ml: 50, isOther: false),
                .init(title: "페트", ml: 400, isOther: false),
                .init(title: "종이컵", ml: 140, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 360 : unitML, isOther: true)
            ]
        case .beer:
            return [
                .init(title: "잔", ml: 225, isOther: false),
                .init(title: "큰잔", ml: 355, isOther: false),
                .init(title: "500cc", ml: 500, isOther: false),
                .init(title: "1000cc", ml: 1000, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 225 : unitML, isOther: true)
            ]
        case .somac:
            return [
                .init(title: "잔", ml: 225, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 225 : unitML, isOther: true)
            ]
        case .wine:
            return [
                .init(title: "잔", ml: 100, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 100 : unitML, isOther: true)
            ]
        case .liquor:
            return [
                .init(title: "샷 잔", ml: 30, isOther: false),
                .init(title: "온더락 잔", ml: 370, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 30 : unitML, isOther: true)
            ]
        case .highball:
            return [
                .init(title: "글라스", ml: 240, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 240 : unitML, isOther: true)
            ]
        case .etc:
            return [
                .init(title: "소주잔", ml: 50, isOther: false),
                .init(title: "맥주잔", ml: 225, isOther: false),
                .init(title: "기타", ml: unitML == 0 ? 50 : unitML, isOther: true)
            ]
        }
    }

    // MARK: - State Properties
    @State private var selectedPresetTitle: String? = nil
    @State private var manualBrandText: String = ""

    @State private var unitCount: Double = 0.0
    @State private var unitName: String = ""
    @State private var unitML: Double = 0.0
    
    @State private var selectedUnitTitle: String? = nil
    @State private var isUnitMLExpanded: Bool = false
    @State private var manualUnitNameText: String = ""
    @State private var manualUnitMLText: String = ""
    
    @State private var isSaving: Bool = false
    @State private var showSaveAlert: Bool = false

    // MARK: - Computed Properties
    
    private var isStep1Ready: Bool {
        let hasPercent = (alcoholPercent != 0) || (defaultPercent != 0)
        if let presets {
            return selectedPresetTitle != nil && hasPercent
        }
        return hasPercent
    }

    private var shouldShowStep2: Bool { isStep1Ready }
    
    private var shouldShowStep3: Bool {
        shouldShowStep2 && unitCount > 0
    }

    private var totalPureAlcohol: Double {
        let percent = (alcoholPercent == 0 && defaultPercent != 0) ? defaultPercent : alcoholPercent
        return unitCount * unitML * (percent / 100.0)
    }
    
    private var alcoholPerUnit: Double {
        let percent = (alcoholPercent == 0 && defaultPercent != 0) ? defaultPercent : alcoholPercent
        return unitML * (percent / 100.0)
    }

    private var defaultPercent: Double {
        switch type {
        case .somac: return 7.6
        case .wine: return 12.0
        case .liquor: return 40.0
        default: return 0.0
        }
    }
    
    private var needsManualBrand: Bool {
        switch type {
        case .wine, .liquor, .highball, .etc: return true
        case .somac: return false
        default: return false
        }
    }

    private var needsManualBrandWhenPreset: Bool {
        guard let selectedPresetTitle else { return false }
        return selectedPresetTitle == "기타"
    }
    
    private var sortedPeople: [Person] {
        allPeople.sorted { ($0.drinks?.count ?? 0) > ($1.drinks?.count ?? 0) }
    }

    // MARK: - Helpers
    
    private func parseManualUnitML() -> Double? {
        let filtered = manualUnitMLText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if filtered.isEmpty { return nil }
        return Double(filtered)
    }

    private func fieldContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
    }

    private func presetTile(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(isSelected ? 0.20 : 0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color.primary.opacity(0.35) : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            )
    }
    
    // MARK: - Save Logic
    private func saveData() {
        isSaving = true
        
        let percentToSave = (alcoholPercent == 0 && defaultPercent != 0) ? defaultPercent : alcoholPercent
        
        let newRecord = DrinkRecord(
            type: type,
            people: Array(selectedPeople),
            timestamp: Date(),
            alcoholPercent: percentToSave,
            units: unitCount,
            unitML: unitML,
            unitName: unitName,
            alcoholPerUnit: alcoholPerUnit,
            brand: brand,
            healthKitSynced: false,
            feeling: selectedFeeling // 저장!
        )
        
        modelContext.insert(newRecord)
        
        Task {
            if unitCount > 0 {
                do {
                    let authorized = try await HealthKitManager.shared.requestAuthorization()
                    if authorized {
                        try await HealthKitManager.shared.saveAlcoholUnits(units: unitCount, date: newRecord.timestamp ?? Date())
                        newRecord.healthKitSynced = true
                    }
                } catch {
                    print("HealthKit Error: \(error)")
                }
            }
            
            await MainActor.run {
                isSaving = false
                showSaveAlert = true
            }
        }
    }

    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Step 1
                    VStack(spacing: 16) {
                        HStack {
                            Text("Step 1")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("브랜드/도수 선택")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Presets Grid
                        if let presets {
                            LazyVGrid(columns: twoColumns, spacing: 12) {
                                ForEach(presets) { preset in
                                    Button {
                                        selectedPresetTitle = preset.title
                                        if type == .somac { brand = nil } else { brand = preset.brand }
                                        alcoholPercent = preset.percent
                                        if preset.brand != nil { manualBrandText = preset.brand ?? "" }
                                    } label: {
                                        presetTile(preset.title, isSelected: selectedPresetTitle == preset.title)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            if needsManualBrandWhenPreset {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("브랜드 (선택)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    fieldContainer {
                                        TextField("미입력 시 '기타'로 표기", text: $manualBrandText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .onChange(of: manualBrandText) { _, newValue in
                                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                                brand = trimmed.isEmpty ? nil : trimmed
                                            }
                                    }
                                }
                            }
                        } else {
                            if needsManualBrand {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(type == .highball || type == .etc ? "종류" : "브랜드")
                                        .font(.caption).foregroundStyle(.secondary)
                                    fieldContainer {
                                        TextField("직접 입력", text: $manualBrandText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .onChange(of: manualBrandText) { _, newValue in
                                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                                brand = trimmed.isEmpty ? nil : trimmed
                                            }
                                    }
                                }
                            }
                        }

                        // Percent
                        VStack(alignment: .leading, spacing: 8) {
                            Text("도수")
                                .font(.caption).foregroundStyle(.secondary)
                            fieldContainer {
                                HStack(spacing: 10) {
                                    TextField("예: 16.0", text: Binding(
                                        get: {
                                            if alcoholPercent == 0, defaultPercent != 0 {
                                                return String(format: "%.1f", defaultPercent)
                                            }
                                            return alcoholPercent == 0 ? "" : String(format: "%.1f", alcoholPercent)
                                        },
                                        set: { newValue in
                                            let filtered = newValue.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
                                            if filtered.isEmpty {
                                                alcoholPercent = 0
                                                return
                                            }
                                            if let v = Double(filtered) { alcoholPercent = v }
                                        }
                                    ))
                                    .keyboardType(.decimalPad)
                                    Spacer(minLength: 0)
                                    Text("%").font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // MARK: - Step 2
                    if shouldShowStep2 {
                        VStack(spacing: 16) {
                            Divider()
                            
                            HStack {
                                Text("Step 2")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("용량 및 단위 선택")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .id("Step2Header")

                            // 1. 음주량 + 0.5 Button
                            VStack(alignment: .leading, spacing: 8) {
                                Text("음주량 (개수)")
                                    .font(.caption).foregroundStyle(.secondary)
                                fieldContainer {
                                    HStack(spacing: 10) {
                                        TextField("예: 1.5", text: Binding(
                                            get: { unitCount == 0 ? "" : String(format: "%g", unitCount) },
                                            set: { newValue in
                                                let filtered = newValue.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
                                                if filtered.isEmpty {
                                                    unitCount = 0
                                                    return
                                                }
                                                if let v = Double(filtered) { unitCount = v }
                                            }
                                        ))
                                        .keyboardType(.decimalPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        
                                        // +0.5 Button
                                        Button {
                                            unitCount += 0.5
                                        } label: {
                                            Text("+0.5")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .cornerRadius(20)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Spacer(minLength: 4)
                                        
                                        Text(unitName.isEmpty ? "단위" : unitName)
                                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                                    }
                                }
                            }

                            // 2. Unit Presets
                            LazyVGrid(columns: twoColumns, spacing: 12) {
                                ForEach(unitPresets) { unit in
                                    Button {
                                        selectedUnitTitle = unit.title
                                        unitML = unit.ml
                                        if unit.isOther {
                                            unitName = manualUnitNameText.isEmpty ? "기타" : manualUnitNameText
                                            isUnitMLExpanded = true
                                            if manualUnitNameText.isEmpty { manualUnitNameText = "" }
                                            manualUnitMLText = (unitML == 0) ? "" : String(format: "%.0f", unitML)
                                        } else {
                                            unitName = unit.title
                                            isUnitMLExpanded = false
                                            manualUnitNameText = unit.title
                                            manualUnitMLText = String(format: "%.0f", unit.ml)
                                        }
                                    } label: {
                                        presetTile(unit.title, isSelected: selectedUnitTitle == unit.title)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // 3. Unit Detail
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("단위 상세 설정")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.18)) { isUnitMLExpanded.toggle() }
                                    } label: {
                                        Text(isUnitMLExpanded ? "접기" : "더보기")
                                            .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if isUnitMLExpanded {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("단위명").font(.caption2).foregroundStyle(.secondary)
                                            fieldContainer {
                                                TextField("예: 잔/병/글라스", text: $manualUnitNameText)
                                                    .onChange(of: manualUnitNameText) { _, newValue in
                                                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                                        unitName = trimmed.isEmpty ? "기타" : trimmed
                                                    }
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("1단위 용량 (mL)").font(.caption2).foregroundStyle(.secondary)
                                            fieldContainer {
                                                HStack(spacing: 10) {
                                                    TextField("예: 360", text: $manualUnitMLText)
                                                        .keyboardType(.decimalPad)
                                                        .onChange(of: manualUnitMLText) { _, _ in
                                                            if let v = parseManualUnitML() { unitML = v }
                                                        }
                                                    Spacer(minLength: 0)
                                                    Text("mL").font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("단위당 알코올").font(.caption).foregroundStyle(.secondary)
                                                Spacer()
                                                Text(String(format: "%.1f mL", alcoholPerUnit)).font(.subheadline).fontWeight(.semibold)
                                            }
                                            Divider()
                                            HStack {
                                                Text("총 알코올 양").font(.caption).foregroundStyle(.primary)
                                                Spacer()
                                                Text(String(format: "%.1f mL", totalPureAlcohol))
                                                    .font(.headline).fontWeight(.bold).foregroundStyle(.blue)
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    } // End Step 2
                    
                    // MARK: - Step 3 (People & Feeling)
                    if shouldShowStep3 {
                        VStack(spacing: 24) {
                            Divider()
                            
                            // 1. 함께한 사람
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Step 3")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("함께한 사람 (선택)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .id("Step3Header")
                                
                                if sortedPeople.isEmpty {
                                    Text("등록된 사람이 없습니다.\n'사람 관리' 탭에서 친구를 추가해보세요.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                } else {
                                    LazyVGrid(columns: adaptiveColumns, spacing: 10) {
                                        ForEach(sortedPeople) { person in
                                            let isSelected = selectedPeople.contains(person)
                                            Button {
                                                if isSelected {
                                                    selectedPeople.remove(person)
                                                } else {
                                                    selectedPeople.insert(person)
                                                }
                                            } label: {
                                                HStack {
                                                    Text(person.name ?? "이름 없음")
                                                        .font(.subheadline)
                                                        .fontWeight(isSelected ? .semibold : .regular)
                                                    
                                                    if isSelected {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                            .font(.caption)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(isSelected ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                                                )
                                                .foregroundColor(isSelected ? .blue : .primary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // 2. 취기 선택 (Step 4)
                            VStack(spacing: 16) {
                                HStack {
                                    Text("취기 선택")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    if let feeling = selectedFeeling {
                                        Text(feeling.label)
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                            .fontWeight(.bold)
                                            .transition(.opacity)
                                    }
                                }
                                
                                HStack(spacing: 0) {
                                    ForEach(IntoxicationFeeling.allCases, id: \.self) { feeling in
                                        let isSelected = selectedFeeling == feeling
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                if selectedFeeling == feeling {
                                                    selectedFeeling = nil // 토글 (선택 해제)
                                                } else {
                                                    selectedFeeling = feeling
                                                }
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                Text(feeling.emoji)
                                                    .font(.system(size: isSelected ? 38 : 30))
                                                    .scaleEffect(isSelected ? 1.1 : 1.0)
                                                
                                                // 선택된 경우 라벨 표시 (옵션)
                                                // 공간이 좁으면 이모지만 크게 보여주고 상단 텍스트로 대체
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 70)
                                            .background(
                                                Circle()
                                                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                            }
                        }
                        .transition(.opacity)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal)
            }
            .onChange(of: shouldShowStep2) { _, ready in
                if ready {
                    if alcoholPercent == 0, defaultPercent != 0 { alcoholPercent = defaultPercent }
                    if type == .somac { brand = nil }
                    if selectedUnitTitle == nil { initializeStep2Defaults() }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("Step2Header", anchor: .top)
                        }
                    }
                }
            }
            .onChange(of: shouldShowStep3) { _, ready in
                if ready {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("Step3Header", anchor: .bottom)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if shouldShowStep2 {
                    Button(action: saveData) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            Text("저장하기")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(unitCount > 0 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(unitCount <= 0 || isSaving)
                    .padding()
//                    .background(
//                        LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
//                            .padding(.top, -20)
//                    )
                }
            }
        }
        .onAppear {
            if presets == nil {
                if defaultPercent != 0, alcoholPercent == 0 { alcoholPercent = defaultPercent }
                if type == .somac { brand = nil }
            }
            if selectedUnitTitle == nil { initializeStep2Defaults() }
        }
        .alert("저장 완료", isPresented: $showSaveAlert) {
            Button("확인") {
                historyBadge = true
                dismiss()
            }
        } message: {
            Text("기록이 성공적으로 저장되었습니다.")
        }
    }
    
    private func initializeStep2Defaults() {
        guard let first = unitPresets.first else { return }
        selectedUnitTitle = first.title
        unitName = first.title
        unitML = first.ml
        
        if first.isOther {
            isUnitMLExpanded = true
            manualUnitNameText = ""
        } else {
            isUnitMLExpanded = false
            manualUnitNameText = first.title
        }
        manualUnitMLText = (unitML == 0) ? "" : String(format: "%.0f", unitML)
    }
}

#Preview {
    RecordStep2View(type: AlcoholType.soju)
        .modelContainer(for: [Person.self, DrinkRecord.self], inMemory: true)
}
