import Foundation

// MARK: - Mini test runner

@MainActor private var passed = 0
@MainActor private var failed = 0

@MainActor
func test(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        print("  ✅ \(name)")
        passed += 1
    } catch {
        print("  ❌ \(name): \(error)")
        failed += 1
    }
}

func expect(_ condition: Bool, _ message: String = "assertion failed") throws {
    guard condition else { throw TestError(message) }
}

func expectNil<T>(_ value: T?, _ message: String = "expected nil") throws {
    guard value == nil else { throw TestError(message + " (got \(value!))") }
}

func expectNotNil<T>(_ value: T?, _ message: String = "expected non-nil") throws -> T {
    guard let v = value else { throw TestError(message) }
    return v
}

struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ msg: String) { description = msg }
}

@MainActor
func suite(_ name: String, _ body: () -> Void) {
    print("\n\(name)")
    body()
}

@MainActor
func results() {
    print("\n─────────────────────")
    print("Passed: \(passed)  Failed: \(failed)")
    if failed > 0 { exit(1) }
}
