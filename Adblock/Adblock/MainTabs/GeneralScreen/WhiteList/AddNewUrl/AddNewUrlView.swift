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
            VStack(spacing: 24) {
                header
                    .padding(.horizontal)
                    .padding(.vertical)
                webLink
                nameOfWeb
                Button(action: {
                    
                }) {
                    HStack {
                        Text("Add to Whitelist")
                            .font(.custom("Inter18pt-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.red))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
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
            HStack {
                Text("WEBSITE LINK")
                    .font(.custom("Inter18pt-Bold", size: 10))
                    .foregroundColor(.grayText)
                Spacer()
            }

                HStack {
                    Image("link")
                        .frame(width: 14, height: 14)
                        .foregroundColor(.grayText)
                        .padding(.horizontal)
                 
                    TextField("https://youtube.com", text: $viewModel.url)
                        .foregroundColor(.grayText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.bgForBut))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var nameOfWeb: some View {
        VStack {
            HStack{
                Group {
                    Text("NAME")
                        .font(.custom("Inter18pt-Bold", size: 10))
                        .foregroundColor(.grayText)
                    + Text("(OPIONAL)")
                        .font(.custom("Inter18pt-Regular", size: 10))
                        .foregroundColor(.grayText)
                }
                Spacer()
            }
            HStack {
                Image("tag")
                    .frame(width: 14, height: 14)
                    .foregroundColor(.grayText)
                    .padding(.horizontal)
             
                TextField("My Favorite Site", text: $viewModel.titel)
                    .foregroundColor(.grayText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.bgForBut))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.vertical)
        }
    }
    
    

}
