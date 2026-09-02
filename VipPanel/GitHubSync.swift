import Foundation

enum SyncError: Error, LocalizedError {
    case needToken
    case http(Int)
    case badData

    var errorDescription: String? {
        switch self {
        case .needToken: return "私有仓库需要 GitHub Token"
        case .http(let c):
            if c == 401 { return "GitHub Token 无效或已过期（401）" }
            if c == 403 { return "GitHub API 限流或无权访问（403）" }
            if c == 404 { return "仓库或文件不存在（404）" }
            return "GitHub 返回 HTTP \(c)"
        case .badData: return "数据解析失败"
        }
    }
}

enum GitHubSync {
    static let defaultRepo = "shake24342/VIPvip"
    static let defaultBranch = "main"
    static let defaultPath = "state.json"

    private struct ContentsResp: Decodable {
        var content: String?
        var encoding: String?
        var message: String?
    }

    /// 支持两种地址：GitHub API（带 token 走这个）与 raw.githubusercontent
    static func fetchState(repo: String,
                           path: String,
                           branch: String,
                           rawURL: String,
                           token: String) async throws -> PanelState {
        if !rawURL.isEmpty, let url = URL(string: rawURL) {
            if let state = try? await fetchRaw(url) { return state }
        }
        return try await fetchViaAPI(repo: repo, path: path, branch: branch, token: token)
    }

    private static func fetchRaw(_ url: URL) async throws -> PanelState {
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw SyncError.http(http.statusCode)
        }
        return try JSONDecoder().decode(PanelState.self, from: data)
    }

    private static func fetchViaAPI(repo: String, path: String, branch: String, token: String) async throws -> PanelState {
        guard !token.isEmpty else { throw SyncError.needToken }
        let urlStr = "https://api.github.com/repos/\(repo)/contents/\(path)?ref=\(branch)"
        guard let url = URL(string: urlStr) else { throw SyncError.badData }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        req.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw SyncError.http(http.statusCode)
        }
        let obj = try JSONDecoder().decode(ContentsResp.self, from: data)
        guard let b64 = obj.content else {
            throw SyncError.badData
        }
        let cleaned = b64.components(separatedBy: .whitespacesAndNewlines).joined()
        guard let decoded = Data(base64Encoded: cleaned) else { throw SyncError.badData }
        return try JSONDecoder().decode(PanelState.self, from: decoded)
    }
}
