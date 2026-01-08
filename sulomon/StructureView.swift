//
//  StructureView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import LocalAuthentication // 1. 프레임워크 임포트

struct StructureView: View {
    @AppStorage("historyBadge") var historyBadge: Bool = false
    
    // 탭 선택 상태
    @State private var selectedTab: Int = 0
    
    // 2. 잠금 상태 관리 (false = 잠김, true = 풀림)
    @State private var isUnlocked: Bool = false
    @State private var authError: String? = nil

    var body: some View {
        Group {
            if isUnlocked {
                // MARK: - 잠금 해제 시 보여질 메인 화면
                VStack {
                    HStack {
                        Text("Sulomon")
                            .fontDesign(.serif)
                            .font(.title)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        // 와인 아이콘을 버튼으로 변경하여 탭 전환 기능 추가
                        Button {
                            selectedTab = 3 // '추가' 탭의 태그값
                        } label: {
                            Image(systemName: "wineglass")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    TabView(selection: $selectedTab) {
                        // 대시보드
                        DashboardView()
                            .tag(0)
                            .tabItem {
                                Label("나의 간", systemImage: "heart.text.square.fill")
                            }

                        // 기록
                        HistoryView()
                            .tag(1)
                            .tabItem {
                                Label("기록", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            }
                            .badge(historyBadge ? "" : nil)

                        // 사람
                        PeopleView()
                            .tag(2)
                            .tabItem {
                                Label("사람", systemImage: "person.circle.fill")
                            }

                        // 추가
                        RecordStep1View()
                            .tag(3)
                            .tabItem {
                                Label("추가", systemImage: "plus.circle.fill")
                            }
                    }
                }
            } else {
                // MARK: - 잠금 화면 (Face ID 실패 시 또는 초기 로드 시)
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("Sulomon이 잠겨있습니다")
                        .font(.headline)
                    
                    if let error = authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        authenticate()
                    } label: {
                        Text("Face ID로 잠금 해제")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            // 앱 실행 시 자동으로 인증 시도
            authenticate()
        }
    }
    
    // MARK: - Face ID 인증 로직
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // 생체 인식이 가능한지 확인
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "내 술자리를 기록하기 위해 인증이 필요합니다."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // 인증 성공
                        withAnimation {
                            self.isUnlocked = true
                        }
                    } else {
                        // 인증 실패
                        self.authError = "인증에 실패했습니다. 다시 시도해주세요."
                    }
                }
            }
        } else {
            // 기기가 생체 인식을 지원하지 않거나 설정되지 않음
            // 시뮬레이터이거나 Face ID가 없는 경우 편의상 해제 처리하거나 비밀번호 입력 유도
            // 여기서는 편의상 해제 처리하거나 에러 메시지 표시
            DispatchQueue.main.async {
                // self.isUnlocked = true // 테스트 시 주석 해제하여 강제 진입 가능
                self.authError = "이 기기에서 Face ID를 사용할 수 없습니다."
            }
        }
    }
}

#Preview {
    StructureView()
}
