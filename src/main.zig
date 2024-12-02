const std = @import("std");
const TreeMap = @import("rb_tree_map.zig").TreeMap;

const gv_file = "g.gv";
const png_file = "g.png";

fn compare(n1: i32, n2: i32) i2 {
    return if (n1 == n2) 0 else if (n1 < n2) -1 else 1;
}

const Map = TreeMap(i32, []const u8, compare);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var map = Map.init(allocator);
    defer Map.deinit();

    const graph_viz = try map
        .put(0, "a")
        .put(-50, "b")
        .put(20, "c")
        .put(-10, "d")
        .put(10, "e")
        .put(-100, "f")
        .put(-1000, "g")
        .put(100, "h")
        .put(15, "i")
        .put(-30, "j")
        .put(45, "k")
        .put(-150, "l")
        .toGraphViz(allocator);

    defer allocator.free(graph_viz);

    const output_file = try std.fs.cwd().createFile(gv_file, .{});
    defer output_file.close();

    var file_bw = std.io.bufferedWriter(output_file.writer());
    const writer = file_bw.writer();

    try writer.writeAll(graph_viz);
    try file_bw.flush();

    const runResult = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "dot", "-Tpng", "-o", png_file, gv_file,
        },
    });
    defer {
        allocator.free(runResult.stdout);
        allocator.free(runResult.stderr);
    }

    switch (runResult.term) {
        .Exited => |exitCode| if (exitCode != 0) return error.ChildProcessError,
        else => return error.ChildProcessError,
    }
}
