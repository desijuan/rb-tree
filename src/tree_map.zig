const std = @import("std");
const utils = @import("utils.zig");
const BinaryTreeNode = @import("binary_tree_node.zig").BinaryTreeNode;

pub fn TreeMap(Key: type, Value: type, comptime compare: fn (Key, Key) i2) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        const Node = BinaryTreeNode(Key, Value, compare);

        allocator: std.mem.Allocator,
        root: ?*Node,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .root = null,
            };
        }

        pub fn deinit(self: Self) void {
            if (self.root) |root| root.deinit(self.allocator);
        }

        pub fn contains(self: Self, key: Key) bool {
            return if (self.root) |root| root.contains(key) else false;
        }

        pub fn get(self: Self, key: Key) ?Value {
            return if (self.root) |root| root.get(key) else null;
        }

        pub fn put(self: *Self, key: Key, value: Value) !void {
            if (self.root) |root| {
                try root.insert(self.allocator, key, value);
            } else {
                self.root = try Node.newLeaf(
                    self.allocator,
                    key,
                    value,
                );
            }
        }

        pub fn remove(self: *Self, key: Key) bool {
            const root = self.root orelse return false;
            const node = root.delete(self.allocator, key) orelse return false;

            if (node.key == root.key)
                self.root = if (node.left) |leftNode|
                    leftNode
                else if (node.right) |rightNode|
                    rightNode
                else
                    null;

            if (Key == []const u8) self.allocator.free(node.key);
            if (Value == []const u8) self.allocator.free(node.value);
            self.allocator.destroy(node);

            return true;
        }

        pub fn print(self: Self) void {
            if (self.root) |root| root.print();
        }
    };
}
