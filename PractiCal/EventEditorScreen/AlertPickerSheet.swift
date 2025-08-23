import SwiftUI

struct AlertPickerSheet: View {
    @Binding var selectedAlert: String
    @Environment(\.dismiss) private var dismiss
    
    private let alertOptions = [
        ("none", "None"),
        ("at_time_of_event", "At time of event"),
        ("5_min_before", "5 minutes before"),
        ("15_min_before", "15 minutes before"),
        ("30_min_before", "30 minutes before"),
        ("1_hour_before", "1 hour before"),
        ("1_day_before", "1 day before")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(alertOptions, id: \.0) { option in
                    Button(action: {
                        selectedAlert = option.0
                        dismiss()
                    }) {
                        HStack {
                            Text(L(option.0))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedAlert == option.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("alert"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}