import Foundation
import SwiftUI

@MainActor
final class PanelViewModel: ObservableObject {
    // 数据
    @Published var accounts: [Account] = []
    @Published var domains: [DomainEntry] = []
    @Published var lastConfirmDate: String = ""

    // 配置
    @Published var githubToken: String {
        didSet { Store.save(githubToken, for: Store.kGithubToken) }
    }
    @Published var apiDomain: String {
        didSet { Store.save(apiDomain, for: Store.kApiDomain); api.updateBaseURL(apiDomain) }
    }
    @Published var repo: String = GitHubSync.defaultRepo
    @Published var branch: String = GitHubSync.defaultBranch
    @Published var filePath: String = GitHubSync.defaultPath
    @Published var rawURL: String = ""

    // 状态
    @Published var lastSync: Date?
    @Published var isSyncing = false
    @Published var isRefreshing = false
    @Published var refreshDone = 0
    @Published var refreshTotal = 0
    @Published var banner: Banner?

    struct Banner: Identifiable, Equatable {
        let id = UUID()
        var text: String
        var isError: Bool
    }

    private let api: APIClient

    init() {
        let savedToken = Store.load(Store.kGithubToken) ?? ""
        let savedDomain = Store.load(Store.kApiDomain) ?? "https://api.u04aqblppfo50.xyz/fast-cloud"
        _githubToken = Published(initialValue: savedToken)
        _apiDomain = Published(initialValue: savedDomain)
        api = APIClient(baseURL: savedDomain)

        if let data = UserDefaults.standard.data(forKey: Store.kAccounts),
           let list = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = list
        }
        if let data = UserDefaults.standard.data(forKey: Store.kDomains),
           let list = try? JSONDecoder().decode([DomainEntry].self, from: data) {
            domains = list
        }
        lastConfirmDate = UserDefaults.standard.string(forKey: Store.kLastConfirm) ?? ""
        if let ts = UserDefaults.standard.object(forKey: Store.kLastSync) as? Date {
            lastSync = ts
        }
    }

    // MARK: 统计（口径与网页面板一致）

    var statTotal: Int { accounts.count }
    var statSigned: Int { accounts.filter { $0.signedToday }.count }
    var statVip24: Int { accounts.filter(\.hasVip24).count }
    var statVip12: Int { accounts.filter(\.hasVip12).count }
    var statProgress: Int { accounts.filter { !$0.dead && $0.hasActiveVip12h }.count }
    var statDelay: Int { accounts.filter(\.isDelayed).count }
    var statAlive: Int { accounts.filter { !$0.dead }.count }
    var statDead: Int { accounts.filter(\.dead).count }

    var isStale: Bool {
        guard let last = lastSync else { return false }
        return Date().timeIntervalSince(last) > 36 * 3600
    }

    // MARK: 同步

    func syncFromGitHub() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let state = try await GitHubSync.fetchState(
                repo: repo, path: filePath, branch: branch,
                rawURL: rawURL, token: githubToken
            )
            accounts = state.accounts.sorted { ($0.slot) < ($1.slot) }
            domains = state.domainHistory
            lastConfirmDate = state.lastConfirmDate
            if !state.apiDomain.isEmpty {
                apiDomain = state.apiDomain
            }
            lastSync = Date()
            persist()
            banner = Banner(text: "已加载 \(accounts.count) 个账号", isError: false)
        } catch let e as SyncError {
            banner = Banner(text: "同步失败：\(e.localizedDescription)", isError: true)
        } catch {
            banner = Banner(text: "同步失败：\(error.localizedDescription)", isError: true)
        }
    }

    // MARK: 实时刷新

    func refreshAll() async {
        guard !isRefreshing else { return }
        let targets = accounts.enumerated().filter { !$0.element.dead && !$0.element.token.isEmpty }
        guard !targets.isEmpty else {
            banner = Banner(text: "没有可刷新的账号（需先同步带凭据的数据）", isError: true)
            return
        }
        isRefreshing = true
        refreshDone = 0
        refreshTotal = targets.count
        defer {
            isRefreshing = false
            refreshDone = 0
            refreshTotal = 0
        }

        var authFailed = 0
        var networkFailed = 0

        for (offset, account) in targets {
            guard let idx = accounts.firstIndex(where: { $0.name == account.name }) else {
                refreshDone += 1
                continue
            }
            do {
                let info = try await api.signinInfo(token: account.token)
                accounts[idx].days = info.days ?? 0
                accounts[idx].signedToday = info.clock ?? false
                accounts[idx].dead = false
                accounts[idx].failCount = 0
            } catch let e as APIError {
                switch e {
                case .authFailed:
                    accounts[idx].dead = true
                    accounts[idx].failCount = 3
                    authFailed += 1
                default:
                    networkFailed += 1
                }
            } catch {
                networkFailed += 1
            }
            refreshDone += 1
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        lastSync = Date()
        persist()

        var parts: [String] = []
        if authFailed > 0 { parts.append("失效 \(authFailed)") }
        if networkFailed > 0 { parts.append("失败 \(networkFailed)") }
        if parts.isEmpty {
            banner = Banner(text: "刷新完成，全部 \(refreshTotal) 个账号正常", isError: false)
        } else {
            banner = Banner(text: "刷新完成：" + parts.joined(separator: " · "), isError: true)
        }
    }

    func refreshOne(_ account: Account) async {
        guard !account.token.isEmpty else {
            banner = Banner(text: "\(account.name) 无凭据", isError: true)
            return
        }
        guard let idx = accounts.firstIndex(where: { $0.name == account.name }) else { return }
        do {
            let info = try await api.signinInfo(token: account.token)
            accounts[idx].days = info.days ?? 0
            accounts[idx].signedToday = info.clock ?? false
            accounts[idx].dead = false
            accounts[idx].failCount = 0
            banner = Banner(text: "\(account.name) 刷新成功，\(accounts[idx].days) 天", isError: false)
        } catch let e as APIError {
            if case .authFailed = e {
                accounts[idx].dead = true
                accounts[idx].failCount = 3
            }
            banner = Banner(text: "\(account.name)：\(e.localizedDescription)", isError: true)
        } catch {
            banner = Banner(text: "\(account.name)：\(error.localizedDescription)", isError: true)
        }
        persist()
    }

    // MARK: 域名探测

    func probeDomain() async {
        let ok = await api.probe()
        if let i = domains.firstIndex(where: { $0.domain == apiDomain }) {
            domains[i].status = ok ? "active" : "failed"
            domains[i].updatedAt = ISO8601DateFormatter().string(from: Date())
        } else {
            domains.append(DomainEntry(domain: apiDomain,
                                       status: ok ? "active" : "failed",
                                       updatedAt: ISO8601DateFormatter().string(from: Date())))
        }
        banner = Banner(text: ok ? "域名可用：\(apiDomain)" : "域名不可用：\(apiDomain)", isError: !ok)
        persist()
    }

    // MARK: 持久化

    func persist() {
        if let d = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(d, forKey: Store.kAccounts)
        }
        if let d = try? JSONEncoder().encode(domains) {
            UserDefaults.standard.set(d, forKey: Store.kDomains)
        }
        UserDefaults.standard.set(lastConfirmDate, forKey: Store.kLastConfirm)
        if let last = lastSync {
            UserDefaults.standard.set(last, forKey: Store.kLastSync)
        }
    }

    func clearCache() {
        accounts = []
        domains = []
        lastConfirmDate = ""
        lastSync = nil
        UserDefaults.standard.removeObject(forKey: Store.kAccounts)
        UserDefaults.standard.removeObject(forKey: Store.kDomains)
        UserDefaults.standard.removeObject(forKey: Store.kLastSync)
        UserDefaults.standard.removeObject(forKey: Store.kLastConfirm)
        banner = Banner(text: "本地缓存已清空", isError: false)
    }
}
