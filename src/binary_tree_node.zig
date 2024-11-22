const std = @import("std");
const utils = @import("utils.zig");

pub fn BinaryTreeNode(Key: type, Value: type, comptime compare: fn (Key, Key) i2) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        const Self = @This();

        key: Key,
        value: Value,
        left: ?*Self,
        right: ?*Self,

        pub fn newLeaf(
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!*Self {
            const newNode = try allocator.create(Self);
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

            newNode.* = Self{
                .key = key_copy,
                .value = value_copy,
                .left = null,
                .right = null,
            };

            return newNode;
        }

        pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
            if (self.left) |leftNode| leftNode.deinit(allocator);
            if (self.right) |rightNode| rightNode.deinit(allocator);

            if (Key == []const u8) allocator.free(self.key);
            if (Value == []const u8) allocator.free(self.value);
            allocator.destroy(self);
        }

        pub fn insert(
            self: *Self,
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!void {
            var lastNode: ?*Self = null;
            var currentNode: ?*Self = self;
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

            const newNode = try Self.newLeaf(
                allocator,
                key,
                value,
            );

            if (went_left)
                parentNode.left = newNode
            else
                parentNode.right = newNode;
        }

        pub fn insertSubtree(
            self: *Self,
            allocator: std.mem.Allocator,
            node: *Self,
        ) void {
            if (node.left) |leftNode| self.insertSubtree(allocator, leftNode);
            if (node.right) |rightNode| self.insertSubtree(allocator, rightNode);

            self.insertLeaf(allocator, node);
        }

        fn insertLeaf(
            self: *Self,
            allocator: std.mem.Allocator,
            leaf: *Self,
        ) void {
            leaf.left = null;
            leaf.right = null;

            var lastNode: ?*Self = null;
            var currentNode: ?*Self = self;
            var went_left = true;

            while (currentNode) |node| switch (compare(leaf.key, node.key)) {
                0 => {
                    node.value = leaf.value;

                    if (Key == []const u8) allocator.free(leaf.key);
                    if (Value == []const u8) allocator.free(leaf.value);
                    allocator.destroy(leaf);

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

        pub fn delete(
            self: *Self,
            allocator: std.mem.Allocator,
            key: Key,
        ) ?*Self {
            var lastNode: ?*Self = null;
            var currentNode: ?*Self = self;
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

        pub fn get(self: *const Self, key: Key) ?Value {
            var currentNode: ?*const Self = self;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return node.value,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return null;
        }

        pub fn contains(self: *const Self, key: Key) bool {
            var currentNode: ?*const Self = self;

            while (currentNode) |node| switch (compare(key, node.key)) {
                0 => return true,
                -1 => currentNode = node.left,
                1 => currentNode = node.right,
                else => unreachable,
            };

            return false;
        }

        pub fn print(self: Self) void {
            if (self.left) |leftNode| leftNode.print();

            std.debug.print(
                std.fmt.comptimePrint(
                    "  key: {s}\nvalue: {s}\n",
                    .{ utils.getFmtStr(Key), utils.getFmtStr(Value) },
                ),
                .{ self.key, self.value },
            );
            // std.debug.print(
            //     "lk: {d}, rk: {d}\n",
            //     .{ if (self.left) |n| n.key else -1000, if (self.right) |n| n.key else -1000 },
            // );

            if (self.right) |rightNode| rightNode.print();
        }
    };
}
