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
    let kickers: [Int] // Using raw values for speed
    
    static func < (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool {
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        for (l, r) in zip(lhs.kickers, rhs.kickers) {
            if l != r { return l < r }
        }
        return false
    }
    
    static func == (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool {
        lhs.rank == rhs.rank && lhs.kickers == rhs.kickers
    }
}

struct HandEvaluator {
    // Pre-computed 5-card combination indices for 7 cards (C(7,5) = 21 combinations)
    private static let combinationIndices: [[Int]] = [
        [0,1,2,3,4], [0,1,2,3,5], [0,1,2,3,6], [0,1,2,4,5], [0,1,2,4,6],
        [0,1,2,5,6], [0,1,3,4,5], [0,1,3,4,6], [0,1,3,5,6], [0,1,4,5,6],
        [0,2,3,4,5], [0,2,3,4,6], [0,2,3,5,6], [0,2,4,5,6], [0,3,4,5,6],
        [1,2,3,4,5], [1,2,3,4,6], [1,2,3,5,6], [1,2,4,5,6], [1,3,4,5,6],
        [2,3,4,5,6]
    ]
    
    /// Evaluate the best 5-card hand from 7 cards (2 hole + 5 community)
    @inline(__always)
    static func evaluate(holeCards: [Card], communityCards: [Card]) -> EvaluatedHand {
        let allCards = holeCards + communityCards
        let count = allCards.count
        
        guard count >= 5 else {
            let ranks = allCards.map { $0.rank.rawValue }.sorted(by: >)
            return EvaluatedHand(rank: .highCard, kickers: ranks)
        }
        
        if count == 5 {
            return evaluateFiveCards(allCards)
        }
        
        // For 6 or 7 cards, try all 5-card combinations
        var best: EvaluatedHand?
        
        if count == 7 {
            for indices in combinationIndices {
                let hand = [allCards[indices[0]], allCards[indices[1]], allCards[indices[2]], 
                           allCards[indices[3]], allCards[indices[4]]]
                let evaluated = evaluateFiveCards(hand)
                if best == nil || evaluated > best! {
                    best = evaluated
                }
            }
        } else {
            // 6 cards: C(6,5) = 6 combinations
            for skip in 0..<count {
                var hand: [Card] = []
                for i in 0..<count where i != skip {
                    hand.append(allCards[i])
                }
                let evaluated = evaluateFiveCards(hand)
                if best == nil || evaluated > best! {
                    best = evaluated
                }
            }
        }
        
        return best!
    }
    
    /// Evaluate exactly 5 cards - optimized version
    @inline(__always)
    static func evaluateFiveCards(_ cards: [Card]) -> EvaluatedHand {
        // Count ranks and suits
        var rankCounts = [Int](repeating: 0, count: 15) // Index 2-14 for ranks
        var suitCounts = [Int](repeating: 0, count: 4)
        var ranks = [Int]()
        ranks.reserveCapacity(5)
        
        for card in cards {
            let r = card.rank.rawValue
            ranks.append(r)
            rankCounts[r] += 1
            suitCounts[card.suit.rawValue] += 1
        }
        
        ranks.sort(by: >)
        
        // Check flush
        let isFlush = suitCounts.contains(5)
        
        // Check straight
        let (isStraight, straightHigh) = checkStraight(ranks)
        
        // Get counts sorted by frequency then rank
        var pairs: [(rank: Int, count: Int)] = []
        for i in 2...14 {
            if rankCounts[i] > 0 {
                pairs.append((i, rankCounts[i]))
            }
        }
        pairs.sort { a, b in
            if a.count != b.count { return a.count > b.count }
            return a.rank > b.rank
        }
        
        // Royal Flush
        if isFlush && isStraight && straightHigh == 14 {
            return EvaluatedHand(rank: .royalFlush, kickers: [14])
        }
        
        // Straight Flush
        if isFlush && isStraight {
            return EvaluatedHand(rank: .straightFlush, kickers: [straightHigh])
        }
        
        // Four of a Kind
        if pairs[0].count == 4 {
            return EvaluatedHand(rank: .fourOfAKind, kickers: [pairs[0].rank, pairs[1].rank])
        }
        
        // Full House
        if pairs[0].count == 3 && pairs.count > 1 && pairs[1].count >= 2 {
            return EvaluatedHand(rank: .fullHouse, kickers: [pairs[0].rank, pairs[1].rank])
        }
        
        // Flush
        if isFlush {
            return EvaluatedHand(rank: .flush, kickers: ranks)
        }
        
        // Straight
        if isStraight {
            return EvaluatedHand(rank: .straight, kickers: [straightHigh])
        }
        
        // Three of a Kind
        if pairs[0].count == 3 {
            let kickers = pairs.dropFirst().prefix(2).map { $0.rank }
            return EvaluatedHand(rank: .threeOfAKind, kickers: [pairs[0].rank] + kickers)
        }
        
        // Two Pair
        if pairs[0].count == 2 && pairs.count > 1 && pairs[1].count == 2 {
            let high = max(pairs[0].rank, pairs[1].rank)
            let low = min(pairs[0].rank, pairs[1].rank)
            let kicker = pairs.count > 2 ? pairs[2].rank : 0
            return EvaluatedHand(rank: .twoPair, kickers: [high, low, kicker])
        }
        
        // One Pair
        if pairs[0].count == 2 {
            let kickers = pairs.dropFirst().prefix(3).map { $0.rank }
            return EvaluatedHand(rank: .onePair, kickers: [pairs[0].rank] + kickers)
        }
        
        // High Card
        return EvaluatedHand(rank: .highCard, kickers: ranks)
    }
    
    @inline(__always)
    private static func checkStraight(_ sortedRanks: [Int]) -> (Bool, Int) {
        let unique = Array(Set(sortedRanks)).sorted(by: >)
        guard unique.count >= 5 else { return (false, 0) }
        
        // Check regular straights
        for i in 0...(unique.count - 5) {
            if unique[i] - unique[i + 4] == 4 {
                return (true, unique[i])
            }
        }
        
        // Check wheel (A-2-3-4-5)
        let wheelSet: Set<Int> = [14, 2, 3, 4, 5]
        if wheelSet.isSubset(of: Set(unique)) {
            return (true, 5)
        }
        
        return (false, 0)
    }
}
