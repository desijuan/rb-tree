const std = @import("std");
const utils = @import("utils.zig");

pub fn BinaryTreeNode(Key: type, Value: type, compare: fn (Key, Key) i2) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        const Node = @This();

        key: Key,
        value: Value,
        left: ?*Node,
        right: ?*Node,

        pub fn createNode(
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!*Node {
            const newNode = try allocator.create(Node);
            errdefer allocator.destroy(newNode);

            const key_copy = if (Key == []const u8) blk: {
                const key_copy = try allocator.alloc(u8, key.len);
                errdefer allocator.free(key_copy);
                @memcpy(key_copy, key);
                break :blk key_copy;
            } else key;
            errdefer if (Key == []const u8) allocator.free(key_copy);

            const value_copy = if (Value == []const u8) blk: {
                const value_copy = try allocator.alloc(u8, value.len);
                errdefer allocator.free(value_copy);
                @memcpy(value_copy, value);
                break :blk value_copy;
            } else value;
            errdefer if (Value == []const u8) allocator.free(value_copy);

            newNode.* = Node{
                .key = key_copy,
                .value = value_copy,
                .left = null,
                .right = null,
            };

            return newNode;
        }

        pub fn destroyNode(
            allocator: std.mem.Allocator,
            self: *const Node,
        ) void {
            if (Key == []const u8) allocator.free(self.key);
            if (Value == []const u8) allocator.free(self.value);
            allocator.destroy(self);
        }

        pub fn deinit(self: *const Node, allocator: std.mem.Allocator) void {
            if (self.left) |leftNode| leftNode.deinit(allocator);
            if (self.right) |rightNode| rightNode.deinit(allocator);

            destroyNode(allocator, self);
        }

        pub fn insertKeyValue(
            self: *Node,
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!void {
            var lastNode: ?*Node = null;
            var currentNode: ?*Node = self;
            var went_left = true;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => {
                    node.value = value;
                    return;
                },
                -1 => {
                    went_left = true;
                    lastNode = node;
                    currentNode = node.left;
                },
                1 => {
                    went_left = false;
                    lastNode = node;
                    currentNode = node.right;
                },
                else => unreachable,
            };

            const parentNode = lastNode.?;

            const newNode = try createNode(allocator, key, value);

            if (went_left)
                parentNode.left = newNode
            else
                parentNode.right = newNode;
        }

        //
        // TODO: Revisar esto
        // vvvvvvvvvvvvvvvvvv
        fn insertLeaf(
            self: *Node,
            allocator: std.mem.Allocator,
            leaf: *Node,
        ) void {
            leaf.left = null;
            leaf.right = null;

            var lastNode: ?*Node = null;
            var currentNode: ?*Node = self;
            var went_left = true;

            while (currentNode) |node| switch (compare(leaf.key, node.key)) {
                0 => {
                    node.value = leaf.value;
                    destroyNode(allocator, leaf);
                    return;
                },
                -1 => {
                    went_left = true;
                    lastNode = node;
                    currentNode = node.left;
                },
                1 => {
                    went_left = false;
                    lastNode = node;
                    currentNode = node.right;
                },
                else => unreachable,
            };

            const parentNode = lastNode.?;

            if (went_left)
                parentNode.left = leaf
            else
                parentNode.right = leaf;
        }

        fn insertSubtree(
            self: *Node,
            allocator: std.mem.Allocator,
            node: *Node,
        ) void {
            if (node.left) |leftNode| self.insertSubtree(allocator, leftNode);
            if (node.right) |rightNode| self.insertSubtree(allocator, rightNode);

            self.insertLeaf(allocator, node);
        }

        fn delete(
            self: *Node,
            allocator: std.mem.Allocator,
            key: Key,
        ) ?*Node {
            var lastNode: ?*Node = null;
            var currentNode: ?*Node = self;
            var went_left = true;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => {
                    if (lastNode) |parentNode| {
                        if (went_left)
                            parentNode.left = null
                        else
                            parentNode.right = null;

                        if (node.left) |leftNode| parentNode.insertSubtree(allocator, leftNode);
                        if (node.right) |rightNode| parentNode.insertSubtree(allocator, rightNode);
                    } else {
                        if (node.left) |leftNode|
                            if (node.right) |rightNode|
                                leftNode.insertSubtree(allocator, rightNode);
                    }

                    return node;
                },
                -1 => {
                    went_left = true;
                    lastNode = node;
                    currentNode = node.left;
                },
                1 => {
                    went_left = false;
                    lastNode = node;
                    currentNode = node.right;
                },
                else => unreachable,
            };

            return null;
        }
        // ^^^^^^^^^^^^^^^^^^
        // TODO: Revisar esto
        //

        pub fn get(self: *const Node, key: Key) ?Value {
            var currentNode: ?*const Node = self;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return node.value,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return null;
        }

        pub fn contains(self: *const Node, key: Key) bool {
            var currentNode: ?*const Node = self;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return true,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return false;
        }

        pub fn toGraphViz(
            self: *const Node,
            writer: std.ArrayList(u8).Writer,
        ) error{OutOfMemory}!void {
            try writer.print(
                \\
                \\    "{[self_key]}" [ label="{[self_key]}: {[self_value]s}"] ;
                \\
            , .{ .self_key = self.key, .self_value = self.value });

            if (self.left) |leftNode|
                try writer.print(
                    \\    "{[self_key]}" -> {[left_key]} ;
                    \\
                , .{ .self_key = self.key, .left_key = leftNode.key })
            else
                try writer.print(
                    \\    "{[self_key]}_left_nil" [ shape="plain", label="nil" ] ;
                    \\    "{[self_key]}" -> "{[self_key]}_left_nil" ;
                    \\
                , .{ .self_key = self.key });

            if (self.right) |rightNode|
                try writer.print(
                    \\    "{[self_key]}" -> "{[right_key]}" ;
                    \\
                , .{ .self_key = self.key, .right_key = rightNode.key })
            else
                try writer.print(
                    \\    "{[self_key]}_right_nil"  [ shape="plain", label="nil" ] ;
                    \\    "{[self_key]}" -> "{[self_key]}_right_nil" ;
                    \\
                , .{ .self_key = self.key });

            if (self.left) |leftNode| try leftNode.toGraphViz(writer);
            if (self.right) |rightNode| try rightNode.toGraphViz(writer);
        }

        pub fn print(self: Node) void {
            if (self.left) |leftNode| leftNode.print();

            std.debug.print(
                std.fmt.comptimePrint(
                    "  key: {s}\nvalue: {s}\n",
                    .{ utils.getFmtStr(Key), utils.getFmtStr(Value) },
                ),
                .{ self.key, self.value },
            );

            if (self.right) |rightNode| rightNode.print();
        }

        inline fn nodeLabelFmtStr() []const u8 {
            return std.fmt.comptimePrint(
                "{s}: {s}",
                .{ utils.getFmtStr(Key), utils.getFmtStr(Value) },
            );
        }
    };
}

const testing = std.testing;

fn intCanonicalOrder(n1: i32, n2: i32) i2 {
    return if (n1 == n2) 0 else if (n1 < n2) -1 else 1;
}

const IntStrNode = BinaryTreeNode(i32, []const u8, intCanonicalOrder);

test "IntStrNode createNode and destroyNode" {
    const allocator = testing.allocator;

    const node = try IntStrNode.createNode(allocator, 1, "a");
    defer IntStrNode.destroyNode(allocator, node);

    try testing.expectEqual(1, node.key);
    try testing.expectEqualSlices(u8, "a", node.value);

    var fa = std.testing.FailingAllocator.init(allocator, .{ .fail_index = 0 });

    try testing.expectError(error.OutOfMemory, IntStrNode.createNode(fa.allocator(), 1, "a"));
}
