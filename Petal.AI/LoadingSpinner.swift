import SwiftUI

struct LoadingSpinner: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Theme.accentColor, lineWidth: 3)
            .frame(width: 30, height: 30)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct LoadingSpinner_Previews: PreviewProvider {
    static var previews: some View {
        LoadingSpinner()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(.systemBackground))
    }
}