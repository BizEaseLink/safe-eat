import CoreText
import Foundation
import SwiftUI
import UIKit

enum SafeEatFont {
    private static let fallbackRegularFontName = "ChillRoundFRegular"
    private static let fallbackSemiboldFontName = "ChillRoundFSemibold"
    private static let fallbackBoldFontName = "ChillRoundFBold"

    private(set) static var activeRegularFontName = fallbackRegularFontName
    private(set) static var activeSemiboldFontName = fallbackSemiboldFontName
    private(set) static var activeBoldFontName = fallbackBoldFontName

    static func bootstrap() {
        let regularResult = registerAppFont(
            named: "ChillRoundFRegular",
            fileExtension: "ttf",
            subdirectory: "resource/fonts"
        )
        let semiboldResult = registerAppFont(
            named: "ChillRoundFSemibold",
            fileExtension: "ttf",
            subdirectory: "resource/fonts"
        )
        let boldResult = registerAppFont(
            named: "ChillRoundFBold",
            fileExtension: "ttf",
            subdirectory: "resource/fonts"
        )

        activeRegularFontName = regularResult.fontName ?? fallbackRegularFontName
        activeSemiboldFontName = semiboldResult.fontName ?? fallbackSemiboldFontName
        activeBoldFontName = boldResult.fontName ?? fallbackBoldFontName

        #if DEBUG
        print("[SafeEatFont] regular=\(activeRegularFontName) source=\(regularResult.source)")
        print("[SafeEatFont] semibold=\(activeSemiboldFontName) source=\(semiboldResult.source)")
        print("[SafeEatFont] bold=\(activeBoldFontName) source=\(boldResult.source)")
        #endif
    }

    static func textStyle(_ style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle:
            return .custom(activeBoldFontName, size: 34, relativeTo: .largeTitle)
        case .title:
            return .custom(activeBoldFontName, size: 28, relativeTo: .title)
        case .title2:
            return .custom(activeBoldFontName, size: 22, relativeTo: .title2)
        case .title3:
            return .custom(activeBoldFontName, size: 20, relativeTo: .title3)
        case .headline:
            return .custom(activeBoldFontName, size: 17, relativeTo: .headline)
        case .subheadline:
            return .custom(activeRegularFontName, size: 15, relativeTo: .subheadline)
        case .callout:
            return .custom(activeRegularFontName, size: 16, relativeTo: .callout)
        case .footnote:
            return .custom(activeRegularFontName, size: 13, relativeTo: .footnote)
        case .caption:
            return .custom(activeRegularFontName, size: 12, relativeTo: .caption)
        case .caption2:
            return .custom(activeRegularFontName, size: 11, relativeTo: .caption2)
        default:
            return .custom(activeRegularFontName, size: 16, relativeTo: .body)
        }
    }

    static func custom(
        _ size: CGFloat,
        relativeTo style: Font.TextStyle = .body,
        weight: SafeEatFontWeight? = nil
    ) -> Font {
        .custom(fontName(for: style, explicitWeight: weight), size: size, relativeTo: style)
    }

    static func uiFont(
        size: CGFloat,
        relativeTo style: Font.TextStyle = .body,
        weight: SafeEatFontWeight? = nil
    ) -> UIFont {
        let name = fontName(for: style, explicitWeight: weight)
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }

    private static func registerAppFont(
        named fileName: String,
        fileExtension: String,
        subdirectory: String
    ) -> (fontName: String?, source: String) {
        let fontURL = candidateFontURLs(
            named: fileName,
            fileExtension: fileExtension,
            subdirectory: subdirectory
        ).first

        guard let fontURL else {
            return (nil, "bundle missing \(fileName).\(fileExtension)")
        }

        var registrationError: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError)

        let postScriptNames = resolvedPostScriptNames(at: fontURL) + [
            fallbackRegularFontName,
            fallbackBoldFontName,
            fileName,
        ]

        if let resolvedName = postScriptNames.first(where: { UIFont(name: $0, size: 16) != nil }) {
            return (resolvedName, fontURL.lastPathComponent)
        }

        if let error = registrationError?.takeRetainedValue() {
            return (nil, CFErrorCopyDescription(error) as String? ?? "unknown font registration error")
        }

        return (nil, "registered but UIFont lookup failed for \(fontURL.lastPathComponent)")
    }

    private static func candidateFontURLs(
        named fileName: String,
        fileExtension: String,
        subdirectory: String
    ) -> [URL] {
        let bundle = Bundle.main
        let directMatch = [
            bundle.url(forResource: fileName, withExtension: fileExtension, subdirectory: subdirectory),
            bundle.url(forResource: fileName, withExtension: fileExtension),
        ].compactMap { $0 }

        if !directMatch.isEmpty {
            return directMatch
        }

        return bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: nil)?
            .filter { $0.lastPathComponent == "\(fileName).\(fileExtension)" } ?? []
    }

    private static func resolvedPostScriptNames(at fontURL: URL) -> [String] {
        var names: [String] = []

        if let provider = CGDataProvider(url: fontURL as CFURL),
           let cgFont = CGFont(provider),
           let postScriptName = cgFont.postScriptName as String? {
            names.append(postScriptName)
        }

        let descriptorNames = (CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor])?
            .compactMap { descriptor in
                CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
            } ?? []

        return Array(NSOrderedSet(array: names + descriptorNames)) as? [String] ?? (names + descriptorNames)
    }

    private static func fontName(for style: Font.TextStyle, explicitWeight: SafeEatFontWeight?) -> String {
        switch explicitWeight ?? inferredWeight(for: style) {
        case .regular:
            return activeRegularFontName
        case .semibold:
            return activeSemiboldFontName
        case .bold:
            return activeBoldFontName
        }
    }

    private static func inferredWeight(for style: Font.TextStyle) -> SafeEatFontWeight {
        switch style {
        case .largeTitle, .title, .title2, .title3, .headline:
            return .bold
        default:
            return .regular
        }
    }
}

enum SafeEatFontWeight {
    case regular
    case semibold
    case bold
}

extension View {
    func safeEatBaseFont() -> some View {
        font(SafeEatFont.textStyle(.body))
    }
}
