const std = @import("std");

pub fn getFmtStr(T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .Int, .Float => "{}",
        .Pointer => if (T != []const u8)
            @compileError("Type " ++ @typeName(T) ++ " not supported")
        else
            "{s}",
        else => @compileError("Type " ++ @typeName(T) ++ " not supported"),
    };
}

pub fn errorIfNotNumberOrString(T: type) void {
    switch (@typeInfo(T)) {
        .Int, .Float => {},
        .Pointer => if (T != []const u8) @compileError("Type " ++ @typeName(T) ++ " not supported"),
        else => @compileError("Type " ++ @typeName(T) ++ " not supported"),
    }
}

pub fn containsDeclaration(T: type, declName: [:0]const u8) bool {
    const typeInfo: std.builtin.Type = @typeInfo(T);
    if (typeInfo != .Struct) @compileError("Struct expected!");

    for (typeInfo.Struct.decls) |decl|
        if (std.mem.eql(u8, declName, decl.name)) return true;

    return false;
}

const testing = std.testing;

test containsDeclaration {
    const T = struct {
        pub const a: u8 = 1;
        pub var b: u8 = 0;
    };

    try testing.expectEqual(true, containsDeclaration(T, "a"));
    try testing.expectEqual(true, containsDeclaration(T, "b"));
    try testing.expectEqual(false, containsDeclaration(T, "c"));
}
