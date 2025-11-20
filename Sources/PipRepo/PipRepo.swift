//
//  PipRepo.swift
//  WheelBuilder
//
import PathKit
import Algorithms



public class RepoFolder {
    public let root: Path
    public var folders: [WheelFolder] = []
    
    public init(root: Path) throws {
        self.root = root
        let whls = try root.children().filter(\.whl_or_gz).sorted()
        
        let groups = whls.chunked(on: \.whl_name)
        for group in groups {
            print(group)
        }
        folders = groups.map({ (name, wheels) in
            .init(
                name: name,
                wheels: .init(wheels)
            )
        })
    }
    
    private var html_elements: String {
        folders.map(\.html_element).joined(separator: "\n")
    }
    
    func html() -> String {
        return """
        <!DOCTYPE html><html><body>
        \(html_elements)
        </body></html>
        """
    }
    
    public func generate_simple(output: Path) throws {
        let simple = output + "simple"
        
        if !simple.exists {
            try simple.mkpath()
        }
        
        try (simple + "index.html").write(html())
        
        for wheel in folders {
            try wheel.generate_index(output: simple)
        }
    }
    
    
}


public class WheelFolder {
    public let name: String
    public let wheels: [Path]
    
    init(name: String, wheels: [Path]) {
        self.name = name
        self.wheels = wheels
    }
    
    var html_element: String {
        "<a href=\"\(name)/\">\(name)</a></br>"
    }
    
    private var html_elements: String {
        wheels
            .map(\.html_whl_element)
            .joined(separator: "\n")
    }
    
    func html() -> String {
        return """
        <!DOCTYPE html><html><body>
        \(html_elements)
        </body></html>
        """
    }
    
    func generate_index(output: Path) throws {
        let root = output + name
        let index = root + "index.html"
        if !root.exists {
            try root.mkpath()
        }
        
        try index.write(html())
        
    }
}

extension Path {
    var html_whl_element: String {
        let fn = lastComponent
        return "<a href=\"../../\(fn)\">\(fn)</a></br>"
    }
    
    var is_whl: Bool { self.extension == "whl" }
    var is_gz: Bool { self.extension == "gz" }
    
    var whl_or_gz: Bool {
        is_whl || is_gz
    }
    
    var whl_name: String {
        lastComponent.split(whereSeparator: {$0 == "-"}).first!.lowercased()
    }
}
