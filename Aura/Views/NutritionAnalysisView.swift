//
//  NutritionAnalysisView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import PhotosUI

struct NutritionAnalysisView: View {
    @StateObject private var viewModel = NutritionViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Camera Button
                    Button(action: {
                        showingSourceSelection = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("拍摄或选择食物照片")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("AI将为您分析营养成分")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Selected Image
                    if let image = viewModel.selectedImage {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("已选择的图片")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(15)
                                .padding(.horizontal)
                            
                            if viewModel.isAnalyzing {
                                HStack {
                                    ProgressView()
                                    Text("正在分析中...")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            
                            // Error Message
                            if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.red)
                                    
                                    Text("分析失败")
                                        .font(.headline)
                                    
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button("重试") {
                                        viewModel.analyzeImage()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                }
                                .padding()
                            }
                        }
                    }
                    
                    // Analysis Results
                    if let result = viewModel.analysisResult {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("营养分析结果")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            NutritionResultCard(result: result)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewModel.saveToHistory()
                            }) {
                                Text("保存到历史记录")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // History
                    if !viewModel.history.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("历史记录")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.history) { item in
                                HistoryItemRow(item: item)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("营养分析")
            .confirmationDialog("选择图片来源", isPresented: $showingSourceSelection) {
                Button("拍照") {
                    showingCamera = true
                }
                Button("从相册选择") {
                    showingImagePicker = true
                }
                Button("取消", role: .cancel) {}
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $viewModel.selectedImage, onImageCaptured: {
                    viewModel.analyzeImage()
                })
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, onImageSelected: {
                    viewModel.analyzeImage()
                })
            }
        }
    }
}

struct NutritionResultCard: View {
    let result: NutritionResult
    
    var body: some View {
        VStack(spacing: 15) {
            // Food Name
            HStack {
                Text(result.foodName)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Calories
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("总卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(result.calories)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                    + Text(" kcal")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Macronutrients
            HStack(spacing: 20) {
                MacroNutrientView(name: "蛋白质", value: result.protein, color: .red)
                MacroNutrientView(name: "碳水", value: result.carbs, color: .blue)
                MacroNutrientView(name: "脂肪", value: result.fat, color: .yellow)
            }
            
            // Description
            if !result.description.isEmpty {
                Divider()
                
                Text(result.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}

struct MacroNutrientView: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryItemRow: View {
    let item: NutritionHistoryItem
    
    var body: some View {
        HStack(spacing: 15) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(item.result.foodName)
                    .font(.headline)
                Text("\(item.result.calories) kcal")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Text(item.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NutritionAnalysisView()
}
