import SwiftUI

struct CardView: View {
    let card: Card?
    let isSelected: Bool
    let size: CardSize
    
    enum CardSize {
        case small, medium, large
        
        var width: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 55
            case .large: return 70
            }
        }
        
        var height: CGFloat { width * 1.4 }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
    }
    
    init(card: Card?, isSelected: Bool = false, size: CardSize = .medium) {
        self.card = card
        self.isSelected = isSelected
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(card == nil ? Color.gray.opacity(0.3) : Color.white)
                .shadow(color: isSelected ? .blue : .black.opacity(0.2), radius: isSelected ? 4 : 2)
            
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            
            if let card = card {
                VStack(spacing: 2) {
                    Text(card.rank.symbol)
                        .font(.system(size: size.fontSize, weight: .bold))
                    Text(card.suit.rawValue)
                        .font(.system(size: size.fontSize))
                }
                .foregroundColor(card.suit.color == "red" ? .red : .black)
            } else {
                Text("?")
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

struct CardPickerView: View {
    @Binding var selectedCards: [Card]
    let maxCards: Int
    let excludedCards: Set<Card>
    let title: String
    
    @State private var showingPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if !selectedCards.isEmpty {
                    Button(action: { selectedCards.removeAll() }) {
                        Text("清除")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<maxCards, id: \.self) { index in
                        let card = index < selectedCards.count ? selectedCards[index] : nil
                        CardView(card: card, size: .large)
                            .onTapGesture {
                                if card != nil {
                                    selectedCards.remove(at: index)
                                } else {
                                    showingPicker = true
                                }
                            }
                    }
                    
                    if selectedCards.count < maxCards {
                        Button(action: { showingPicker = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 70, height: 98)
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showingPicker) {
            CardSelectionSheet(
                selectedCards: $selectedCards,
                maxCards: maxCards,
                excludedCards: excludedCards
            )
        }
    }
}

struct CardSelectionSheet: View {
    @Binding var selectedCards: [Card]
    let maxCards: Int
    let excludedCards: Set<Card>
    @Environment(\.dismiss) var dismiss
    
    let suits: [Suit] = [.spades, .hearts, .clubs, .diamonds]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(suits, id: \.self) { suit in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suitName(suit))
                                .font(.headline)
                                .foregroundColor(suit.color == "red" ? .red : .primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(Rank.allCases, id: \.self) { rank in
                                    let card = Card(suit: suit, rank: rank)
                                    let isExcluded = excludedCards.contains(card)
                                    let isSelected = selectedCards.contains(card)
                                    
                                    CardView(card: card, isSelected: isSelected, size: .small)
                                        .opacity(isExcluded && !isSelected ? 0.3 : 1)
                                        .onTapGesture {
                                            if isSelected {
                                                selectedCards.removeAll { $0 == card }
                                            } else if !isExcluded && selectedCards.count < maxCards {
                                                selectedCards.append(card)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("选择卡牌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
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
    CardView(card: Card(suit: .hearts, rank: .ace), size: .large)
}
