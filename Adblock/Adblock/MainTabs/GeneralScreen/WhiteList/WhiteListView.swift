

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
                mainButton
            }
            .padding(.horizontal)
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
//                viewModel.closeWhiteList()
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
    private var mainButton: some View {
        Button(action: {}) {
            HStack {
                Image("Shield")
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

#Preview {
    WhiteListView(viewModel: WhiteListViewModel(coordinator: AppCoordinator(),
                                                whiteListStore: WhiteListStore()))
}
