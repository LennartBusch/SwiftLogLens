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
            
            if argumentList.count >= 2 {
                let secondArgumentIndex = argumentList.index(after: argumentList.startIndex)
                let secondArgument = argumentList[secondArgumentIndex]
                return "(\(secondArgument.expression.trimmedDescription)).rawValue"
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
    
    private static func contextTypeExpressionSource(from lexicalContext: [Syntax]) -> String? {
        for node in lexicalContext {
            if node.is(ClassDeclSyntax.self)
                || node.is(ActorDeclSyntax.self)
                || node.is(StructDeclSyntax.self)
                || node.is(EnumDeclSyntax.self)
                || node.is(ExtensionDeclSyntax.self)
            {
                return "Self.self"
            }
        }
        
        return nil
    }
    
    private static func hasPrivacyArgument(_ expressions: LabeledExprListSyntax) -> Bool {
        expressions.contains { labeledExpression in
            labeledExpression.label?.text == "privacy"
        }
    }
    
    private static func loggerMessageSource(
        from messageExpression: ExprSyntax,
        privacySource: String,
        fallbackMessageExpression: String
    ) -> String {
        guard let stringLiteral = messageExpression.as(StringLiteralExprSyntax.self) else {
            return "\"\\((\(fallbackMessageExpression)), privacy: \(privacySource))\""
        }
        
        var source = ""
        source += stringLiteral.openingPounds?.text ?? ""
        source += stringLiteral.openingQuote.text
        
        for segment in stringLiteral.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                source += stringSegment.content.text
                continue
            }
            
            guard let expressionSegment = segment.as(ExpressionSegmentSyntax.self) else {
                source += segment.description
                continue
            }
            
            let expressionsSource = expressionSegment.expressions.trimmedDescription
            let sourceWithPrivacy: String
            if hasPrivacyArgument(expressionSegment.expressions) {
                sourceWithPrivacy = expressionsSource
            } else if expressionsSource.isEmpty {
                sourceWithPrivacy = "privacy: \(privacySource)"
            } else {
                sourceWithPrivacy = "\(expressionsSource), privacy: \(privacySource)"
            }
            
            source += expressionSegment.backslash.text
            source += expressionSegment.pounds?.text ?? ""
            source += expressionSegment.leftParen.text
            source += sourceWithPrivacy
            source += expressionSegment.rightParen.text
        }
        
        source += stringLiteral.closingQuote.text
        source += stringLiteral.closingPounds?.text ?? ""
        return source
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
            ?? contextTypeExpressionSource(from: context.lexicalContext)
            .map { "LogLens.category(forContextType: \($0))" }
            ?? "LogLens.defaultCategory(fromFilePath: \(callSiteFile))"
        
        let categorySource = categoryExpression?.trimmedDescription
            ?? contextualCategorySource
        let levelSource = levelExpression.trimmedDescription
        let messageSource = messageExpression.trimmedDescription
        let privacySource = privacyExpression?.trimmedDescription ?? ".public"
        let loggerMessageForPersistPath = loggerMessageSource(
            from: messageExpression,
            privacySource: privacySource,
            fallbackMessageExpression: "__loglensMessage"
        )
        let loggerMessageForDirectPath = messageExpression.as(StringLiteralExprSyntax.self) == nil
            ? loggerMessageSource(
                from: messageExpression,
                privacySource: privacySource,
                fallbackMessageExpression: messageSource
            )
            : loggerMessageForPersistPath
        let expansion = """
        ({
            let __loglensCategory: String = \(categorySource)
            let __loglensLevel: OSLogType = \(levelSource)
            let __loglensLogger = LogLens.logger(forCategory: __loglensCategory)
            let __loglensShouldPersist = LogLens.shouldPersistLogs
            if __loglensShouldPersist {
                let __loglensMessage: String = \(messageSource)
                #sourceLocation(file: \(callSiteFile), line: \(callSiteLine))
                __loglensLogger.log(level: __loglensLevel, \(loggerMessageForPersistPath))
                #sourceLocation()
                LogLens.persistIfConfigured(
                    category: __loglensCategory,
                    level: __loglensLevel,
                    message: __loglensMessage
                )
            } else {
                #sourceLocation(file: \(callSiteFile), line: \(callSiteLine))
                __loglensLogger.log(level: __loglensLevel, \(loggerMessageForDirectPath))
                #sourceLocation()
            }
        }())
        """
        
        return ExprSyntax(stringLiteral: expansion)
    }
}
