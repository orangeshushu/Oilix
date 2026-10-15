import SwiftUI

struct NoteView: View {
    @ObservedObject var samples: WaterSampleViewModel
    @Binding var i: Int
    @Binding var noteSheet: Bool
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        OilixNavigation {
            Form {
                Section(header: Text("Sample note")) {
                    TextEditor(text: $draft)
                        .frame(minHeight: 180)
                        .focused($focused)
                        .accessibilityLabel("Sample note")
                        .accessibilityIdentifier("note.editor")
                }
            }
            .oilixKeyboardDismissal()
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }.accessibilityIdentifier("note.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { noteSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard samples.samples.indices.contains(i) else { return }
                        samples.samples[i].note = draft
                        noteSheet = false
                    }
                    .accessibilityIdentifier("note.save")
                }
            }
        }
        .onAppear {
            if samples.samples.indices.contains(i) { draft = samples.samples[i].note }
            focused = true
        }
        .interactiveDismissDisabled()
    }
}
