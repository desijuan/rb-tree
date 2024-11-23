const std = @import("std");
const utils = @import("utils.zig");
const BinaryTreeNode = @import("binary_tree_node.zig").BinaryTreeNode;

pub fn ImmutableTreeMap(Key: type, Value: type, comptime compare: fn (Key, Key) i2) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        const Node = BinaryTreeNode(Key, Value, compare);

        allocator: std.mem.Allocator,
        root: ?*Node,

        const Map = @This();

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
            if (self.root) |root| {
                try root.insertKeyValue(self.allocator, key, value);
            } else {
                self.root = try Node.createNode(self.allocator, key, value);
            }
        }

        pub fn get(self: Map, key: Key) ?Value {
            return if (self.root) |root| root.get(key) else null;
        }

        pub fn contains(self: Map, key: Key) bool {
            return if (self.root) |root| root.contains(key) else false;
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
