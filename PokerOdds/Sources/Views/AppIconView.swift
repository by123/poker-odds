import SwiftUI

/// App Icon design - can be rendered and exported
struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Felt green background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.36, blue: 0.18),
                            Color(red: 0.03, green: 0.24, blue: 0.11),
                            Color(red: 0.02, green: 0.16, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Radial highlight
            RadialGradient(
                colors: [Color.white.opacity(0.05), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: size * 0.5
            )
            
            // Main chip
            GoldChipIcon(size: size * 0.7)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

struct GoldChipIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Chip body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 0.15),
                            Color(red: 0.75, green: 0.58, blue: 0.12),
                            Color(red: 0.6, green: 0.48, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: size * 0.05, y: size * 0.02)
            
            // Inner ring
            Circle()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: size * 0.03)
                .padding(size * 0.12)
            
            // Edge dashes
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size * 0.035)
                    .offset(x: size * 0.42)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }
            
            // Center circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(size * 0.22)
                .shadow(color: .black.opacity(0.3), radius: size * 0.02)
            
            // Spade symbol
            VStack(spacing: -size * 0.02) {
                Text("♠")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("%")
                    .font(.system(size: size * 0.12, weight: .black))
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.15))
            }
        }
        .frame(width: size, height: size)
    }
}

// Preview and export helper
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            AppIconView(size: 512)
            
            HStack(spacing: 20) {
                AppIconView(size: 180)
                AppIconView(size: 120)
                AppIconView(size: 60)
            }
        }
        .padding(40)
        .background(Color(white: 0.1))
    }
}

#Preview("App Icon") {
    AppIconPreview()
}
