import Foundation
import Security

/// 凭据存储：优先 Keychain，失败时回退 UserDefaults（ad-hoc 签名环境下保证可用）
enum Store {
    private static let service = "com.vippanel.ios"

    static func save(_ value: String, for key: String) {
        UserDefaults.standard.set(value, forKey: "ud_\(key)")
        guard let data = value.data(using: .utf8), !value.isEmpty else {
            delete(key)
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        let attrs = query.merging([kSecValueData as String: data]) { _, new in new }
        SecItemAdd(attrs as CFDictionary, nil)
    }

    static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let s = String(data: data, encoding: .utf8), !s.isEmpty {
            return s
        }
        return UserDefaults.standard.string(forKey: "ud_\(key)")
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "ud_\(key)")
    }

    // MARK: 键名

    static let kGithubToken = "github_token"
    static let kApiDomain = "api_domain"
    static let kAccounts = "accounts_cache"
    static let kDomains = "domains_cache"
    static let kLastSync = "last_sync"
    static let kLastConfirm = "last_confirm"
    static let kSource = "data_source"
}
