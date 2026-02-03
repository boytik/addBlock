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
        ZStack {
            
            VStack(alignment: .center) {
                header
                
                //SearchBar
                inputTextField
                
                //Block Options
                blockingSetting
                
                domainAvtivity
                    .padding(.vertical)
                
                if viewModel.isEmptyData == true {
                    Image("EmptyData")
                        .zIndex(0)
                } else {
                    //тут чарт нарисовать когда будем получать данные
                }
            }
            .padding(.horizontal)
            .frame(maxHeight: .infinity)
            .background(Color(.black))
            if viewModel.showMenu {
                       dropdownMenu
                           .zIndex(100) // выше вообще всего
                   }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.closeScreen()
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
    }
    
    private var inputTextField: some View {
        VStack {
            HStack {
                Text("Target Website")
                    .font(.custom("Inter18pt-SemiBold", size: 14))
                    .foregroundStyle(.white)
                    .padding(.vertical)
                Spacer()
            }
            HStack {
                Image("Planet")
                    .padding(.leading)
                TextField("e.g., youtube.com",
                          text: $viewModel.tagetWeb)
            }
            .frame(height: 58)
            .background(Color(.bgForBut))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            HStack {
                Text("Rule applies to this domain and all its subdomains.")
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
                Spacer()
            }
            
        }
    }
    
    private var blockingSetting: some View {
        VStack {
            HStack {
                Text("Blocking Options")
                    .font(.custom("Inter18pt-SemiBold", size: 14))
                    .foregroundStyle(.grayText)
                    .padding(.vertical)
                Spacer()
            }
            VStack {
                RowForBloking(imageName: "block",
                              titel: "Block Ads",
                              bgForIcon: "redWithAlpha",
                              subTitel: "Removes banner and video ads",
                              isOn: $viewModel.blockAds)
                RowForBloking(imageName: "Eye",
                              titel: "Block Trackers",
                              bgForIcon: "redWithAlpha",
                              subTitel: "Stops analytics & data collection",
                              isOn: $viewModel.blockTrackers)
                RowForBloking(imageName: "orangeShield",
                              titel: "Anti-Adblock Killer", bgForIcon: "orangeWithAlpha",
                              subTitel: "Bypasses Disable Adblock popups",
                              isOn: $viewModel.antiAdblockKiller)
                RowForBloking(imageName: "MagicWand",
                              titel: "Hide Elements",
                              bgForIcon: "blueWithAlpha",
                              subTitel: "Social widgets, comments, footers",
                              isOn: $viewModel.hideElements)
            }
            .background(RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(.bgForBut)
        }
    }
    private var domainAvtivity: some View {
        HStack {
            Text("Domain Activity")
                .font(.custom("Inter18pt-SemiBold", size: 14))
                .foregroundStyle(.white)
            Spacer()
            
            if viewModel.showMenu == false {
                Button {
                    withAnimation {
                        viewModel.showMenu.toggle()
                    }
                } label: {
                    HStack {
                        Text("Last 24h")
                            .font(.custom("Inter18pt-Regular", size: 12))
                            .foregroundStyle(.grayText)
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.grayText)
                    }
                }
            }
        }
    }
    
    private var dropdownMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { viewModel.opneAndCloseMenu(range: .lastDay) } label: {
                Text("Last 24h").foregroundStyle(.grayText)
            }
            Button { viewModel.opneAndCloseMenu(range: .lastWeek) } label: {
                Text("Last week").foregroundStyle(.grayText)
            }
            Button { viewModel.opneAndCloseMenu(range: .lastMonth) } label: {
                Text("Last month").foregroundStyle(.grayText)
            }
        }
        .padding()
        .background(.bgForBut)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 20)
        .offset(x: 120, y: 220)
    }
    
}

private struct RowForBloking: View {
    let imageName: String
    let titel: String
    let bgForIcon: String
    let subTitel: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color("\(bgForIcon)"))
                    .frame(width: 40, height: 40)
                Image("\(imageName)")
                        .frame(width: 40, height: 40)
            }
            VStack (alignment: .leading) {
                Text("\(titel)")
                    .font(.custom("Inter18pt-Medium", size: 14))
                    .foregroundStyle(.white)
                Text("\(subTitel)")
                    .font(.custom("Inter18pt-Regular", size: 12))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color("AccentColor"))
        }
        .padding()
    }
}


