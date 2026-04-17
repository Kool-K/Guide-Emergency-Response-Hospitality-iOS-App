import re

with open('Sources/Guide/GuestDashboardView.swift', 'r') as f:
    content = f.read()

zoomable_struct = '''
// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let uiImage: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        if scale < 1.0 { scale = 1.0 }
                        if scale > 5.0 { scale = 5.0 }
                        lastScale = scale
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
    }
}
'''

content = re.sub(
    r'(struct GuestDashboardView: View \{)',
    zoomable_struct + r'\n\1',
    content
)

content = re.sub(
    r'Image\(uiImage: uiImage\)\s*\n\s*\.resizable\(\)\s*\n\s*\.scaledToFit\(\)',
    r'ZoomableImageView(uiImage: uiImage)',
    content
)

with open('Sources/Guide/GuestDashboardView.swift', 'w') as f:
    f.write(content)
