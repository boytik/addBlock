

import SwiftUI

struct GeneralView: View {
    @StateObject private var viewModel = GeneralViewModel()
    
    var body: some View {
        VStack(alignment: .center) {
                //MARK: HEADER
                HStack {
                    Spacer()
                    Text("AdBlocker")
                        .font(.custom("Inter18pt-Bold", size: 20))
                        .lineSpacing(8)
                        .tracking(-0.5)
                        .foregroundStyle(.white)

                    Spacer()
                    Button (action: {
                        
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color("BgForBut"))
                                .frame(width: 40, height: 40)
                            Image(systemName: "gearshape.fill")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.white)
                        }
                    }
                }
            
                //MARK: MainButton
                Button(action: {
                    viewModel.isWorking.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isWorking ? Color("AccentColor") : Color("BgForBut"))
                            .frame(maxWidth: 192, maxHeight: 192)
                        Image(systemName: "power")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 84)
                            .foregroundStyle(.white)
                    }
                }
            
            //MARK: Titels
            
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
                .foregroundStyle(.secondary)
            }
            
            //MARK: Picker
            timeRangePicker
                .padding(.vertical)
              
            }
    }
    
    
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
}
