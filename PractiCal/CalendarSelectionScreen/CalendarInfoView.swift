import SwiftUI

struct CalendarInfoView: View {
    @Environment(\.dismiss) private var dismiss
    let calendar: CalendarItem?
    @Binding var calendarColors: [String: Color]
    @State private var selectedCustomColor = Color.blue
    @State private var currentColor = Color.blue
    
    private let predefinedColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo,
        .purple, .pink, .brown, .gray, Color(.systemRed), Color(.systemOrange), Color(.systemYellow)
    ]
    
    private var currentCalendarColor: Color {
        guard let calendar = calendar else { return .blue }
        return calendarColors[calendar.id] ?? calendar.color
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Calendar Title with Color
                HStack(spacing: 12) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 24, height: 24)
                    Text(calendar?.name ?? "Calendar")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                .onAppear {
                    // Initialize colors
                    let initialColor = currentCalendarColor
                    selectedCustomColor = initialColor
                    currentColor = initialColor
                }
                
                // 8x2 Color Grid with Custom Picker
                VStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { col in
                            let index = row * 8 + col
                            
                            if index < predefinedColors.count {
                                ColorCircleButton(
                                    color: predefinedColors[index],
                                    isSelected: isColorSelected(predefinedColors[index]),
                                    onTap: { selectColor(predefinedColors[index]) }
                                )
                                .frame(maxWidth: .infinity)
                            } else if index == 15 {
                                // ColorPicker as last item
                                ColorPicker("", selection: $selectedCustomColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    .frame(maxWidth: .infinity)
                                    .onChange(of: selectedCustomColor) { _, newColor in
                                        selectColor(newColor)
                                    }
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .overlay(
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        )
        .presentationDetents([.medium])
        .presentationCornerRadius(16)
    }
    
    private func isColorSelected(_ color: Color) -> Bool {
        return currentCalendarColor == color
    }
    
    private func selectColor(_ color: Color) {
        guard let calendar = calendar else { return }
        
        // Create a new dictionary to trigger the binding setter
        var newColors = calendarColors
        newColors[calendar.id] = color
        calendarColors = newColors
        
        currentColor = color
    }
}

struct ColorCircleButton: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 2 : 0)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}