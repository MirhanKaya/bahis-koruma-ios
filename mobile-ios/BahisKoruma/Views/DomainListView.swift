import SwiftUI

// MARK: - Screen 3: Domain List

struct DomainListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingDomains && viewModel.domains.isEmpty {
                    loadingView
                } else if let error = viewModel.domainsError, viewModel.domains.isEmpty {
                    errorView(message: error)
                } else if viewModel.domains.isEmpty {
                    emptyView
                } else {
                    domainList
                }
            }
            .navigationTitle(L("domains.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
        }
        .task { await viewModel.loadDomains() }
        .confirmationDialog(
            L("domains.logout.title"),
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button(L("domains.logout.confirm"), role: .destructive) {
                viewModel.logout()
            }
            Button(L("button.cancel"), role: .cancel) {}
        } message: {
            Text(L("domains.logout.message"))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel.loadDomains() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoadingDomains)
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(L("button.signout"))
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(hex: "#e63946"))
            }
        }
    }

    // MARK: - Domain List

    private var domainList: some View {
        List {
            // Stats
            Section {
                statsHeader
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .listRowBackground(Color.clear)

            // Domain rows
            Section(header: Text(L("domains.list.header"))) {
                ForEach(viewModel.domains) { domain in
                    DomainRow(domain: domain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadDomains()
        }
        .overlay(alignment: .top) {
            // Inline loading indicator during refresh
            if viewModel.isLoadingDomains && !viewModel.domains.isEmpty {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 10) {
            StatCard(
                value: "\(viewModel.domains.count)",
                label: L("domains.stats.total"),
                icon: "globe",
                color: "#1a1a2e"
            )
            StatCard(
                value: "\(viewModel.domains.filter { $0.isBlocked }.count)",
                label: L("domains.stats.blocked"),
                icon: "xmark.shield.fill",
                color: "#e63946"
            )
            StatCard(
                value: "\(viewModel.domains.filter { $0.category == "gambling" }.count)",
                label: L("domains.stats.gambling"),
                icon: "suit.club.fill",
                color: "#7b2ff7"
            )
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.3)
            Text(L("domains.loading"))
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundColor(Color(hex: "#e63946"))

            VStack(spacing: 6) {
                Text(L("domains.error.title"))
                    .font(.system(size: 17, weight: .semibold))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task { await viewModel.loadDomains() }
            } label: {
                Text(L("button.retry"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 13)
                    .background(Color(hex: "#1a1a2e"))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.slash")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.4))
            Text(L("domains.empty"))
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

// MARK: - Domain Row

private struct DomainRow: View {
    let domain: Domain

    var statusColor: Color {
        domain.isBlocked ? Color(hex: "#e63946") : Color(hex: "#2a9d8f")
    }
    var statusIcon: String {
        domain.isBlocked ? "xmark.shield.fill" : "checkmark.shield.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: statusIcon)
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(domain.domain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    CategoryBadge(category: domain.category)
                    Text("·")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text(domain.isBlocked
                         ? L("domains.status.blocked")
                         : L("domains.status.allowed"))
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Category Badge

private struct CategoryBadge: View {
    let category: String

    private var label: String {
        category == "gambling"
            ? L("domains.category.gambling")
            : L("domains.category.unknown")
    }
    private var color: Color {
        category == "gambling" ? Color(hex: "#e63946") : Color(hex: "#888888")
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(5)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    DomainListView()
        .environmentObject(AppViewModel())
}
