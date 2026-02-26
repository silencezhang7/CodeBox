import SwiftUI

struct ModelRowView: View {
    let model: AIModel
    let isActive: Bool

    @State private var testState: TestState = .idle

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .green : Color(.systemGray4))
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    Text(model.provider)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(4)
                        .foregroundColor(.blue)
                    Text(model.modelId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            testButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var testButton: some View {
        switch testState {
        case .idle:
            Button {
                runTest()
            } label: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .padding(7)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

        case .testing:
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 30, height: 30)

        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
                .onAppear { resetAfterDelay() }

        case .failure(let msg):
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
                .help(msg)
                .onAppear { resetAfterDelay() }
        }
    }

    @MainActor
    private func runTest() {
        testState = .testing
        let apiKey = model.apiKey
        let baseURL = model.baseURL
        let provider = model.provider
        Task {
            let result = await ModelTestService.test(apiKey: apiKey, baseURL: baseURL, provider: provider)
            await MainActor.run { testState = result }
        }
    }

    @MainActor
    private func resetAfterDelay() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            testState = .idle
        }
    }
}
