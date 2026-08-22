import SwiftUI

/// Households tab: list all joined households with recipe counts and a Join Household form.
struct HouseholdsView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @State private var model = JoinHouseholdModel()
    @State private var recipeCounts: [UUID: Int] = [:]
    @State private var isLoadingCounts = false

    private let recipesRepository = RecipesRepository()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                Section("Join a Household") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("6-character code", text: $model.inviteCode)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .onChange(of: model.inviteCode) { _, newValue in
                                    model.inviteCode = String(newValue.prefix(6)).uppercased()
                                    if model.errorMessage != nil { model.errorMessage = nil }
                                    if model.successMessage != nil { model.successMessage = nil }
                                }

                            Button {
                                Task {
                                    await model.join(auth: auth, recipesRefresh: recipesRefresh)
                                    await loadRecipeCounts()
                                }
                            } label: {
                                if model.isLoading {
                                    ProgressView()
                                        .frame(height: 20)
                                } else {
                                    Text("Join")
                                        .bold()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.nnTint)
                            .disabled(model.inviteCode.count < 6 || model.isLoading)
                        }

                        if let errorMessage = model.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }

                        if let successMessage = model.successMessage {
                            Text(successMessage)
                                .font(.footnote)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.easeInOut, value: model.successMessage)
                    .animation(.easeInOut, value: model.errorMessage)
                }

                Section("My Households") {
                    if auth.joinedHouseholds.isEmpty {
                        Text("No households joined yet.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(auth.joinedHouseholds) { household in
                            NavigationLink(destination: HouseholdDetailView(household: household)) {
                                householdRow(household)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Households")
            .task {
                await loadRecipeCounts()
            }
            .onChange(of: auth.joinedHouseholdIds) {
                Task {
                    await loadRecipeCounts()
                }
            }
            .refreshable {
                await auth.refreshJoinedHouseholds()
                await loadRecipeCounts()
            }
        }
    }

    private func householdRow(_ household: Household) -> some View {
        let isOwner = auth.isOwner(of: household.id) || household.id == auth.householdId
        let name = household.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = (name != nil && !name!.isEmpty) ? name! : "Household (\(household.id.uuidString.suffix(4)))"
        let count = recipeCounts[household.id, default: 0]
        let pendingCount = auth.pendingRequestCounts[household.id, default: 0]

        return HStack(spacing: 12) {
            Image(systemName: isOwner ? "star.fill" : "house.fill")
                .foregroundColor(isOwner ? .orange : .nnTint)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.body)
                        .fontWeight(.semibold)

                    if isOwner {
                        Text("Owner")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())

                        if pendingCount > 0 {
                            Text("\(pendingCount) pending")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 12) {
                    Text("\(count) \(count == 1 ? "recipe" : "recipes")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Code: \(household.inviteCode)")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func loadRecipeCounts() async {
        guard !auth.joinedHouseholdIds.isEmpty else {
            recipeCounts = [:]
            return
        }
        isLoadingCounts = true
        do {
            recipeCounts = try await recipesRepository.fetchRecipeCounts(householdIDs: auth.joinedHouseholdIds)
        } catch {
            // Keep previous counts on error
        }
        isLoadingCounts = false
    }
}
