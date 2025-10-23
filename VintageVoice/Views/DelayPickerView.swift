//
//  DelayPickerView.swift
//  VintageVoice
//
//  Delay preset picker with stamp tier visualization
//

import SwiftUI

struct DelayPickerView: View {
    @Binding var selectedDelay: DelayPreset
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.vintageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header info
                        VStack(spacing: 8) {
                            Text("Choose Arrival Time")
                                .font(.vintageHeadline)
                                .foregroundColor(.vintageInk)

                            Text("Longer delays earn higher tier stamps")
                                .font(.vintageCaption)
                                .foregroundColor(.vintageBrown)
                        }
                        .padding()

                        // Delay options
                        ForEach(DelayPreset.allCases) { preset in
                            DelayOptionRow(
                                preset: preset,
                                isSelected: selectedDelay == preset
                            ) {
                                selectedDelay = preset
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.vintageInk)
                }
            }
        }
    }
}

struct DelayOptionRow: View {
    let preset: DelayPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Stamp preview
                Circle()
                    .fill(preset.stampTier.color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack(spacing: 2) {
                            Text(preset.stampTier.displayName)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(preset.stampTier.postagePoints)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.displayName)
                        .font(.vintageBody)
                        .foregroundColor(.vintageInk)

                    Text("Arrives: \(formatDeliveryDate(for: preset))")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(
                isSelected ? Color.vintageParchment : Color.white
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.vintageAccent : Color.vintageBrown.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }

    private func formatDeliveryDate(for preset: DelayPreset) -> String {
        let date = preset.deliveryDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DelayPickerView(selectedDelay: .constant(.oneDay))
}
