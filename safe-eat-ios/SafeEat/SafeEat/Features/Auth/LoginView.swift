import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var store: AppStore

    @State private var phone = ""
    @State private var code = ""
    @State private var devCodeHint: String?
    @State private var sendingSMS = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                SafeEatPageHeader(title: "登录")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Safe-Eat")
                        .font(SafeEatFont.custom(34, relativeTo: .largeTitle))
                    Text("先做 iOS 低成本 MVP，走短信登录与识别闭环")
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(.secondary)
                }

                GroupBox {
                    VStack(spacing: 14) {
                        TextField("手机号", text: $phone)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 10) {
                            TextField("验证码", text: $code)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button(sendingSMS ? "发送中" : "发送验证码") {
                                Task {
                                    await sendSMS()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(sendingSMS || phone.count < 6)
                        }

                        if let devCodeHint {
                            Text("开发环境验证码：\(devCodeHint)")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(.orange)
                        }

                        Button {
                            Task {
                                await store.login(phone: phone, code: code)
                            }
                        } label: {
                            if store.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("登录")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(phone.isEmpty || code.isEmpty || store.isLoading)
                    }
                    .padding(.top, 6)
                } label: {
                    Text("手机号登录")
                        .font(SafeEatFont.textStyle(.headline))
                }

                Spacer()
            }
            .padding(20)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func sendSMS() async {
        sendingSMS = true
        defer { sendingSMS = false }

        do {
            let response = try await store.sendSMS(phone: phone)
            devCodeHint = response.devCode
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStore())
}
