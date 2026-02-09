

import SwiftUI

struct WhiteListView: View {
    @StateObject var viewModel: WhiteListViewModel

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
            }
            .padding(.horizontal)
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
            Text("WhiteL List")
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
        .padding(.horizontal)
    }
    
    private var emtyState: some View {
        VStack(spacing: 24) {
            Image("Empty")
                .frame(width: 96, height: 96)
            Text("No web-site in white list yet")
                .font(.custom("Inter18pt-Regular", size: 14))
                .foregroundColor(.grayText)
        }
    }
    
    private var whiteList: some View {
        List {
            ForEach(viewModel.items) { item in
                RowForList(titel: item.name, url: item.url)
            }
        }
    }
    
    
    private var mainButton: some View {
        Button(action: {}) {
            HStack {
                Image("Shield")
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .padding()
                Text("Add web-site")
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

struct RowForList:  View {
    let titel: String?
    let url: String
    
    var body: some View {
        VStack {
            HStack {
                Group {
                    Image("ImgRow")
                        .frame(width: 40, height: 40)
                    VStack {
                        Text("\(titel ?? "Website")")
                            .font(.custom("Inter18pt-Medium", size: 16))
                            .foregroundColor(.white)
                        Text("\(url)")
                            .font(.custom("Inter18pt-Regular", size: 12))
                            .foregroundColor(.grayText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.grayText)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal)
            }
            Divider()
        }
    }
}

#Preview {
    WhiteListView(viewModel: WhiteListViewModel(coordinator: AppCoordinator(),
                                                whiteListStore: WhiteListStore()))
}
