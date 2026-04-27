import SwiftUI

struct CertificateGalleryView: View {
    @State private var items: [DisclosureItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.danger)
                    .padding(20)
            } else if items.isEmpty {
                Text(SafeEatL10n.text(L10nKey.Errors.invalidResponse))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .padding(20)
            } else {
//                RichContentView(html: buildHTML(from: items))
            }
        }
        .navigationTitle(SafeEatL10n.text(L10nKey.Profile.About.certificate))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCertificates() }
    }

    private func loadCertificates() async {
        do {
            items = try await SafeEatAPI().fetchDisclosure(category: "证件公示")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func buildHTML(from items: [DisclosureItem]) -> String {
        var parts: [String] = []
        for item in items {
            if items.count > 1 {
                parts.append("<h2>\(item.title)</h2>")
            }
            parts.append(item.content)
            if item.id != items.last?.id {
                parts.append("<hr>")
            }
        }
        return parts.joined(separator: "\n")
    }
}
