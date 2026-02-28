//
//  AIAdviceView.swift
//  Aura
//
//  AI 建议 Tab 占位（PRD Tab 4）
//

import SwiftUI

struct AIAdviceView: View {
    var body: some View {
        NavigationStack {
            Text("AI Advice")
                .font(.title2)
                .foregroundColor(Color.auraGrayLight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    AIAdviceView()
}
