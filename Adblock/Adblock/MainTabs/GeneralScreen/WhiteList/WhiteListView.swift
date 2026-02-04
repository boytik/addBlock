//
//  WhiteListView.swift
//  Adblock
//
//  Created by Евгений on 04.02.2026.
//

import SwiftUI

struct WhiteListView: View {
    @StateObject var viewModel: WhiteListViewModel
    
    init(viewModel: WhiteListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            header
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.closeWhiteList()
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
    }}
