import Foundation

// MARK: - 响应模型

struct APIEnvelope<T: Decodable>: Decodable {
    var code: String?
    var message: String?
    var result: T?
}

struct SigninInfo: Decodable {
    var days: Int?
    var clock: Bool?
    var info: [String]?
    var rewards: [String]?
}

// MARK: - 错误

enum APIError: Error, LocalizedError {
    case authFailed(String)
    case business(String)
    case badResponse
    case jwtFailed(String)

    /// 目标站返回的鉴权类错误码
    static let authCodes: Set<String> = ["1019", "1032", "1033", "1034"]

    var errorDescription: String? {
        switch self {
        case .authFailed(let m): return m.isEmpty ? "Token 失效" : m
        case .business(let m): return m
        case .badResponse: return "返回数据异常"
        case .jwtFailed(let m): return m
        }
    }
}

// MARK: - 客户端

final class APIClient {
    static let siteOrigin = "https://4w546gg3ihtq8u.xyz"

    private(set) var baseURL: String
    private var jwt: String?
    private var jwtFetchedAt: Date?
    private let session: URLSession

    init(baseURL: String) {
        self.baseURL = baseURL
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: cfg)
    }

    func updateBaseURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != baseURL else { return }
        baseURL = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        jwt = nil
        jwtFetchedAt = nil
    }

    // MARK: JWT（10 分钟缓存，与网页版一致）

    func getJwt(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let j = jwt, let t = jwtFetchedAt, Date().timeIntervalSince(t) < 600 {
            return j
        }
        guard let url = URL(string: "\(baseURL)/app/jwt-token") else { throw APIError.badResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.siteOrigin, forHTTPHeaderField: "Origin")
        req.setValue(Self.siteOrigin + "/", forHTTPHeaderField: "Referer")
        let (data, _) = try await session.data(for: req)
        let obj = try decode(APIEnvelope<String>.self, from: data)
        guard obj.code == "0000", let j = obj.result, !j.isEmpty else {
            throw APIError.jwtFailed(obj.message ?? "JWT 获取失败")
        }
        jwt = j
        jwtFetchedAt = Date()
        return j
    }

    /// 查询账号签到状态（只读）
    func signinInfo(token: String) async throws -> SigninInfo {
        let j = try await getJwt()
        guard let url = URL(string: "\(baseURL)/activation/signin/info") else { throw APIError.badResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(j, forHTTPHeaderField: "jwtToken")
        req.setValue(token, forHTTPHeaderField: "accessToken")
        req.setValue(Self.siteOrigin, forHTTPHeaderField: "Origin")
        req.setValue(Self.siteOrigin + "/", forHTTPHeaderField: "Referer")
        let (data, _) = try await session.data(for: req)
        let obj = try decode(APIEnvelope<SigninInfo>.self, from: data)
        guard let code = obj.code else { throw APIError.badResponse }
        if code != "0000" {
            if APIError.authCodes.contains(code) {
                throw APIError.authFailed(obj.message ?? "Token 失效")
            }
            throw APIError.business(obj.message ?? "业务错误 \(code)")
        }
        return obj.result ?? SigninInfo()
    }

    /// 探测域名可用性
    func probe() async -> Bool {
        do {
            _ = try await getJwt(forceRefresh: true)
            return true
        } catch {
            return false
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.badResponse
        }
    }
}
