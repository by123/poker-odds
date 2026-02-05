import Foundation
import GameplayKit

struct OddsResult {
    let winRate: Double
    let tieRate: Double
    let loseRate: Double
    let simulations: Int
    let bestHand: HandRank?
}

struct OddsCalculator {
    /// Calculate win probability using deterministic Monte Carlo simulation
    /// Same input always produces same output
    static func calculate(
        holeCards: [Card],
        communityCards: [Card],
        numOpponents: Int,
        simulations: Int = 10000
    ) async -> OddsResult {
        guard holeCards.count == 2 else {
            return OddsResult(winRate: 0, tieRate: 0, loseRate: 0, simulations: 0, bestHand: nil)
        }
        
        // Generate deterministic seed from input
        let seed = generateSeed(holeCards: holeCards, communityCards: communityCards, numOpponents: numOpponents)
        
        let usedCards = Set(holeCards + communityCards)
        let cardsNeeded = 5 - communityCards.count
        
        // Split work across available cores
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let batchSize = simulations / coreCount
        
        // Run parallel simulations with deterministic seeds per batch
        let results = await withTaskGroup(of: (wins: Int, ties: Int, losses: Int, bestHand: HandRank).self) { group in
            for i in 0..<coreCount {
                let isLastBatch = i == coreCount - 1
                let count = isLastBatch ? simulations - (batchSize * i) : batchSize
                let batchSeed = seed &+ UInt64(i * 1000000) // Different but deterministic seed per batch
                
                group.addTask {
                    runSimulationBatch(
                        holeCards: holeCards,
                        communityCards: communityCards,
                        usedCards: usedCards,
                        cardsNeeded: cardsNeeded,
                        numOpponents: numOpponents,
                        count: count,
                        seed: batchSeed
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
    
    /// Generate a deterministic seed from the input cards
    private static func generateSeed(holeCards: [Card], communityCards: [Card], numOpponents: Int) -> UInt64 {
        var hasher = Hasher()
        
        // Sort cards to ensure consistent hashing regardless of selection order
        let sortedHole = holeCards.sorted { $0.id < $1.id }
        let sortedCommunity = communityCards.sorted { $0.id < $1.id }
        
        for card in sortedHole {
            hasher.combine(card.id)
        }
        for card in sortedCommunity {
            hasher.combine(card.id)
        }
        hasher.combine(numOpponents)
        
        let hash = hasher.finalize()
        return UInt64(bitPattern: Int64(hash))
    }
    
    /// Run a batch of simulations with deterministic randomness
    private static func runSimulationBatch(
        holeCards: [Card],
        communityCards: [Card],
        usedCards: Set<Card>,
        cardsNeeded: Int,
        numOpponents: Int,
        count: Int,
        seed: UInt64
    ) -> (wins: Int, ties: Int, losses: Int, bestHand: HandRank) {
        var wins = 0
        var ties = 0
        var losses = 0
        var bestHandSeen: HandRank = .highCard
        
        // Use deterministic random generator
        let randomSource = GKMersenneTwisterRandomSource(seed: seed)
        
        // Pre-build available cards array once
        let availableCards = Card.allCards.filter { !usedCards.contains($0) }
        
        for _ in 0..<count {
            // Deterministic shuffle using Fisher-Yates with seeded RNG
            var shuffled = availableCards
            for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
                let j = randomSource.nextInt(upperBound: i + 1)
                shuffled.swapAt(i, j)
            }
            
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
