

import SwiftUI
import StoreKit

struct OnbordingView: View {

    
    @StateObject var viewModel: OnbordingViewModel
    @Environment(\.requestReview) private var requestReView
    
    var body: some View {
        ZStack {
            Image(viewModel.bgTitel)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: viewModel.bgTitel)
            
            VStack {
                Spacer()
                basement
            }
            .padding(.bottom, 50)
        }
        .onChange(of: viewModel.shuoldRequestReview) { newValue in
            if newValue {
                requestReView()
                viewModel.shuoldRequestReview = false
            }
        }

    }
    
    private var basement: some View {
        VStack(alignment: .center) {
            Spacer()
            VStack(spacing: 12) {
                Text("Ad Blocker \nNo Ads & Trackers")
                    .font(.custom("Inter18pt-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(" Easily navigate your TV with your phone \nUse the touchpad for fast, smooth control")
                    .font(.custom("Inter18pt-Medium", size: 14))
                    .foregroundColor(.grayText)
                    .multilineTextAlignment(.center)
            }
            PageIndicator(currentPage: viewModel.currentPage, totalPages: 5)
                .padding(.vertical, 24)
            Button(action: {
                viewModel.nextStep()
            } ) {
                Text("\(viewModel.textForButton)")
                    .font(.custom("Inter18pt-Medium", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.red))
                    .clipShape(RoundedRectangle(cornerRadius: 46))
            }
            if viewModel.showTermOfUseAndPrivacy {
                HStack(spacing: 32) {
                    Button(action: {
                        viewModel.openTermsOfService()
                    }) {
                        Text("Terms of use")
                            .font(.custom("Inter18pt-Regular", size: 14))
                            .foregroundColor(.grayText)
                    }
                    Button(action: {
                        viewModel.openPrivacyPolicy()
                    }) {
                        Text("Privacy Policy")
                            .font(.custom("Inter18pt-Regular", size: 14))
                            .foregroundColor(.grayText)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 24)
    }
    
}
struct PageIndicator: View {
    
    var currentPage: Int
    var totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.gray.opacity(0.4))
                    .frame(
                        width: index == currentPage ? 18 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}
