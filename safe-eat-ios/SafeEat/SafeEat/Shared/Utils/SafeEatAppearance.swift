import UIKit

enum SafeMealAppearance {
    static func configure() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = SafeMealTheme.textSecondaryUIColor
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = SafeMealTheme.primaryUIColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.primaryUIColor,
        ]
        tabBarAppearance.inlineLayoutAppearance.normal.iconColor = SafeMealTheme.textSecondaryUIColor
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = SafeMealTheme.primaryUIColor
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.primaryUIColor,
        ]
        tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = SafeMealTheme.textSecondaryUIColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = SafeMealTheme.primaryUIColor
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.textSecondaryUIColor,
        ]
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.primaryUIColor,
        ]

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = .systemBackground
        navigationAppearance.titleTextAttributes = [
            .font: font(size: 18, weight: .bold),
            .foregroundColor: SafeMealTheme.textPrimaryUIColor,
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .font: font(size: 32, weight: .bold),
            .foregroundColor: SafeMealTheme.textPrimaryUIColor,
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance

        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: font(size: 15),
            .foregroundColor: SafeMealTheme.primaryUIColor,
        ], for: .normal)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = SafeMealTheme.primaryUIColor
        UITabBar.appearance().unselectedItemTintColor = SafeMealTheme.textSecondaryUIColor
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.textSecondaryUIColor,
        ], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: font(size: 11),
            .foregroundColor: SafeMealTheme.primaryUIColor,
        ], for: .selected)

        UITextField.appearance().font = font(size: 16)
        UITextView.appearance().font = font(size: 16)
    }

    private static func font(size: CGFloat) -> UIFont {
        SafeMealFont.uiFont(size: size)
    }

    private static func font(size: CGFloat, weight: SafeMealFontWeight) -> UIFont {
        SafeMealFont.uiFont(size: size, weight: weight)
    }
}
