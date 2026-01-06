//
//  StructureView.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI

struct StructureView: View {
    @AppStorage("historyBadge") var historyBadge: Bool = false
    var body: some View {
        VStack{
            HStack{
                Text("Sulomon")
                    .fontDesign(.serif)
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName:"wineglass")
                    .font(.title2)
            }
            .padding(.horizontal)
            TabView{
                
                Tab("나의 간", systemImage: "heart.text.square.fill") {
                    DashboardView()
                }
                Tab("기록", systemImage:"clock.arrow.trianglehead.counterclockwise.rotate.90"){
                    HistoryView()
                }
                .badge(historyBadge ? Text("") : nil)
                Tab("사람", systemImage:"person.circle.fill") {
                    PeopleView()
                }
                Tab("추가", systemImage:"plus.circle.fill"){
                    RecordStep1View()
                }
            }
        }
    }
}

#Preview {
    StructureView()
}
