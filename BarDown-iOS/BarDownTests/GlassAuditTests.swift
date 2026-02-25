import Testing
import Foundation

@Suite("Glass Usage Audit")
struct GlassAuditTests {

    @Test("No .glassEffect() calls exist in feature code outside GlassKit")
    func noGlassEffectLeaks() throws {
        let featureDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // BarDownTests/
            .deletingLastPathComponent() // BarDown-iOS/
            .appendingPathComponent("BarDown") // BarDown-iOS/BarDown/

        guard FileManager.default.fileExists(atPath: featureDir.path) else {
            Issue.record("Feature source directory not found at \(featureDir.path)")
            return
        }

        let enumerator = FileManager.default.enumerator(
            at: featureDir,
            includingPropertiesForKeys: nil
        )

        var violations: [String] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }

            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)

            for (index, line) in lines.enumerated() {
                if line.contains(".glassEffect") {
                    violations.append("\(fileURL.lastPathComponent):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }
        }

        #expect(violations.isEmpty, "Found .glassEffect() outside GlassKit:\n\(violations.joined(separator: "\n"))")
    }
}
