import SwiftUI

struct CandidateSelectView: View {
    let candidates: [IdentifyCandidate]
    let sessionId: String
    let onSelect: (String, String) -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [FoodSearchItem] = []
    @State private var isSearching = false
    @State private var selectedName: String?
    @State private var isConfirming = false

    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            navBar

            ScrollView {
                VStack(spacing: 16) {
                    // AI 识别候选
                    if candidates.isEmpty {
                        emptyCandidateView
                    } else {
                        candidateSection
                    }

                    // 搜索栏
                    searchSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background { SafeEatMainGradientBackground() }
        .navigationBarHidden(true)
    }

    // MARK: - 导航栏

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(SafeEatTheme.textSecondary)
            }

            Spacer()

            Text(SafeEatL10n.text(L10nKey.Candidate.title))
                .font(SafeEatFont.textStyle(.headline))
                .foregroundColor(SafeEatTheme.textPrimary)

            Spacer()

            Color.clear.frame(width: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - 候选列表

    private var candidateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Candidate.aiResult))
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundColor(SafeEatTheme.textSecondary)

            ForEach(candidates) { candidate in
                candidateRow(candidate)
            }
        }
    }

    private func candidateRow(_ candidate: IdentifyCandidate) -> some View {
        let isSelected = selectedName == candidate.name
        let percent = Int((candidate.confidence * 100).rounded())

        return Button {
            selectedName = candidate.name
            confirmSelection(candidate.name)
        } label: {
            HStack(spacing: 14) {
                // 置信度圆环
                ZStack {
                    Circle()
                        .stroke(SafeEatTheme.line, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: candidate.confidence)
                        .stroke(
                            confidenceColor(candidate.confidence),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Text("\(percent)%")
                        .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .semibold))
                        .foregroundColor(SafeEatTheme.textPrimary)
                }

                Text(candidate.name)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundColor(SafeEatTheme.textPrimary)

                Spacer()

                if isSelected && isConfirming {
                    ProgressView()
                        .tint(SafeEatTheme.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SafeEatTheme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? SafeEatTheme.primary.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SafeEatTheme.primary.opacity(0.3) : SafeEatTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
    }

    // MARK: - 搜索

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Candidate.searchHint))
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundColor(SafeEatTheme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(SafeEatTheme.textSecondary)

                TextField(SafeEatL10n.text(L10nKey.Candidate.searchPlaceholder), text: $searchText)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundColor(SafeEatTheme.textPrimary)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(newValue)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SafeEatTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(SafeEatTheme.line, lineWidth: 1)
            )

            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(SafeEatTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if !searchResults.isEmpty {
                ForEach(searchResults) { item in
                    searchResultRow(item)
                }
            } else if searchText.count >= 2 {
                Text(SafeEatL10n.text(L10nKey.Candidate.noResult))
                    .font(SafeEatFont.textStyle(.subheadline))
                    .foregroundColor(SafeEatTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private func searchResultRow(_ item: FoodSearchItem) -> some View {
        let isSelected = selectedName == item.name

        return Button {
            selectedName = item.name
            confirmSelection(item.name)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14))
                    .foregroundColor(SafeEatTheme.primary)

                Text(item.name)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundColor(SafeEatTheme.textPrimary)

                Spacer()

                if isSelected && isConfirming {
                    ProgressView()
                        .tint(SafeEatTheme.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SafeEatTheme.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? SafeEatTheme.primary.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? SafeEatTheme.primary.opacity(0.3) : SafeEatTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
    }

    // MARK: - 空候选

    private var emptyCandidateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 36))
                .foregroundColor(SafeEatTheme.textSecondary)
            Text(SafeEatL10n.text(L10nKey.Candidate.emptyHint))
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundColor(SafeEatTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 方法

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return SafeEatTheme.success }
        if confidence >= 0.5 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

    private func confirmSelection(_ name: String) {
        guard !isConfirming else { return }
        isConfirming = true
        onSelect(name, sessionId)
    }

    private func performSearch(_ query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        Task {
            isSearching = true
            defer { isSearching = false }
            do {
                guard let token = store.session?.accessToken else { return }
                let response = try await store.api.searchFoods(accessToken: token, query: query)
                searchResults = response.items
            } catch {
                searchResults = []
            }
        }
    }
}

#Preview {
    NavigationStack {
        CandidateSelectView(
            candidates: [
                IdentifyCandidate(name: "红烧肉", confidence: 0.92, type: nil, source: nil),
                IdentifyCandidate(name: "东坡肉", confidence: 0.78, type: nil, source: nil),
                IdentifyCandidate(name: "扣肉", confidence: 0.45, type: nil, source: nil)
            ],
            sessionId: "test-session",
            onSelect: { _, _ in }
        )
    }
    .environmentObject(AppStore())
}
