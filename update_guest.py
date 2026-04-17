import re

with open('Sources/Guide/GuestDashboardView.swift', 'r') as f:
    content = f.read()

# Add states
content = re.sub(
    r'(@State private var toastData: ToastData\?\n)',
    r'\1    @State private var showingBlueprint = false\n    @State private var blueprintBase64: String? = nil\n',
    content
)

# Add buttons
new_buttons = '''            // View Hotel Blueprint
            Button(action: { showingBlueprint = true }) {
                HStack {
                    Label("View Hotel Blueprint", systemImage: "map.fill")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Open Context Maps
            Button(action: {
                if let url = URL(string: "maps://") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Open Maps", systemImage: "location.viewfinder")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Smart Assistant'''

content = re.sub(
    r'\s*// Smart Assistant',
    '\n' + new_buttons,
    content
)

# Add blueprintSheet definition
blueprint_sheet_def = '''    // MARK: - Blueprint Sheet
    
    // MARK: - Blueprint Sheet (Updated)
    private var blueprintSheet: some View {
        NavigationView {
            Group {
                if let base64 = blueprintBase64,
                   let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    // REMOVED ScrollView here to prevent gesture conflicts
                    ZoomableImageView(uiImage: uiImage)
                        .background(Color.black.opacity(0.05))
                } else {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading Blueprint...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Hotel Blueprint")
            .navigationBarItems(trailing: Button("Done") { showingBlueprint = false })
        }
    }
'''

content = re.sub(
    r'\s*// MARK: - Inbox Sheet',
    '\n' + blueprint_sheet_def + '\n    // MARK: - Inbox Sheet',
    content
)

# Add sheet attachment
content = re.sub(
    r'\s*\.sheet\(isPresented: \$showingInbox\)',
    '''
            .sheet(isPresented: $showingBlueprint) {
                blueprintSheet
            }
            .sheet(isPresented: $showingInbox)''',
    content
)

with open('Sources/Guide/GuestDashboardView.swift', 'w') as f:
    f.write(content)

