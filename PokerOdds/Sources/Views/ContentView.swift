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
        NavigationView {
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
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("♠️ 德州扑克计算器")
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
        VStack(alignment: .leading, spacing: 8) {
            Text("👥 对手数量")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(1...9, id: \.self) { num in
                    Button(action: { 
                        numOpponents = num
                        clearResult()
                    }) {
                        Text("\(num)")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(numOpponents == num ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(numOpponents == num ? .white : .primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    var stageIndicator: some View {
        HStack {
            Text("当前阶段:")
                .foregroundColor(.secondary)
            Text(stageName)
                .font(.headline)
                .foregroundColor(stageColor)
        }
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
            
            // Win rate bar
            VStack(spacing: 8) {
                HStack {
                    Text("胜率")
                    Spacer()
                    Text(String(format: "%.1f%%", result.winRate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
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
                .frame(height: 24)
                
                HStack {
                    Label(String(format: "%.1f%%", result.winRate), systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Spacer()
                    Label(String(format: "%.1f%%", result.tieRate), systemImage: "equal.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Spacer()
                    Label(String(format: "%.1f%%", result.loseRate), systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Stats
            HStack {
                VStack {
                    Text("模拟次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.simulations)")
                        .font(.headline)
                }
                Spacer()
                if let hand = result.bestHand {
                    VStack {
                        Text("最佳牌型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(hand.description)
                            .font(.headline)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
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
