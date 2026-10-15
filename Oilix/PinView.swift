//
//  PinView.swift
//  Oilix
//
//  Created by Guo, Congyu on 2/15/22.
//

import SwiftUI

struct PinView: View {
    let res: String
    @ScaledMetric(relativeTo: .caption) private var markerWidth: CGFloat = 76
    @ScaledMetric(relativeTo: .caption) private var markerHeight: CGFloat = 32

    var body: some View {
        VStack(spacing: 0) {
            Text(res.isEmpty ? "-" : res)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, 6)
                .frame(width: min(markerWidth, 160), height: min(markerHeight, 80))
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor, lineWidth: 2))
            Image(systemName: "triangle.fill").resizable().scaledToFit()
                .foregroundColor(.accentColor).frame(width: 14, height: 10)
                .rotationEffect(.degrees(180)).accessibilityHidden(true)
        }
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(res.isEmpty ? "Result not available" : "\(res) mg/L")
    }
}

struct PinView_Previews: PreviewProvider {
    static var previews: some View { PinView(res: "114.514") }
}
