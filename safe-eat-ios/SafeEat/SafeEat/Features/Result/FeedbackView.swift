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
    @State private var replacementImage: UIImage?
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceDialog = false
    @State private var showImagePicker = false
    @State private var submitting = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    private var displayName: String {
        let rawName = recognition.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawName.isEmpty || rawName == "未知食物" {
            return "未识别食物"
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
        let base = [
            trimmedProposedName,
            displayName,
            "日式荞麦面",
            "荞麦冷面",
            "凉拌荞麦面",
        ]

        var seen = Set<String>()
        return base.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != "未识别食物", seen.insert(trimmed).inserted else {
                return nil
            }
            return trimmed
        }
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
                    title: "反馈",
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
        .confirmationDialog("更换证据图", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("拍照补传") {
                    pickerSource = .camera
                    showImagePicker = true
                }
            }

            Button("从相册选择") {
                pickerSource = .photoLibrary
                showImagePicker = true
            }

            Button("取消", role: .cancel) {}
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
        Text("反馈将在上传后进入审核")
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

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("识别结果不准确？")
                .font(SafeEatFont.custom(36, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text("帮我们修正一下")
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)

            Text("你的修改会用于优化识别模型，让结果更准确。")
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private var correctionZone: some View {
//        GeometryReader { proxy in
//            let leftWidth = min(max(proxy.size.width * 0.36, 126), 158)
//            let arrowWidth: CGFloat = 28
//            let rightWidth = max(proxy.size.width - leftWidth - arrowWidth - 24, 160)
//
//            HStack(alignment: .center, spacing: 12) {
//                currentRecognitionCard
//                    .frame(width: leftWidth)
//
//                Image(systemName: "arrow.right")
//                    .font(.system(size: 24, weight: .semibold))
//                    .foregroundStyle(SafeEatTheme.textSecondary)
//                    .frame(width: arrowWidth)
//
//                correctionCard
//                    .frame(width: rightWidth)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
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
        .padding(.bottom, 16)
//        .frame(height: 272)
    }

    private var currentRecognitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                badge(title: "当前识别", emphasized: false)
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

            Spacer(minLength: 0)

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
            .frame(height: 126)

            Text(displayName)
                .font(SafeEatFont.custom(17, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var correctionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            badge(title: "你认为正确的是", emphasized: true)

            HStack(spacing: 10) {
                TextField("例如：日式荞麦面", text: $proposedName)
                    .font(SafeEatFont.custom(18, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !trimmedProposedName.isEmpty {
                    Button {
                        proposedName = ""
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

            Text("试试这些：")
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                ForEach(suggestionCandidates.prefix(4), id: \.self) { suggestion in
                    Button {
                        proposedName = suggestion
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

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("补充说明（可选）")
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fieldFill)
                    .overlay(cardStroke(cornerRadius: 24))

                if comment.isEmpty {
                    Text("这不是普通凉面，调味偏清淡，但有酱汁。")
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
                        Text("\(comment.count)/200")
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
                Text("我们会认真审核")
                    .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(colorScheme == .dark ? Color(red: 0.80, green: 0.94, blue: 0.84) : SafeEatTheme.primaryDeep)

                Text("审核完成后只保留结构化记录，不会泄露你的个人信息。")
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
                    Text("提交修正")
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
            Text("感谢你的帮助，你的反馈将让识别更精准！")
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
        let data = replacementImage?.jpegDataForUpload()
            ?? LocalImageLoader.loadRawImage(for: historyItem)?.jpegDataForUpload()

        guard let evidenceData = data else {
            store.errorMessage = "反馈必须附带证据图。"
            return
        }

        submitting = true
        defer { submitting = false }

        do {
            let payload = FeedbackPayload(
                proposedName: trimmedProposedName,
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                evidenceImageData: evidenceData
            )
            let updatedRecognition = try await store.authorizedRequest { token in
                try await store.api.submitFeedback(
                    accessToken: token,
                    recognitionId: recognition.id,
                    payload: payload
                )
            }
            store.cacheRecognition(updatedRecognition, for: historyItem.id)
            dismiss()
        } catch {
            store.handleAPIError(error)
        }
    }
}
