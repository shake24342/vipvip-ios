import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var vm: PanelViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dataStatusCard
                    statsSection
                    actionSection
                    stepSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("总览")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await vm.syncFromGitHub() }
                    } label: {
                        if vm.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(vm.isSyncing || vm.isRefreshing)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: 数据状态

    private var dataStatusCard: some View {
        CardBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(vm.isStale ? Theme.warn : Theme.ok)
                        .frame(width: 8, height: 8)
                    Text(dataTitle)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                Text(dataSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if vm.isStale {
                    Text("数据已超过 36 小时未更新，页面显示的可能不是当前真实状态。")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.warn)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var dataTitle: String {
        guard let last = vm.lastSync else { return "尚未同步数据" }
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return "数据时间 " + f.string(from: last)
    }

    private var dataSubtitle: String {
        if vm.lastConfirmDate.isEmpty {
            return "共 \(vm.statTotal) 个账号"
        }
        return "服务端确认日 \(vm.lastConfirmDate) · 共 \(vm.statTotal) 个账号"
    }

    // MARK: 统计

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("账号统计")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                StatCell(title: "今日已签", value: vm.statSigned, tint: Theme.ok)
                StatCell(title: "延迟中", value: vm.statDelay, tint: .secondary)
                StatCell(title: "24h VIP", value: vm.statVip24, tint: Color(hue: 0.105, saturation: 0.85, brightness: 0.85))
                StatCell(title: "7~14 天", value: vm.statVip12, tint: Color(hue: 0.75, saturation: 0.7, brightness: 0.8))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                StatCell(title: "存活", value: vm.statAlive, tint: .primary)
                StatCell(title: "已失效", value: vm.statDead, tint: vm.statDead > 0 ? Theme.danger : .primary)
            }
        }
    }

    // MARK: 操作

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await vm.refreshAll() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(vm.isRefreshing ? "刷新中 \(vm.refreshDone)/\(vm.refreshTotal)" : "刷新实时状态")
                        .fontWeight(.medium)
                    Spacer()
                    if vm.isRefreshing {
                        ProgressView(value: Double(vm.refreshDone), total: Double(max(vm.refreshTotal, 1)))
                            .frame(width: 70)
                    }
                }
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(vm.isRefreshing || vm.isSyncing)

            if vm.isRefreshing {
                Text("逐个向服务端查询真实签到状态，约需 \(vm.refreshTotal / 2) 秒")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 阶梯说明

    private var stepSection: some View {
        CardBox {
            VStack(alignment: .leading, spacing: 10) {
                Text("签到阶梯")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                let aliveAccounts = vm.accounts.filter { !$0.dead }
                if aliveAccounts.isEmpty {
                    Text("暂无数据，请先同步")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(aliveAccounts.enumerated()), id: \.offset) { _, a in
                                VStack(spacing: 3) {
                                    Text("\(a.days)")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.progressColor(days: a.days))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.progressColor(days: a.days))
                                        .frame(width: 18, height: max(3, CGFloat(a.days) * 2.2))
                                }
                                .frame(width: 24)
                            }
                        }
                    }
                    Text("错峰机制下相邻账号天数应呈阶梯分布；若整体塌缩到 0~2 天，说明服务端已清零，脚本会自动重建阶梯。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
