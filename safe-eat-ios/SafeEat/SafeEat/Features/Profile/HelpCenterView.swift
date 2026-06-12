import SwiftUI

struct HelpCenterView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ProfileSecondaryPage(
            title: "帮助中心",
            subtitle: "常见问题与使用指南"
        ) {
            ForEach(faqSections) { section in
                ProfileSectionBlock(title: section.title) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { index, item in
                        FAQRow(question: item.question, answer: item.answer)
                        if index < section.items.count - 1 {
                            Divider().overlay(SafeEatTheme.line)
                        }
                    }
                }
            }

            ProfileSectionBlock(title: "联系我们") {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                    Text("bel_safeeat@163.com")
                        .font(SafeEatFont.textStyle(.body))
                        .foregroundStyle(SafeEatTheme.primary)
                }
                .onTapGesture {
                    if let url = URL(string: "mailto:bel_safeeat@163.com") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

// MARK: - FAQ 折叠行

private struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Text("Q")
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(SafeEatTheme.primary))
                    Text(question)
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(alignment: .top, spacing: 10) {
                    Text("A")
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(SafeEatTheme.primarySoft))
                        .overlay(Circle().stroke(SafeEatTheme.primary, lineWidth: 1.5))
                    Text(answer)
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FAQ 数据

private struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [FAQItem]
}

private struct FAQItem {
    let question: String
    let answer: String
}

private let faqSections: [FAQSection] = [
    FAQSection(title: "识别与使用", items: [
        FAQItem(
            question: "拍照识别支持哪些食物？",
            answer: "支持大多数常见中餐、西餐、日料、韩餐等菜品，以及水果、零食、饮品等。识别准确度受拍摄角度、光线、遮挡等因素影响，建议正对食物、光线充足时拍摄。"
        ),
        FAQItem(
            question: "识别结果不准确怎么办？",
            answer: "AI 识别受拍摄条件影响，可能存在偏差。结果仅供参考，不构成医疗或专业营养建议。如发现明显错误，可通过「意见反馈」告知我们。"
        ),
        FAQItem(
            question: "免费用户可以拍照识别吗？",
            answer: "免费用户享有基础识别次数，具体额度以应用内实时展示为准。开通会员可获得更多次数。"
        ),
        FAQItem(
            question: "看广告获得的识别次数可以累积吗？",
            answer: "广告兑换的识别次数仅限当日使用，不可跨天累积，每日补次上限以应用内提示为准。"
        ),
    ]),
    FAQSection(title: "会员与订阅", items: [
        FAQItem(
            question: "会员有哪些等级？",
            answer: "共三个付费等级：轻享版（Lite）适合日常管理入门，专业版（Pro）提供深度营养分析，至尊版（Premium）全功能解锁且无广告。"
        ),
        FAQItem(
            question: "如何取消自动续费？",
            answer: "iOS：设置 → Apple ID → 订阅 → 选择食安安 → 取消订阅。鸿蒙/华为：华为应用市场 → 订阅管理 → 取消。微信/支付宝：在对应支付平台的自动扣款管理中关闭。取消后当前周期权益不受影响。"
        ),
        FAQItem(
            question: "如何申请退款？",
            answer: "iOS/Apple 内购：访问 reportaproblem.apple.com 申请退款，由 Apple 审核。鸿蒙/华为：在应用市场订单管理中申请。微信/支付宝代扣：联系 bel_safeeat@163.com 处理。"
        ),
        FAQItem(
            question: "免费试用到期会自动扣费吗？",
            answer: "是的，3天免费试用到期后会自动转为付费订阅并扣款。如不想继续，请在试用期内取消订阅。"
        ),
    ]),
    FAQSection(title: "账号与数据", items: [
        FAQItem(
            question: "如何注销账号？",
            answer: "个人中心 → 账号与安全 → 删除账号。提交后进入7天冷静期，冷静期内可撤回。期满后账号永久注销，数据不可恢复。详见《账号注销指引》。"
        ),
        FAQItem(
            question: "我的饮食数据安全吗？",
            answer: "所有数据传输使用 HTTPS/TLS 加密，敏感信息在数据库中加密存储。我们不会出售您的个人数据，不会用于精准广告投放。详见《隐私政策》。"
        ),
        FAQItem(
            question: "食物照片会被用于其他用途吗？",
            answer: "不会。照片仅用于食物识别分析，不会用于人脸识别或其他非声明用途。您可随时在历史记录中删除照片数据。"
        ),
    ]),
    FAQSection(title: "其他", items: [
        FAQItem(
            question: "食安安可以替代医生建议吗？",
            answer: "不可以。食安安仅为日常饮食辅助参考工具，所有分析结果不构成医疗诊断、诊疗建议或专业营养指导。患有基础疾病请务必遵从执业医师意见。"
        ),
        FAQItem(
            question: "如何切换应用语言？",
            answer: "个人中心 → 语言设置，支持中文和英文切换。"
        ),
    ]),
]

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
