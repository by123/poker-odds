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
                    VStack(alignment: .leading, spacing: 14) {
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
                        communityCardSection
                        
                        // Stage indicator
                        stageChip
                        
                        // Results
                        if let result = result {
                            ResultsView(result: result, onRefine: refineCalculation)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("POKER ODDS")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.chipGold)
                Text("德州扑克胜率计算器")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            HStack(spacing: -8) {
                ChipView(color: .chipRed, size: 30)
                ChipView(color: .chipGold, size: 30)
                ChipView(color: .chipBlack, size: 30)
            }
        }
    }
    
    func cardSection(title: String, emoji: String, cards: Binding<[Card]>, maxCards: Int, excluded: Set<Card>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.chipGold)
                Spacer()
                if !cards.wrappedValue.isEmpty {
                    Button(action: {
                        cards.wrappedValue.removeAll()
                        result = nil
                    }) {
                        Text("CLEAR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.chipRed)
                    }
                }
            }
            
            HStack(spacing: 8) {
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
        .padding(14)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    var communityCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🃏")
                Text("COMMUNITY")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.chipGold)
                Spacer()
                if !communityCards.isEmpty {
                    Button(action: {
                        communityCards.removeAll()
                        result = nil
                    }) {
                        Text("CLEAR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.chipRed)
                    }
                }
            }
            
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    CommunityCardSlot(
                        card: index < communityCards.count ? communityCards[index] : nil,
                        index: index,
                        currentCount: communityCards.count,
                        allCards: $communityCards,
                        excluded: Set(holeCards),
                        onChanged: { result = nil }
                    )
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    var stageChip: some View {
        HStack(spacing: 10) {
            ChipView(color: stageColor, size: 24)
            Text(stageName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
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
            let odds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 10000
            )
            await MainActor.run {
                result = odds
                isCalculating = false
            }
        }
    }
    
    func refineCalculation() {
        isCalculating = true
        Task {
            let odds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 50000
            )
            await MainActor.run {
                result = odds
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("👥")
                Text("OPPONENTS")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.chipGold)
                Spacer()
                Text("\(selected)")
                    .font(.system(size: 20, weight: .black))
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
                                ChipView(color: .chipGold, size: 34)
                            } else {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 34, height: 34)
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    .frame(width: 34, height: 34)
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
        .padding(14)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.chipWhite)
                    
                    VStack(spacing: 0) {
                        Text(card.rank.symbol)
                            .font(.system(size: 16, weight: .black))
                        Text(card.suit.symbol)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(card.suit.color == "red" ? .red : .black)
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.4))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.chipGold.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
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

// MARK: - Community Card Slot (with flop/turn/river rules)
struct CommunityCardSlot: View {
    let card: Card?
    let index: Int
    let currentCount: Int
    @Binding var allCards: [Card]
    let excluded: Set<Card>
    var onChanged: () -> Void
    
    @State private var showPicker = false
    
    // Determine if this slot is tappable
    var isTappable: Bool {
        if card != nil {
            // Can tap to remove only the last card(s)
            return index >= currentCount - 1
        } else {
            // Can add based on current count:
            // 0 cards -> can tap slots 0,1,2 (to add flop)
            // 3 cards -> can tap slot 3 (to add turn)
            // 4 cards -> can tap slot 4 (to add river)
            switch currentCount {
            case 0: return index < 3
            case 3: return index == 3
            case 4: return index == 4
            default: return false
            }
        }
    }
    
    // How many cards to select
    var cardsToSelect: Int {
        switch currentCount {
        case 0: return 3  // Flop
        case 3: return 1  // Turn
        case 4: return 1  // River
        default: return 0
        }
    }
    
    var body: some View {
        Button(action: {
            if card != nil {
                // Remove from this index onwards
                if currentCount == 5 {
                    allCards.removeLast()
                } else if currentCount == 4 {
                    allCards.removeLast()
                } else {
                    allCards.removeAll()
                }
                onChanged()
            } else if isTappable {
                showPicker = true
            }
        }) {
            ZStack {
                if let card = card {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.chipWhite)
                    
                    VStack(spacing: 0) {
                        Text(card.rank.symbol)
                            .font(.system(size: 16, weight: .black))
                        Text(card.suit.symbol)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(card.suit.color == "red" ? .red : .black)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(isTappable ? 0.4 : 0.2))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            Color.chipGold.opacity(isTappable ? 0.5 : 0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4])
                        )
                    
                    if isTappable {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.chipGold.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.7, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(!isTappable && card == nil)
        .sheet(isPresented: $showPicker) {
            CommunityCardPicker(
                selectedCards: $allCards,
                requiredCount: cardsToSelect,
                excluded: excluded,
                onDone: onChanged
            )
        }
    }
}

// MARK: - Community Card Picker (enforces exact count)
struct CommunityCardPicker: View {
    @Binding var selectedCards: [Card]
    let requiredCount: Int
    let excluded: Set<Card>
    var onDone: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var tempSelection: [Card] = []
    
    var canComplete: Bool {
        tempSelection.count == requiredCount
    }
    
    var title: String {
        switch requiredCount {
        case 3: return "选择翻牌 (3张)"
        case 1: return "选择1张"
        default: return "选择卡牌"
        }
    }
    
    var body: some View {
        ZStack {
            Color.feltGreen.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button("取消") { dismiss() }
                        .foregroundColor(.chipRed)
                    Spacer()
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.chipGold)
                    Spacer()
                    Button("完成") {
                        selectedCards.append(contentsOf: tempSelection)
                        onDone()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(canComplete ? .chipGold : .gray)
                    .disabled(!canComplete)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Selection indicator
                HStack {
                    Text("已选: \(tempSelection.count)/\(requiredCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if !tempSelection.isEmpty {
                        Button("清除") { tempSelection.removeAll() }
                            .font(.system(size: 13))
                            .foregroundColor(.chipRed)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach([Suit.spades, .hearts, .clubs, .diamonds], id: \.self) { suit in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(suit.symbol)
                                        .font(.title3)
                                    Text(suitName(suit))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(suit.color == "red" ? .red : .white)
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                                    ForEach(Rank.allCases.reversed(), id: \.self) { rank in
                                        let card = Card(suit: suit, rank: rank)
                                        let isExcluded = excluded.contains(card) || selectedCards.contains(card)
                                        let isSelected = tempSelection.contains(card)
                                        let canSelect = tempSelection.count < requiredCount || isSelected
                                        
                                        Button(action: {
                                            if isSelected {
                                                tempSelection.removeAll { $0 == card }
                                            } else if !isExcluded && canSelect {
                                                tempSelection.append(card)
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
    var onRefine: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 14) {
            // Win rate row
            HStack(spacing: 12) {
                // Big win rate
                VStack(spacing: 4) {
                    Text("WIN")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.chipGold)
                    Text(String(format: "%.1f%%", result.winRate))
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                // Tie
                VStack(spacing: 4) {
                    Text("TIE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.chipGold)
                    Text(String(format: "%.1f%%", result.tieRate))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .frame(maxWidth: .infinity)
                
                // Lose
                VStack(spacing: 4) {
                    Text("LOSE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.chipGold)
                    Text(String(format: "%.1f%%", result.loseRate))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.chipRed)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Progress bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.green)
                        .frame(width: geo.size.width * result.winRate / 100)
                    Rectangle().fill(Color.yellow)
                        .frame(width: geo.size.width * result.tieRate / 100)
                    Rectangle().fill(Color.chipRed)
                        .frame(width: geo.size.width * result.loseRate / 100)
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 10)
            
            // Best hand & sims
            HStack {
                if let hand = result.bestHand {
                    Text("最佳: \(hand.description)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("\(result.simulations.formatted()) 次模拟")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Refine button (show if < 50000 sims)
            if result.simulations < 50000, let onRefine = onRefine {
                Button(action: onRefine) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("精确计算 (50,000次)")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.chipGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.chipGold.opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.chipGold.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ResultChip: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                ChipView(color: color, size: 40)
                Text(String(format: "%.0f", value))
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ContentView()
}
