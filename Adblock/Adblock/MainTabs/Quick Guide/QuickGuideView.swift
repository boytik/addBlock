

import SwiftUI

struct QuickGuideView: View {
    @StateObject var viewModal: QuickGuideViewModel
    
    init(viewModel: QuickGuideViewModel) {
          _viewModal = StateObject(wrappedValue: viewModel)
      }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    header
                        .padding(.vertical)
                    Image("Image")
                        .padding(.vertical)
                    Text("Let's kill those ads".localized)
                        .font(.custom("Inter18pt-Bold", size: 30))
                        .foregroundColor(.white)
                    Text("Enable the Safari extension to start \nbrowsing effectively distraction-free.".localized)
                        .font(.custom("Inter18pt-Regular", size: 14))
                        .foregroundColor(.grayText)
                    
                    openSettings
                    tapExtensions
                    toggleOn
                    buttons
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                viewModal.closeSheet()
            }) {
                Image(systemName: "xmark")
            }
            Spacer()
        }
        .overlay{
            Text("Add Custom Rule".localized)
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
        .padding(.horizontal)
    }
    
    private var openSettings: some View {
        HStack {
                Image("Setting")
                     .frame(width: 40, height: 40)
                     .padding(.horizontal)
                 VStack(alignment: .leading) {
                     Text("1. Open Settings".localized)
                         .font(.custom("Inter18pt-SemiBold", size: 15))
                         .foregroundStyle(.white)
                         .padding(.bottom, 4)
                     Text("Tap the button below to \nautomatically open iOS Settings.".localized)
                         .font(.custom("Inter18pt-Regular", size: 12))
                         .foregroundColor(.grayText)
                 }
                 .padding(.trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
        .padding(.vertical, 8)
    
    }
    
    private var tapExtensions: some View {
        HStack {
           Image("Puzzle")
                .frame(width: 40, height: 40)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("2. Tap Extensions".localized)
                    .font(.custom("Inter18pt-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)
                Text("Scroll down to find ".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.grayText)
                + Text("Safari".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.red)
                + Text(", then tap \nExtensions.".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.grayText)
            }
            .padding(.trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
        .padding(.vertical, 8)
    
    }
    
    private var toggleOn: some View {
        HStack() {
            Image("Toggle")
                .frame(width: 40, height: 40)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("3. Toggle On".localized)
                    .font(.custom("Inter18pt-SemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)
                Text("Find this app in the list and switch \ntoggle to ".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.grayText)
                + Text("ON.".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
        .padding(.vertical, 8)
    }
    
    private var buttons: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModal.openSettings()
            }){
                HStack {
                    Text("Go to Settings".localized)
                        .font(.custom("Inter18pt-SemiBold", size: 16))
                        .foregroundColor(.white)
                    Image("GoTo")
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height:56)
                .background(RoundedRectangle(cornerRadius: 24))
                .foregroundColor(.red)
            }
            Button(action: {
                viewModal.closeSheet()
            }) {
                Text("I'll do this later".localized)
                    .font(.custom("Inter18pt-Medium", size: 14))
                    .foregroundColor(.grayText)
                    .frame(maxWidth: .infinity)
                    .frame(height:56)
            }
        }
    }
}
