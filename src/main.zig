const std = @import("std");
const TreeMap = @import("tree_map.zig").TreeMap;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    var la = std.heap.loggingAllocator(gpa.allocator());

    const allocator = la.allocator();

    var tree = TreeMap(i32, []const u8).init(allocator);
    defer tree.deinit();

    try tree.put(0, "que se yo");
    try tree.put(-1, "la pregunta es:");
    try tree.put(2, "sí señor!");
    try tree.put(-2, "a la izquierda");
    try tree.put(10, "a la derecha");
    try tree.put(9, "anteúlltimo");

    std.debug.print("\n --- TREE ---\n\n", .{});
    tree.print();
    std.debug.print("\n --- TREE ---\n\n", .{});

    std.debug.print("{d:>5}: \"{s}\"\n", .{ -1, tree.get(-1) orelse "null" });
    std.debug.print("{d:>5}: \"{s}\"\n", .{ 3, tree.get(3) orelse "null" });
    std.debug.print("\n", .{});

    _ = tree.remove(-1);

    std.debug.print("\n --- TREE ---\n\n", .{});
    tree.print();
    std.debug.print("\n --- TREE ---\n\n", .{});
}

test "simple test" {
    try std.testing.expectEqual(1, 1);
}
