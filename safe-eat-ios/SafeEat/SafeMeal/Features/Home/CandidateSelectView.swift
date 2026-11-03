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
        .background { SafeMealMainGradientBackground() }
        .navigationBarHidden(true)
    }

    // MARK: - 导航栏

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HugeIcon(glyph: .cancelCircle, size: 28)
                    .foregroundColor(SafeMealTheme.textSecondary)
            }

            Spacer()

            Text(SafeMealL10n.text(L10nKey.Candidate.title))
                .font(SafeMealFont.textStyle(.headline))
                .foregroundColor(SafeMealTheme.textPrimary)

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
            Text(SafeMealL10n.text(L10nKey.Candidate.aiResult))
                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                .foregroundColor(SafeMealTheme.textSecondary)

            // 按置信度从高到低排列，最可能的放最上面
            ForEach(candidates.sorted { $0.confidence > $1.confidence }) { candidate in
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
            HStack(spacing: 16) {
                // 置信度圆环（放大到 52，百分比更清楚）
                ZStack {
                    Circle()
                        .stroke(SafeMealTheme.line, lineWidth: 3.5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: candidate.confidence)
                        .stroke(
                            confidenceColor(candidate.confidence),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(percent)%")
                        .font(SafeMealFont.custom(13, relativeTo: .caption, weight: .bold))
                        .foregroundColor(SafeMealTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(SafeMealFont.custom(18, relativeTo: .body, weight: .semibold))
                        .foregroundColor(SafeMealTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    if let type = candidate.type, !type.isEmpty {
                        Text(type)
                            .font(SafeMealFont.custom(12, relativeTo: .caption))
                            .foregroundColor(SafeMealTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if isSelected && isConfirming {
                    ProgressView()
                        .tint(SafeMealTheme.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SafeMealTheme.textSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? SafeMealTheme.primary.opacity(0.10) : colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? SafeMealTheme.primary.opacity(0.35) : SafeMealTheme.line, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
    }

    // MARK: - 搜索

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeMealL10n.text(L10nKey.Candidate.searchHint))
                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                .foregroundColor(SafeMealTheme.textSecondary)

            HStack(spacing: 12) {
                HugeIcon(glyph: .search01, size: 18)
                    .foregroundColor(SafeMealTheme.textSecondary)

                TextField(SafeMealL10n.text(L10nKey.Candidate.searchPlaceholder), text: $searchText)
                    .font(SafeMealFont.textStyle(.body))
                    .foregroundColor(SafeMealTheme.textPrimary)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(newValue)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        HugeIcon(glyph: .cancelCircle, size: 16)
                            .foregroundColor(SafeMealTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SafeMealTheme.line, lineWidth: 1)
            )

            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(SafeMealTheme.primary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if !searchResults.isEmpty {
                ForEach(searchResults) { item in
                    searchResultRow(item)
                }
            } else if searchText.count >= 2 {
                Text(SafeMealL10n.text(L10nKey.Candidate.noResult))
                    .font(SafeMealFont.textStyle(.subheadline))
                    .foregroundColor(SafeMealTheme.textSecondary)
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
            HStack(spacing: 14) {
                HugeIcon(glyph: .restaurant02, size: 18)
                    .foregroundColor(SafeMealTheme.primary)

                Text(item.name)
                    .font(SafeMealFont.custom(17, relativeTo: .body, weight: .medium))
                    .foregroundColor(SafeMealTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                if isSelected && isConfirming {
                    ProgressView()
                        .tint(SafeMealTheme.primary)
                } else {
                    HugeIcon(glyph: .arrowRight01, size: 14)
                        .foregroundColor(SafeMealTheme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? SafeMealTheme.primary.opacity(0.10) : colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SafeMealTheme.primary.opacity(0.3) : SafeMealTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
    }

    // MARK: - 空候选

    private var emptyCandidateView: some View {
        VStack(spacing: 12) {
            HugeIcon(glyph: .image01, size: 36)
                .foregroundColor(SafeMealTheme.textSecondary)
            Text(SafeMealL10n.text(L10nKey.Candidate.emptyHint))
                .font(SafeMealFont.textStyle(.subheadline))
                .foregroundColor(SafeMealTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 方法

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return SafeMealTheme.success }
        if confidence >= 0.5 { return SafeMealTheme.warning }
        return SafeMealTheme.danger
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
