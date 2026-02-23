import SwiftSyntax
import SwiftSyntaxMacros

enum LogLensMacroError: Error, CustomStringConvertible {
    case unsupportedArguments
    
    var description: String {
        "Unsupported #loglens arguments."
    }
}

public struct LogLensMacro: ExpressionMacro {
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
        
        let categorySource = categoryExpression?.trimmedDescription
            ?? "LogLens.defaultCategory(fromFilePath: \(callSiteFile))"
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
