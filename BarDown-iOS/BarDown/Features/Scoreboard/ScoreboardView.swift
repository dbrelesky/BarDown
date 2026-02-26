import SwiftUI

struct ScoreboardView: View {
    @State private var viewModel = ScoreboardViewModel()
    @State private var showCalendar = false
    @State private var showAllFinals = false
    @State private var pullOffset: CGFloat = 0

    private let pullThreshold: CGFloat = 72
    private let finalCollapseCount = 3

    var body: some View {
        ZStack(alignment: .top) {
            ScoreboardBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    topControls

                    switch viewModel.state {
                    case .loading:
                        ScoreboardLoadingView()
                    case .empty:
                        ScoreboardEmptyView()
                    case .error(let message):
                        ScoreboardErrorView(message: message) {
                            await viewModel.refresh()
                        }
                    case .loaded(let games):
                        loadedContent(games: games)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 104)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                -(geometry.contentOffset.y + geometry.contentInsets.top)
            } action: { oldPull, newPull in
                pullOffset = max(0, newPull)
                if newPull > pullThreshold && oldPull <= pullThreshold && !viewModel.isRefreshing {
                    Task { await viewModel.refresh() }
                }
            }

            if viewModel.isRefreshing || pullOffset > pullThreshold {
                PullToRefreshView(isRefreshing: viewModel.isRefreshing)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .task {
            await viewModel.loadAvailableDates()
        }
        .task(id: viewModel.selectedDate) {
            await viewModel.loadGames(for: viewModel.selectedDate)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheetView(
                selectedDate: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.selectedDate = $0 }
                ),
                gameDates: viewModel.gameDates,
                onDateSelected: { date in
                    viewModel.selectedDate = date
                    showCalendar = false
                }
            )
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            showAllFinals = false
        }
    }

    @ViewBuilder
    private func loadedContent(games: [GameModel]) -> some View {
        let liveGames = games.filter(\.isLive)
        let upcomingGames = games.filter(\.isScheduled)
        let finalGames = games.filter(\.isFinal)

        VStack(spacing: 14) {
            if !liveGames.isEmpty {
                section(title: "LIVE") {
                    ForEach(liveGames) { game in
                        GameCardView(game: game)
                    }
                }
            }

            if !upcomingGames.isEmpty {
                section(title: "UPCOMING") {
                    ForEach(upcomingGames) { game in
                        GameCardView(game: game)
                    }
                }
            }

            if !finalGames.isEmpty {
                section(title: "FINAL") {
                    let displayedFinals = showAllFinals ? finalGames : Array(finalGames.prefix(finalCollapseCount))
                    ForEach(displayedFinals) { game in
                        GameCardView(game: game)
                    }

                    if finalGames.count > finalCollapseCount && !showAllFinals {
                        Button("Show \(finalGames.count - finalCollapseCount) more final games") {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                showAllFinals = true
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private var topControls: some View {
        HStack(alignment: .center, spacing: 10) {
            DateStripView(viewModel: viewModel)

            Button {
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.62))
                .tracking(1.4)
                .padding(.leading, 2)

            VStack(spacing: 12) {
                content()
            }
        }
    }
}

private struct ScoreboardBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.12, blue: 0.19),
                Color(red: 0.07, green: 0.08, blue: 0.12),
                Color(red: 0.04, green: 0.04, blue: 0.06),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 60,
                endRadius: 560
            )
        )
    }
}
