import SwiftUI

/// Temporary placeholder for screens not yet implemented. Each screen stub uses
/// this so the app compiles and navigates while the real UI is built out per
/// the SPEC.md checklist. Delete usages as screens are completed.
struct ScaffoldPlaceholder: View {
    let title: String
    let specNote: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.nnTint)
            Text(title)
                .font(.title2.bold())
            Text(specNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
