import Foundation

enum HandRank: Int, Comparable, CustomStringConvertible {
    case highCard = 1
    case onePair = 2
    case twoPair = 3
    case threeOfAKind = 4
    case straight = 5
    case flush = 6
    case fullHouse = 7
    case fourOfAKind = 8
    case straightFlush = 9
    case royalFlush = 10
    
    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .highCard: return "高牌"
        case .onePair: return "一对"
        case .twoPair: return "两对"
        case .threeOfAKind: return "三条"
        case .straight: return "顺子"
        case .flush: return "同花"
        case .fullHouse: return "葫芦"
        case .fourOfAKind: return "四条"
        case .straightFlush: return "同花顺"
        case .royalFlush: return "皇家同花顺"
        }
    }
}

struct EvaluatedHand: Comparable {
    let rank: HandRank
    let kickers: [Rank] // For tie-breaking
    
    static func < (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool {
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        for (l, r) in zip(lhs.kickers, rhs.kickers) {
            if l != r { return l < r }
        }
        return false
    }
}

struct HandEvaluator {
    /// Evaluate the best 5-card hand from 7 cards (2 hole + 5 community)
    static func evaluate(holeCards: [Card], communityCards: [Card]) -> EvaluatedHand {
        let allCards = holeCards + communityCards
        guard allCards.count >= 5 else {
            return EvaluatedHand(rank: .highCard, kickers: allCards.map(\.rank).sorted(by: >))
        }
        
        // Generate all 5-card combinations
        let combinations = allCards.combinations(of: 5)
        return combinations.map { evaluateFiveCards($0) }.max()!
    }
    
    /// Evaluate exactly 5 cards
    static func evaluateFiveCards(_ cards: [Card]) -> EvaluatedHand {
        let ranks = cards.map(\.rank).sorted(by: >)
        let suits = cards.map(\.suit)
        
        let isFlush = Set(suits).count == 1
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        let sortedByCount = rankCounts.sorted { 
            if $0.value != $1.value { return $0.value > $1.value }
            return $0.key > $1.key
        }
        
        // Check for straight
        let uniqueRanks = Array(Set(ranks)).sorted(by: >)
        let isStraight = checkStraight(uniqueRanks)
        let straightHighCard = getStraightHighCard(uniqueRanks)
        
        // Royal Flush
        if isFlush && isStraight && straightHighCard == .ace && !uniqueRanks.contains(.five) {
            return EvaluatedHand(rank: .royalFlush, kickers: [.ace])
        }
        
        // Straight Flush
        if isFlush && isStraight {
            return EvaluatedHand(rank: .straightFlush, kickers: [straightHighCard!])
        }
        
        // Four of a Kind
        if sortedByCount[0].value == 4 {
            let quad = sortedByCount[0].key
            let kicker = sortedByCount[1].key
            return EvaluatedHand(rank: .fourOfAKind, kickers: [quad, kicker])
        }
        
        // Full House
        if sortedByCount[0].value == 3 && sortedByCount[1].value == 2 {
            return EvaluatedHand(rank: .fullHouse, kickers: [sortedByCount[0].key, sortedByCount[1].key])
        }
        
        // Flush
        if isFlush {
            return EvaluatedHand(rank: .flush, kickers: ranks)
        }
        
        // Straight
        if isStraight {
            return EvaluatedHand(rank: .straight, kickers: [straightHighCard!])
        }
        
        // Three of a Kind
        if sortedByCount[0].value == 3 {
            let trip = sortedByCount[0].key
            let kickers = sortedByCount.dropFirst().map(\.key).sorted(by: >)
            return EvaluatedHand(rank: .threeOfAKind, kickers: [trip] + kickers)
        }
        
        // Two Pair
        if sortedByCount[0].value == 2 && sortedByCount[1].value == 2 {
            let pairs = [sortedByCount[0].key, sortedByCount[1].key].sorted(by: >)
            let kicker = sortedByCount[2].key
            return EvaluatedHand(rank: .twoPair, kickers: pairs + [kicker])
        }
        
        // One Pair
        if sortedByCount[0].value == 2 {
            let pair = sortedByCount[0].key
            let kickers = sortedByCount.dropFirst().map(\.key).sorted(by: >)
            return EvaluatedHand(rank: .onePair, kickers: [pair] + kickers)
        }
        
        // High Card
        return EvaluatedHand(rank: .highCard, kickers: ranks)
    }
    
    private static func checkStraight(_ uniqueRanks: [Rank]) -> Bool {
        guard uniqueRanks.count >= 5 else { return false }
        
        // Check regular straight
        for i in 0...(uniqueRanks.count - 5) {
            let slice = uniqueRanks[i..<(i+5)]
            if isConsecutive(Array(slice)) { return true }
        }
        
        // Check wheel (A-2-3-4-5)
        let wheelRanks: Set<Rank> = [.ace, .two, .three, .four, .five]
        if wheelRanks.isSubset(of: Set(uniqueRanks)) { return true }
        
        return false
    }
    
    private static func isConsecutive(_ ranks: [Rank]) -> Bool {
        for i in 0..<(ranks.count - 1) {
            if ranks[i].rawValue - ranks[i+1].rawValue != 1 { return false }
        }
        return true
    }
    
    private static func getStraightHighCard(_ uniqueRanks: [Rank]) -> Rank? {
        // Check regular straights first
        for i in 0...(max(0, uniqueRanks.count - 5)) {
            let slice = Array(uniqueRanks[i..<min(i+5, uniqueRanks.count)])
            if slice.count == 5 && isConsecutive(slice) {
                return slice[0]
            }
        }
        
        // Check wheel
        let wheelRanks: Set<Rank> = [.ace, .two, .three, .four, .five]
        if wheelRanks.isSubset(of: Set(uniqueRanks)) {
            return .five // Wheel's high card is 5
        }
        
        return nil
    }
}

// Helper extension for combinations
extension Array {
    func combinations(of size: Int) -> [[Element]] {
        guard size <= count else { return [] }
        guard size > 0 else { return [[]] }
        guard size < count else { return [self] }
        
        var result: [[Element]] = []
        var indices = [Int](0..<size)
        
        while true {
            result.append(indices.map { self[$0] })
            
            var i = size - 1
            while i >= 0 && indices[i] == count - size + i {
                i -= 1
            }
            
            if i < 0 { break }
            
            indices[i] += 1
            for j in (i + 1)..<size {
                indices[j] = indices[j - 1] + 1
            }
        }
        
        return result
    }
}
