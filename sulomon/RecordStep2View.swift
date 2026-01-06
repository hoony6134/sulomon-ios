//
//  RecordStep2View.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData
// import VoidUtilities // 필요한 경우 주석 해제

struct RecordStep2View: View {
    @AppStorage("historyBadge") var historyBadge: Bool = false
    // MARK: - SwiftData Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // 저장 후 창 닫기용

    // MARK: - External Data / Bindings
    @State var type: AlcoholType
    @State var alcoholPercent: Double = 0.0
    @State var brand: String? = nil
    
    // MARK: - Internal UI Layout
    private let twoColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Preset Models
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

    // MARK: - State Properties (Step 1)
    @State private var selectedPresetTitle: String? = nil
    @State private var manualBrandText: String = ""

    // MARK: - State Properties (Step 2)
    @State private var unitCount: Double = 0.0 // 사용자 입력 개수
    @State private var unitName: String = ""
    @State private var unitML: Double = 0.0
    
    // UI Logic States
    @State private var selectedUnitTitle: String? = nil
    @State private var isUnitMLExpanded: Bool = false
    @State private var manualUnitNameText: String = ""
    @State private var manualUnitMLText: String = ""
    
    // Saving State
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
        
        // 1. SwiftData 저장
        let percentToSave = (alcoholPercent == 0 && defaultPercent != 0) ? defaultPercent : alcoholPercent
        
        let newRecord = DrinkRecord(
            type: type,
            timestamp: Date(),
            alcoholPercent: percentToSave,
            units: unitCount,
            unitML: unitML,
            unitName: unitName,
            alcoholPerUnit: alcoholPerUnit,
            brand: brand,
            healthKitSynced: false
        )
        
        modelContext.insert(newRecord)
        
        // 2. HealthKit 저장 시도
        Task {
            // 사용자 입력값이 0보다 클 때만 HealthKit 저장 시도
            if unitCount > 0 {
                do {
                    // 권한 확인 및 요청
                    let authorized = try await HealthKitManager.shared.requestAuthorization()
                    if authorized {
                        // 저장
                        try await HealthKitManager.shared.saveAlcoholUnits(units: unitCount, date: newRecord.timestamp ?? Date())
                        
                        // 성공 시 플래그 업데이트 (메인 스레드에서 UI 관련 데이터 업데이트 권장이나 SwiftData Actor 모델상 Task 내부 수행 가능)
                        newRecord.healthKitSynced = true
                    }
                } catch {
                    print("HealthKit Error: \(error)")
                    // 실패해도 SwiftData에는 저장되었으므로 진행
                }
            }
            
            // 3. 완료 처리
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

                        // Presets
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
                            // Manual Brand
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
                            // Direct Input
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

                        // Percent Input
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
                            .id("Step2Header") // ScrollViewReader 타겟 ID

                            // 1. 음주량 입력 (Count)
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
                                        
                                        Spacer(minLength: 0)
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
                                        // Unit Name
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
                                        // Unit ML
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
                                        // Calculation Preview
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
                    
                    Spacer(minLength: 60) // 저장 버튼 공간 확보
                }
                .padding(.horizontal)
            }
            .onChange(of: shouldShowStep2) { _, ready in
                if ready {
                    // Defaults setup
                    if alcoholPercent == 0, defaultPercent != 0 { alcoholPercent = defaultPercent }
                    if type == .somac { brand = nil }
                    if selectedUnitTitle == nil { initializeStep2Defaults() }
                    
                    // 1. Scroll to Step 2 Header with Animation
                    // 0.1초 딜레이는 UI가 렌더링된 후 스크롤하기 위함
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("Step2Header", anchor: .top)
                        }
                    }
                }
            }
            // 저장 버튼 Overlay
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
                    .background(
                        LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                            .padding(.top, -20)
                    )
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
}
