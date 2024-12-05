const std = @import("std");
const utils = @import("utils.zig");
const RBTreeNode = @import("rb_tree_node.zig").RBTreeNode;

pub fn TreeMap(
    comptime Key: type,
    comptime Value: type,
    comptime compare: fn (Key, Key) i2,
) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);
    const Node = RBTreeNode(Key, Value, compare);

    return struct {
        const Map = @This();

        root: ?*const Node,

        pub fn init(allocator: std.mem.Allocator) Map {
            Node.mem.pool = std.heap.MemoryPool(Node).init(allocator);

            if (comptime utils.containsDeclaration(Node.mem, "arena")) {
                Node.mem.arena = std.heap.ArenaAllocator.init(allocator);
                Node.mem.arena_allocator = Node.mem.arena.allocator();
            }

            return Map{
                .root = null,
            };
        }

        pub fn deinit() void {
            if (comptime utils.containsDeclaration(Node.mem, "arena")) {
                Node.mem.arena.deinit();
            }
            Node.mem.pool.deinit();
        }

        pub fn put(self: Map, key: Key, value: Value) Map {
            const root: *const Node = self.root orelse return Map{
                .root = Node.createNode(key, value, .Black, null, null),
            };

            const newRoot: *const Node = root.insert(key, value).setColor(.Black);

            return if (root == newRoot) self else Map{ .root = newRoot };
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

        pub fn toGraphViz(self: Map, allocator: std.mem.Allocator) error{OutOfMemory}![]const u8 {
            var array_list = try std.ArrayList(u8).initCapacity(allocator, 4 * 1024);
            errdefer array_list.deinit();

            const writer = array_list.writer();

            try writer.writeAll(
                \\digraph g {
                \\node [shape=box, penwidth=2]
                \\
            );

            if (self.root) |root| try root.toGraphViz(writer);

            try writer.writeAll(
                \\}
                \\
            );

            return array_list.toOwnedSlice();
        }
    };
}
