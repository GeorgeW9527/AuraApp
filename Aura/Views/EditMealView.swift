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
    @State private var selectedMacro: String? = nil

    // Colors matching edit meal.png
    private let pageBackground = Color(red: 0.97, green: 0.98, blue: 0.96)
    private let panelBackground = Color.white
    private let fieldBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
    private let lime = Color(red: 0.84, green: 0.91, blue: 0.34)
    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let labelColor = Color(red: 0.62, green: 0.67, blue: 0.75)

    private var currentItem: NutritionHistoryItem {
        viewModel.history.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                mealImageSection
                mealDetailsSection
                nutritionalBreakdownSection
                ingredientsSection
                Spacer(minLength: 40)
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        .navigationTitle("Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.auraGrayDark)
                }
            }
        }
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
            .frame(height: 200)
            .clipped()

            // AI Analysis badge
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                Text("AI ANALYSIS ORIGINAL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(fieldBackground)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(labelColor)
            )
    }

    // MARK: - Meal Details

    private var mealDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Meal Name
            VStack(alignment: .leading, spacing: 6) {
                Text("MEAL NAME")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(labelColor)

                TextField("", text: $mealName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .cornerRadius(12)
            }

            // Calories
            VStack(alignment: .leading, spacing: 6) {
                Text("CALORIES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(labelColor)

                HStack {
                    TextField("0", text: $caloriesText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(deepGreen)

                    Spacer()

                    Text("kcal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(labelColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(fieldBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Nutritional Breakdown

    private var nutritionalBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NUTRITIONAL BREAKDOWN")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(labelColor)

            HStack(spacing: 10) {
                macroCard(title: "PROTEIN", value: $proteinText)
                macroCard(title: "CARBS", value: $carbsText)
                macroCard(title: "FATS", value: $fatsText)
            }
        }
    }

    private func macroCard(title: String, value: Binding<String>) -> some View {
        let isHighlighted = selectedMacro == title
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedMacro == title {
                    selectedMacro = nil
                } else {
                    selectedMacro = title
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isHighlighted ? deepGreen : labelColor)

                TextField("0", text: value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))

                HStack {
                    Spacer()
                    Text("g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(labelColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isHighlighted ? lime : fieldBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INGREDIENTS DETECTED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(labelColor)

                Spacer()

                Button {
                    newIngredientName = ""
                    newIngredientQty = ""
                    showingAddIngredient = true
                } label: {
                    Text("ADD INGREDIENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(deepGreen)
                }
            }

            if ingredients.isEmpty {
                Text("No ingredients detected. Tap ADD INGREDIENT to add manually.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(labelColor)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(fieldBackground)
                    .cornerRadius(12)
            }

            ForEach(Array(ingredients.enumerated()), id: \.element.id) { idx, _ in
                HStack(spacing: 10) {
                    Circle()
                        .fill(deepGreen)
                        .frame(width: 6, height: 6)

                    TextField("Ingredient", text: $ingredients[idx].name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.20, green: 0.23, blue: 0.28))

                    Spacer()

                    TextField("Qty", text: $ingredients[idx].quantity)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(labelColor)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.90, green: 0.93, blue: 0.96), lineWidth: 1)
                )
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
                    .foregroundColor(deepGreen)
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(deepGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(lime)
                .cornerRadius(12)
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
