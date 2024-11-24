const std = @import("std");
const utils = @import("utils.zig");

pub fn ImmutableTreeMap(
    comptime Key: type,
    comptime Value: type,
    comptime compare: fn (Key, Key) i2,
    comptime NodeType: fn (type, type, comptime fn (anytype, anytype) i2) type,
) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);
    const Node = NodeType(Key, Value, compare);

    return struct {
        const Map = @This();

        allocator: std.mem.Allocator,
        root: ?*Node,

        pub fn init(allocator: std.mem.Allocator) Map {
            return Map{
                .allocator = allocator,
                .root = null,
            };
        }

        pub fn deinit(self: Map) void {
            if (self.root) |root| root.deinit(self.allocator);
        }

        pub fn put(self: *Map, key: Key, value: Value) !void {
            if (self.root) |root|
                try root.insertKeyValue(self.allocator, key, value)
            else
                self.root = try Node.createNode(self.allocator, key, value);
        }

        pub fn get(self: Map, key: Key) ?Value {
            var currentNode: ?*const Node = self.root;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return node.value,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return null;
        }

        pub fn contains(self: Map, key: Key) bool {
            var currentNode: ?*const Node = self.root;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return true,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return false;
        }

        pub fn isEmpty(self: Map) bool {
            return self.root == null;
        }

        pub fn toGraphViz(self: Map) error{OutOfMemory}![]const u8 {
            var array_list = try std.ArrayList(u8).initCapacity(self.allocator, 4 * 1024);
            errdefer array_list.deinit();

            const writer = array_list.writer();

            try writer.writeAll(
                \\digraph g {
                \\    node [shape=box]
                \\
            );

            if (self.root) |root| try root.toGraphViz(writer);

            try writer.writeAll(
                \\}
                \\
            );

            return array_list.toOwnedSlice();
        }

        pub fn print(self: Map) void {
            if (self.root) |root| root.print();
        }
    };
}
