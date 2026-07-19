import SwiftUI

struct SourcesView: View {
    @StateObject private var pluginManager = PluginManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text("Available Sources")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(pluginManager.availableSources) { source in
                                SourceRow(source: source, isInstalled: isInstalled(source: source))
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Installed Plugins")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 32)
                        
                        if pluginManager.installedPlugins.isEmpty {
                            Text("No plugins installed yet. Install a source above to populate your home feed.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(pluginManager.installedPlugins) { plugin in
                                    InstalledSourceRow(plugin: plugin)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sources")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func isInstalled(source: PluginConfig) -> Bool {
        pluginManager.installedPlugins.contains(where: { $0.id == source.id })
    }
}

struct SourceRow: View {
    let source: PluginConfig
    let isInstalled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(white: 0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(source.name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("v\(source.version, specifier: "%.1f") • \(source.author)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                if !isInstalled {
                    PluginManager.shared.installPlugin(source: source)
                }
            }) {
                Text(isInstalled ? "Installed" : "Install")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isInstalled ? .gray : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isInstalled ? Color(white: 0.15) : Color.white)
                    .cornerRadius(20)
            }
            .disabled(isInstalled)
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(12)
    }
}

struct InstalledSourceRow: View {
    let plugin: PluginConfig
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(plugin.name.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(plugin.name)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(white: 0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
