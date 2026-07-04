import CoreText
import Foundation

// MARK: - PorteosFontLoader
// Bundles JetBrains Mono so SwiftUI never falls back to system mono / synthetic weights.

enum PorteosFontLoader {

    private static let files = [
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
        "JetBrainsMono-SemiBold",
        "JetBrainsMono-Bold",
    ]

    static func registerBundledFonts() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                    ?? Bundle.main.url(forResource: name, withExtension: "ttf") else {
                #if DEBUG
                print("[PorteosFontLoader] Missing font file: \(name).ttf")
                #endif
                continue
            }
            var error: Unmanaged<CFError>?
            let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            #if DEBUG
            if !ok, let err = error?.takeRetainedValue() {
                print("[PorteosFontLoader] Register failed \(name): \(err)")
            }
            #endif
        }
    }
}
