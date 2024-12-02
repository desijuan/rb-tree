const std = @import("std");
const utils = @import("utils.zig");

const Color = enum(u1) {
    Black = 0,
    Red = 1,

    fn flip(self: Color) Color {
        return switch (self) {
            .Black => .Red,
            .Red => .Black,
        };
    }

    fn toStr(self: Color) []const u8 {
        return switch (self) {
            .Black => "black",
            .Red => "red",
        };
    }
};

pub fn RBTreeNode(
    comptime Key: type,
    comptime Value: type,
    comptime compare: fn (Key, Key) i2,
) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        pub var arena_allocator: std.mem.Allocator = undefined;
        pub var mem_pool: std.heap.MemoryPool(Node) = undefined;

        const Node = @This();

        key: Key,
        value: Value,
        color: Color,
        left: ?*const Node,
        right: ?*const Node,

        fn isBlack(node: ?*const Node) bool {
            return if (node) |self| (self.color == .Black) else true;
        }

        fn isRed(node: ?*const Node) bool {
            return if (node) |self| (self.color == .Red) else false;
        }

        pub fn createNode(
            key: Key,
            value: Value,
            color: Color,
            left: ?*const Node,
            right: ?*const Node,
        ) *const Node {
            const newNode: *Node = mem_pool.create() catch @panic("OOM");

            const key_copy: Key = if (Key == []const u8) blk: {
                const key_copy = arena_allocator.alloc(u8, key.len) catch @panic("OOM");
                @memcpy(key_copy, key);
                break :blk key_copy;
            } else key;

            const value_copy: Value = if (Value == []const u8) blk: {
                const value_copy = arena_allocator.alloc(u8, value.len) catch @panic("OOM");
                @memcpy(value_copy, value);
                break :blk value_copy;
            } else value;

            newNode.* = Node{
                .key = key_copy,
                .value = value_copy,
                .color = color,
                .left = left,
                .right = right,
            };

            return newNode;
        }

        pub fn destroy(self: *Node) void {
            if (Key == []const u8) arena_allocator.free(self.key);
            if (Value == []const u8) arena_allocator.free(self.value);
            mem_pool.destroy(self);
        }

        fn invertColor(self: *const Node) *const Node {
            return createNode(self.key, self.value, self.color.flip(), self.left, self.right);
        }

        fn setLeft(self: *const Node, node: *const Node) *const Node {
            return createNode(self.key, self.value, self.color, node, self.right);
        }

        fn setRight(self: *const Node, node: *const Node) *const Node {
            return createNode(self.key, self.value, self.color, self.left, node);
        }

        fn setLeftAndColor(self: *const Node, maybeNode: ?*const Node, color: Color) *const Node {
            return createNode(self.key, self.value, color, maybeNode, self.right);
        }

        fn setRightAndColor(self: *const Node, maybeNode: ?*const Node, color: Color) *const Node {
            return createNode(self.key, self.value, color, self.left, maybeNode);
        }

        fn rotateLeft(self: *const Node) *const Node {
            return self.right.?.setLeftAndColor(self.setRightAndColor(self.right.?.left, .Red), self.color);
        }

        fn rotateRight(self: *const Node) *const Node {
            return self.left.?.setRightAndColor(self.setLeftAndColor(self.left.?.right, .Red), self.color);
        }

        fn flipColor(self: *const Node) *const Node {
            return createNode(self.key, self.value, self.color.flip(), self.left.?.invertColor(), self.right.?.invertColor());
        }

        fn rotateLeftIfNeeded(self: *const Node) *const Node {
            return if (isRed(self.right)) self.rotateLeft() else self;
        }

        fn rotateRightIfNeeded(self: *const Node) *const Node {
            return if (isRed(self.left) and isRed(self.left.?.left)) self.rotateRight() else self;
        }

        fn flipColorIfNeeded(self: *const Node) *const Node {
            return if (isRed(self.left) and isRed(self.right)) self.flipColor() else self;
        }

        fn setValue(self: *const Node, value: Value) *const Node {
            return createNode(self.key, value, self.color, self.left, self.right);
        }

        pub fn setColor(self: *const Node, color: Color) *const Node {
            return if (color == self.color) self else createNode(self.key, self.value, color, self.left, self.right);
        }

        pub fn insert(self: *const Node, key: Key, value: Value) *const Node {
            const newNode: *const Node = switch (compare(key, self.key)) {
                0 => return self.setValue(value),

                -1 => self.setLeft(if (self.left) |left|
                    left.insert(key, value)
                else
                    createNode(
                        key,
                        value,
                        .Red,
                        null,
                        null,
                    )),

                1 => self.setRight(if (self.right) |right|
                    right.insert(key, value)
                else
                    createNode(
                        key,
                        value,
                        .Red,
                        null,
                        null,
                    )),

                else => unreachable,
            };

            return if (self == newNode)
                self
            else
                newNode.rotateLeftIfNeeded()
                    .rotateRightIfNeeded()
                    .flipColorIfNeeded();
        }

        pub fn toGraphViz(
            self: *const Node,
            writer: std.ArrayList(u8).Writer,
        ) error{OutOfMemory}!void {
            try writer.print(
                \\
                \\"{[self_key]}" [label="{[self_key]}: {[self_value]s}", color={[color]s}];
                \\
            , .{ .self_key = self.key, .self_value = self.value, .color = self.color.toStr() });

            if (self.left) |leftNode|
                try writer.print(
                    \\"{[self_key]}" -> "{[left_key]}";
                    \\
                , .{ .self_key = self.key, .left_key = leftNode.key })
            else
                try writer.print(
                    \\"{[self_key]}_left_nil" [shape="plain", label="nil"];
                    \\"{[self_key]}" -> "{[self_key]}_left_nil";
                    \\
                , .{ .self_key = self.key });

            if (self.right) |rightNode|
                try writer.print(
                    \\"{[self_key]}" -> "{[right_key]}";
                    \\
                , .{ .self_key = self.key, .right_key = rightNode.key })
            else
                try writer.print(
                    \\"{[self_key]}_right_nil"  [shape="plain", label="nil"];
                    \\"{[self_key]}" -> "{[self_key]}_right_nil";
                    \\
                , .{ .self_key = self.key });

            if (self.left) |leftNode| try leftNode.toGraphViz(writer);
            if (self.right) |rightNode| try rightNode.toGraphViz(writer);
        }
    };
}
