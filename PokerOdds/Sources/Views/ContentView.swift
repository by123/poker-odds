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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Opponents selector
                    opponentsSection
                    
                    Divider()
                    
                    // Hole cards
                    CardPickerView(
                        selectedCards: $holeCards,
                        maxCards: 2,
                        excludedCards: Set(communityCards),
                        title: "🃏 你的手牌"
                    )
                    .onChange(of: holeCards) { _, _ in clearResult() }
                    
                    Divider()
                    
                    // Community cards
                    CardPickerView(
                        selectedCards: $communityCards,
                        maxCards: 5,
                        excludedCards: Set(holeCards),
                        title: "🎴 公共牌"
                    )
                    .onChange(of: communityCards) { _, _ in clearResult() }
                    
                    // Stage indicator
                    stageIndicator
                    
                    Divider()
                    
                    // Calculate button
                    calculateButton
                    
                    // Results
                    if let result = result {
                        resultsView(result)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("♠️ 德州扑克计算器")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: resetAll) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
        }
    }
    
    var opponentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("👥 对手数量")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...9, id: \.self) { num in
                        Button(action: { 
                            numOpponents = num
                            clearResult()
                        }) {
                            Text("\(num)")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(numOpponents == num ? Color.blue : Color(.systemGray5))
                                .foregroundColor(numOpponents == num ? .white : .primary)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var stageIndicator: some View {
        HStack {
            Text("当前阶段:")
                .foregroundColor(.secondary)
            Text(stageName)
                .font(.headline)
                .foregroundColor(stageColor)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    var stageName: String {
        switch communityCards.count {
        case 0: return "翻牌前 (Pre-flop)"
        case 3: return "翻牌 (Flop)"
        case 4: return "转牌 (Turn)"
        case 5: return "河牌 (River)"
        default: return "选择 0/3/4/5 张公共牌"
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
            HStack {
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
            .padding()
            .background(canCalculate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canCalculate || isCalculating)
    }
    
    func resultsView(_ result: OddsResult) -> some View {
        VStack(spacing: 16) {
            Text("📊 计算结果")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Win rate display
            VStack(spacing: 12) {
                HStack {
                    Text("胜率")
                        .font(.title3)
                    Spacer()
                    Text(String(format: "%.1f%%", result.winRate))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geo.size.width * result.winRate / 100)
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: geo.size.width * result.tieRate / 100)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * result.loseRate / 100)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(height: 28)
                
                // Legend
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 10, height: 10)
                        Text("胜 \(String(format: "%.1f%%", result.winRate))")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.yellow).frame(width: 10, height: 10)
                        Text("平 \(String(format: "%.1f%%", result.tieRate))")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 10, height: 10)
                        Text("负 \(String(format: "%.1f%%", result.loseRate))")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Stats row
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("模拟次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.simulations.formatted())")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
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
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    func calculate() {
        isCalculating = true
        Task {
            let odds = await OddsCalculator.calculate(
                holeCards: holeCards,
                communityCards: communityCards,
                numOpponents: numOpponents,
                simulations: 20000
            )
            await MainActor.run {
                result = odds
                isCalculating = false
            }
        }
    }
    
    func clearResult() {
        result = nil
    }
    
    func resetAll() {
        holeCards = []
        communityCards = []
        numOpponents = 3
        result = nil
    }
}

#Preview {
    ContentView()
}
