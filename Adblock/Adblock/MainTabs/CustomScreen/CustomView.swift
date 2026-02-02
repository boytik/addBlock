

import SwiftUI
struct CustomView: View {
    
    @StateObject var viewModel: CstomViewModel
    
    init(viewModel: CstomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            header
            customSearchBar
                .padding(.vertical)
            RowForCustomView(icon: "Shield",
                             titel: "All Domains",
                             subTitel: "Blocking ads & trackers",
                             isOn: $viewModel.blockAllDomains)
        }
        .padding(.horizontal)
        .background(Color(.black))
    }
    
    private var header: some View {
        HStack {
            Image("CustomTab")
                .foregroundStyle(.grayText)
            
            Spacer()
            Text("Custom Rules")
                .font(.custom("Inter18pt-Bold", size: 18))
                .foregroundStyle(.white)
            Spacer()
            Button(action: {
                viewModel.openAddCustomRule()
            }) {
             Label("" , systemImage: "plus")
            }
            .frame(width: 36, height: 36)
        }
    }
    
    private var customSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .frame(width: 16, height: 16)
                .foregroundStyle(.grayText)
                .padding(.leading)
            TextField("Search domains",
                      text: $viewModel.searchText)
            .padding(.horizontal)
        }
        .frame(height: 58)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct RowForCustomView: View {
    let icon: String
    let titel: String
    let subTitel: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image("\(icon)")
                .frame(width: 40, height: 40 )
            VStack(alignment: .leading) {
                Text("\(titel)")
                    .font(.custom("Inter18pt-SemiBold", size: 16))
                    .foregroundStyle(.white)
                Text("\(subTitel)")
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
            }
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.accent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
