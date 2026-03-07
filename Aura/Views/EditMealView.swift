//
//  EditMealView.swift
//  Aura
//
//  编辑餐食 - 参考 Edit Meal.png，用户可修改餐食数据
//

import SwiftUI

struct EditMealIngredient: Identifiable {
    let id = UUID()
    var name: String
    var quantity: String
}

struct EditMealView: View {
    let item: NutritionHistoryItem
    @ObservedObject var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mealName: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatsText: String = ""
    @State private var ingredients: [EditMealIngredient] = []
    @State private var isSaving = false
    @State private var showingAddIngredient = false
    @State private var newIngredientName = ""
    @State private var newIngredientQty = ""

    private var currentItem: NutritionHistoryItem {
        viewModel.history.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mealImageSection
                mealDetailsSection
                nutritionalBreakdownSection
                ingredientsSection
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .navigationTitle("Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFromItem()
        }
        .sheet(isPresented: $showingAddIngredient) {
            addIngredientSheet
        }
    }

    // MARK: - Meal Image

    private var mealImageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = currentItem.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let imageURL = currentItem.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            .frame(height: 220)
            .clipped()

            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("AI ANALYSIS ORIGINAL")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .padding(12)
        }
        .cornerRadius(12)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.94))
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(Color.auraGrayLight)
            )
    }

    // MARK: - Meal Details (Name, Calories)

    private var mealDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelField("MEAL NAME", text: $mealName)

            VStack(alignment: .leading, spacing: 6) {
                Text("CALORIES")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                HStack(spacing: 0) {
                    TextField("0", text: $caloriesText)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGreen)
                    Text(" kcal")
                        .font(.body)
                        .foregroundColor(Color.auraGrayLight)
                }
                .padding(14)
                .background(Color(white: 0.96))
                .cornerRadius(10)
            }
        }
    }

    private func labelField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
            TextField("", text: text)
                .font(.body)
                .foregroundColor(Color.auraGrayDark)
                .padding(14)
                .background(Color(white: 0.96))
                .cornerRadius(10)
        }
    }

    // MARK: - Nutritional Breakdown

    private var nutritionalBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NUTRITIONAL BREAKDOWN")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)

            HStack(spacing: 12) {
                macroCard(title: "PROTEIN", value: $proteinText)
                macroCard(title: "CARBS", value: $carbsText)
                macroCard(title: "FATS", value: $fatsText)
            }
        }
    }

    private func macroCard(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color.auraGrayLight)
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            Text("g")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(white: 0.96))
        .cornerRadius(10)
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INGREDIENTS DETECTED")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Button {
                    newIngredientName = ""
                    newIngredientQty = ""
                    showingAddIngredient = true
                } label: {
                    Text("ADD INGREDIENT")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGreen)
                }
            }

            if ingredients.isEmpty {
                Text("No ingredients detected. Tap ADD INGREDIENT to add manually.")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.96))
                    .cornerRadius(10)
            }

            ForEach(Array(ingredients.enumerated()), id: \.element.id) { idx, _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.auraGreen)
                        .frame(width: 8, height: 8)
                    TextField("Ingredient", text: $ingredients[idx].name)
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    TextField("Qty", text: $ingredients[idx].quantity)
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                    Button(role: .destructive) {
                        ingredients.remove(at: idx)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(Color.auraGrayLight)
                    }
                }
                .padding(14)
                .background(Color(white: 0.96))
                .cornerRadius(10)
            }
        }
    }

    private var addIngredientSheet: some View {
        NavigationStack {
            Form {
                Section("New Ingredient") {
                    TextField("Name", text: $newIngredientName)
                    TextField("Quantity (e.g. 1 slice)", text: $newIngredientQty)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddIngredient = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !newIngredientName.isEmpty {
                            ingredients.append(EditMealIngredient(
                                name: newIngredientName,
                                quantity: newIngredientQty.isEmpty ? "1 unit" : newIngredientQty
                            ))
                            showingAddIngredient = false
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.auraGreen)
                    .disabled(newIngredientName.isEmpty)
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            Text("Save Changes")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.auraGreen)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(isSaving || !isValid)
    }

    private var isValid: Bool {
        !mealName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(caloriesText) != nil && (Int(caloriesText) ?? 0) > 0
    }

    // MARK: - Load & Save

    private func loadFromItem() {
        let r = currentItem.result
        mealName = r.foodName
        caloriesText = "\(r.calories)"
        proteinText = "\(Int(r.protein))"
        carbsText = "\(Int(r.carbs))"
        fatsText = "\(Int(r.fat))"
        ingredients = parseIngredients(from: r.description)
    }

    private func parseIngredients(from description: String) -> [EditMealIngredient] {
        guard !description.isEmpty else { return [] }
        return description.split(separator: ",").map { part in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if let paren = trimmed.firstIndex(of: "(") {
                let name = String(trimmed[..<paren]).trimmingCharacters(in: .whitespaces)
                let qtyStart = trimmed.index(after: paren)
                let qtyEnd = trimmed.firstIndex(of: ")") ?? trimmed.endIndex
                let qty = String(trimmed[qtyStart..<qtyEnd]).trimmingCharacters(in: .whitespaces)
                return EditMealIngredient(name: name, quantity: qty.isEmpty ? "1" : qty)
            }
            return EditMealIngredient(name: trimmed, quantity: "1")
        }
    }

    private func saveChanges() {
        guard let cal = Int(caloriesText), cal > 0 else { return }
        let name = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let protein = Double(proteinText) ?? currentItem.result.protein
        let carbs = Double(carbsText) ?? currentItem.result.carbs
        let fat = Double(fatsText) ?? currentItem.result.fat

        isSaving = true
        Task {
            await viewModel.updateHistoryItem(currentItem, foodName: name, calories: cal, protein: protein, carbs: carbs, fat: fat)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditMealView(
            item: NutritionHistoryItem(
                result: NutritionResult(
                    foodName: "Avocado Toast & Egg",
                    calories: 340,
                    protein: 12,
                    carbs: 24,
                    fat: 22,
                    description: "Sourdough bread, egg, avocado"
                )
            ),
            viewModel: NutritionViewModel()
        )
    }
}

