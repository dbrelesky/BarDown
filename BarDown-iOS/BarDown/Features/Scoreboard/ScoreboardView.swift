import SwiftUI

struct ScoreboardView: View {
    @State private var viewModel = ScoreboardViewModel()
    @State private var showCalendar = false
    @State private var showAllFinals = false
    @State private var pullOffset: CGFloat = 0

    private let pullThreshold: CGFloat = 60
    private let finalCollapseCount = 3

    var body: some View {
        ScrollView {
            // Pull-to-refresh offset anchor
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .named("scoreboardScroll")).minY
                    )
            }
            .frame(height: 0)

            // Custom pull-to-refresh indicator
            if viewModel.isRefreshing || pullOffset > pullThreshold {
                PullToRefreshView(isRefreshing: viewModel.isRefreshing)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Date strip (pinned below NavigationBar, above content)
            DateStripView(viewModel: viewModel)
                .padding(.vertical, 4)

            // Content area
            VStack(spacing: 12) {
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
                    let liveGames = games.filter(\.isLive)
                    let upcomingGames = games.filter(\.isScheduled)
                    let finalGames = games.filter(\.isFinal)

                    // LIVE section
                    if !liveGames.isEmpty {
                        SectionHeader(title: "LIVE")
                        ForEach(liveGames) { game in
                            GameCardView(game: game)
                        }
                        .padding(.horizontal)
                    }

                    // UPCOMING section
                    if !upcomingGames.isEmpty {
                        SectionHeader(title: "UPCOMING")
                        ForEach(upcomingGames) { game in
                            GameCardView(game: game)
                        }
                        .padding(.horizontal)
                    }

                    // FINAL section (with collapse)
                    if !finalGames.isEmpty {
                        SectionHeader(title: "FINAL")
                        let displayedFinals = showAllFinals
                            ? finalGames
                            : Array(finalGames.prefix(finalCollapseCount))

                        ForEach(displayedFinals) { game in
                            GameCardView(game: game)
                        }
                        .padding(.horizontal)

                        if finalGames.count > finalCollapseCount && !showAllFinals {
                            Button("Show \(finalGames.count - finalCollapseCount) more final games") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAllFinals = true
                                }
                            }
                            .font(.subheadline)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .coordinateSpace(name: "scoreboardScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            pullOffset = offset
            // Trigger refresh when pulled past threshold and not already refreshing
            if offset > pullThreshold && !viewModel.isRefreshing {
                Task { await viewModel.refresh() }
            }
        }
        .task {
            // Load available dates for the strip on first appear
            await viewModel.loadAvailableDates()
        }
        .task(id: viewModel.selectedDate) {
            // Re-fetch games whenever selectedDate changes
            await viewModel.loadGames(for: viewModel.selectedDate)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCalendar = true
                } label: {
                    Image(systemName: "calendar")
                }
            }
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
        // Reset collapse when date changes (new day = fresh view)
        .onChange(of: viewModel.selectedDate) { _, _ in
            showAllFinals = false
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
