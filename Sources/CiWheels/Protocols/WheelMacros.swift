//
//  WheelMacros.swift
//  WheelBuilder
//

import SwiftSyntaxMacros

@attached(member, names: arbitrary)
public macro WheelClass(build_target: BuildTarget? = nil) = #externalMacro(module: "WheelBuilderMacros", type: "WheelClassAttributes")

@attached(member, names: arbitrary)
public macro LibraryClass(build_target: BuildTarget? = nil) = #externalMacro(module: "WheelBuilderMacros", type: "WheelClassAttributes")
