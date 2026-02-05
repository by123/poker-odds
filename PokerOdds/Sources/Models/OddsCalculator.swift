import Foundation

struct OddsResult {
    let winRate: Double
    let tieRate: Double
    let loseRate: Double
    let simulations: Int
    let bestHand: HandRank?
}

actor OddsCalculator {
    /// Calculate win probability using Monte Carlo simulation
    static func calculate(
        holeCards: [Card],
        communityCards: [Card],
        numOpponents: Int,
        simulations: Int = 10000
    ) async -> OddsResult {
        guard holeCards.count == 2 else {
            return OddsResult(winRate: 0, tieRate: 0, loseRate: 0, simulations: 0, bestHand: nil)
        }
        
        let usedCards = Set(holeCards + communityCards)
        let cardsNeeded = 5 - communityCards.count
        
        var wins = 0
        var ties = 0
        var losses = 0
        var bestHandSeen: HandRank = .highCard
        
        for _ in 0..<simulations {
            var deck = Deck(excluding: usedCards)
            
            // Deal remaining community cards
            let remainingCommunity = deck.draw(cardsNeeded)
            let fullCommunity = communityCards + remainingCommunity
            
            // Evaluate our hand
            let ourHand = HandEvaluator.evaluate(holeCards: holeCards, communityCards: fullCommunity)
            if ourHand.rank > bestHandSeen {
                bestHandSeen = ourHand.rank
            }
            
            // Deal and evaluate opponent hands
            var opponentBest: EvaluatedHand?
            for _ in 0..<numOpponents {
                let oppHole = deck.draw(2)
                let oppHand = HandEvaluator.evaluate(holeCards: oppHole, communityCards: fullCommunity)
                if opponentBest == nil || oppHand > opponentBest! {
                    opponentBest = oppHand
                }
            }
            
            // Compare
            if let best = opponentBest {
                if ourHand > best {
                    wins += 1
                } else if ourHand < best {
                    losses += 1
                } else {
                    ties += 1
                }
            } else {
                wins += 1
            }
        }
        
        let total = Double(simulations)
        return OddsResult(
            winRate: Double(wins) / total * 100,
            tieRate: Double(ties) / total * 100,
            loseRate: Double(losses) / total * 100,
            simulations: simulations,
            bestHand: bestHandSeen
        )
    }
}
