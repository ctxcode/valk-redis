
# valk-redis

A Redis client for [Valk](https://valk-lang.dev). Purely written in Valk, with no os-package
dependencies: it speaks RESP over `valk.net` and needs nothing installed besides a server.

Works with Redis and Valkey, over RESP2 (every version) or RESP3 (Redis 6 and newer).

Requires Valk 0.7.2 or newer.

## Install

```
vman install github.com/ctxcode/valk-redis
```

## Example

```rust
use redis

let con = redis.connect("127.0.0.1", 6379) ! panic("Failed to connect: %{E.message}")
defer con.close()

// Strings and counters
con.set("greeting", "hello", 60) ! panic("%{E.message}")     // with a 60 second lifetime
let greeting = con.get("greeting") ! panic("%{E.message}")   // null when the key is missing
let visits = con.incr("visits") ! panic("%{E.message}")

// Hashes, lists, sets and sorted sets
con.hset_many("user:1", .{ "name" => "Ada", "role" => "admin" }) ! panic("%{E.message}")
let user = con.hgetall("user:1") ! panic("%{E.message}")     // Map[String]
con.rpush("jobs", "send-mail") ! panic("%{E.message}")
let job = con.blpop("jobs", 5) ! panic("%{E.message}")       // waits up to five seconds
con.zadd("board", 30, "ada") ! panic("%{E.message}")
let top = con.zrange_with_scores("board", 0, 9, true) ! panic("%{E.message}")

// Anything this package has no method for
con.run(.{ "SET", "visits", 1, "EX", 60 }) ! panic("%{E.message}")
let ttl = con.run(.{ "TTL", "visits" }) ! panic("%{E.message}")
println(ttl.to_int())
```

Values are sent as bytes, so a `String` holding any byte works, and numbers convert to text
on their own: `con.set("n", 42)` and `con.run(.{ "EXPIRE", key, 60 })` need no formatting.

## Connecting

```rust
// host, port, password, database, username, connect timeout in ms, protocol
let con = redis.connect("127.0.0.1", 6379, "secret", 0, "", 5000, 3) ! panic("%{E.message}")
```

A password alone is a server with `requirepass`; a username and password together are an ACL
user. `protocol` 3 asks for RESP3, which gives maps, sets, doubles and out-of-band pushes
their own types, and lets a subscribed connection keep running ordinary commands. Every method
of this package works the same on both protocols.

Once the connection is up it waits forever for a reply, so that blocking commands such as
`blpop` work. `con.set_timeouts(read_ms, write_ms)` changes that.

A connection carries one command at a time, so it belongs to one coroutine or one thread. Give
every worker its own.

## Replies

Typed methods hand back what the command means: `?String` for a key that may be missing,
`uint` for a count, `bool` for a yes or no, `Map[String]` for a hash. `run` hands back a
`Value`, which converts:

```rust
let reply = con.run(.{ "GET", "visits" }) ! panic("%{E.message}")
reply.is_null()             // the key does not exist
reply.to_string()           // the bytes
reply.to_int()              // parsed as a number
reply.to_strings()          // an array reply as Array[String]
reply.to_string_map()       // a field/value reply as Map[String], flat array or RESP3 map
reply.to_json()             // parsed as JSON
```

A command the server refuses throws `server`, and `E.error_code` holds the first word of its
answer, such as `WRONGTYPE` or `NOSCRIPT`.

## Pipelines

A pipeline pays for one round trip instead of one per command:

```rust
let pipe = con.pipeline()
pipe.add(.{ "SET", "a", 1 })
pipe.add(.{ "INCR", "a" })
let replies = pipe.exec() ! panic("%{E.message}")
```

A command that failed is an `error` value in the result rather than a thrown error, so one
failure does not hide the other replies.

## Transactions

```rust
con.watch(.{ "balance" }) ! panic("%{E.message}")
con.multi() ! panic("%{E.message}")
con.queue(.{ "DECRBY", "balance", 10 }) ! panic("%{E.message}")
let replies = con.exec() ! panic("%{E.message}")
if !isset(replies) : println("balance changed, try again")
```

`exec` returns null when a watched key changed, which is how a transaction that has to be
retried is told apart from one that ran.

## Scripts

```rust
global take_token: redis.Script (redis.Script.new("
    local left = tonumber(redis.call('GET', KEYS[1]) or ARGV[1])
    if left <= 0 then return 0 end
    redis.call('DECR', KEYS[1])
    return left
"))

let left = take_token.run(con, .{ "tokens" }, .{ "10" }) ! panic("%{E.message}")
```

A `Script` sends its body once and runs it by SHA-1 afterwards, and sends it again by itself
when the server has forgotten it.

## Publish and subscribe

```rust
let listener = redis.connect("127.0.0.1", 6379) ! panic("%{E.message}")
listener.subscribe(.{ "news" }) ! panic("%{E.message}")
while true {
    let message = listener.next_message(1000) ! break
    if !isset(message) : continue   // nothing within a second
    println(message.channel + ": " + message.data)
}
```

`psubscribe` subscribes to patterns such as `jobs.*`, and the message then also carries the
pattern that matched. On RESP2 a subscribed connection only accepts subscribe, unsubscribe and
ping commands, so publish from a second connection; RESP3 has no such restriction.

## Walking the keyspace

`keys("user:*")` blocks the server while it walks every key. On a database that is in use,
scan instead:

```rust
let keys = con.scan_iter("session:*")
while true {
    let key = keys.next() ! panic("%{E.message}")
    if !isset(key) : break
    con.del(key) ! panic("%{E.message}")
}
```

`sscan_iter` walks a set the same way; `hscan` and `zscan` read one page of a hash or sorted
set.

## Errors

Every method throws `redis.Error`:

| code | when |
| --- | --- |
| `connect` | the connection could not be opened, or reading and writing failed |
| `auth` | the credentials were rejected, or none were given where they are needed |
| `server` | the server answered with an error; `error_code` holds its first word |
| `protocol` | the server sent bytes this package did not expect |
| `timeout` | a read ran past the connection timeout |
| `closed` | the connection is closed |

## Development

`make server` starts a Redis in docker on port 6399 and `make server-down` removes it again.
`make test` runs the suite against it, using database 9. `make example` builds and runs the
example, `make lint` checks the sources and `make docs` regenerates the API documentation.
Override the compiler with `make vc=/path/to/valk test`.
