
//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI

struct SettingsView: View {
    @StateObject var viewModal: SettingsViewModal
    
    init(viewModel: SettingsViewModal) {
          _viewModal = StateObject(wrappedValue: viewModel)
      }
    var body: some View {
        ZStack {
            VStack {
                header
                    .padding(.vertical)
                    .padding(.bottom, 24)

                RowForSettings(iconName: "feedback",
                               titel: "Share feedback".localized,
                               action: { viewModal.shareFeedback() })

                RowForSettings(iconName: "rate",
                               titel: "Rate Our App".localized,
                               action: { viewModal.rateApp() })

                RowForSettings(iconName: "contact",
                               titel: "Contact Us".localized,
                               action: { viewModal.contactUs() })

                RowForSettings(iconName: "privacy",
                               titel: "Privacy Policy".localized,
                               action: { viewModal.openPrivacyPolicy() })

                RowForSettings(iconName: "terms",
                               titel: "Terms of Service".localized,
                               action: { viewModal.openTermsOfService() })
                Spacer()
             
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .background(Color(.black))

        
    }
    private var header: some View {
        HStack {
            Button(action: {
                viewModal.closeSettings()
            }){
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .overlay{
            Text("Settings".localized)
                .font(.custom("Inter18pt-SemiBold", size: 18))
                .foregroundStyle(.white)
        }
    }
    
}

struct RowForSettings: View {
    let iconName: String
    let titel: String
    let action: () -> Void
    var body: some View {
        VStack {
            HStack {
                Image("\(iconName)")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                
                
                Text("\(titel)")
                    .font(.custom("Inter18pt-SemiBold", size: 17))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.grayText)
            }
            .padding(.bottom, 24)
            .frame(height: 24)
            .onTapGesture {
               action()
            }
            Divider()
                .background(Color.grayText)
        }
        .padding(.bottom, 24)
    }
}

