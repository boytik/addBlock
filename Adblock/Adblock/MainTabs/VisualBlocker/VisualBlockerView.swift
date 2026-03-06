//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//

import SwiftUI

struct VisualBlockerView: View {
    @StateObject var viewModel: VisualBlockerViewModel
    
    init(viewModel: VisualBlockerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
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
                    Button(action: {
                        viewModel.openSafariTutorial()
                    }) {
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
                viewModel.close()
            }) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .overlay {
            Text("Visual Blocker")
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
        .padding(.horizontal)
    }

}
#Preview {
    VisualBlockerView(viewModel: VisualBlockerViewModel(coordinator: AppCoordinator()))
}
