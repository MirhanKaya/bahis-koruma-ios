import SwiftUI

// MARK: - Screen 3: Domain List

struct DomainListView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingDomains {
                    loadingView
                } else if let error = viewModel.domainsError {
                    errorView(message: error)
                } else if viewModel.domains.isEmpty {
                    emptyView
                } else {
                    domainList
                }
            }
            .navigationTitle(L("domains.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.loadDomains() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingDomains)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("button.close")) {
                        viewModel.logout()
                    }
                    .foregroundColor(Color(hex: "#e63946"))
                }
            }
        }
        .task { await viewModel.loadDomains() }
    }

    // MARK: - Domain List

    private var domainList: some View {
        List {
            Section {
                statsHeader
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section(header: Text(L("domains.list.header"))) {
                ForEach(viewModel.domains) { domain in
                    DomainRow(domain: domain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(viewModel.domains.count)",
                label: L("domains.stats.total"),
                color: "#1a1a2e"
            )
            StatCard(
                value: "\(viewModel.domains.filter { $0.isBlocked }.count)",
                label: L("domains.stats.blocked"),
                color: "#e63946"
            )
            StatCard(
                value: "\(viewModel.domains.filter { $0.category == "gambling" }.count)",
                label: L("domains.stats.gambling"),
                color: "#7b2ff7"
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text(L("domains.loading"))
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#e63946"))
            Text(L("domains.error"))
                .font(.system(size: 17, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.loadDomains() }
            } label: {
                Text(L("button.retry"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#1a1a2e"))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(L("domains.empty"))
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Domain Row

private struct DomainRow: View {
    let domain: Domain

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(domain.isBlocked ? Color(hex: "#e63946").opacity(0.12) : Color(hex: "#2a9d8f").opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: domain.isBlocked ? "xmark.shield.fill" : "checkmark.shield.fill")
                    .font(.system(size: 16))
                    .foregroundColor(domain.isBlocked ? Color(hex: "#e63946") : Color(hex: "#2a9d8f"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(domain.domain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                HStack(spacing: 6) {
                    CategoryBadge(category: domain.category)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(domain.isBlocked ? L("domains.status.blocked") : L("domains.status.allowed"))
                        .font(.system(size: 12))
                        .foregroundColor(domain.isBlocked ? Color(hex: "#e63946") : Color(hex: "#2a9d8f"))
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Category Badge

private struct CategoryBadge: View {
    let category: String

    var label: String {
        category == "gambling" ? L("domains.category.gambling") : L("domains.category.unknown")
    }
    var color: String {
        category == "gambling" ? "#e63946" : "#888888"
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(hex: color))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: color).opacity(0.12))
            .cornerRadius(6)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    DomainListView()
        .environmentObject(AppViewModel())
}
