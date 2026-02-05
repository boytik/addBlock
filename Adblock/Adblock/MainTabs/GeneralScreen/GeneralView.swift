

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
                    ReusableCardView(titel: "ADS BLOCKED",
                                     generalCount: 1000,
                                     currentCount: viewModel.adsBlockedCount,
                                     icon: "nosign")
                    ReusableCardView(titel: "TRACKERS",
                                     generalCount: 1000,
                                     currentCount: viewModel.trackersBlokedCount,
                                     icon: "eye.slash.fill")
                }
                HStack {
                    Text("GLOBAL PROTECTION RULES")
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
        .onAppear(){ //Создано для теста удалить 
            let suite = UserDefaults(suiteName: "group.com.botyik.adblock")
            suite?.set("Hello from App", forKey: "appGroupTest")
        }
    }
    //MARK: Header
    private var header: some View {
        HStack {
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
            Text("AdBlocker")
                .font(.custom("Inter18pt-Bold", size: 20))
                .tracking(-0.5)
                .foregroundStyle(.white)
        }
    }
    
    //MARK: MAIN Button
    private var mainButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                   viewModel.isWorking.toggle()
               }
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.isWorking ? Color("AccentColor") : Color("BgForBut"))
                    .frame(width: 192, height: 192)
                    .scaleEffect(isPulsing ? 1.03 : 1.0)
                    .shadow(
                            color: Color("AccentColor"),
                            radius: isPulsing ? 40 : 20
                        )
                
                        .shadow(
                            color: Color("AccentColor").opacity(0.4),
                            radius: viewModel.isWorking ? 80 : 0
                        )
                        .animation(
                                    viewModel.isWorking
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
            .onChange(of: viewModel.isWorking, perform: { isOn in
                isPulsing = isOn
            })
        }
    }
    
    //MARK: Titels Under Button
    private var titelsUnderButton: some View {
        Group {
            Text(viewModel.isWorking ? "Protection Active" : "Protection Inactive")
                .font(.custom("Inter18pt-Bold", size: 30))
                .foregroundStyle(.white)
            
            Text(
                viewModel.isWorking
                ? "Your device is secure from ads & trackers."
                : "Your device is not secure from ads & trackers."
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
                title: "Block Ads",
                subtitle: "Web & In-app banners",
                isOn: $viewModel.isBlockAds
            )
            
            ProtectionRowView(
                imageName: "finger",
                title: "Block Trackers",
                subtitle: "Prevent user profiling",
                isOn: $viewModel.isBlockTrackers
            )
            
            ProtectionRowView(
                imageName: "bones",
                title: "Anti-Adblock killer",
                subtitle: "Avoid detection scripts",
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
                Text("Anti-Adblock killer")
                    .font(.custom("Inter18pt-Medium", size: 16))
                    .foregroundStyle(.white)

                Text("Avoid setections scripts")
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
            }

            Spacer()

            Button(action: {
                viewModel.openWhiteList()
            }) {
                Image(systemName: "chevron.right")
            }
            .padding(.trailing)
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
    let generalCount: Int
    let currentCount: Int
    let icon: String
    private var percentOfBar: Double {
        guard generalCount > 0 else { return 0 }
        return Double(currentCount) / Double(generalCount)
    }
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
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                        Capsule()
                            .fill(Color.accent)
                            .frame(width: geo.size.width * percentOfBar)
                    }
                }
                .frame(height: 4)
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}


