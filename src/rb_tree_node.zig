const std = @import("std");
const utils = @import("utils.zig");

const Color = enum {
    Black,
    Red,
};

pub fn RBNode(Key: type, Value: type) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    return struct {
        const Self = @This();

        key: Key,
        value: Value,
        color: Color,
        left: ?*Self,
        right: ?*Self,

        pub fn newLeaf(
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!*Self {
            const newNode = try allocator.create(Self);

            newNode.* = Self{
                .key = if (Key == []const u8) key: {
                    const key_str_cpy = try allocator.alloc(u8, key.len);
                    @memcpy(key_str_cpy, key);
                    break :key key_str_cpy;
                } else key,
                .value = if (Value == []const u8) key: {
                    const value_str_cpy = try allocator.alloc(u8, value.len);
                    @memcpy(value_str_cpy, value);
                    break :key value_str_cpy;
                } else value,
                .color = .Black,
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
            if (key == self.key) {
                self.value = value;
            } else if (key < self.key) {
                try self.insertLeft(allocator, key, value);
            } else {
                try self.insertRight(allocator, key, value);
            }
        }

        fn insertLeft(
            self: *Self,
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!void {
            if (self.left) |leftNode| {
                try leftNode.insert(allocator, key, value);
            } else {
                self.left = try Self.newLeaf(
                    allocator,
                    key,
                    value,
                );
            }
        }

        fn insertRight(
            self: *Self,
            allocator: std.mem.Allocator,
            key: Key,
            value: Value,
        ) error{OutOfMemory}!void {
            if (self.right) |rightNode| {
                try rightNode.insert(allocator, key, value);
            } else {
                self.right = try Self.newLeaf(
                    allocator,
                    key,
                    value,
                );
            }
        }

        pub fn print(self: Self) void {
            if (self.left) |leftNode| leftNode.print();

            std.debug.print(
                std.fmt.comptimePrint(
                    "  key: {s}\nvalue: {s}\ncolor: {{s}}\n",
                    .{ utils.getFmtStr(Key), utils.getFmtStr(Value) },
                ),
                .{ self.key, self.value, @tagName(self.color) },
            );

            if (self.right) |rightNode| rightNode.print();
        }
    };
}
