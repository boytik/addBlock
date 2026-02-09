//
//  AddNewUrlView.swift
//  Adblock
//
//  Created by Евгений on 09.02.2026.
//

import SwiftUI

struct AddNewUrlView: View {
    @StateObject var viewModel: AddWebSiteViewModel
    
    init(viewModel: AddWebSiteViewModel) {
       _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack {
                header
            }
            .padding(.horizontal)
        }
    }
    private var header: some View {
        HStack {
            Text("Add WebSite")
                .font(.custom("Inter18pt-Bold", fixedSize: 20))
                .foregroundColor(.red)
            
            Spacer()
            Button(action: {}) {
                Text("Cancel")
                    .font(.custom("Inter18pt-Medium", fixedSize: 14))
                    .foregroundColor(.red)
            }
        }
    }
    private var webLink: some View {
        VStack {
            Text("WEBSITE LINK")
            TextField("https://youtube.com", text: $viewModel.url)
        }
    }
}
