import Combine
import Foundation
import StoreKit

// MARK: - 协议定义（便于测试 mock）

protocol StoreKitServiceProtocol {
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> StoreKitPurchaseResult
    func currentEntitlements() async -> [Transaction]
    func restorePurchases() async throws -> [Transaction]
}

enum StoreKitPurchaseResult {
    case success(transaction: Transaction)
    case pending
    case userCancelled
    case failed(error: Error)
}

// MARK: - 实现

@MainActor
final class StoreKitService: StoreKitServiceProtocol, ObservableObject {
    static let shared = StoreKitService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []

    nonisolated(unsafe) private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 商品加载

    func loadProducts() async throws -> [Product] {
        let productIDs = MembershipProductID.allProductIDs
        let storeProducts = try await Product.products(for: productIDs)
        products = storeProducts
        return storeProducts
    }

    func product(for planTier: String) -> Product? {
        let productID = MembershipProductID.productID(for: planTier)
        return products.first { $0.id == productID }
    }

    // MARK: - 购买

    func purchase(_ product: Product) async throws -> StoreKitPurchaseResult {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            return .success(transaction: transaction)

        case .userCancelled:
            return .userCancelled

        case .pending:
            return .pending

        @unknown default:
            return .failed(error: StoreKitError.unknown)
        }
    }

    // MARK: - 订阅状态

    func currentEntitlements() async -> [Transaction] {
        var entitlements: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                entitlements.append(transaction)
            }
        }
        return entitlements
    }

    func restorePurchases() async throws -> [Transaction] {
        try await StoreKit.AppStore.sync()
        var restored: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                restored.append(transaction)
            }
        }
        return restored
    }

    // MARK: - Transaction 监听

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try await self.checkVerified(result)
                    self.purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                } catch {
                    // 验证失败的交易忽略
                }
            }
        }
    }

    // MARK: - 验证

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - 商品 ID 映射

enum MembershipProductID {
    // 商品 ID 格式: com.bizeasylink.safeeat.membership.<billingCycle>.<planTier>
    // 与后端 planTier 对应: lite, pro, premium
    // 与 billingCycle 对应: monthly, yearly

    static let allProductIDs: [String] = [
        "com.bizeasylink.safeeat.membership.monthly.lite",
        "com.bizeasylink.safeeat.membership.yearly.lite",
        "com.bizeasylink.safeeat.membership.monthly.pro",
        "com.bizeasylink.safeeat.membership.yearly.pro",
        "com.bizeasylink.safeeat.membership.monthly.premium",
        "com.bizeasylink.safeeat.membership.yearly.premium",
    ]

    static func productID(for planTier: String) -> String {
        "com.bizeasylink.safeeat.membership.\(planTier)"
    }

    /// 从商品 ID 解析 planTier（格式: ...membership.<billingCycle>.<planTier>）
    static func planTier(from productID: String) -> String? {
        let components = productID.components(separatedBy: ".")
        guard components.count >= 5 else { return nil }
        return components.last
    }

    /// 从商品 ID 解析 billingCycle
    static func billingCycle(from productID: String) -> String? {
        let components = productID.components(separatedBy: ".")
        guard components.count >= 5 else { return nil }
        return components[components.count - 2]
    }
}