import SwiftUI

// Note: L function is defined in SettingsView.swift

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @State private var searchText = ""
    @State private var selectedLanguageForConfirmation: SupportedLanguage?
    @State private var showConfirmationDialog = false
    
    private var filteredLanguages: [SupportedLanguage] {
        let allLanguages = SupportedLanguage.allCases
        
        if searchText.isEmpty {
            return allLanguages
        }
        
        return allLanguages.filter { language in
            language.displayName.localizedCaseInsensitiveContains(searchText) ||
            language.nativeName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField(L("search_languages"), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(L("clear")) {
                            searchText = ""
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                List {
                    // System Default at the top
                    if searchText.isEmpty || 
                       SupportedLanguage.systemDefault.displayName.localizedCaseInsensitiveContains(searchText) {
                        LanguageRow(
                            language: .systemDefault,
                            isSelected: languageManager.selectedLanguage == .systemDefault,
                            onSelect: {
                                selectedLanguageForConfirmation = .systemDefault
                                showConfirmationDialog = true
                            }
                        )
                        .listRowBackground(Color(.systemGray6).opacity(0.5))
                    }
                    
                    // All other languages
                    ForEach(filteredLanguages.filter { $0 != .systemDefault }) { language in
                        LanguageRow(
                            language: language,
                            isSelected: languageManager.selectedLanguage == language,
                            onSelect: {
                                selectedLanguageForConfirmation = language
                                showConfirmationDialog = true
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(L("language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
            .actionSheet(isPresented: $showConfirmationDialog) {
                ActionSheet(
                    title: Text(L("change_language")),
                    message: Text(selectedLanguageForConfirmation != nil ? 
                        L("change_language_message").replacingOccurrences(of: "{language}", with: selectedLanguageForConfirmation!.displayName) : 
                        ""),
                    buttons: [
                        .default(Text(L("change"))) {
                            if let selectedLanguage = selectedLanguageForConfirmation {
                                languageManager.setLanguage(selectedLanguage)
                                dismiss()
                            }
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if language != .systemDefault {
                        Text(language.nativeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject(LanguageManager())
}