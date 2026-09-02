import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var vm: PanelViewModel
    @State private var query = ""
    @State private var filter: AccountFilter = .all
    @State private var sortByDays = false

    private var filtered: [Account] {
        var list = vm.accounts.filter { a in
            if !query.trimmingCharacters(in: .whitespaces).isEmpty,
               !a.name.localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces)) {
                return false
            }
            return filter.matches(a)
        }
        if sortByDays {
            list.sort { $0.days != $1.days ? $0.days > $1.days : $0.slot < $1.slot }
        } else {
            list.sort { $0.slot < $1.slot }
        }
        return list
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                if filtered.isEmpty {
                    EmptyBox(title: emptyTitle, hint: "点右上角同步，或到「设置」填写 GitHub Token")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { a in
                            AccountRow(account: a)
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.syncFromGitHub() }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("账号 \(vm.statTotal)")
            .searchable(text: $query, prompt: "搜索账号名")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            sortByDays = false
                        } label: {
                            Label("按槽位排序", systemImage: sortByDays ? "" : "checkmark")
                        }
                        Button {
                            sortByDays = true
                        } label: {
                            Label("按天数排序", systemImage: sortByDays ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AccountFilter.allCases) { f in
                    Button {
                        filter = f
                    } label: {
                        HStack(spacing: 5) {
                            Text(f.rawValue)
                                .font(.system(size: 13, weight: filter == f ? .medium : .regular))
                            if f == .dead && vm.statDead > 0 {
                                Text("\(vm.statDead)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.danger)
                            }
                        }
                        .foregroundStyle(filter == f ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(filter == f ? Theme.accent : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var emptyTitle: String {
        switch filter {
        case .vip: return "暂无 15 天 24h VIP 账号"
        case .vip12h: return "暂无 7~14 天阶段的账号"
        case .noVip: return "暂无未获得 VIP 的账号"
        case .delay: return "暂无延迟中的账号"
        case .dead: return "没有失效账号"
        case .all: return "暂无账号"
        }
    }
}

// MARK: - 单行

struct AccountRow: View {
    @EnvironmentObject var vm: PanelViewModel
    let account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.statusColor(account))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(account.name)
                            .font(.system(size: 15, weight: .medium))
                        if account.signedToday {
                            Tag(text: "今天", color: Theme.ok)
                        } else if account.signedYesterday {
                            Tag(text: "昨天", color: .secondary)
                        }
                    }
                    Text(secondaryText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(account.days)")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.progressColor(days: account.days))
                    Text("天")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: account.progress)
                .tint(Theme.progressColor(days: account.days))
                .scaleEffect(x: 1, y: 0.65, anchor: .center)
        }
        .padding(.vertical, 7)
        .opacity(account.dead ? 0.5 : 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                Task { await vm.refreshOne(account) }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .tint(Theme.accent)

            if !account.card.isEmpty {
                Button {
                    copy(account.card, tip: "已复制 \(account.name) 卡号")
                } label: {
                    Label("卡号", systemImage: "doc.on.doc")
                }
                .tint(.indigo)
            }

            if !account.pwd.isEmpty {
                Button {
                    copy(account.pwd, tip: "已复制 \(account.name) 密码")
                } label: {
                    Label("密码", systemImage: "key")
                }
                .tint(.teal)
            }
        }
        .contextMenu {
            if !account.token.isEmpty {
                Button {
                    copy(account.token, tip: "已复制 Token，粘贴到网站即可登录")
                } label: {
                    Label("复制 Token", systemImage: "key.horizontal")
                }
            }
            Button {
                Task { await vm.refreshOne(account) }
            } label: {
                Label("刷新实时状态", systemImage: "arrow.clockwise")
            }
        }
    }

    private var iconName: String {
        if account.dead { return "xmark.circle.fill" }
        if account.delay > 0 { return "hourglass" }
        if account.days >= 15 { return "star.circle.fill" }
        if account.days >= 7 { return "bolt.circle.fill" }
        if account.days > 0 { return "calendar.circle.fill" }
        return "clock.circle.fill"
    }

    private var secondaryText: String {
        var parts: [String] = []
        parts.append(account.id.isEmpty ? "无 ID" : "ID \(account.id)")
        if account.dead {
            parts.append("已失效")
        } else if account.delay > 0 {
            parts.append("延迟 \(account.delay) 天")
        } else {
            parts.append("连续 \(account.days) 天")
        }
        return parts.joined(separator: " · ")
    }

    private func copy(_ text: String, tip: String) {
        UIPasteboard.general.string = text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        vm.banner = PanelViewModel.Banner(text: tip, isError: false)
    }
}

struct Tag: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.16))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
