import SwiftUI

/// График Domain Activity: тёмный контейнер, красная линия тренда.
struct DomainActivityChart: View {
    let values: [Int]
    
    private let lineColor = Color.red
    private let gridColor = Color.white.opacity(0.15)
    
    var body: some View {
        if values.isEmpty {
            Color("BgForBut")
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = values.max() ?? 1
            
            ZStack(alignment: .bottom) {
                gridLines(width: width, height: height)
                
                if values.count > 1 {
                    trendLinePath(width: width, height: height, maxVal: maxVal)
                        .stroke(lineColor, lineWidth: 2.5)
                        .opacity(0.95)
                } else if values.count == 1, maxVal > 0 {
                    let y = height - 12 - (height - 24) * CGFloat(values[0]) / CGFloat(maxVal)
                    Circle()
                        .fill(lineColor)
                        .frame(width: 8, height: 8)
                        .position(x: width / 2, y: y)
                }
            }
        }
        .frame(height: 140)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: height * 3 / 4)
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(gridColor)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
                    .frame(height: height / 4 - 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
    
    private func trendLinePath(width: CGFloat, height: CGFloat, maxVal: Int) -> Path {
        guard values.count > 1, maxVal > 0 else { return Path() }
        let barCount = values.count
        let barWidth = (width - CGFloat(barCount - 1) * 4) / CGFloat(barCount)
        let spacing: CGFloat = 4
        let stepX = barWidth + spacing
        let usableHeight = height - 24
        
        // Сглаженные точки (центры баров)
        var points: [CGPoint] = []
        for (i, value) in values.enumerated() {
            let x = 2 + CGFloat(i) * stepX + barWidth / 2
            let y = height - 12 - (CGFloat(value) / CGFloat(maxVal)) * usableHeight
            points.append(CGPoint(x: x, y: y))
        }
        
        // Catmull-Rom / сглаживание
        var path = Path()
        path.move(to: points[0])
        for i in 1..<points.count {
            let p0 = points[max(0, i - 2)]
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = points[min(i + 1, points.count - 1)]
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }
}
