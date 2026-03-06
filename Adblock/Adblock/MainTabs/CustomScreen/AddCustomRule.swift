//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI

struct AddCustomRule: View {

    @StateObject var viewModel: AddCustomRuleViewModel

    init(viewModel: AddCustomRuleViewModel) {
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

                    inputTextField

                    blockingSetting

                    domainAvtivity
                        .padding(.vertical)

                    if viewModel.isEmptyData {
                        Image("EmptyData")
                            .padding(.top, 8)
                    } else {
                        DomainActivityChart(points: viewModel.chartData)
                            .padding(.top, 8)
                            .id(viewModel.rangeOfDates)
                    }

                    Spacer()

                    saveButton
                        .padding(.vertical, 24)
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity)
                .background(Color(.black))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                viewModel.closeScreen()
            }) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .overlay {
            Text(viewModel.isEditMode ? "Edit Custom Rule" : "Add Custom Rule")
                .foregroundStyle(.white)
                .font(.custom("Inter18pt-Bold", size: 18))
        }
    }

    // MARK: - Input

    private var inputTextField: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Target Website")
                    .font(.custom("Inter18pt-SemiBold", size: 14))
                    .foregroundStyle(.white)
                    .padding(.vertical)

                if viewModel.showDuplicateError {
                    Text("— rule for this domain already exists")
                        .font(.custom("Inter18pt-Medium", size: 12))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }

                Spacer()
            }
            HStack {
                Image("Planet")
                    .padding(.leading)
                ZStack(alignment: .leading) {
                    if viewModel.tagetWeb.isEmpty {
                        Text("e.g., youtube.com")
                            .foregroundColor(Color("PlaceHolder"))
                    }
                    TextField("", text: $viewModel.tagetWeb)
                        .foregroundColor(viewModel.showDuplicateError ? .red : .white)
                        .autocapitalization(.none)
                        .onChange(of: viewModel.tagetWeb) { _ in
                            viewModel.clearError()
                        }
                }
            }
            .frame(height: 58)
            .background(Color(.bgForBut))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(viewModel.showDuplicateError ? Color.red : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                Text("Rule applies to this domain and all its subdomains.")
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
                Spacer()
            }
        }
    }

    // MARK: - Blocking Options

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
                              titel: "Anti-Adblock Killer",
                              bgForIcon: "orangeWithAlpha",
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

    // MARK: - Domain Activity (всегда показываем)

    private var domainAvtivity: some View {
        HStack {
            Text("Domain Activity")
                .font(.custom("Inter18pt-SemiBold", size: 14))
                .foregroundStyle(.white)
            Spacer()

            Menu {
                Button("Last 24h ") {
                    viewModel.selectDateRange(.lastDay)
                }
                Button("Last week") {
                    viewModel.selectDateRange(.lastWeek)
                }
                Button("Last month") {
                    viewModel.selectDateRange(.lastMonth)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.rangeOfDates.displayValue)
                        .font(.custom("Inter18pt-Regular", size: 12))
                        .foregroundStyle(.grayText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.grayText)
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            viewModel.saveRule()
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image("whiteShield")
                        .frame(width:16 , height: 16)
                    Text((viewModel.isEditMode ? "Save Rule" : "Add Rule"))
                        .font(.custom("Inter18pt-SemiBold", size: 16))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.red))
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .disabled(viewModel.tagetWeb.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
        .opacity(viewModel.tagetWeb.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
    }
}

// MARK: - Row

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
                    .fill(Color(bgForIcon))
                    .frame(width: 40, height: 40)
                Image(imageName)
                    .frame(width: 40, height: 40)
            }
            VStack(alignment: .leading) {
                Text(titel)
                    .font(.custom("Inter18pt-Medium", size: 14))
                    .foregroundStyle(.white)
                Text(subTitel)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundColor(.grayText)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color("AccentColor"))
        }
        .padding()
    }
}
