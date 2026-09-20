import Combine
import Foundation

/// 全局验证码倒计时管理器
/// 倒计时状态通过 UserDefaults 持久化，Timer 全局存活不随页面销毁
@MainActor
final class SMSCountdownManager: ObservableObject {
    static let shared = SMSCountdownManager()

    @Published var countdown: Int = 0
    @Published var isSending: Bool = false

    private var timer: Timer?
    private let cooldownSeconds = 60
    private static let smsSentAtKey = "safe-eat.auth.smsSentAt"

    private init() {
        // 启动时恢复倒计时
        let remaining = remainingSeconds
        if remaining > 0 {
            countdown = remaining
            startTimer()
        }
    }

    /// 标记验证码已发送，开始倒计时
    func markSent() {
        UserDefaults.standard.set(Date(), forKey: Self.smsSentAtKey)
        countdown = remainingSeconds
        startTimer()
    }

    /// 当前剩余秒数（基于 UserDefaults 持久化的发送时间）
    var remainingSeconds: Int {
        guard let sentAt = UserDefaults.standard.object(forKey: Self.smsSentAtKey) as? Date else { return 0 }
        let elapsed = Int(Date().timeIntervalSince(sentAt))
        return max(0, cooldownSeconds - elapsed)
    }

    private func startTimer() {
        timer?.invalidate()
        guard countdown > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let remaining = self.remainingSeconds
                if remaining <= 0 {
                    self.countdown = 0
                    self.timer?.invalidate()
                    self.timer = nil
                } else {
                    self.countdown = remaining
                }
            }
        }
    }
}
