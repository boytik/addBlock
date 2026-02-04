

import SwiftUI
struct CustomView: View {
    
    @StateObject var viewModel: CstomViewModel
    
    init(viewModel: CstomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    header
                    customSearchBar
                        .padding(.vertical)
                    RowForCustomView(icon: "Shield",
                                     titel: "All Domains",
                                     subTitel: "Blocking ads & trackers",
                                     isOn: $viewModel.blockAllDomains)
                    inactiveBlock
                    
                }
                .padding(.horizontal)

            }
        }
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
    
    private var inactiveBlock: some View {
        HStack {
            Text("INACTIVE")
                .font(.custom("Inter18pt-Bold", size: 12))
                .foregroundColor(.grayText)
            Spacer()
        }
    }
    
    private var basement: some View {
        VStack {
            Image("CastomRules")
                .frame(width: 96, height: 96)
        }
    }
}

struct RowForCustomView: View {
    let icon: String
    let titel: String
    let subTitel: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Group{
                Image("\(icon)")
                    .frame(width: 40, height: 40 )
                    .padding(.horizontal)
                VStack(alignment: .leading) {
                    Text("\(titel)")
                        .font(.custom("Inter18pt-SemiBold", size: 16))
                        .foregroundStyle(.white)
                        .padding(.bottom, 4)
                    Text("\(subTitel)")
                        .font(.custom("Inter18pt-Regular", size: 12))
                        .foregroundStyle(.grayText)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.accent)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
