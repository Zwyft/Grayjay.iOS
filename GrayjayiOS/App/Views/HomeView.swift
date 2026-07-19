import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Feed")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Content Feed Placeholder
                VStack(spacing: 32) {
                    ForEach(0..<5) { index in
                        VideoCardPlaceholder()
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct VideoCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            Rectangle()
                .fill(Color(white: 0.1))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            // Metadata
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.2))
                        .frame(width: 200, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(width: 120, height: 12)
                }
            }
        }
    }
}
