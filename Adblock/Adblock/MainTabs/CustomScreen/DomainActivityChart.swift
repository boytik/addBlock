//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI

/// Composite Time-Series Chart: Area + Bars + Line.
/// Layer 1: Area (soft fill), Layer 2: Bars, Layer 3: Line (trend).
struct DomainActivityChart: View {
    let points: [DomainActivityPoint]

    private let lineColor = Color.red
    private let barColor = Color.red.opacity(0.7)
    private let areaColor = Color.red.opacity(0.2)
    private let gridLineColor = Color.white.opacity(0.15)
    private let barWidth: CGFloat = 8
    private let barSpacing: CGFloat = 39
    private let chartHeight: CGFloat = 178
    private let barCornerRadius: CGFloat = 4
    private let lineWidth: CGFloat = 4

    @State private var appeared = false

    var body: some View {
        if points.allSatisfy({ $0.count == 0 }) {
            emptyState
        } else {
            chartContent
        }
    }

    private var emptyState: some View {
        Image("EmptyData")
            .frame(height: chartHeight)
            .frame(maxWidth: .infinity)
            .background(Color("BgForBut"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let maxVal = max(points.map(\.count).max() ?? 1, 1)
            let padding: CGFloat = 24
            let usableHeight = chartHeight - padding * 2

            HStack {
                Spacer(minLength: 0)
                ZStack(alignment: .bottomLeading) {
                    // Layer 0: Горизонтальные линии сетки (4 шт)
                    gridLines(height: usableHeight)

                    // Layer 1: Area (бледно красная заливка под линией тренда)
                    areaPath(height: usableHeight, maxVal: maxVal)
                        .fill(
                            LinearGradient(
                                colors: [areaColor, areaColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.4), value: appeared)

                    // Layer 2: Bars
                    barsView(height: usableHeight, maxVal: maxVal)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.35).delay(0.05), value: appeared)

                    // Layer 3: Line (тренд — сглаженные данные, не по верхушкам столбцов)
                    if points.count > 1 {
                        trendLinePath(height: usableHeight, maxVal: maxVal)
                            .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.4).delay(0.1), value: appeared)
                    }
                }
                .frame(width: chartContentWidth)
                Spacer(minLength: 0)
            }
            .padding(padding)
        }
        .frame(height: chartHeight)
        .background(Color("BgForBut"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private var chartContentWidth: CGFloat {
        CGFloat(points.count) * barWidth + CGFloat(max(0, points.count - 1)) * barSpacing
    }

    private func barCenterX(for index: Int) -> CGFloat {
        CGFloat(index) * (barWidth + barSpacing) + barWidth / 2
    }

    /// Сглаженные значения для линии тренда (3-точечное скользящее среднее).
    private var trendValues: [Double] {
        let counts = points.map { Double($0.count) }
        guard !counts.isEmpty else { return [] }
        if counts.count == 1 { return counts }
        return (0..<counts.count).map { i in
            let prev = i > 0 ? counts[i - 1] : counts[i]
            let next = i < counts.count - 1 ? counts[i + 1] : counts[i]
            return (prev + counts[i] + next) / 3
        }
    }

    private func gridLines(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Spacer(minLength: 0)
                Rectangle()
                    .fill(gridLineColor)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 0)
        }
        .frame(width: chartContentWidth, height: height)
    }

    private func areaPath(height: CGFloat, maxVal: Int) -> Path {
        guard !points.isEmpty, maxVal > 0 else { return Path() }
        let trend = trendValues
        let maxTrend = trend.max() ?? 1
        let scaleMax = max(maxTrend, 1.0)
        var path = Path()
        var pointsForLine: [CGPoint] = []
        for (i, val) in trend.enumerated() {
            let x = barCenterX(for: i)
            let y = height - (CGFloat(val) / CGFloat(scaleMax)) * height
            pointsForLine.append(CGPoint(x: x, y: y))
        }
        guard !pointsForLine.isEmpty else { return Path() }
        path.move(to: CGPoint(x: pointsForLine[0].x, y: height))
        path.addLine(to: pointsForLine[0])
        for i in 1..<pointsForLine.count {
            let p0 = pointsForLine[max(0, i - 2)]
            let p1 = pointsForLine[i - 1]
            let p2 = pointsForLine[i]
            let p3 = pointsForLine[min(i + 1, pointsForLine.count - 1)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        path.addLine(to: CGPoint(x: pointsForLine.last!.x, y: height))
        path.closeSubpath()
        return path
    }

    private func barsView(height: CGFloat, maxVal: Int) -> some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(Array(points.enumerated()), id: \.element.id) { _, pt in
                if pt.count > 0 {
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(barColor)
                        .frame(width: barWidth, height: max(2, (CGFloat(pt.count) / CGFloat(maxVal)) * height))
                        .scaleEffect(y: appeared ? 1 : 0, anchor: .bottom)
                } else {
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(Color.clear)
                        .frame(width: barWidth, height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func trendLinePath(height: CGFloat, maxVal: Int) -> Path {
        guard points.count > 1 else { return Path() }
        let trend = trendValues
        let maxTrend = trend.max() ?? 1
        let scaleMax = max(maxTrend, 1.0)
        var pointsForLine: [CGPoint] = []
        for (i, val) in trend.enumerated() {
            let x = barCenterX(for: i)
            let y = height - (CGFloat(val) / CGFloat(scaleMax)) * height
            pointsForLine.append(CGPoint(x: x, y: y))
        }
        var path = Path()
        path.move(to: pointsForLine[0])
        for i in 1..<pointsForLine.count {
            let p0 = pointsForLine[max(0, i - 2)]
            let p1 = pointsForLine[i - 1]
            let p2 = pointsForLine[i]
            let p3 = pointsForLine[min(i + 1, pointsForLine.count - 1)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }
}
