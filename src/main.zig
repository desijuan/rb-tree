const std = @import("std");
const ImmutableTreeMap = @import("tree_map.zig").ImmutableTreeMap;

fn compare(n1: i32, n2: i32) i2 {
    return if (n1 == n2) 0 else if (n1 < n2) -1 else 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    var la = std.heap.loggingAllocator(gpa.allocator());

    const allocator = la.allocator();

    var tree = ImmutableTreeMap(i32, []const u8, compare).init(allocator);
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

    const graph_viz = try tree.toGraphViz();
    defer allocator.free(graph_viz);

    std.debug.print("{s}\n\n", .{graph_viz});
}
