//
//  AddCustomRule.swift
//  Adblock
//
//  Created by Евгений on 01.02.2026.
//

import SwiftUI
struct AddCustomRule: View {
    
    @StateObject var viewModel: AddCustomRuleViewModel
    
    init(viewModel: AddCustomRuleViewModel) {
          _viewModel = StateObject(wrappedValue: viewModel)
      }
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            //SearchBar
            Text("Target Website")
                .font(.custom("Inter18pt-SemiBold", size: 14))
                .foregroundStyle(.grayText)
                .padding(.vertical)
            inputTextField
            Text("Rule applies to this domain and all its subdomains.")
                .font(.custom("Inter18pt-Regular", size: 12))
                .foregroundStyle(.grayText)
            //Block Options
            Text("Blocking Options")
                .font(.custom("Inter18pt-SemiBold", size: 14))
                .foregroundStyle(.grayText)
                .padding(.vertical)
            
        }
        .padding(.horizontal)
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.closeScreen()
            }) {
                Image(systemName: "xmark")
            }
            Spacer()
                .overlay{
                    Text("Add Custom Rule")
                        .foregroundStyle(.white)
                        .font(.custom("Inter18pt-Bold", size: 18))
                }
            
        }
    }
    
    private var inputTextField: some View {
        HStack {
            Image("Planet")
                .padding(.leading)
            TextField("e.g., youtube.com", text: $viewModel.tagetWeb)
        }
        .background(Color(.bgForBut))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var blockingSetting: some View {
        VStack {
            RowForBloking(imageName: "nosign",
                          titel: "Block Ads",
                          subTitel: "Removes banner and video ads",
                          isOn: $viewModel.blockAds)
            RowForBloking(imageName: "eye.slash.fill",
                          titel: "Block Trackers",
                          subTitel: "Stops analytics & data collection",
                          isOn: $viewModel.blockTrackers)
            RowForBloking(imageName: "Shield",
                          titel: "Anti-Adblock Killer",
                          subTitel: "Bypasses Disable Adblock popups",
                          isOn: $viewModel.antiAdblockKiller)
            RowForBloking(imageName: "MagicWand",
                          titel: "Hide Elements",
                          subTitel: "Social widgets, comments, footers",
                          isOn: $viewModel.hideElements)
        }
    }
    
    
}

private struct RowForBloking: View {
    let imageName: String
    let titel: String
    let subTitel: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
        Image("\(imageName)")
            VStack (alignment: .leading) {
                Text("\(titel)")
                Text("\(subTitel)")
            }
            Spacer()
            Toggle("", isOn: $isOn)
        }
        .padding()
    }
}
