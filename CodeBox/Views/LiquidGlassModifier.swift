import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}
