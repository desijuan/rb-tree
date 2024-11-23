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

    var map = ImmutableTreeMap(i32, []const u8, compare).init(allocator);
    defer map.deinit();

    try map.put(0, "a");
    try map.put(-50, "b");
    try map.put(20, "c");
    try map.put(-10, "d");
    try map.put(10, "e");
    try map.put(-100, "f");
    try map.put(-1000, "g");
    try map.put(100, "h");
    try map.put(15, "i");
    try map.put(-30, "j");

    const graph_viz = try map.toGraphViz();
    defer allocator.free(graph_viz);

    std.debug.print("\n{s}\n", .{graph_viz});
}
