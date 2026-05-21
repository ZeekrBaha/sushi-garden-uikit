import UIKit
import CoreText

enum FontLoader {
    /// Registers all bundled custom fonts. No-op if none are present yet.
    static func registerCustomFonts() {
        let exts = ["ttf", "otf"]
        for ext in exts {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
