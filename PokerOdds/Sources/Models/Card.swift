import Foundation

enum Suit: Int, CaseIterable, Codable, Hashable {
    case spades = 0
    case hearts = 1
    case diamonds = 2
    case clubs = 3
    
    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }
    
    var color: String {
        switch self {
        case .hearts, .diamonds: return "red"
        case .spades, .clubs: return "black"
        }
    }
}

enum Rank: Int, CaseIterable, Codable, Hashable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14
    
    var symbol: String {
        switch self {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        case .ten: return "10"
        default: return String(rawValue)
        }
    }
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Card: Hashable, Codable, Identifiable {
    let suit: Suit
    let rank: Rank
    
    var id: String { "\(rank.symbol)\(suit.symbol)" }
    
    var display: String { "\(rank.symbol)\(suit.symbol)" }
    
    static var allCards: [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in
                Card(suit: suit, rank: rank)
            }
        }
    }
}

struct Deck {
    private var cards: [Card]
    
    init(excluding: Set<Card> = []) {
        cards = Card.allCards.filter { !excluding.contains($0) }.shuffled()
    }
    
    mutating func draw() -> Card? {
        cards.popLast()
    }
    
    mutating func draw(_ count: Int) -> [Card] {
        (0..<count).compactMap { _ in draw() }
    }
}
