import SwiftUI

struct CustomView: View {
    @StateObject var viewModel: CstomViewModel
    @EnvironmentObject var coordinator: AppCoordinator

    init(viewModel: CstomViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    header
                    customSearchBar
                        .padding(.vertical, 4)

                    // MARK: - Active Rules
                    if !viewModel.activeRules.isEmpty {
                        sectionHeader("ACTIVE")

                        ForEach(viewModel.activeRules) { rule in
                            CustomRuleRow(
                                domain: rule.domain,
                                subtitle: viewModel.subtitle(for: rule),
                                isEnabled: true,
                                onToggle: { viewModel.toggleRule(rule) },
                                onDelete: { viewModel.deleteRule(rule) }
                            )
                        }
                    }

                    // MARK: - Inactive Rules
                    if !viewModel.inactiveRules.isEmpty {
                        sectionHeader("INACTIVE")

                        ForEach(viewModel.inactiveRules) { rule in
                            CustomRuleRow(
                                domain: rule.domain,
                                subtitle: "Paused",
                                isEnabled: false,
                                onToggle: { viewModel.toggleRule(rule) },
                                onDelete: { viewModel.deleteRule(rule) }
                            )
                        }
                    }

                    // MARK: - Empty State
                    if viewModel.activeRules.isEmpty && viewModel.inactiveRules.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $viewModel.showAddCustomRule, onDismiss: { viewModel.dismissAddCustomRule() }) {
            AddCustomRule(viewModel: AddCustomRuleViewModel(
                coordinator: coordinator,
                customRulesStore: coordinator.customRulesStore,
                ruleService: coordinator.ruleService,
                configProvider: coordinator.customRuleConfigProvider,
                onDismiss: { viewModel.dismissAddCustomRule() }
            ))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image("CustomTab")
                .foregroundStyle(.grayText)

            Spacer()
            Text("Custom Rules")
                .font(.custom("Inter18pt-Bold", size: 18))
                .foregroundStyle(.white)
            Spacer()

            Button(action: {
                viewModel.openAddCustomRule()
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.red)
            }
            .frame(width: 36, height: 36)
        }
    }

    // MARK: - Search

    private var customSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .frame(width: 16, height: 16)
                .foregroundStyle(.grayText)
                .padding(.leading)
            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text("Search domains...")
                        .foregroundColor(Color("PlaceHolder"))
                }
                TextField("", text: $viewModel.searchText)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
        .frame(height: 58)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("Inter18pt-Bold", size: 12))
                .foregroundColor(.grayText)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("CastomRules")
                .frame(width: 96, height: 96)

            Text("Add specific rules to block elements\non sites that bypass general filters.")
                .font(.custom("Inter18pt-Regular", size: 14))
                .foregroundColor(.grayText)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Row

struct CustomRuleRow: View {
    let domain: String
    let subtitle: String
    let isEnabled: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var toggleState: Bool

    init(domain: String, subtitle: String, isEnabled: Bool,
         onToggle: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.domain = domain
        self.subtitle = subtitle
        self.isEnabled = isEnabled
        self.onToggle = onToggle
        self.onDelete = onDelete
        self._toggleState = State(initialValue: isEnabled)
    }

    var body: some View {
        HStack {
            // Иконка домена (первая буква)
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(String(domain.prefix(1)).uppercased())
                    .font(.custom("Inter18pt-Bold", size: 16))
                    .foregroundColor(isEnabled ? .red : .grayText)
            }
            .padding(.leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(domain)
                    .font(.custom("Inter18pt-SemiBold", size: 16))
                    .foregroundStyle(isEnabled ? .white : .grayText)
                Text(subtitle)
                    .font(.custom("Inter18pt-Regular", size: 12))
                    .foregroundStyle(.grayText)
            }

            Spacer()

            Toggle("", isOn: $toggleState)
                .labelsHidden()
                .tint(.accent)
                .padding(.trailing)
                .onChange(of: toggleState) { _ in
                    onToggle()
                }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 72)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Rule", systemImage: "trash")
            }
        }
    }
}
