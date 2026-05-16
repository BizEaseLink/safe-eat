import SwiftUI

struct SignupBonusSheet: View {
    let bonusQuota: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text(SafeEatL10n.text(L10nKey.Home.signupBonusWelcomeTitle))
                .font(.title2)
                .bold()

            Text(SafeEatL10n.format(L10nKey.Home.signupBonusQuotaFormat, bonusQuota))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(SafeEatL10n.text(L10nKey.Home.signupBonusSubtitle))
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Button(SafeEatL10n.text(L10nKey.Home.signupBonusStartAction)) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(32)
    }
}

#Preview {
    SignupBonusSheet(bonusQuota: 10, onDismiss: {})
}
