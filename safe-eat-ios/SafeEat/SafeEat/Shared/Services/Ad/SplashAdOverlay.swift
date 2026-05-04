import SwiftUI

struct SplashAdOverlay: UIViewRepresentable {

    @Binding var isShowing: Bool

    private static let timeoutInterval: TimeInterval = 8

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black

        // 没有有效 slotId 时直接跳过广告
        guard let slotId = AdConfigStore.shared.slotId(for: .splash), !slotId.isEmpty else {
            print("[UMeng] 开屏广告无有效 slotId，跳过")
            DispatchQueue.main.async { isShowing = false }
            return container
        }

        let splashAd = UMUnionSplashAd(slotId: slotId)
        splashAd.delegate = context.coordinator
        splashAd.timeout = 5
        context.coordinator.splashAd = splashAd
        context.coordinator.isShowing = $isShowing
        context.coordinator.startTime = Date()
        splashAd.loadAd()

        // 启动基于实际时间的超时检查
        context.coordinator.scheduleTimeoutCheck(interval: Self.timeoutInterval)

        // 监听 App 前后台切换，回到前台时重新校验超时
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UMUnionSplashAdDelegate {
        var splashAd: UMUnionSplashAd?
        var isShowing: Binding<Bool>?
        var isDismissed = false
        var startTime: Date = Date()

        func uadSplashDidLoad(_ splashAd: UMUnionSplashAd) {
            // 数据加载成功，等待渲染成功后再展示
        }

        func uadSplashRenderSuccess(_ splashAd: UMUnionSplashAd) {
            // 渲染成功后才调用 show
            DispatchQueue.main.async {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                let window = windowScene?.windows.first(where: { $0.isKeyWindow })
                if let window {
                    splashAd.showFullScreenAd(in: window, skipView: nil)
                } else {
                    print("[UMeng] 开屏广告找不到 keyWindow")
                    self.dismiss()
                }
            }
        }

        func uadSplashDidLoad(_ splashAd: UMUnionSplashAd, failWithError error: Error?) {
            print("[UMeng] 开屏广告加载失败: \(error?.localizedDescription ?? "unknown")")
            DispatchQueue.main.async { self.dismiss() }
        }

        func uadSplashRenderFail(_ splashAd: UMUnionSplashAd, error: Error?) {
            print("[UMeng] 开屏广告渲染失败: \(error?.localizedDescription ?? "unknown")")
            DispatchQueue.main.async { self.dismiss() }
        }

        func uadSplashClose(_ splashAd: UMUnionSplashAd) {
            DispatchQueue.main.async { self.dismiss() }
        }

        /// 基于实际经过时间的超时检查，不受后台暂停影响
        func scheduleTimeoutCheck(interval: TimeInterval) {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                guard let self, !self.isDismissed else { return }
                self.checkTimeout()
            }
        }

        /// 校验是否已超时，若未超时则安排剩余时间的检查
        private func checkTimeout() {
            guard !isDismissed else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= SplashAdOverlay.timeoutInterval {
                print("[UMeng] 开屏广告超时兜底触发（经过 \(Int(elapsed))s）")
                dismiss()
            } else {
                let remaining = SplashAdOverlay.timeoutInterval - elapsed
                scheduleTimeoutCheck(interval: remaining)
            }
        }

        /// App 回到前台时重新校验超时
        @objc func appDidBecomeActive() {
            checkTimeout()
        }

        func dismiss() {
            guard !isDismissed else { return }
            isDismissed = true
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            splashAd = nil
            isShowing?.wrappedValue = false
        }
    }
}
