//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//

import SwiftUI

struct WhiteListView: View {
    @StateObject var viewModel: WhiteListViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var itemToDelete: WhiteListItem?

    init(viewModel: WhiteListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack {
                header
                    .padding(.vertical)
                if viewModel.items.isEmpty {
                    Spacer()
                    emtyState
                    Spacer()
                } else {
                    whiteList
                }
                mainButton
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: Binding(
            get: { coordinator.sheet == .addWebsite },
            set: { if !$0 { coordinator.dismissSheet() } }
        )) {
            AddNewUrlView(viewModel: AddWebSiteViewModel(coordinator: coordinator,
                                                         whitelist: coordinator.whiteListStore))
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.closeWhiteList()
            }) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .overlay{
            Text("White List".localized)
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
        .padding(.horizontal)
    }
    
    private var emtyState: some View {
        VStack(spacing: 24) {
            Image("Empty")
                .frame(width: 96, height: 96)
            Text("No website in white list yet".localized)
                .font(.custom("Inter18pt-Regular", size: 14))
                .foregroundColor(.grayText)
        }
    }
    
    private var whiteList: some View {
        List {
            ForEach(viewModel.items) { item in
                RowForList(titel: item.name, url: item.url, onDelete: {
                    itemToDelete = item
                })
                    .listRowBackground(Color.black)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .alert("Remove from White List".localized, isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Cancel".localized, role: .cancel) {
                itemToDelete = nil
            }
            Button("Remove".localized, role: .destructive) {
                if let item = itemToDelete {
                    viewModel.deleteUrl(id: item.id)
                }
                itemToDelete = nil
            }
        } message: {
            Text("Are you sure you want to remove this website from the white list?".localized)
        }
    }
    
    
    private var mainButton: some View {
        Button(action: {
            viewModel.openAddWeb()
        }) {
            HStack {
                Image("Shield")
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .padding()
                Text("Add WebSite".localized)
                    .font(.custom("Inter18pt-SemiBold", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)

        .background(Color(.red))
        .clipShape(RoundedRectangle(cornerRadius: 46))
        }
    }
}

struct RowForList: View {
    let titel: String?
    let url: String
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack {
            HStack {
                Group {
                    Image("ImgRow")
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text("\(titel ?? "Website".localized)")
                            .font(.custom("Inter18pt-Medium", size: 16))
                            .foregroundColor(.white)
                        Text("\(url)")
                            .font(.custom("Inter18pt-Regular", size: 12))
                            .foregroundColor(.grayText)
                    }
                    .padding(.leading)
                }
                Spacer()
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                        .frame(width: 24, height: 24)
                        .padding(.horizontal)
                }
            }
            Divider()
        }
        .background(Color(.clear))
    }
}

#Preview {
    WhiteListView(viewModel: WhiteListViewModel(coordinator: AppCoordinator(),
                                                whiteListStore: WhiteListStore()))
}
