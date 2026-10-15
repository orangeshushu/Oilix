import SwiftUI

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundColor(enabled ? .white : .secondary)
            .background(enabled ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SampleMetadataRow: View {
    let title: String
    let symbol: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.system(size: 18))
                .foregroundColor(.secondary).frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

struct SamplePreview: View {
    let image: UIImage

    var body: some View {
        Color(uiColor: .secondarySystemBackground)
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay(Image(uiImage: image).resizable().scaledToFit())
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
