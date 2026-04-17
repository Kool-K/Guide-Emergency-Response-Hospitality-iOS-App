import re

with open('Sources/Guide/ManagerDashboardView.swift', 'r') as f:
    content = f.read()

# Remove state variables
content = re.sub(r'\s*@State private var activeUsers: \[User\] = \[\]\n', '\n', content)
content = re.sub(r'\s*@State private var showingUsersList = false\n', '\n', content)

# Remove the sheet assignment
content = re.sub(
    r'\s*\.sheet\(isPresented: \$showingUsersList\) \{\s*usersSheet\s*\}\n',
    '\n',
    content
)

# Remove the usersSheet
content = re.sub(
    r'\s*// MARK: - Users Sheet.*?// MARK: - Issues Sheet',
    '\n    // MARK: - Issues Sheet',
    content, flags=re.DOTALL
)

# Remove the activeUsers assign inside fetchData
content = re.sub(r'\s*async let fetchedUsers = try\? SupabaseService\.shared\.fetchActiveUsers\(\)\n', '\n', content)
content = re.sub(r', fetchedUsers', '', content)
content = re.sub(
    r'\s*if let users = results\.3 \{\s*self\.activeUsers = users\s*\}\n',
    '\n',
    content
)

# Remove the fetchActiveUsers function
content = re.sub(
    r'\s*private func fetchActiveUsers\(\) \{.*?\n    \}\n',
    '\n',
    content, flags=re.DOTALL
)

# Also remove 'signals' state variable and MKCoordinateRegion since map is removed from Top?
# User requested to remove the Map shown on top of the page.
content = re.sub(r'\s*@State private var region = MKCoordinateRegion\([^)]*\)\n', '\n', content)
# Keep signals if they are used elsewhere, wait, signals are only used in map.
content = re.sub(r'\s*@State private var signals: \[DistressSignal\] = \[\]\n', '\n', content)
content = re.sub(r'\s*async let fetchedSignals = try\? SupabaseService\.shared\.client\.from\("distress_signals"\)\.select\(\)\.eq\("status", value: "active"\)\.execute\(\)\.value as \[DistressSignal\]\n', '\n', content)
content = re.sub(r'fetchedSignals, ', '', content)
content = re.sub(
    r'\s*if let signals = results\.0 \{\s*self\.signals = signals\s*if let first = signals\.first \{\s*self\.region\.center = CLLocationCoordinate2D\(latitude: first\.latitude, longitude: first\.longitude\)\s*\}\s*\}\n',
    '\n',
    content
)

with open('Sources/Guide/ManagerDashboardView.swift', 'w') as f:
    f.write(content)
