const std = @import("std");
const utils = @import("utils.zig");

const Color = enum {
    Black,
    Red,
};

pub fn RBTreeNode(
    comptime Key: type,
    comptime Value: type,
    comptime compare: fn (Key, Key) i2,
) type {
    for ([_]type{ Key, Value }) |T| utils.errorIfNotNumberOrString(T);

    _ = compare;

    return struct {
        const Node = @This();

        key: Key,
        value: Value,
        color: Color,
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
                .color = .Black,
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
            _ = self;
            _ = allocator;
            _ = key;
            _ = value;

            @compileError("Not Implemented");
        }

        pub fn toGraphViz(
            self: *const Node,
            writer: std.ArrayList(u8).Writer,
        ) error{OutOfMemory}!void {
            _ = self;
            _ = writer;

            // try writer.print(
            //     \\
            //     \\    "{[self_key]}" [ label="{[self_key]}: {[self_value]s}"] ;
            //     \\
            // , .{ .self_key = self.key, .self_value = self.value });
            //
            // if (self.left) |leftNode|
            //     try writer.print(
            //         \\    "{[self_key]}" -> {[left_key]} ;
            //         \\
            //     , .{ .self_key = self.key, .left_key = leftNode.key })
            // else
            //     try writer.print(
            //         \\    "{[self_key]}_left_nil" [ shape="plain", label="nil" ] ;
            //         \\    "{[self_key]}" -> "{[self_key]}_left_nil" ;
            //         \\
            //     , .{ .self_key = self.key });
            //
            // if (self.right) |rightNode|
            //     try writer.print(
            //         \\    "{[self_key]}" -> "{[right_key]}" ;
            //         \\
            //     , .{ .self_key = self.key, .right_key = rightNode.key })
            // else
            //     try writer.print(
            //         \\    "{[self_key]}_right_nil"  [ shape="plain", label="nil" ] ;
            //         \\    "{[self_key]}" -> "{[self_key]}_right_nil" ;
            //         \\
            //     , .{ .self_key = self.key });
            //
            // if (self.left) |leftNode| try leftNode.toGraphViz(writer);
            // if (self.right) |rightNode| try rightNode.toGraphViz(writer);

            @compileError("Not Implemented");
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
