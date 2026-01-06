//
//  RecordStep1View.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import VoidUtilities

struct RecordStep1View: View {
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    Text("오늘은 어떤 술을 마셨나요?")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.bottom,8)
                ScrollView(){
                    LazyVGrid(columns: twoColumns) {
                        ForEach(AlcoholType.allCases, id: \.self) { type in
                            NavigationLink(destination: RecordStep2View(type: type)){
                                AlcoholCardView(type: type)
                            }
                            .foregroundStyle(Color.black)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct AlcoholCardView: View {
    var type: AlcoholType
    @State var isOpen: Bool = false
    var body: some View {
        Image(type.rawValue)
            .resizable()
            .scaledToFit()
            .overlay{
                HStack{
                    Spacer()
                    VStack{
                        Text(type.rawValue)
                            .fontWeight(.semibold)
                            .padding(20)
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StructureView()
}
