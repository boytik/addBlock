//
//  QuickGuideView.swift
//  Adblock
//
//  Created by Евгений on 03.02.2026.
//

import SwiftUI

struct QuickGuideView: View {
    var body: some View {
        ScrollView {
            VStack {
                header
                Image("Image")
                Text("Let's kill those ads")
                Text("Enable the Safari extension to start \nbrowsing effectively distraction-free.")
               
                openSettings
                tapExtensions
                toggleOn
            }
        }
        
    }
    private var header: some View {
        HStack {
            Button(action: {
              
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
    private var openSettings: some View {
        HStack {
           Image("Setting")
                .frame(width: 40, height: 40)
            VStack {
                Text("1. Open Settings")
                    .font(.custom("Inter18pt-SemiBold", size: 15))
                    .foregroundStyle(.white)
                Text("Tap the button below to \nautomatically open iOS Settings.")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.grayText)
            }
        }
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
    
    }
    private var tapExtensions: some View {
        HStack {
           Image("Puzzle")
                .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text("2. Tap Extensions")
                    .font(.custom("Inter18pt-SemiBold", size: 15))
                    .foregroundStyle(.white)
                Text("Scroll down to find")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.grayText)
                + Text("Safari")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.red)
                + Text(", then tap \nExtensions.")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.grayText)
            }
        }
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
    
    }
    private var toggleOn: some View {
        HStack {
           Image("Toggle")
                .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text("3. Toggle On")
                    .font(.custom("Inter18pt-SemiBold", size: 15))
                    .foregroundStyle(.white)
                Text("Find this app in the list and switch toggle to.")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.grayText)
                + Text("ON")
                    .font(.custom("Inter18pt-", size: 15))
                    .foregroundColor(.green)
            }
        }
        .background(RoundedRectangle(cornerRadius: 24))
        .foregroundStyle(.bgForBut)
    
    }
}
