

import SwiftUI

struct GeneralView: View {
    @StateObject var viewModel: GeneralViewModel
    @State var isPulsing = false
    
    init(viewModel: GeneralViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .center) {
                    header
                        .padding(.vertical)
                    
                    mainButton
                    titelsUnderButton
                    
                    timeRangePicker
                        .padding(.vertical)
                    
                    HStack(spacing: 16) {
                        ReusableCardView(titel: "ADS BLOCKED".localized,
                                         currentCount: viewModel.adsBlockedCount,
                                         icon: "nosign")
                        ReusableCardView(titel: "TRACKERS".localized,
                                         currentCount: viewModel.trackersBlokedCount,
                                         icon: "eye.slash.fill")
                    }
                    HStack {
                        Text("GLOBAL PROTECTION RULES".localized)
                            .font(.custom("Inter18pt-Bold", size: 12))
                            .foregroundStyle(.grayText)
                            .padding(.top)
                        Spacer()
                    }
                    
                    turnOnBlock
                        .padding(.vertical)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.loadBlockedCount()
            viewModel.loadExtensionState()
        }
    }
    //MARK: Header
    private var header: some View {
        HStack {
            Button(action: {
                viewModel.didTapQuickGuide()
            }) {
                ZStack {
                    Circle()
                        .fill(Color("BgForBut"))
                        .frame(width: 40, height: 40)
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                }
            }
            Spacer()
            Button(action: {viewModel.didTapSettings()}) {
                ZStack {
                    Circle()
                        .fill(Color("BgForBut"))
                        .frame(width: 40, height: 40)
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.trailing)
        }
        .overlay {
            Text("AdBlocker".localized)
                .font(.custom("Inter18pt-Bold", size: 20))
                .tracking(-0.5)
                .foregroundStyle(.white)
        }
    }
    
    //MARK: MAIN Button
    private var mainButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.didTapMainButton()
            }
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.isWorking && viewModel.areExtensionsEnabled ? Color("AccentColor") : Color("BgForBut"))
                    .frame(width: 192, height: 192)
                    .scaleEffect(isPulsing ? 1.03 : 1.0)
                    .shadow(
                            color: Color("AccentColor"),
                            radius: isPulsing ? 40 : 20
                        )
                
                        .shadow(
                            color: Color("AccentColor").opacity(0.4),
                            radius: viewModel.isWorking && viewModel.areExtensionsEnabled ? 80 : 0
                        )
                        .animation(
                                    viewModel.isWorking && viewModel.areExtensionsEnabled
                                    ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                    : .default,
                                    value: isPulsing
                                )
                
                Image(systemName: "power")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .foregroundStyle(.white)
            }
            .disabled(viewModel.isUpdatingRules)
            .onChange(of: viewModel.isWorking) { newValue in
                isPulsing = newValue && viewModel.areExtensionsEnabled
            }
            .onChange(of: viewModel.isExtensionEnabled) { newValue in
                isPulsing = viewModel.isWorking && viewModel.areExtensionsEnabled
            }
            .overlay {
                if viewModel.isUpdatingRules {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
    }
    
    //MARK: Titels Under Button
    private var titelsUnderButton: some View {
        Group {
            Text(viewModel.isWorking && viewModel.areExtensionsEnabled ? "Protection Active".localized : "Protection Inactive".localized)
                .font(.custom("Inter18pt-Bold", size: 30))
                .foregroundStyle(.white)
            
            Text(
                viewModel.isWorking && viewModel.areExtensionsEnabled
                ? "Your device is secure from ads & trackers.".localized
                : "Your device is not secure from ads & trackers.".localized
            )
            .font(.custom("Inter18pt-Regular", size: 14))
            .foregroundStyle(.grayText)
            .padding(.top, 5)
        }
    }
    
    //MARK: Dates Filters
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.titel)
                    .font(.custom("Inter18pt-Medium", size: 14))
                    .foregroundColor(
                        viewModel.selectedRange == range
                        ? Color.white
                        : Color.gray
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        viewModel.selectedRange == range
                        ? Color("AccentColor")
                        : Color.clear
                    )
                    .clipShape(Capsule())
                    .onTapGesture {
                        viewModel.selectedRange = range
                    }
            }
        }
        .frame(maxWidth: .infinity,
               minHeight: 44)
        .background(Color("BgForBut"))
        .clipShape(Capsule())
    }
    
    private var turnOnBlock: some View {
        VStack {
            ProtectionRowView(
                imageName: "phone",
                title: "Block Ads".localized,
                subtitle: "Web & In-app banners".localized,
                isOn: $viewModel.isBlockAds
            )
            
            ProtectionRowView(
                imageName: "finger",
                title: "Block Trackers".localized,
                subtitle: "Prevent user profiling".localized,
                isOn: $viewModel.isBlockTrackers
            )
            
            ProtectionRowView(
                imageName: "bones",
                title: "Anti-Adblock killer".localized,
                subtitle: "Avoid detection scripts".localized,
                isOn: $viewModel.isAntiAdblokKiller
            )
            whiteList
            
        }
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var whiteList: some View {
        HStack {
            Image("WhiteList")
                .frame(width: 40, height: 40)
                .foregroundStyle(.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("White List".localized)
                    .font(.custom("Inter18pt-Medium", size: 16))
                    .foregroundStyle(.white)

                Text("Add websites to not block ads".localized)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.red)
                .padding(.trailing)
        }
        .onTapGesture {
            viewModel.openWhiteList()
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
    
    
}
//MARK: Reusable element for toggles
struct ProtectionRowView: View {
    let imageName: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(imageName)
                .frame(width: 40, height: 40)
                .foregroundStyle(.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Inter18pt-Medium", size: 16))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.accent)
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
}

struct ReusableCardView : View {
    let titel: String
    let currentCount: Int
    let icon: String
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(titel)")
                        .font(.custom("Inter18pt-Bold", size: 12))
                        .foregroundStyle(.grayText)
                    
                    Image(systemName: "\(icon)")
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.grayText)
                        .padding(.leading)
                }
                .padding(.vertical)
                
                Text("\(currentCount)")
                    .font(.custom("Inter18pt-Bold", size: 30))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .frame(width: 155, height: 144)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}


