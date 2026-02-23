import SwiftSyntax
import SwiftSyntaxMacros

enum LogLensMacroError: Error, CustomStringConvertible {
    case unsupportedArguments
    
    var description: String {
        "Unsupported #loglens arguments."
    }
}

public struct LogLensMacro: ExpressionMacro {
    private static let supportedCategoryAttributeNames: Set<String> = [
        "LoglensCategrory",
        "LoglensCategory",
    ]
    
    private static func isSupportedCategoryAttribute(_ attributeName: String) -> Bool {
        let trimmed = attributeName
        if supportedCategoryAttributeNames.contains(trimmed) {
            return true
        }
        
        if let baseName = trimmed.split(separator: ".").last {
            return supportedCategoryAttributeNames.contains(String(baseName))
        }
        
        return false
    }
    
    private static func categoryExpression(from attributes: AttributeListSyntax?) -> String? {
        guard let attributes else {
            return nil
        }
        
        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else {
                continue
            }
            
            guard isSupportedCategoryAttribute(attribute.attributeName.trimmedDescription) else {
                continue
            }
            
            guard
                let arguments = attribute.arguments,
                case let .argumentList(argumentList) = arguments,
                let firstArgument = argumentList.first
            else {
                continue
            }
            
            return "(\(firstArgument.expression.trimmedDescription)).rawValue"
        }
        
        return nil
    }
    
    private static func contextAnnotatedCategoryExpression(from lexicalContext: [Syntax]) -> String? {
        for node in lexicalContext {
            if let classDecl = node.as(ClassDeclSyntax.self),
               let categoryExpression = categoryExpression(from: classDecl.attributes) {
                return categoryExpression
            }
            if let actorDecl = node.as(ActorDeclSyntax.self),
               let categoryExpression = categoryExpression(from: actorDecl.attributes) {
                return categoryExpression
            }
            if let structDecl = node.as(StructDeclSyntax.self),
               let categoryExpression = categoryExpression(from: structDecl.attributes) {
                return categoryExpression
            }
            if let enumDecl = node.as(EnumDeclSyntax.self),
               let categoryExpression = categoryExpression(from: enumDecl.attributes) {
                return categoryExpression
            }
            if let extensionDecl = node.as(ExtensionDeclSyntax.self),
               let categoryExpression = categoryExpression(from: extensionDecl.attributes) {
                return categoryExpression
            }
        }
        
        return nil
    }
    
    private static func contextTypeCategory(from lexicalContext: [Syntax]) -> String? {
        for node in lexicalContext {
            if let classDecl = node.as(ClassDeclSyntax.self) {
                return classDecl.name.text
            }
            if let actorDecl = node.as(ActorDeclSyntax.self) {
                return actorDecl.name.text
            }
            if let structDecl = node.as(StructDeclSyntax.self) {
                return structDecl.name.text
            }
            if let enumDecl = node.as(EnumDeclSyntax.self) {
                return enumDecl.name.text
            }
            if let extensionDecl = node.as(ExtensionDeclSyntax.self) {
                return extensionDecl.extendedType.trimmedDescription
            }
        }
        return nil
    }
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        var unlabeledExpressions: [ExprSyntax] = []
        var categoryExpression: ExprSyntax?
        var privacyExpression: ExprSyntax?
        
        for argument in node.arguments {
            guard let label = argument.label?.text else {
                unlabeledExpressions.append(argument.expression)
                continue
            }
            
            switch label {
            case "category":
                categoryExpression = argument.expression
            case "privacy":
                privacyExpression = argument.expression
            default:
                throw LogLensMacroError.unsupportedArguments
            }
        }
        
        let levelExpression: ExprSyntax
        let messageExpression: ExprSyntax
        
        switch unlabeledExpressions.count {
        case 1:
            levelExpression = ExprSyntax(stringLiteral: ".default")
            messageExpression = unlabeledExpressions[0]
        case 2:
            levelExpression = unlabeledExpressions[0]
            messageExpression = unlabeledExpressions[1]
        default:
            throw LogLensMacroError.unsupportedArguments
        }
        
        let callSiteLocation = context.location(
            of: node,
            at: .afterLeadingTrivia,
            filePathMode: .filePath
        )
        let callSiteFile = callSiteLocation?.file.trimmedDescription ?? "#filePath"
        let callSiteLine = callSiteLocation?.line.trimmedDescription ?? "#line"
        let contextualCategorySource = contextAnnotatedCategoryExpression(from: context.lexicalContext)
            ?? contextTypeCategory(from: context.lexicalContext)
            .map { "\"\($0)\"" }
            ?? "LogLens.defaultCategory(fromFilePath: \(callSiteFile))"
        
        let categorySource = categoryExpression?.trimmedDescription
            ?? contextualCategorySource
        let levelSource = levelExpression.trimmedDescription
        let messageSource = messageExpression.trimmedDescription
        let privacySource = privacyExpression?.trimmedDescription ?? ".public"
        
        let expansion = """
        ({
            let __loglensCategory: String = \(categorySource)
            let __loglensLevel: OSLogType = \(levelSource)
            let __loglensMessage: String = \(messageSource)
            let __loglensLogger = LogLens.logger(forCategory: __loglensCategory)
            #sourceLocation(file: \(callSiteFile), line: \(callSiteLine))
            __loglensLogger.log(level: __loglensLevel, "\\(__loglensMessage, privacy: \(privacySource))")
            #sourceLocation()
            LogLens.persistIfConfigured(
                category: __loglensCategory,
                level: __loglensLevel,
                message: __loglensMessage
            )
        }())
        """
        
        return ExprSyntax(stringLiteral: expansion)
    }
}
