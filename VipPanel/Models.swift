import Foundation

// MARK: - 账号

struct Account: Codable, Identifiable, Equatable {
    var name: String = ""
    var card: String = ""
    var pwd: String = ""
    var token: String = ""
    var days: Int = 0
    var id: String = ""
    var slot: Int = 0
    var delay: Int = 0
    var dead: Bool = false
    var failCount: Int = 0
    var signedToday: Bool = false
    var signedYesterday: Bool = false
    var vip7ExpireAt: String = ""
    var vipValidDate: Double = 0
    var lastRunDate: String = ""

    var identity: String { name.isEmpty ? UUID().uuidString : name }

    enum CodingKeys: String, CodingKey {
        case name, card, pwd, token, days, id, slot, delay, dead
        case failCount, signedToday, signedYesterday, vip7ExpireAt, vipValidDate, lastRunDate
        case idCard, idCardPwd
    }

    init() {}

    /// 同时兼容私有仓库 state.json（idCard/idCardPwd）与面板内嵌数据（card/pwd）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = Self.str(c, .name)
        card = Self.str(c, .card).isEmpty ? Self.str(c, .idCard) : Self.str(c, .card)
        pwd = Self.str(c, .pwd).isEmpty ? Self.str(c, .idCardPwd) : Self.str(c, .pwd)
        token = Self.str(c, .token)
        days = Self.int(c, .days)
        id = Self.str(c, .id)
        slot = Self.int(c, .slot)
        delay = Self.int(c, .delay)
        dead = Self.bool(c, .dead)
        failCount = Self.int(c, .failCount)
        signedToday = Self.bool(c, .signedToday)
        signedYesterday = Self.bool(c, .signedYesterday)
        vip7ExpireAt = Self.str(c, .vip7ExpireAt)
        vipValidDate = Self.dbl(c, .vipValidDate)
        lastRunDate = Self.str(c, .lastRunDate)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(card, forKey: .card)
        try c.encode(pwd, forKey: .pwd)
        try c.encode(token, forKey: .token)
        try c.encode(days, forKey: .days)
        try c.encode(id, forKey: .id)
        try c.encode(slot, forKey: .slot)
        try c.encode(delay, forKey: .delay)
        try c.encode(dead, forKey: .dead)
        try c.encode(failCount, forKey: .failCount)
        try c.encode(signedToday, forKey: .signedToday)
        try c.encode(signedYesterday, forKey: .signedYesterday)
        try c.encode(vip7ExpireAt, forKey: .vip7ExpireAt)
        try c.encode(vipValidDate, forKey: .vipValidDate)
        try c.encode(lastRunDate, forKey: .lastRunDate)
    }

    private static func str(_ c: KeyedDecodingContainer<CodingKeys>, _ k: CodingKeys) -> String {
        if let v = try? c.decode(String.self, forKey: k) { return v }
        if let v = try? c.decode(Int.self, forKey: k) { return String(v) }
        if let v = try? c.decode(Double.self, forKey: k) { return String(v) }
        return ""
    }

    private static func int(_ c: KeyedDecodingContainer<CodingKeys>, _ k: CodingKeys) -> Int {
        if let v = try? c.decode(Int.self, forKey: k) { return v }
        if let v = try? c.decode(Double.self, forKey: k) { return Int(v) }
        if let s = try? c.decode(String.self, forKey: k), let v = Int(s) { return v }
        return 0
    }

    private static func dbl(_ c: KeyedDecodingContainer<CodingKeys>, _ k: CodingKeys) -> Double {
        if let v = try? c.decode(Double.self, forKey: k) { return v }
        if let s = try? c.decode(String.self, forKey: k), let v = Double(s) { return v }
        return 0
    }

    private static func bool(_ c: KeyedDecodingContainer<CodingKeys>, _ k: CodingKeys) -> Bool {
        if let v = try? c.decode(Bool.self, forKey: k) { return v }
        if let v = try? c.decode(Int.self, forKey: k) { return v != 0 }
        return false
    }

    // MARK: 派生状态（口径与网页面板保持一致）

    var hasActiveVip12h: Bool {
        guard !vip7ExpireAt.isEmpty else { return false }
        let now = Date().timeIntervalSince1970 * 1000
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: vip7ExpireAt) { return d.timeIntervalSince1970 * 1000 > now }
        if let t = Double(vip7ExpireAt) { return t > now }
        return false
    }

    var isDelayed: Bool { !dead && delay > 0 }
    var hasVip24: Bool { !dead && days >= 15 }
    var hasVip12: Bool { !dead && days >= 7 && days < 15 }

    /// 15 天领奖进度
    var progress: Double { min(1.0, max(0.0, Double(days) / 15.0)) }

    var statusText: String {
        if dead { return "已失效" }
        if delay > 0 { return "延迟 \(delay) 天" }
        return "连续 \(days) 天"
    }
}

// MARK: - 域名

struct DomainEntry: Codable, Identifiable, Equatable {
    var domain: String = ""
    var status: String = ""
    var updatedAt: String = ""
    var id: String { domain }

    var isActive: Bool { status.lowercased() == "active" }
}

// MARK: - state.json

struct PanelState: Codable {
    var accounts: [Account] = []
    var startDate: String = ""
    var meta: [String: String]?
    var apiDomain: String = ""
    var domainHistory: [DomainEntry] = []
    var staggerDate: String = ""
    var lastConfirmDate: String = ""

    enum CodingKeys: String, CodingKey {
        case accounts, startDate, meta, apiDomain, domainHistory, staggerDate, lastConfirmDate
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accounts = (try? c.decode([Account].self, forKey: .accounts)) ?? []
        startDate = (try? c.decode(String.self, forKey: .startDate)) ?? ""
        apiDomain = (try? c.decode(String.self, forKey: .apiDomain)) ?? ""
        domainHistory = (try? c.decode([DomainEntry].self, forKey: .domainHistory)) ?? []
        staggerDate = (try? c.decode(String.self, forKey: .staggerDate)) ?? ""
        lastConfirmDate = (try? c.decode(String.self, forKey: .lastConfirmDate)) ?? ""
    }
}

// MARK: - 筛选

enum AccountFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case vip = "24h VIP"
    case vip12h = "7~14 天"
    case noVip = "未获 VIP"
    case delay = "延迟中"
    case dead = "已失效"

    var id: String { rawValue }

    func matches(_ a: Account) -> Bool {
        switch self {
        case .all: return true
        case .vip: return a.hasVip24
        case .vip12h: return a.hasVip12
        case .noVip: return !a.dead && a.days < 15 && !a.hasActiveVip12h
        case .delay: return a.isDelayed
        case .dead: return a.dead
        }
    }
}
