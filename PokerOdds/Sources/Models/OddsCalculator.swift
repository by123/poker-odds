import Foundation

struct OddsResult {
    let winRate: Double
    let tieRate: Double
    let loseRate: Double
    let simulations: Int
    let bestHand: HandRank?
}

struct OddsCalculator {
    /// Calculate win probability using parallel Monte Carlo simulation
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
        
        // Split work across available cores
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let batchSize = simulations / coreCount
        
        // Run parallel simulations
        let results = await withTaskGroup(of: (wins: Int, ties: Int, losses: Int, bestHand: HandRank).self) { group in
            for i in 0..<coreCount {
                let isLastBatch = i == coreCount - 1
                let count = isLastBatch ? simulations - (batchSize * i) : batchSize
                
                group.addTask {
                    runSimulationBatch(
                        holeCards: holeCards,
                        communityCards: communityCards,
                        usedCards: usedCards,
                        cardsNeeded: cardsNeeded,
                        numOpponents: numOpponents,
                        count: count
                    )
                }
            }
            
            var totalWins = 0
            var totalTies = 0
            var totalLosses = 0
            var bestHandSeen: HandRank = .highCard
            
            for await result in group {
                totalWins += result.wins
                totalTies += result.ties
                totalLosses += result.losses
                if result.bestHand > bestHandSeen {
                    bestHandSeen = result.bestHand
                }
            }
            
            return (totalWins, totalTies, totalLosses, bestHandSeen)
        }
        
        let total = Double(simulations)
        return OddsResult(
            winRate: Double(results.0) / total * 100,
            tieRate: Double(results.1) / total * 100,
            loseRate: Double(results.2) / total * 100,
            simulations: simulations,
            bestHand: results.3
        )
    }
    
    /// Run a batch of simulations (for parallel execution)
    private static func runSimulationBatch(
        holeCards: [Card],
        communityCards: [Card],
        usedCards: Set<Card>,
        cardsNeeded: Int,
        numOpponents: Int,
        count: Int
    ) -> (wins: Int, ties: Int, losses: Int, bestHand: HandRank) {
        var wins = 0
        var ties = 0
        var losses = 0
        var bestHandSeen: HandRank = .highCard
        
        // Pre-build available cards array once
        let availableCards = Card.allCards.filter { !usedCards.contains($0) }
        
        for _ in 0..<count {
            // Shuffle and deal from available cards
            var shuffled = availableCards.shuffled()
            
            // Deal remaining community cards
            let remainingCommunity = Array(shuffled.prefix(cardsNeeded))
            shuffled.removeFirst(cardsNeeded)
            let fullCommunity = communityCards + remainingCommunity
            
            // Evaluate our hand
            let ourHand = HandEvaluator.evaluate(holeCards: holeCards, communityCards: fullCommunity)
            if ourHand.rank > bestHandSeen {
                bestHandSeen = ourHand.rank
            }
            
            // Deal and evaluate opponent hands
            var beaten = true
            var tied = false
            
            for i in 0..<numOpponents {
                let startIdx = i * 2
                guard startIdx + 1 < shuffled.count else { break }
                let oppHole = [shuffled[startIdx], shuffled[startIdx + 1]]
                let oppHand = HandEvaluator.evaluate(holeCards: oppHole, communityCards: fullCommunity)
                
                if oppHand > ourHand {
                    beaten = false
                    tied = false
                    break
                } else if oppHand == ourHand {
                    tied = true
                }
            }
            
            if beaten && !tied {
                wins += 1
            } else if tied {
                ties += 1
            } else {
                losses += 1
            }
        }
        
        return (wins, ties, losses, bestHandSeen)
    }
}
