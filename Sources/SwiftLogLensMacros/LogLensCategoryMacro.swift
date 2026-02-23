import SwiftSyntax
import SwiftSyntaxMacros

enum LogLensCategoryMacroError: Error, CustomStringConvertible {
    case missingCategoryArgument
    
    var description: String {
        "@LoglensCategrory requires one LogCategory argument, e.g. @LoglensCategrory(Logs.networkUtil)."
    }
}

public struct LogLensCategoryMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        _ = declaration
        _ = context
        
        guard
            let arguments = node.arguments,
            case let .argumentList(argumentList) = arguments,
            let firstArgument = argumentList.first
        else {
            throw LogLensCategoryMacroError.missingCategoryArgument
        }
        
        let categoryExpressionSource = firstArgument.expression.trimmedDescription
        let member = """
        public static var __loglensDeclaredCategory: String {
            (\(categoryExpressionSource)).rawValue
        }
        """
        
        return [DeclSyntax(stringLiteral: member)]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        _ = node
        _ = declaration
        _ = protocols
        _ = context
        
        let extensionSource = "extension \(type.trimmedDescription): LogLensCategoryProviding {}"
        guard let extensionDecl = DeclSyntax(stringLiteral: extensionSource).as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
}
