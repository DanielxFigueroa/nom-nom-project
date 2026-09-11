import SwiftUI

/// A dedicated, collapsible card displaying on-device AI nutritional insights,
/// smart swaps, positive highlights, and pairing advice for PCOS nutrition.
struct PCOSInsightsCard: View {
    @Bindable var model: RecipeDetailModel
    @State private var isExpanded: Bool = true
    @State private var swapToConfirm: PCOSAnalysisResult.SwapSuggestion?
    @State private var showSwapAlert: Bool = false

    init(model: RecipeDetailModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView

            if isExpanded {
                contentBody
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.nnTint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.nnTint.opacity(0.22), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .animation(.easeInOut(duration: 0.25), value: model.pcosAnalysisState)
        .alert(
            "Apply Ingredient Swap?",
            isPresented: $showSwapAlert,
            presenting: swapToConfirm
        ) { swap in
            Button("Apply Swap") {
                Task {
                    await model.applySwap(swap)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { swap in
            Text("Replace \"\(swap.originalIngredient)\" with \"\(swap.suggestedSwap)\"? This will update the recipe for all members of your household.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.nnTint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PCOS Nutrition Insights")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if let result = model.pcosAnalysisState.value {
                        glycemicBadge(result: result)
                    }
                }

                Spacer()

                if model.pcosAnalysisState.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nnTint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("PCOS Nutrition Insights, \(isExpanded ? "expanded" : "collapsed")")
        .accessibilityHint("Double-tap to \(isExpanded ? "collapse" : "expand") insights")
    }

    private func glycemicBadge(result: PCOSAnalysisResult) -> some View {
        HStack(spacing: 5) {
            Image(systemName: result.isBloodSugarBalanced ? "checkmark.circle.fill" : "chart.line.uptrend.xyaxis")
                .font(.caption2.weight(.bold))
            Text(result.glycemicImpactBadge)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            result.isBloodSugarBalanced
                ? Color.nnSuccess.opacity(0.18)
                : Color.nnWarning.opacity(0.22),
            in: Capsule()
        )
        .foregroundStyle(
            result.isBloodSugarBalanced
                ? Color.nnSuccess
                : Color.nnWarning
        )
    }

    // MARK: - Content Body

    @ViewBuilder
    private var contentBody: some View {
        switch model.pcosAnalysisState {
        case .idle:
            idleView
        case .loading:
            loadingShimmerView
        case .failed(let errorMessage):
            errorView(message: errorMessage)
        case .loaded(let result):
            insightsDetailView(result: result)
        }
    }

    // MARK: - Idle State

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personalized analysis ready for your active focus areas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await model.loadPCOSAnalysis(forceRefresh: true)
                }
            } label: {
                Label("Generate Insights", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.nnTint, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Loading Shimmer

    private var loadingShimmerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Analyzing ingredients against PCOS profile…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                shimmerBar(widthFraction: 0.9, height: 14)
                shimmerBar(widthFraction: 0.75, height: 14)
                shimmerBar(widthFraction: 0.5, height: 14)
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.top, 4)
    }

    private func shimmerBar(widthFraction: CGFloat, height: CGFloat) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: proxy.size.width * widthFraction, height: height)
                .modifier(ShimmerModifier())
        }
        .frame(height: height)
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.nnWarning)
                Text("Unable to load insights")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            }

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await model.loadPCOSAnalysis(forceRefresh: true)
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.nnTint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Insights Detail

    private func insightsDetailView(result: PCOSAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Summary Note
            if !result.summaryNote.isEmpty {
                Text(result.summaryNote)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Positive Highlights Section
            if !result.positiveHighlights.isEmpty {
                positiveHighlightsSection(highlights: result.positiveHighlights)
                Divider()
            }

            // Smart Swaps Section
            smartSwapsSection(swaps: result.swaps)

            // Order of Eating & Pairing Advice Section
            if !result.pairingTips.isEmpty {
                Divider()
                pairingAdviceSection(tips: result.pairingTips)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Positive Highlights

    private func positiveHighlightsSection(highlights: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Positive Highlights", systemImage: "hand.thumbsup.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nnTint)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.nnSuccess)
                            .padding(.top, 2)

                        Text(highlight)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Smart Swaps

    private func smartSwapsSection(swaps: [PCOSAnalysisResult.SwapSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Smart Swaps", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nnTint)

            if swaps.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.nnSuccess)
                    Text("No swaps needed! This recipe fits your active PCOS profile nicely.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.systemBackground).opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(spacing: 8) {
                    ForEach(swaps) { swap in
                        swapCard(swap)
                    }
                }

                Button {
                    Task {
                        _ = await model.forkAsPCOSVariation(householdID: model.recipe.householdId)
                    }
                } label: {
                    HStack(spacing: 6) {
                        if model.isForkingVariation {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(model.isForkingVariation ? "Saving Variation…" : "Save as PCOS Variation")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.nnTint, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(model.isForkingVariation || model.isApplyingSwap)
                .padding(.top, 4)

                Text("Clones recipe with suggested swaps and tags it with PCOS.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func isSwapApplied(_ swap: PCOSAnalysisResult.SwapSuggestion) -> Bool {
        if model.appliedSwapIDs.contains(swap.id) {
            return true
        }
        if model.recipe.isPCOSAdapted && model.ingredients.contains(where: {
            $0.name.localizedCaseInsensitiveContains(swap.suggestedSwap)
        }) {
            return true
        }
        return false
    }

    private func swapCard(_ swap: PCOSAnalysisResult.SwapSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                // Original Ingredient
                VStack(alignment: .leading, spacing: 2) {
                    Text("Original")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(swap.originalIngredient)
                        .font(.subheadline.weight(.medium))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.nnTint)
                    .padding(.horizontal, 2)

                // Suggested Swap
                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggested")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.nnTint)

                    HStack(spacing: 4) {
                        Text(swap.suggestedSwap)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)

                        if let qty = swap.adjustedQuantity, !qty.isEmpty {
                            let unitStr = swap.adjustedUnit.map { " \($0)" } ?? ""
                            Text("(\(qty)\(unitStr))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            // Rationale
            if !swap.rationale.isEmpty {
                Text(swap.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action row: Apply Swap or Applied state
            HStack {
                Spacer()
                if isSwapApplied(swap) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2.weight(.bold))
                        Text("Swap Applied")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.nnSuccess.opacity(0.18), in: Capsule())
                    .foregroundStyle(Color.nnSuccess)
                } else {
                    Button {
                        swapToConfirm = swap
                        showSwapAlert = true
                    } label: {
                        HStack(spacing: 5) {
                            if model.isApplyingSwap && swapToConfirm?.id == swap.id {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2.weight(.bold))
                            }
                            Text("Apply Swap")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.nnTint.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.nnTint)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isApplyingSwap || model.isForkingVariation)
                }
            }
            .padding(.top, 2)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.nnTint.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Pairing Advice

    private func pairingAdviceSection(tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Order of Eating & Pairing Advice", systemImage: "fork.knife")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nnTint)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.nnTint.opacity(0.18))
                                .frame(width: 22, height: 22)
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.nnTint)
                        }
                        .padding(.top, 1)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Shimmer Animation Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.8)
                    .offset(x: proxy.size.width * phase)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}
