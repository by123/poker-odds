import SwiftUI

// Card views are now in ContentView.swift
// This file kept for potential future use

struct SimpleCardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            
            VStack(spacing: 0) {
                Text(card.rank.symbol)
                    .font(.system(size: 16, weight: .bold))
                Text(card.suit.rawValue)
                    .font(.system(size: 14))
            }
            .foregroundColor(card.suit.color == "red" ? .red : .black)
        }
        .aspectRatio(0.7, contentMode: .fit)
    }
}

#Preview {
    SimpleCardView(card: Card(suit: .hearts, rank: .ace))
        .frame(width: 60)
}
