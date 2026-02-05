import SwiftUI

struct ContentView: View {
    @State private var holeCards: [Card] = []
    @State private var communityCards: [Card] = []
    @State private var numOpponents: Int = 3
    @State private var result: OddsResult?
    @State private var isCalculating = false
    
    var usedCards: Set<Card> {
        Set(holeCards + communityCards)
    }
    
    var canCalculate: Bool {
        holeCards.count == 2
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        Text("♠️ 德州扑克计算器")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        // Opponents selector
                        opponentsSection

                        // Hole cards
                        cardSection(
                            title: "🃏 你的手牌",
                            cards: $holeCards,
                            maxCards: 2,
                            excluded: Set(communityCards)
                        )

                        // Community cards
                        cardSection(
                            title: "🎴 公共牌",
                            cards: $communityCards,
                            maxCards: 5,
                            excluded: Set(holeCards)
                        )

                        // Stage indicator
                        stageIndicator

                        // Results
                        if let result = result {
                            resultsView(result)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 0) {
                    Divider()
                    calculateButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    
    var opponentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("👥 对手数量: \(numOpponents)人")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(1...9, id: \.self) { num in
                    Button(action: { 
                        numOpponents = num
                        result = nil
                    }) {
                        Text("\(num)")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(numOpponents == num ? Color.blue : Color(.systemGray5))
                            .foregroundColor(numOpponents == num ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    func cardSection(title: String, cards: Binding<[Card]>, maxCards: Int, excluded: Set<Card>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if !cards.wrappedValue.isEmpty {
                    Button("清除") {
                        cards.wrappedValue.removeAll()
                        result = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(0..<maxCards, id: \.self) { index in
                    CardSlotView(
                        card: index < cards.wrappedValue.count ? cards.wrappedValue[index] : nil,
                        allCards: cards,
                        index: index,
                        maxCards: maxCards,
                        excluded: excluded
                    )
                    .onChange(of: cards.wrappedValue) { _, _ in
                        result = nil
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    var stageIndicator: some View {
        HStack {
            Text("当前阶段:")
                .foregroundColor(.secondary)
            Text(stageName)
                .fontWeight(.semibold)
                .foregroundColor(stageColor)
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    var stageName: String {
        switch communityCards.count {
        case 0: return "翻牌前 (Pre-flop)"
        case 3: return "翻牌 (Flop)"
        case 4: return "转牌 (Turn)"
        case 5: return "河牌 (River)"
        default: return "选择公共牌"
        }
    }
    
    var stageColor: Color {
        switch communityCards.count {
        case 0: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    var calculateButton: some View {
        Button(action: calculate) {
            HStack(spacing: 8) {
                if isCalculating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "chart.pie.fill")
                }
                Text(isCalculating ? "计算中..." : "计算胜率")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canCalculate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canCalculate || isCalculating)
    }
    
    func resultsView(_ result: OddsResult) -> some View {
        VStack(spacing: 12) {
            // Win rate big display
            VStack(spacing: 4) {
                Text("胜率")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", result.winRate))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: max(0, geo.size.width * result.winRate / 100))
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: max(0, geo.size.width * result.tieRate / 100))
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: max(0, geo.size.width * result.loseRate / 100))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(height: 24)
                
                HStack {
                    Label(String(format: "%.1f%%", result.winRate), systemImage: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Label(String(format: "%.1f%%", result.tieRate), systemImage: "equal")
                        .foregroundColor(.yellow)
                    Spacer()
                    Label(String(format: "%.1f%%", result.loseRate), systemImage: "hand.thumbsdown.fill")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Stats
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("模拟次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.simulations.formatted())")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                if let hand = result.bestHand {
                    VStack(spacing: 4) {
                        Text("最佳牌型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(hand.description)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    func calculate() {
        isCalculating = true
        Task {
            // Quick result first (5000 sims)
            let quickOdds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 5000
            )
            await MainActor.run {
                result = quickOdds
            }
            
            // Then refine with more simulations (50000 total)
            let refinedOdds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 50000
            )
            await MainActor.run {
                result = refinedOdds
                isCalculating = false
            }
        }
    }
}

// MARK: - Card Slot View
struct CardSlotView: View {
    let card: Card?
    @Binding var allCards: [Card]
    let index: Int
    let maxCards: Int
    let excluded: Set<Card>
    
    @State private var showPicker = false
    
    var body: some View {
        Button(action: {
            if card != nil {
                allCards.remove(at: index)
            } else {
                showPicker = true
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card == nil ? Color(.systemGray5) : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
                
                if let card = card {
                    VStack(spacing: 2) {
                        Text(card.rank.symbol)
                            .font(.system(size: 18, weight: .bold))
                        Text(card.suit.rawValue)
                            .font(.system(size: 16))
                    }
                    .foregroundColor(card.suit.color == "red" ? .red : .black)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.7, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            CardPickerSheet(
                selectedCards: $allCards,
                maxCards: maxCards,
                excluded: excluded
            )
        }
    }
}

// MARK: - Card Picker Sheet
struct CardPickerSheet: View {
    @Binding var selectedCards: [Card]
    let maxCards: Int
    let excluded: Set<Card>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach([Suit.spades, .hearts, .clubs, .diamonds], id: \.self) { suit in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suitName(suit))
                                .font(.headline)
                                .foregroundColor(suit.color == "red" ? .red : .primary)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                                ForEach(Rank.allCases.reversed(), id: \.self) { rank in
                                    let card = Card(suit: suit, rank: rank)
                                    let isExcluded = excluded.contains(card)
                                    let isSelected = selectedCards.contains(card)
                                    let canSelect = selectedCards.count < maxCards || isSelected
                                    
                                    Button(action: {
                                        if isSelected {
                                            selectedCards.removeAll { $0 == card }
                                        } else if !isExcluded && canSelect {
                                            selectedCards.append(card)
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(isSelected ? Color.blue.opacity(0.2) : Color.white)
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                                            VStack(spacing: 0) {
                                                Text(rank.symbol)
                                                    .font(.system(size: 14, weight: .bold))
                                                Text(suit.rawValue)
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(suit.color == "red" ? .red : .black)
                                        }
                                        .aspectRatio(0.75, contentMode: .fit)
                                        .opacity(isExcluded && !isSelected ? 0.3 : 1)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isExcluded && !isSelected)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("选择卡牌 (\(selectedCards.count)/\(maxCards))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("清除") { selectedCards.removeAll() }
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    func suitName(_ suit: Suit) -> String {
        switch suit {
        case .spades: return "♠️ 黑桃"
        case .hearts: return "♥️ 红心"
        case .diamonds: return "♦️ 方块"
        case .clubs: return "♣️ 梅花"
        }
    }
}

#Preview {
    ContentView()
}
