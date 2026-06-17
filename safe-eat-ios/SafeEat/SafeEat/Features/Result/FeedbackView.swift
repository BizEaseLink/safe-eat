import SwiftUI
import UIKit

struct FeedbackView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let recognition: RecognitionRecord
    let historyItem: LocalHistoryItem

    @State private var proposedName = ""
    @State private var comment = ""
    @State private var selectedFeedbackType: FeedbackType?
    @State private var replacementImage: UIImage?
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceDialog = false
    @State private var showImagePicker = false
    @State private var submitting = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var searchResults: [FoodSearchItem] = []
    @State private var isSearching = false

    private var displayName: String {
        let rawName = recognition.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawName.isEmpty || rawName == "未知食物" {
            return SafeEatL10n.text(L10nKey.Common.unknownFood)
        }
        return rawName
    }

    private var currentPreviewImage: UIImage? {
        replacementImage
            ?? LocalImageLoader.loadStickerImage(for: historyItem)
            ?? LocalImageLoader.loadDisplayImage(for: historyItem)
    }

    private var trimmedProposedName: String {
        proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !submitting && !trimmedProposedName.isEmpty
    }

    private var suggestionCandidates: [String] {
        // 食物库搜索结果，排除当前名称和输入值，最多3个
        let filtered = searchResults.map(\.name).filter { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty
                && trimmed != displayName
                && trimmed != trimmedProposedName
                && trimmed != SafeEatL10n.text(L10nKey.Common.unknownFood)
        }
        return Array(filtered.prefix(3))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                pageBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SafeEatGlobalScrollOffsetReader(
                            scrollOffset: $scrollOffset
                        )
                        .id(recognition.id)

                        Color.clear
                            .frame(height: proxy.safeAreaInsets.top + 74)

                        statusTag

                        heroSection

                        feedbackTypeSection

                        correctionZone

                        commentSection

                        auditNoteCard

                        submitButton

                        thanksFootnote

                        Color.clear
                            .frame(height: keyboardBottomSpacing(bottomInset: proxy.safeAreaInsets.bottom))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                SafeEatTopBackChrome(
                    title: SafeEatL10n.text(L10nKey.Feedback.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top,
                    onBack: { dismiss() }
                )
            }
            
            .ignoresSafeArea()
            .onTapGesture {
                isCommentFocused = false
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if proposedName.isEmpty {
                let initial = recognition.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
                proposedName = initial == "未知食物" ? "" : initial
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(with: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                keyboardHeight = 0
            }
        }
        .onChange(of: comment) { _, newValue in
            if newValue.count > 200 {
                comment = String(newValue.prefix(200))
            }
        }
        .confirmationDialog(SafeEatL10n.text(L10nKey.Feedback.replaceEvidenceTitle), isPresented: $showSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(SafeEatL10n.text(L10nKey.Feedback.sourceCamera)) {
                    pickerSource = .camera
                    showImagePicker = true
                }
            }

            Button(SafeEatL10n.text(L10nKey.Feedback.sourceLibrary)) {
                pickerSource = .photoLibrary
                showImagePicker = true
            }

            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSource) { image in
                replacementImage = image
            }
        }
    }

    private var pageBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.12, green: 0.13, blue: 0.15),
                        Color(red: 0.09, green: 0.10, blue: 0.12),
                    ]
                    : [
                        Color(red: 0.99, green: 0.995, blue: 0.99),
                        Color(red: 0.965, green: 0.978, blue: 0.968),
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.15 : 0.52),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 18,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.91, blue: 0.78).opacity(colorScheme == .dark ? 0.08 : 0.30),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 280
            )
        }
    }

    private var statusTag: some View {
        Text(SafeEatL10n.text(L10nKey.Feedback.status))
            .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
            .foregroundStyle(SafeEatTheme.warning)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.18 : 0.12))
            )
            .overlay(
                Capsule()
                    .stroke(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.26 : 0.18), lineWidth: 1)
            )
    }

    private var feedbackTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SafeEatL10n.text(L10nKey.Feedback.typeTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FeedbackType.allCases) { type in
                        let isSelected = selectedFeedbackType == type
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFeedbackType = isSelected ? nil : type
                            }
                        } label: {
                            Text(type.displayName)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                                .foregroundStyle(isSelected ? .white : SafeEatTheme.primaryDeep)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected
                                             ? AnyShapeStyle(LinearGradient(
                                                colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                             : AnyShapeStyle(colorScheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : SafeEatTheme.primarySoft.opacity(0.72)))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(SafeEatL10n.text(L10nKey.Feedback.typeHint))
                .font(SafeEatFont.custom(13, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SafeEatL10n.text(L10nKey.Feedback.heroTitle))
                .font(SafeEatFont.custom(36, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Feedback.heroSubtitle))
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)

            Text(SafeEatL10n.text(L10nKey.Feedback.heroBody))
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private var correctionZone: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentRecognitionCard

            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.08)
                                  : Color.white.opacity(0.82))
                    )
                Spacer()
            }

            correctionCard
        }
    }

    private var currentRecognitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                badge(title: SafeEatL10n.text(L10nKey.Feedback.badgeCurrent), emphasized: false)
                Spacer()

                Button {
                    showSourceDialog = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.78))
                        )
                }
                .buttonStyle(.plain)
            }

            Group {
                if let image = currentPreviewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 6)
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 26))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            Text(displayName)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var correctionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            badge(title: SafeEatL10n.text(L10nKey.Feedback.badgeCorrect), emphasized: true)

            HStack(spacing: 10) {
                // 当前识别名称（固定位第一个，可点选回填）
                Button {
                    proposedName = displayName
                    searchResults = []
                    isNameFieldFocused = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                        Text(displayName)
                            .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(SafeEatTheme.primaryDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // 搜索按钮
                Button {
                    isNameFieldFocused = false
                    searchFoods()
                } label: {
                    Group {
                        if isSearching {
                            ProgressView()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSearching || trimmedProposedName.isEmpty)
                .opacity(trimmedProposedName.isEmpty ? 0.4 : 1)
            }

            HStack(spacing: 10) {
                TextField(SafeEatL10n.text(L10nKey.Feedback.inputPlaceholder), text: $proposedName)
                    .focused($isNameFieldFocused)
                    .font(SafeEatFont.custom(18, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: proposedName) { _, _ in
                        searchResults = []
                    }

                if !trimmedProposedName.isEmpty {
                    Button {
                        proposedName = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(fieldFill)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // 搜索结果
            if !suggestionCandidates.isEmpty {
                Text(SafeEatL10n.text(L10nKey.Feedback.suggestionsTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                    ForEach(suggestionCandidates, id: \.self) { suggestion in
                        Button {
                            proposedName = suggestion
                            searchResults = []
                            isNameFieldFocused = false
                        } label: {
                            Text(suggestion)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                                .foregroundStyle(SafeEatTheme.primaryDeep)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func searchFoods() {
        guard !trimmedProposedName.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let response = try await store.authorizedRequest { token in
                    try await store.api.searchFoods(accessToken: token, query: trimmedProposedName)
                }
                searchResults = response.items
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

//    private var commentSection: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("补充说明（可选）")
//                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
//                .foregroundStyle(SafeEatTheme.textSecondary)
//
//            ZStack(alignment: .topLeading) {
//                RoundedRectangle(cornerRadius: 24, style: .continuous)
//                    .fill(fieldFill)
//                    .overlay(cardStroke(cornerRadius: 24))
//
//                if comment.isEmpty {
//                    Text("这不是普通凉面，调味偏清淡，但有酱汁。")
//                        .font(SafeEatFont.custom(18, relativeTo: .body))
//                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.65))
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .allowsHitTesting(false)
//                }
//
//                TextEditor(text: $comment)
//                    .font(SafeEatFont.custom(18, relativeTo: .body))
//                    .foregroundColor(SafeEatTheme.textPrimary)
//                    .scrollContentBackground(.hidden)
//                    .frame(minHeight: 132)
//                    .padding(.horizontal, 10)
//                    .padding(.top, 8)
//
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Text("\(comment.count)/200")
//                            .font(SafeEatFont.custom(12, relativeTo: .caption))
//                            .foregroundStyle(SafeEatTheme.textSecondary)
//                            .padding(.trailing, 16)
//                            .padding(.bottom, 14)
//                    }
//                }
//            }
//            .frame(minHeight: 156)
//        }
//    }
    
    @FocusState private var isCommentFocused: Bool
    @FocusState private var isNameFieldFocused: Bool

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Feedback.noteTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fieldFill)
                    .overlay(cardStroke(cornerRadius: 24))

                if comment.isEmpty {
                    Text(SafeEatL10n.text(L10nKey.Feedback.notePlaceholder))
                        .font(SafeEatFont.custom(16, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $comment)
                    .focused($isCommentFocused)
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundColor(SafeEatTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 132)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .background(Color.clear)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(SafeEatL10n.format(L10nKey.Feedback.noteCountFormat, comment.count))
                            .font(SafeEatFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .padding(.trailing, 16)
                            .padding(.bottom, 14)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(minHeight: 156)
        }
    }
    

    private var auditNoteCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 24))
                .foregroundStyle(SafeEatTheme.success)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(SafeEatL10n.text(L10nKey.Feedback.auditTitle))
                    .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(colorScheme == .dark ? Color(red: 0.80, green: 0.94, blue: 0.84) : SafeEatTheme.primaryDeep)

                Text(SafeEatL10n.text(L10nKey.Feedback.auditBody))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.78) : SafeEatTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? SafeEatTheme.primaryDeep.opacity(0.38) : SafeEatTheme.primarySoft.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : SafeEatTheme.line, lineWidth: 1)
        )
    }

    private var submitButton: some View {
        Button {
            Task {
                await submit()
            }
        } label: {
            Group {
                if submitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(SafeEatL10n.text(L10nKey.Feedback.submit))
                        .font(SafeEatFont.custom(22, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: SafeEatTheme.primaryDeep.opacity(0.16), radius: 16, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.58)
    }

    private var thanksFootnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 18, weight: .semibold))
            Text(SafeEatL10n.text(L10nKey.Feedback.thanks))
                .font(SafeEatFont.custom(16, relativeTo: .footnote))
        }
        .foregroundStyle(colorScheme == .dark ? Color(red: 0.73, green: 0.90, blue: 0.78) : SafeEatTheme.primary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }

    private func badge(title: String, emphasized: Bool) -> some View {
        Text(title)
            .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
            .foregroundStyle(emphasized ? Color.white : SafeEatTheme.primaryDeep)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        emphasized
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : SafeEatTheme.primarySoft.opacity(0.80)
                            )
                    )
            )
    }

    private var correctionCardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.62)
    }

    private var fieldFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.78)
    }

    private func cardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
    }

    private func keyboardBottomSpacing(bottomInset: CGFloat) -> CGFloat {
        if keyboardHeight <= 0 {
            return 20
        }

        return max(32, keyboardHeight - bottomInset + 52)
    }

    private func updateKeyboardHeight(with notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        let overlap = max(0, UIScreen.main.bounds.height - frame.minY)
        withAnimation(.easeInOut(duration: 0.22)) {
            keyboardHeight = overlap
        }
    }

    private func submit() async {
        submitting = true
        defer { submitting = false }

        // 异步发给后端，根据响应决定本地更新策略
        Task {
            do {
                let records = try await store.authorizedRequest { token in
                    try await store.api.submitFeedback(
                        accessToken: token,
                        recognitionId: recognition.id,
                        proposedName: trimmedProposedName,
                        comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                        feedbackType: selectedFeedbackType
                    )
                }

                if let updatedRecord = records.first {
                    // 知识库有匹配：全量替换本地数据
                    store.replaceRecognitionData(for: historyItem.id, with: updatedRecord)
                } else {
                    // 知识库无匹配：只加待审核标记，不改数据
                    store.setFeedbackPending(for: historyItem.id, pending: true)
                }
            } catch {
                #if DEBUG
                print("[Feedback] 后端请求失败: \(error)")
                #endif
                // 后端失败时，本地只改名称作为降级
                store.updateLocalRecognizedName(trimmedProposedName, for: historyItem.id)
            }
        }

        dismiss()
    }
}
