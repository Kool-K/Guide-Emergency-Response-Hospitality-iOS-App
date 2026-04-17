import re

with open('Sources/Guide/ManagerDashboardView.swift', 'r') as f:
    content = f.read()

# Add PhotosUI import
content = re.sub(
    r'(import MapKit\n)',
    r'\1import PhotosUI\n',
    content
)

# Add blueprintItem state
content = re.sub(
    r'(@State private var toastData: ToastData\?\n)',
    r'\1    @State private var blueprintItem: PhotosPickerItem? = nil\n',
    content
)

# Remove Map section
content = re.sub(
    r'\s*// Map section\n\s*ZStack.*?// Action cards',
    '\n                    // Action cards',
    content, flags=re.DOTALL
)

# Replace Active Users button with Update Blueprint & Open Maps
open_maps_manager_button = '''                            // Update Blueprint
                            PhotosPicker(selection: $blueprintItem, matching: .images) {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.primaryAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Update Blueprint")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Upload evacuation map for guests")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Open Context Maps
                            Button(action: {
                                if let url = URL(string: "maps://") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "location.viewfinder")
                                        .font(.title3)
                                        .foregroundColor(Theme.info)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Open Maps")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("View local geographic maps")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }'''

content = re.sub(
    r'\s*// Active Users.*?liquidGlass\(cornerRadius: 16\)\n\s*\}',
    '\n' + open_maps_manager_button,
    content, flags=re.DOTALL
)

# We must also handle the onChange of blueprintItem
on_change_modifier = '''        .toast($toastData)
        .onChange(of: blueprintItem) { newItem in
            Task {
                guard let newItem = newItem else { return }
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        let base64 = data.base64EncodedString()
                        try await SupabaseService.shared.uploadBlueprint(base64: base64)
                        DispatchQueue.main.async {
                            toastData = ToastData(message: "✓ Blueprint updated successfully", style: .success)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        toastData = ToastData(message: "✗ Failed to upload blueprint", style: .error)
                    }
                }
            }
        }
        .onAppear {'''

content = content.replace("        .toast($toastData)\n        .onAppear {", on_change_modifier)

with open('Sources/Guide/ManagerDashboardView.swift', 'w') as f:
    f.write(content)
