import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftLogLensPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LogLensMacro.self,
        LogLensCategoryMacro.self,
    ]
}
