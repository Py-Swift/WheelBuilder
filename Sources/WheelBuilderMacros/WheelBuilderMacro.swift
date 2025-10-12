import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros



public struct WheelClassAttributes: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        
        
        switch declaration.kind {
        case .classDecl:
            let classDecl = declaration.cast(ClassDeclSyntax.self)
            
            let cls_name = classDecl.name.text
            
            let result: ExprSyntax? = switch node.arguments {
            case .argumentList(let exprlist):
                exprlist.first?.expression
            default: nil
            }
            
            let build_target: DeclSyntax = switch node.attributeName.description {
            case "WheelClass":
                if let result {
                    "public let build_target: BuildTarget = \(raw: result)"
                } else {
                    "public let build_target: BuildTarget = .pypi(\(raw: cls_name).name)"
                }
            default:
                ""
            }
            
            
            return [
                "public static let name: String = \(literal: cls_name.lowercased())",
                "public var version: String?",
                build_target,
                "public var platform: any PlatformProtocol",
                "public var root: Path",
                """
                public init(version: String? = nil, platform: any PlatformProtocol, root: Path) {
                    self.version = version
                    self.platform = platform
                    self.root = root
                }
                """,
            ]
        default:
            break
        }
        
        return []
    }
}


@main
struct WheelBuilderPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WheelClassAttributes.self
    ]
}
