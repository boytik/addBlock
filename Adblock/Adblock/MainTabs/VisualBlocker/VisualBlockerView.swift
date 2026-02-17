//
//  VisualBlocker.swift
//  Adblock
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI

struct VisualBlockerView: View {
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.02, blue: 0.02)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    header
                        .padding(.vertical)
                    Image("V1")
                    
                    Text("Visual Blocker")
                        .font(.custom("Inter18pt-Bold", size: 30))
                        .foregroundColor(.white)
                    Text("Manually select and hide annoying elements on \nany webpage to create custom rules.")
                        .font(.custom("Inter18pt-Regular", size: 14))
                        .foregroundColor(.grayText)
                    Image("V2")
                    Image("V3")
                    Image("V4")
                    Button(action: {}) {
                        HStack {
                            Text("Open Safari Tutorial")
                                .font(.custom("Inter18pt-Bold", size: 18))
                                .foregroundColor(.white)
                            Image("V5")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(.red))
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
            }
        }
    }
    private var header: some View {
        HStack {
            Button(action: {
                
            }) {
                Image(systemName: "xmark")
            }
            Spacer()
        }
        .overlay{
            Text("Add Custom Rule")
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
        .padding(.horizontal)
    }

}
#Preview {
    VisualBlockerView()
}
