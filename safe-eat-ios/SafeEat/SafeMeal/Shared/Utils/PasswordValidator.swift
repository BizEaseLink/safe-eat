import Foundation

// MARK: - 密码强度验证

/// 与后端 DTO 保持一致的密码强度规则：
/// - 至少 8 个字符
/// - 包含大写字母
/// - 包含小写字母
/// - 包含数字
/// - 包含特殊字符
enum PasswordValidator {

    struct ValidationResult {
        let isLengthValid: Bool
        let hasUppercase: Bool
        let hasLowercase: Bool
        let hasDigit: Bool
        let hasSpecialChar: Bool

        var isValid: Bool {
            isLengthValid && hasUppercase && hasLowercase && hasDigit && hasSpecialChar
        }
    }

    static func validate(_ password: String) -> ValidationResult {
        ValidationResult(
            isLengthValid: password.count >= 8,
            hasUppercase: password.range(of: "[A-Z]", options: .regularExpression) != nil,
            hasLowercase: password.range(of: "[a-z]", options: .regularExpression) != nil,
            hasDigit: password.range(of: "\\d", options: .regularExpression) != nil,
            hasSpecialChar: password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?`~]", options: .regularExpression) != nil
        )
    }
}
