import SwiftUI

// MARK: - Casino Colors
extension Color {
    static let feltGreen = Color(red: 0.05, green: 0.35, blue: 0.15)
    static let chipGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let chipRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    static let chipBlack = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let chipWhite = Color(red: 0.95, green: 0.95, blue: 0.92)
}

struct ContentView: View {
    @State private var holeCards: [Card] = []
    @State private var communityCards: [Card] = []
    @State private var numOpponents: Int = 3
    @State private var result: OddsResult?
    @State private var isCalculating = false
    
    // 统一的屏幕边距
    private let screenPadding: CGFloat = 20
    
    var canCalculate: Bool {
        holeCards.count == 2
    }
    
    var body: some View {
        ZStack {
            // Felt background with subtle pattern
            FeltBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        headerView
                        
                        // Opponents selector
                        ChipSelector(selected: $numOpponents, onChange: { result = nil })
                        
                        // Hole cards
                        cardSection(
                            title: "YOUR HAND",
                            emoji: "🎰",
                            cards: $holeCards,
                            maxCards: 2,
                            excluded: Set(communityCards)
                        )
                        
                        // Community cards
                        cardSection(
                            title: "COMMUNITY",
                            emoji: "🃏",
                            cards: $communityCards,
                            maxCards: 5,
                            excluded: Set(holeCards)
                        )
                        
                        // Stage indicator
                        stageChip
                        
                        // Results
                        if let result = result {
                            ResultsView(result: result)
                        }
                    }
                    .padding(.horizontal, screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                
                // Fixed bottom button - 使用相同的边距
                calculateButton
                    .padding(.horizontal, screenPadding)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(0.8))
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("POKER ODDS")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.chipGold)
                Text("德州扑克胜率计算器")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            // Decorative chips
            HStack(spacing: -10) {
                ChipView(color: .chipRed, size: 36)
                ChipView(color: .chipGold, size: 36)
                ChipView(color: .chipBlack, size: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    func cardSection(title: String, emoji: String, cards: Binding<[Card]>, maxCards: Int, excluded: Set<Card>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.chipGold)
                Spacer()
                if !cards.wrappedValue.isEmpty {
                    Button(action: {
                        cards.wrappedValue.removeAll()
                        result = nil
                    }) {
                        Text("CLEAR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.chipRed)
                    }
                }
            }
            
            HStack(spacing: 10) {
                ForEach(0..<maxCards, id: \.self) { index in
                    CasinoCardSlot(
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
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    var stageChip: some View {
        HStack {
            ChipView(color: stageColor, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("STAGE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))
                Text(stageName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    var stageName: String {
        switch communityCards.count {
        case 0: return "Pre-flop 翻牌前"
        case 3: return "Flop 翻牌"
        case 4: return "Turn 转牌"
        case 5: return "River 河牌"
        default: return "选择公共牌"
        }
    }
    
    var stageColor: Color {
        switch communityCards.count {
        case 0: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .chipRed
        default: return .gray
        }
    }
    
    var calculateButton: some View {
        Button(action: calculate) {
            HStack(spacing: 12) {
                if isCalculating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Image(systemName: "suit.spade.fill")
                        .font(.title3)
                }
                Text(isCalculating ? "CALCULATING..." : "CALCULATE ODDS")
                    .font(.system(size: 16, weight: .black))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                canCalculate ?
                    LinearGradient(colors: [.chipGold, .chipGold.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(.black)
            .cornerRadius(28)
            .shadow(color: canCalculate ? .chipGold.opacity(0.5) : .clear, radius: 10, y: 4)
        }
        .disabled(!canCalculate || isCalculating)
    }
    
    func calculate() {
        isCalculating = true
        Task {
            let quickOdds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 5000
            )
            await MainActor.run { result = quickOdds }
            
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

// MARK: - Felt Background
struct FeltBackground: View {
    var body: some View {
        ZStack {
            Color.feltGreen
            
            // Subtle radial gradient
            RadialGradient(
                colors: [Color.feltGreen.opacity(0.8), Color.black.opacity(0.5)],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            
            // Noise texture effect
            Canvas { context, size in
                for _ in 0..<1000 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.08)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Chip View
struct ChipView: View {
    let color: Color
    var size: CGFloat = 44
    
    var body: some View {
        ZStack {
            // Main chip body
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            
            // Inner ring pattern
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: size * 0.06)
                .frame(width: size * 0.7, height: size * 0.7)
            
            // Edge dashes
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.15, height: size * 0.06)
                    .offset(x: size * 0.38)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            // Outer ring
            Circle()
                .strokeBorder(color.opacity(0.5), lineWidth: size * 0.08)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Chip Selector
struct ChipSelector: View {
    @Binding var selected: Int
    var onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👥")
                Text("OPPONENTS")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.chipGold)
                Spacer()
                Text("\(selected)")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { num in
                    Button(action: {
                        selected = num
                        onChange()
                    }) {
                        ZStack {
                            if selected == num {
                                ChipView(color: .chipGold, size: 36)
                            } else {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    .frame(width: 36, height: 36)
                            }
                            Text("\(num)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selected == num ? .black : .white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Casino Card Slot
struct CasinoCardSlot: View {
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
                if let card = card {
                    // Card face
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.chipWhite)
                    
                    VStack(spacing: 2) {
                        Text(card.rank.symbol)
                            .font(.system(size: 20, weight: .black))
                        Text(card.suit.symbol)
                            .font(.system(size: 18))
                    }
                    .foregroundColor(card.suit.color == "red" ? .red : .black)
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.4))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.chipGold.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.chipGold.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.7, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            CasinoCardPicker(
                selectedCards: $allCards,
                maxCards: maxCards,
                excluded: excluded
            )
        }
    }
}

// MARK: - Casino Card Picker
struct CasinoCardPicker: View {
    @Binding var selectedCards: [Card]
    let maxCards: Int
    let excluded: Set<Card>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.feltGreen.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("清除") { selectedCards.removeAll() }
                        .foregroundColor(.chipRed)
                    Spacer()
                    Text("SELECT CARDS")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.chipGold)
                    Spacer()
                    Button("完成") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(.chipGold)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach([Suit.spades, .hearts, .clubs, .diamonds], id: \.self) { suit in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(suit.symbol)
                                        .font(.title2)
                                    Text(suitName(suit))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(suit.color == "red" ? .red : .white)
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
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
                                                    .fill(isSelected ? Color.chipGold : Color.chipWhite)
                                                VStack(spacing: 0) {
                                                    Text(rank.symbol)
                                                        .font(.system(size: 14, weight: .bold))
                                                    Text(suit.symbol)
                                                        .font(.system(size: 12))
                                                }
                                                .foregroundColor(isSelected ? .black : (suit.color == "red" ? .red : .black))
                                            }
                                            .aspectRatio(0.75, contentMode: .fit)
                                            .opacity(isExcluded && !isSelected ? 0.3 : 1)
                                        }
                                        .disabled(isExcluded && !isSelected)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func suitName(_ suit: Suit) -> String {
        switch suit {
        case .spades: return "SPADES"
        case .hearts: return "HEARTS"
        case .diamonds: return "DIAMONDS"
        case .clubs: return "CLUBS"
        }
    }
}

// MARK: - Results View
struct ResultsView: View {
    let result: OddsResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Big win rate display
            ZStack {
                // Chip background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.chipGold.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 4) {
                    Text("WIN RATE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.chipGold)
                    
                    Text(String(format: "%.1f", result.winRate))
                        .font(.system(size: 64, weight: .black))
                        .foregroundColor(.white)
                    + Text("%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.chipGold)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress chips
            HStack(spacing: 20) {
                ResultChip(label: "WIN", value: result.winRate, color: .green)
                ResultChip(label: "TIE", value: result.tieRate, color: .chipGold)
                ResultChip(label: "LOSE", value: result.loseRate, color: .chipRed)
            }
            
            // Best hand
            if let hand = result.bestHand {
                HStack {
                    ChipView(color: .chipGold, size: 28)
                    Text("BEST: \(hand.description)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(result.simulations.formatted()) sims")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ResultChip: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ChipView(color: color, size: 50)
                Text(String(format: "%.0f", value))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ContentView()
}
