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
