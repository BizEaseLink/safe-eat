import Foundation
import Security

final class AuthSessionStore {
    private let key = "safe-eat.auth-session"
    private let service = "com.bizeasylink.safe-eat.auth-session"
    private let account = "default"

    func load() -> AuthSession? {
        if let data = readKeychainData() {
            return try? JSONDecoder().decode(AuthSession.self, from: data)
        }

        guard let legacyData = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        guard let session = try? JSONDecoder().decode(AuthSession.self, from: legacyData) else {
            return nil
        }

        save(session)
        UserDefaults.standard.removeObject(forKey: key)
        return session
    }

    func save(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            saveKeychainData(data)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
    }

    private func readKeychainData() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        return item as? Data
    }

    private func saveKeychainData(_ data: Data) {
        let query = baseQuery()
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            var createQuery = query
            createQuery[kSecValueData as String] = data
            SecItemAdd(createQuery as CFDictionary, nil)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
