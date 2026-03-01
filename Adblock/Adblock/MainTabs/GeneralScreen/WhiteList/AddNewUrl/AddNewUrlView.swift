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
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                           viewModel.addNewUrl()
                       }                }) {
                    HStack {
                        Text("Add to White List".localized)
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
            .padding(.bottom)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private var header: some View {
        HStack {
            Text("Add WebSite".localized)
                .font(.custom("Inter18pt-Bold", fixedSize: 20))
                .foregroundColor(.white)
            
            Spacer()
            Button(action: {
                viewModel.closeSheet()
            }) {
                Text("Cancel".localized)
                    .font(.custom("Inter18pt-Medium", fixedSize: 16))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var webLink: some View {
        VStack(spacing: 6) {
                    HStack {
                        Text("WEBSITE LINK".localized)
                            .font(.custom("Inter18pt-Bold", size: 10))
                            .foregroundColor(.grayText)
                
                if viewModel.showDuplicateError {
                    Text("— this domain is already in WhiteList".localized)
                        .font(.custom("Inter18pt-Medium", size: 10))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
                Spacer()
            }
            
            HStack {
                Image("link")
                    .frame(width: 14, height: 14)
                    .foregroundColor(.grayText)
                    .padding(.horizontal)
                
                ZStack(alignment: .leading) {
                    if viewModel.url.isEmpty {
                        Text("https://youtube.com".localized)
                            .foregroundColor(.gray)
                    }
                    TextField("", text: $viewModel.url)
                        .foregroundColor(viewModel.showDuplicateError ? .red : .white)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onChange(of: viewModel.url) { _ in
                            viewModel.clearError()
                        }
                }
                .tint(.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.bgForBut))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(viewModel.showDuplicateError ? Color.red : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var nameOfWeb: some View {
        VStack(spacing: 6) {
            HStack {
                Group {
                    Text("NAME ".localized)
                        .font(.custom("Inter18pt-Bold", size: 10))
                        .foregroundColor(.grayText)
                    + Text("(OPTIONAL)".localized)
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
                
                TextField("", text: $viewModel.titel, prompt:
                            Text("My Favorite Site".localized)
                    .foregroundColor(Color("PlaceHolder"))
                )
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.bgForBut))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

