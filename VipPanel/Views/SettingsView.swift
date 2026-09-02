import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: PanelViewModel
    @State private var showToken = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 10) {
                        if showToken {
                            TextField("GitHub Personal Access Token", text: $vm.githubToken)
                                .font(.system(size: 13, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("GitHub Personal Access Token", text: $vm.githubToken)
                                .font(.system(size: 13, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        Button {
                            showToken.toggle()
                        } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("GitHub 凭据")
                } footer: {
                    Text("用于读取私有仓库 VIPvip 的 state.json（需要 repo 权限）。Token 保存在本机 Keychain，不会上传。")
                }

                Section("仓库") {
                    LabeledField(label: "仓库", text: $vm.repo, mono: true)
                    LabeledField(label: "分支", text: $vm.branch, mono: true)
                    LabeledField(label: "文件路径", text: $vm.filePath, mono: true)
                }

                Section("接口域名") {
                    LabeledField(label: "API 域名", text: $vm.apiDomain, mono: true)
                }

                Section {
                    Button {
                        Task { await vm.syncFromGitHub() }
                    } label: {
                        HStack {
                            if vm.isSyncing {
                                ProgressView()
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                            }
                            Text(vm.isSyncing ? "同步中…" : "从 GitHub 同步")
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(vm.isSyncing || vm.isRefreshing)
                }

                Section {
                    Button(role: .destructive) {
                        vm.clearCache()
                    } label: {
                        Label("清空本地缓存", systemImage: "trash")
                    }
                } footer: {
                    Text("仅清除本机缓存的账号数据，不影响 GitHub 上的 state.json。")
                }

                Section("关于") {
                    LabeledRow(label: "版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledRow(label: "安装方式", value: "TrollStore / ad-hoc 签名，永久有效")
                }
            }
            .navigationTitle("设置")
        }
        .navigationViewStyle(.stack)
    }
}

struct LabeledField: View {
    var label: String
    @Binding var text: String
    var mono = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .font(mono ? .system(size: 13, design: .monospaced) : .system(size: 14))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.vertical, 2)
    }
}

struct LabeledRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
        }
    }
}
