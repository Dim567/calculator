const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const CustomError = error{
    NonDigit,
    WrongBrackets,
    MoreThanOneEqualitySign,
    TwoOperatorsTogether,
};

const Node = struct {
    val: f64,
    priority: i64 = 0,
    next: ?*Node = null,
    op: u8,
};

const List = struct {
    head: ?*Node = null,
    tail: ?*Node = null,
    len: usize = 0,

    pub fn add(self: *List, node: *Node) void {
        if (self.head == null) {
            self.head = node;
            self.tail = node;

            self.len += 1;
            return;
        }

        self.tail.?.next = node;
        self.tail = node;
        self.len += 1;
    }

    pub fn printL(self: *List) void {
        var cur = self.head;
        while (cur) |item| {
            // print("Val: {d} Op: {c} Pr: {d}\n", .{ item.val, item.op, item.priority });
            cur = item.next;
        }
        // print("List length: {d}\n", .{self.len});
    }
};

pub fn main() !void {
    var buffer: [100000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fbaAllocator = fba.allocator();

    var arena = std.heap.ArenaAllocator.init(fbaAllocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var buf: [10000]u8 = undefined;
    var list = List{};

    const stdin = std.io.getStdIn().reader();
    const str = try stdin.readUntilDelimiter(&buf, '\n');

    // 1. Parse input and build linked list
    var digitsAccum: [19]u8 = undefined; // 19 = max number of characters (bytes) in string representation of i64
    var accumInd: usize = 0;
    var prevChar: u8 = 's'; // 'start of the input' label
    var priority: i64 = 0;
    var maxPriority: i64 = 0;
    var closingBracketsCounter: i64 = 0;
    var equalityOperatorsCounter: u8 = 0;
    var previouslyWasOperator: bool = false;
    for (str) |item| {
        if (priority > maxPriority) {
            maxPriority = priority;
        }
        if (priority < 0) {
            return CustomError.WrongBrackets;
        }
        defer prevChar = item;

        if (prevChar == 's' or prevChar == '(') {
            if (item == '-' or item == '+') {
                previouslyWasOperator = true;
                const node = try allocator.create(Node);
                node.* = .{
                    .op = item,
                    .val = 0,
                    .next = null,
                    .priority = priority,
                };
                list.add(node);
                continue;
            }
        }
        if (item == '(') {
            priority += 1;
            continue;
        }

        if (item == '=') {
            equalityOperatorsCounter += 1;
            if (equalityOperatorsCounter > 1) {
                return CustomError.MoreThanOneEqualitySign;
            }
        }

        if (item == '+' or item == '-' or item == '*' or item == '/' or item == '=') {
            if (previouslyWasOperator) {
                return CustomError.TwoOperatorsTogether;
            }
            previouslyWasOperator = true;
            const num = try std.fmt.parseFloat(f64, digitsAccum[0..accumInd]);
            const node = try allocator.create(Node);
            node.* = .{
                .op = item,
                .val = num,
                .next = null,
                .priority = priority,
            };
            list.add(node);
            if (closingBracketsCounter > 0) {
                priority -= closingBracketsCounter;
                closingBracketsCounter = 0;
            }

            accumInd = 0;
            continue;
        }

        if (item == ')') {
            closingBracketsCounter += 1;
            continue;
        }

        // Didit must be from 0 to 9.
        // Item is the char code of the digit: '0'=48, '9'=57
        // or period for floating point numbers: '.'=46
        if (item == 46 or (item >= 48 and item <= 57)) {
            previouslyWasOperator = false;
            digitsAccum[accumInd] = item;
            accumInd += 1;
            continue;
        }

        return CustomError.NonDigit;
    }

    if (priority != 0) {
        return CustomError.WrongBrackets;
    }

    // list.printL(); // for debugging

    // 2. Calculate result
    // 2.1. Find sublist with highest priority
    // 2.2. Calculate sublist result
    // 2.3. Replace initial sublist with the node containing result
    var startNode: ?*Node = undefined;
    var endNode: ?*Node = undefined;
    var st: bool = false;
    while (maxPriority >= 0) {
        var node = list.head;
        while (node != null) {
            if (node.?.priority == maxPriority) {
                if (!st) {
                    startNode = node;
                    st = true;
                }
                endNode = node;
            }
            if (st and node.?.priority < maxPriority) {
                break;
            }

            if (st and node.?.next == null) {
                endNode = node;
                break;
            }
            node = node.?.next;
        }
        if (!st) {
            maxPriority -= 1;
            continue;
        }
        const tmp = calc(startNode.?, endNode.?);
        // print("{d}===\n", .{tmp});
        startNode.?.op = endNode.?.op;
        startNode.?.val = tmp;
        startNode.?.priority = maxPriority - 1;
        startNode.?.next = endNode.?.next;
        st = false;
    }

    print("Result = {d}\n", .{startNode.?.val});
}

/// Calculates result of the sublist passed in as pointers
/// to start node and end node of the sublist
fn calc(startNode: *Node, endNode: *Node) f64 {
    if (startNode == endNode) {
        return startNode.val;
    }

    var cur: ?*Node = startNode;
    var prev: ?*Node = null;

    while (cur != endNode) {
        if (prev != null and prev.?.op == '*') {
            prev.?.op = cur.?.op;
            prev.?.val *= cur.?.val;
            prev.?.next = cur.?.next;
            cur = cur.?.next;
            continue;
        }
        if (prev != null and prev.?.op == '/') {
            prev.?.op = cur.?.op;
            prev.?.val /= cur.?.val;
            prev.?.next = cur.?.next;
            cur = cur.?.next;
            continue;
        }
        prev = cur;
        cur = cur.?.next;
    }

    if (prev.?.op == '*') {
        prev.?.op = endNode.op;
        prev.?.val *= endNode.val;
        prev.?.next = endNode.next;
    } else if (prev.?.op == '/') {
        prev.?.op = endNode.op;
        prev.?.val /= endNode.val;
        prev.?.next = endNode.next;
    } else {
        prev = endNode;
    }

    cur = startNode;
    var res: f64 = cur.?.val;
    while (cur != prev) {
        defer cur = cur.?.next;

        if (cur.?.op == '+') {
            res += cur.?.next.?.val;
            continue;
        }
        res -= cur.?.next.?.val;
    }
    return res;
}
