import UIKit

enum SafeEatAppearance {
    static func configure() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = SafeEatTheme.textSecondaryUIColor
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = SafeEatTheme.primaryUIColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.primaryUIColor,
        ]
        tabBarAppearance.inlineLayoutAppearance.normal.iconColor = SafeEatTheme.textSecondaryUIColor
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = SafeEatTheme.primaryUIColor
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.primaryUIColor,
        ]
        tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = SafeEatTheme.textSecondaryUIColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = SafeEatTheme.primaryUIColor
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.primaryUIColor,
        ]

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = .systemBackground
        navigationAppearance.titleTextAttributes = [
            .font: font(size: 18, weight: .bold),
            .foregroundColor: SafeEatTheme.textPrimaryUIColor,
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .font: font(size: 32, weight: .bold),
            .foregroundColor: SafeEatTheme.textPrimaryUIColor,
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance

        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: font(size: 15),
            .foregroundColor: SafeEatTheme.primaryUIColor,
        ], for: .normal)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = SafeEatTheme.primaryUIColor
        UITabBar.appearance().unselectedItemTintColor = SafeEatTheme.textSecondaryUIColor
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.textSecondaryUIColor,
        ], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: font(size: 11),
            .foregroundColor: SafeEatTheme.primaryUIColor,
        ], for: .selected)

        UITextField.appearance().font = font(size: 16)
        UITextView.appearance().font = font(size: 16)
    }

    private static func font(size: CGFloat) -> UIFont {
        SafeEatFont.uiFont(size: size)
    }

    private static func font(size: CGFloat, weight: SafeEatFontWeight) -> UIFont {
        SafeEatFont.uiFont(size: size, weight: weight)
    }
}
