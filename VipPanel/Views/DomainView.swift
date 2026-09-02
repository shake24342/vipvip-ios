import SwiftUI

struct DomainView: View {
    @EnvironmentObject var vm: PanelViewModel
    @State private var probing = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前 API 域名")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(vm.apiDomain)
                                .font(.system(size: 13, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            Task {
                                probing = true
                                await vm.probeDomain()
                                probing = false
                            }
                        } label: {
                            if probing {
                                ProgressView()
                            } else {
                                Image(systemName: "waveform.path")
                            }
                        }
                        .disabled(probing)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("接口")
                } footer: {
                    Text("目标站域名会不定期更换，脚本探测到新域名后会写入 state.json，同步即可更新。")
                }

                Section("历史记录") {
                    if vm.domains.isEmpty {
                        Text("暂无域名状态数据")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.domains) { d in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(d.isActive ? Theme.ok : Theme.danger)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(d.domain.replacingOccurrences(of: "https://", with: ""))
                                        .font(.system(size: 13, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if !d.updatedAt.isEmpty {
                                        Text(timeText(d.updatedAt))
                                            .font(.system(size: 11))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Text(d.isActive ? "可用" : "失效")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(d.isActive ? Theme.ok : Theme.danger)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill((d.isActive ? Theme.ok : Theme.danger).opacity(0.14))
                                    )
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("域名状态")
        }
        .navigationViewStyle(.stack)
    }

    private func timeText(_ iso: String) -> String {
        let p = ISO8601DateFormatter()
        if let d = p.date(from: iso) {
            let f = DateFormatter()
            f.dateFormat = "MM-dd HH:mm"
            return f.string(from: d)
        }
        return iso
    }
}
