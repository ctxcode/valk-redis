
# Documentation

Namespaces: [main](#main)

---

# main

## Errors for 'main'

```js
// Thrown by every operation of this package.
+ error Error (connect, tls, auth, protocol, server, cluster, timeout, type, closed) payload { message: String, error_code: String ("") }
```

## Enums for 'main'

```js
// The kinds of `Value`.
+ enum TYPE { null, string, int, float, bool, array, map, set, push, error, big_number, verbatim }
```

## Functions for 'main'

```js
// Reads a `redis://` or `rediss://` URL as a `Config`, for a pool or a changed setting.
+ fn config_from_url(text: String, timeout_ms: uint (5000)) Config !Error
// Opens a connection and logs in.
+ fn connect(host: String ("127.0.0.1"), port: u32 (6379), password: String (""), db: uint (0), username: String (""), timeout_ms: uint (5000), protocol: uint (2)) Connection !Error
// Asks the sentinels where the primary is, and connects to it.
+ fn connect_sentinel(config: SentinelConfig) Connection !Error
// Opens a connection described by a URL.
+ fn connect_url(text: String, timeout_ms: uint (5000)) Connection !Error
// Opens a connection described by a `Config` and logs in.
+ fn connect_with(config: Config) Connection !Error
// Returns the replicas of the primary, as `host:port`, for reads that may be a moment behind.
+ fn sentinel_replicas(config: SentinelConfig) Array[String] !Error
```

## Classes for 'main'

```js
// Everything needed to open a connection.
+ class Config {
    // The database to select, 0 being the default one.
    + db: uint
    // Host name or address of the server.
    + host: String
    // The password, or "" for a server without one.
    + password: String
    // Port of the server.
    + port: u32
    // The protocol to speak: 2 or 3.
    + protocol: uint
    // How long connecting may take, in milliseconds.
    + timeout_ms: uint
    // TLS settings, or null for a connection without TLS.
    + tls: ?TlsOptions
    // The ACL user name, or "" to log in with the password alone.
    + username: String
}
```

```js
// A connection to one server.
+ class Connection {
    // Whether `close` was called, or the server closed the connection.
    ~ closed: bool
    // The settings this connection was opened with.
    + config: Config
    // The database this connection selected.
    ~ db: uint
    // Prints every command and reply when true.
    + debug: bool
    // The protocol version in use: 2 or 3.
    ~ protocol: uint
    // Server properties reported by `HELLO`, such as `version` and `role`. Empty on RESP2.
    ~ server_info: Map[String]
    // How many channels and patterns this connection is subscribed to.
    ~+ subscriptions: uint
    // Whether the connection runs over TLS.
    ~ tls_active: bool

    // Appends to a key and returns the new length.
    + fn append(key: String, value: String) uint !Error
    // Waits for a value at the head of a list and takes it off.
    + fn blpop(key: String, timeout_seconds: uint (0)) ?String !Error
    // Waits for a value at the head of any of `keys`, in the order given.
    + fn blpop_many(keys: Array[String], timeout_seconds: uint (0)) ?Array[String] !Error
    // Waits for a value at the tail of a list and takes it off.
    + fn brpop(key: String, timeout_seconds: uint (0)) ?String !Error
    // Waits for a value at the tail of any of `keys`, in the order given.
    + fn brpop_many(keys: Array[String], timeout_seconds: uint (0)) ?Array[String] !Error
    // Closes the connection. Further commands throw `closed`.
    + fn close() void
    // Returns the configuration settings matching a glob pattern.
    + fn config_get(pattern: String) Map[String] !Error
    // Changes one configuration setting.
    + fn config_set(name: String, value: String) void !Error
    // Returns how many keys the selected database holds.
    + fn dbsize() uint !Error
    // Takes 1 off a number held at a key and returns the result.
    + fn decr(key: String) int !Error
    // Takes `amount` off a number held at a key and returns the result.
    + fn decr_by(key: String, amount: int) int !Error
    // Removes a key and returns whether it existed.
    + fn del(key: String) bool !Error
    // Removes several keys and returns how many existed.
    + fn del_many(keys: Array[String]) uint !Error
    // Throws away the queued commands.
    + fn discard() void !Error
    // Runs a Lua script on the server and returns its reply.
    + fn eval(source: String, keys: Array[String] (.{}), args: Array[String] (.{})) Value !Error
    // Runs a script the server already has, by its SHA-1. Throws `server` with the code `NOSCRIPT` when it does not have it.
    + fn evalsha(sha: String, keys: Array[String] (.{}), args: Array[String] (.{})) Value !Error
    // Runs the queued commands and returns their replies in order.
    + fn exec() ?Array[Value] !Error
    // Returns whether a key exists.
    + fn exists(key: String) bool !Error
    // Returns how many of `keys` exist. A key present several times counts each time.
    + fn exists_many(keys: Array[String]) uint !Error
    // Gives a key a lifetime in seconds and returns whether it was set.
    + fn expire(key: String, seconds: uint) bool !Error
    // Makes a key expire at a Unix time in seconds.
    + fn expire_at(key: String, unix_seconds: uint) bool !Error
    // Removes every key of every database.
    + fn flushall() void !Error
    // Removes every key of the selected database.
    + fn flushdb() void !Error
    // Returns the value of a key, or null when it does not exist.
    + fn get(key: String) ?String !Error
    // Returns a key and deletes it. Needs Redis 6.2 or newer.
    + fn getdel(key: String) ?String !Error
    // Sets a key and returns what it held before.
    + fn getset(key: String, value: String) ?String !Error
    // Removes one field of a hash and returns whether it existed.
    + fn hdel(key: String, field: String) bool !Error
    // Removes several fields of a hash and returns how many existed.
    + fn hdel_many(key: String, fields: Array[String]) uint !Error
    // Returns whether a hash has a field.
    + fn hexists(key: String, field: String) bool !Error
    // Returns one field of a hash, or null when the field or the key does not exist.
    + fn hget(key: String, field: String) ?String !Error
    // Returns every field of a hash with its value, or an empty map when the key does not exist.
    + fn hgetall(key: String) Map[String] !Error
    // Adds `amount` to a number held in a field and returns the result.
    + fn hincr_by(key: String, field: String, amount: int) int !Error
    // Adds a floating point `amount` to a number held in a field and returns the result.
    + fn hincr_by_float(key: String, field: String, amount: float) float !Error
    // Returns the field names of a hash.
    + fn hkeys(key: String) Array[String] !Error
    // Returns how many fields a hash has.
    + fn hlen(key: String) uint !Error
    // Returns the values of several fields; a field that does not exist becomes null.
    + fn hmget(key: String, fields: Array[String]) Array[?String] !Error
    // Reads one page of a hash, as fields with their values.
    + fn hscan(key: String, cursor: uint (0), pattern: String (""), count: uint (0)) (uint, Map[String]) !Error
    // Sets one field of a hash and returns whether the field is new.
    + fn hset(key: String, field: String, value: String) bool !Error
    // Sets several fields of a hash and returns how many of them are new.
    + fn hset_many(key: String, values: Map[String]) uint !Error
    // Sets one field of a hash only when it does not exist yet.
    + fn hsetnx(key: String, field: String, value: String) bool !Error
    // Returns the values of a hash.
    + fn hvals(key: String) Array[String] !Error
    // Adds 1 to a number held at a key and returns the result. A missing key counts as 0.
    + fn incr(key: String) int !Error
    // Adds `amount` to a number held at a key and returns the result.
    + fn incr_by(key: String, amount: int) int !Error
    // Adds a floating point `amount` to a number held at a key and returns the result.
    + fn incr_by_float(key: String, amount: float) float !Error
    // Returns the `INFO` fields of a section, or of the default sections when none is given.
    + fn info(section: String ("")) Map[String] !Error
    // Returns every key matching a glob pattern such as `user:*`.
    + fn keys(pattern: String ("*")) Array[String] !Error
    // Returns the value at an offset of a list, or null when the offset lies outside it.
    + fn lindex(key: String, index: int) ?String !Error
    // Returns how many values a list holds.
    + fn llen(key: String) uint !Error
    // Takes the first value off a list, or null when it is empty.
    + fn lpop(key: String) ?String !Error
    // Adds a value at the head of a list and returns its new length.
    + fn lpush(key: String, value: String) uint !Error
    // Adds several values at the head of a list, the last one ending up first.
    + fn lpush_many(key: String, values: Array[String]) uint !Error
    // Returns the values of a list between two offsets. Negative offsets count from the end, so `lrange(key, 0, -1)` is the whole list.
    + fn lrange(key: String, start: int (0), stop: int (-1)) Array[String] !Error
    // Removes values equal to `value` and returns how many were removed.
    + fn lrem(key: String, value: String, count: int (0)) uint !Error
    // Writes the value at an offset of a list. Throws `server` when the offset lies outside it.
    + fn lset(key: String, index: int, value: String) void !Error
    // Keeps only the values between two offsets and removes the rest.
    + fn ltrim(key: String, start: int, stop: int) void !Error
    // Returns the values of several keys at once; a key that does not exist becomes null.
    + fn mget(keys: Array[String]) Array[?String] !Error
    // Sets several keys at once.
    + fn mset(values: Map[String]) void !Error
    // Starts a transaction. Commands added with `queue` are kept by the server until `exec`.
    + fn multi() void !Error
    // Waits for the next message on the channels this connection is subscribed to.
    + fn next_message(timeout_ms: uint (0)) ?Message !Error
    // Removes the lifetime of a key, so that it stays until it is deleted.
    + fn persist(key: String) bool !Error
    // Gives a key a lifetime in milliseconds and returns whether it was set.
    + fn pexpire(key: String, milliseconds: uint) bool !Error
    // Sends `PING` and returns whether the server answered.
    + fn ping() bool
    // Starts a pipeline on this connection.
    + fn pipeline() Pipeline
    // Subscribes to channels matching glob patterns such as `news.*`.
    + fn psubscribe(patterns: Array[String]) void !Error
    // Returns the milliseconds a key still has to live, -1 when it has no lifetime and -2 when it does not exist.
    + fn pttl(key: String) int !Error
    // Publishes a message and returns how many subscribers the server handed it to.
    + fn publish(channel: String, message: String) uint !Error
    // Unsubscribes from patterns, or from every pattern when none are given.
    + fn punsubscribe(patterns: Array[String] (.{})) void !Error
    // Adds a command to the open transaction.
    + fn queue(args: Array[String]) void !Error
    // Returns a random key, or null when the database is empty.
    + fn random_key() ?String !Error
    // Renames a key. Throws `server` when the key does not exist.
    + fn rename(key: String, to: String) void !Error
    // Renames a key when the new name is free, and returns whether it was renamed.
    + fn rename_nx(key: String, to: String) bool !Error
    // Takes the last value off a list, or null when it is empty.
    + fn rpop(key: String) ?String !Error
    // Takes the last value off one list and puts it at the head of another.
    + fn rpoplpush(key: String, to: String) ?String !Error
    // Adds a value at the tail of a list and returns its new length.
    + fn rpush(key: String, value: String) uint !Error
    // Adds several values at the tail of a list, in order.
    + fn rpush_many(key: String, values: Array[String]) uint !Error
    // Runs one command and returns its reply, for commands this package has no method for.
    + fn run(args: Array[String]) Value !Error
    // The same as `run`, but an error reply is returned as a `Value` of type `error` instead of thrown.
    + fn run_raw(args: Array[String]) Value !Error
    // Adds a member to a set and returns whether it is new.
    + fn sadd(key: String, member: String) bool !Error
    // Adds several members to a set and returns how many are new.
    + fn sadd_many(key: String, members: Array[String]) uint !Error
    // Reads one page of the keyspace.
    + fn scan(cursor: uint (0), pattern: String (""), count: uint (0)) (uint, Array[String]) !Error
    // Walks every key of the database, a page at a time.
    + fn scan_iter(pattern: String (""), count: uint (0)) ScanIterator
    // Returns how many members a set has.
    + fn scard(key: String) uint !Error
    // Returns whether the server has a script with this SHA-1.
    + fn script_exists(sha: String) bool !Error
    // Stores a script on the server and returns its SHA-1.
    + fn script_load(source: String) String !Error
    // Returns the members of the first key that the other keys do not hold.
    + fn sdiff(keys: Array[String]) Array[String] !Error
    // Stores the difference of `keys` in `to` and returns how many members there are.
    + fn sdiffstore(to: String, keys: Array[String]) uint !Error
    // Selects another database.
    + fn select(db: uint) void !Error
    // Returns the server version, such as `7.2.4`.
    + fn server_version() String !Error
    // Sets the value of a key and returns whether it was written.
    + fn set(key: String, value: String, expire_seconds: uint (0), expire_ms: uint (0), if_not_exists: bool (false), if_exists: bool (false), keep_ttl: bool (false)) bool !Error
    // Sets the socket read and write timeouts in milliseconds; 0 waits forever (the default).
    + fn set_timeouts(read_timeout_ms: uint, write_timeout_ms: uint) void
    // Sets a key with a lifetime in seconds.
    + fn setex(key: String, value: String, seconds: uint) void !Error
    // Sets a key only when it does not exist yet, and returns whether it was written.
    + fn setnx(key: String, value: String) bool !Error
    // Returns the members that every one of `keys` holds.
    + fn sinter(keys: Array[String]) Array[String] !Error
    // Stores the members that every one of `keys` holds in `to` and returns how many there are.
    + fn sinterstore(to: String, keys: Array[String]) uint !Error
    // Returns whether a set holds a member.
    + fn sismember(key: String, member: String) bool !Error
    // Returns every member of a set, in no particular order.
    + fn smembers(key: String) Array[String] !Error
    // Moves a member from one set to another and returns whether it was there.
    + fn smove(key: String, to: String, member: String) bool !Error
    // Takes a random member off a set, or null when it is empty.
    + fn spop(key: String) ?String !Error
    // Returns a random member without removing it, or null when the set is empty.
    + fn srandmember(key: String) ?String !Error
    // Returns `count` random members without removing them. A negative `count` may return the same member several times.
    + fn srandmembers(key: String, count: int) Array[String] !Error
    // Removes a member from a set and returns whether it was there.
    + fn srem(key: String, member: String) bool !Error
    // Removes several members from a set and returns how many were there.
    + fn srem_many(key: String, members: Array[String]) uint !Error
    // Reads one page of a set.
    + fn sscan(key: String, cursor: uint (0), pattern: String (""), count: uint (0)) (uint, Array[String]) !Error
    // Walks every member of a set, a page at a time.
    + fn sscan_iter(key: String, pattern: String (""), count: uint (0)) ScanIterator
    // Returns the length of the value of a key, or 0 when it does not exist.
    + fn strlen(key: String) uint !Error
    // Subscribes to channels. Read what arrives with `next_message`.
    + fn subscribe(channels: Array[String]) void !Error
    // Returns the members of all of `keys` together.
    + fn sunion(keys: Array[String]) Array[String] !Error
    // Stores the members of all of `keys` in `to` and returns how many there are.
    + fn sunionstore(to: String, keys: Array[String]) uint !Error
    // Returns the Unix time of the server in seconds.
    + fn time() uint !Error
    // Returns the seconds a key still has to live, -1 when it has no lifetime and -2 when it does not exist.
    + fn ttl(key: String) int !Error
    // Returns the type of a key: `string`, `list`, `set`, `zset`, `hash`, `stream`, or `none` when it does not exist.
    + fn type_of(key: String) String !Error
    // Unsubscribes from channels, or from every channel when none are given.
    + fn unsubscribe(channels: Array[String] (.{})) void !Error
    // Stops watching every watched key.
    + fn unwatch() void !Error
    // Watches keys for the next transaction: when any of them changes before `exec`, the transaction does not run and `exec` returns null.
    + fn watch(keys: Array[String]) void !Error
    // Acknowledges entries, so that the group stops counting them as pending.
    + fn xack(key: String, group: String, ids: Array[String]) uint !Error
    // Adds an entry to a stream and returns its id.
    + fn xadd(key: String, fields: Map[String], id: String ("*"), maxlen: uint (0), approximate: bool (true)) String !Error
    // Takes pending entries over for another consumer, when the one that holds them has not acknowledged them for `min_idle_ms`.
    + fn xclaim(key: String, group: String, consumer: String, min_idle_ms: uint, ids: Array[String]) Array[StreamEntry] !Error
    // Removes an entry and returns whether it was there.
    + fn xdel(key: String, id: String) bool !Error
    // Creates a consumer group on a stream.
    + fn xgroup_create(key: String, group: String, id: String ("$"), create_stream: bool (true)) bool !Error
    // Removes a consumer group and returns whether it was there.
    + fn xgroup_destroy(key: String, group: String) bool !Error
    // Returns how many entries a stream holds.
    + fn xlen(key: String) uint !Error
    // Returns what a group still owes: how many entries are pending, and who holds them.
    + fn xpending(key: String, group: String) PendingSummary !Error
    // Returns the entries between two ids, oldest first.
    + fn xrange(key: String, start: String ("-"), end: String ("+"), count: uint (0)) Array[StreamEntry] !Error
    // Reads entries added after the ids given, from one or more streams.
    + fn xread(streams: Map[String], count: uint (0), block_ms: uint (0), block: bool (false)) Array[StreamEntries] !Error
    // Reads entries for one consumer of a group.
    + fn xreadgroup(group: String, consumer: String, streams: Map[String], count: uint (0), block_ms: uint (0), block: bool (false), no_ack: bool (false)) Array[StreamEntries] !Error
    // Returns the entries between two ids, newest first. `start` is the higher id here.
    + fn xrevrange(key: String, start: String ("+"), end: String ("-"), count: uint (0)) Array[StreamEntry] !Error
    // Trims a stream to `maxlen` entries and returns how many were removed.
    + fn xtrim(key: String, maxlen: uint, approximate: bool (true)) uint !Error
    // Adds a member to a sorted set, or changes its score, and returns whether it is new.
    + fn zadd(key: String, score: float, member: String) bool !Error
    // Adds several members with their scores and returns how many are new.
    + fn zadd_many(key: String, members: Map[float]) uint !Error
    // Returns how many members a sorted set has.
    + fn zcard(key: String) uint !Error
    // Returns how many members have a score between `min` and `max`.
    + fn zcount(key: String, min: String ("-inf"), max: String ("+inf")) uint !Error
    // Adds `amount` to the score of a member and returns its new score.
    + fn zincr_by(key: String, amount: float, member: String) float !Error
    // Takes the member with the highest score off the set, or null when it is empty.
    + fn zpopmax(key: String) ?ScoredMember !Error
    // Takes the member with the lowest score off the set, or null when it is empty.
    + fn zpopmin(key: String) ?ScoredMember !Error
    // Returns the members between two positions, lowest score first.
    + fn zrange(key: String, start: int (0), stop: int (-1), reverse: bool (false)) Array[String] !Error
    // Returns the members with a score between `min` and `max`, lowest score first.
    + fn zrange_by_score(key: String, min: String ("-inf"), max: String ("+inf"), offset: uint (0), count: uint (0)) Array[String] !Error
    // The same as `zrange_by_score`, with the score of every member.
    + fn zrange_by_score_with_scores(key: String, min: String ("-inf"), max: String ("+inf"), offset: uint (0), count: uint (0)) Array[ScoredMember] !Error
    // The same as `zrange`, with the score of every member.
    + fn zrange_with_scores(key: String, start: int (0), stop: int (-1), reverse: bool (false)) Array[ScoredMember] !Error
    // Returns the position of a member, counted from the lowest score, or null when it is not in the set.
    + fn zrank(key: String, member: String) ?uint !Error
    // Removes a member and returns whether it was there.
    + fn zrem(key: String, member: String) bool !Error
    // Removes the members between two positions and returns how many were removed.
    + fn zrem_by_rank(key: String, start: int, stop: int) uint !Error
    // Removes the members with a score between `min` and `max` and returns how many were removed.
    + fn zrem_by_score(key: String, min: String ("-inf"), max: String ("+inf")) uint !Error
    // Removes several members and returns how many were there.
    + fn zrem_many(key: String, members: Array[String]) uint !Error
    // Returns the position of a member, counted from the highest score.
    + fn zrevrank(key: String, member: String) ?uint !Error
    // Reads one page of a sorted set, as members with their scores.
    + fn zscan(key: String, cursor: uint (0), pattern: String (""), count: uint (0)) (uint, Array[ScoredMember]) !Error
    // Returns the score of a member, or null when it is not in the set.
    + fn zscore(key: String, member: String) ?float !Error
}
```

```js
// A message from a channel this connection is subscribed to.
+ class Message {
    // The channel the message was published to.
    + channel: String
    // What was published.
    + data: String
    // `message` for a channel, `pmessage` for one that matched a pattern, and `smessage` for a sharded channel.
    + kind: String
    // The pattern that matched, for a `pmessage`, and "" otherwise.
    + pattern: String
}
```

```js
// What a consumer group still owes: how many entries are pending and who holds them.
+ class PendingSummary {
    // How many entries each consumer holds.
    + consumers: Map[uint]
    // How many entries were delivered and not acknowledged.
    + count: uint
    // The highest pending id, or "" when nothing is pending.
    + highest: String
    // The lowest pending id, or "" when nothing is pending.
    + lowest: String
}
```

```js
// Several commands sent in one go.
+ class Pipeline {
    // How many commands are waiting to be sent.
    ~ count: uint

    // Adds a command. Nothing is sent until `exec`.
    + fn add(args: Array[String]) Pipeline
    // Throws away the commands that were added but not sent.
    + fn clear() void
    // Sends every command added so far and returns their replies in order.
    + fn exec() Array[Value] !Error
}
```

```js
// A set of connections that are opened once and handed out as they are needed.
+ class Pool {
    // Whether `get` checks an idle connection with a `PING` before handing it out, which costs a round trip and catches a connection the server closed in the meantime.
    + check_on_get: bool
    // The settings new connections are opened with.
    + config: Config
    // How many connections are handed out at this moment.
    ~ in_use: uint
    // The greatest number of connections that may exist at one time, idle and handed out together. 0 is no limit.
    + max_connections: uint
    // How many idle connections are kept. Connections given back beyond this are closed.
    + max_idle: uint
    // How many connections the pool has: idle plus handed out.
    ~ size: uint
    // How long `get` waits for a connection to come back when the pool is at its limit, in milliseconds. It throws `timeout` after that; 0 waits forever.
    + wait_timeout_ms: uint

    // Closes every idle connection. Connections that are handed out are left alone and close when they are given back.
    + fn close_idle() void
    // Takes a connection out of the pool, opening one when none is idle.
    + fn get() Connection !Error
    // Creates a pool. No connection is opened until the first `get`.
    + static fn new(config: Config, max_connections: uint (16), max_idle: uint (8)) Pool
    // Gives a connection back.
    + fn put(con: Connection) void
}
```

```js
// Walks the keys of a database, or the members of a set, one page at a time.
+ class ScanIterator {
    // Returns everything that is left in one array.
    + fn all() Array[String] !Error
    // Returns the next key or member, or null at the end.
    + fn next() ?String !Error
}
```

```js
// One member of a sorted set with its score.
+ class ScoredMember {
    // The member.
    + member: String
    // Its score.
    + score: float
}
```

```js
// A Lua script that is sent to the server once and then run by its SHA-1.
+ class Script {
    // The SHA-1 of the source, which is the name the server knows it by.
    ~ sha: String
    // The Lua source.
    + source: String

    // Creates a script. Nothing is sent to a server until it runs.
    + static fn new(source: String) Script
    // Runs the script and returns its reply.
    + fn run(con: Connection, keys: Array[String] (.{}), args: Array[String] (.{})) Value !Error
}
```

```js
// Where to find a primary through Sentinel.
+ class SentinelConfig {
    // Whether the connection is checked with `ROLE` before it is handed back, so that a sentinel that named a replica is not mistaken for the primary.
    + check_role: bool
    // The database to select on the primary.
    + db: uint
    // The name the sentinels watch the primary under.
    + master_name: String
    // The password of the primary, or "" when it has none.
    + password: String
    // The protocol to speak with the primary: 2 or 3.
    + protocol: uint
    // The password of the sentinels themselves, if they ask for one.
    + sentinel_password: String
    // The sentinels, as `host:port`, tried in the order they are given.
    + sentinels: Array[String]
    // How long connecting to a sentinel or to the primary may take, in milliseconds.
    + timeout_ms: uint
    // TLS for the primary, or null.
    + tls: ?TlsOptions
    // The ACL user of the primary, or "" to log in with the password alone.
    + username: String
}
```

```js
// The entries one stream returned from `xread` or `xreadgroup`.
+ class StreamEntries {
    // The entries, oldest first.
    + entries: Array[StreamEntry]
    // The stream these entries came from.
    + stream: String
}
```

```js
// One entry of a stream: its id and its fields.
+ class StreamEntry {
    // The fields of the entry.
    + fields: Map[String]
    // The id, as `<milliseconds>-<sequence>`.
    + id: String
}
```

```js
// TLS settings for a connection.
+ class TlsOptions {
    // A directory of certificate authorities to trust, instead of the system bundle.
    + ca_dir: ?String
    // A PEM file with the certificate authorities to trust, instead of the system bundle.
    + ca_file: ?String
    // The name to check the certificate against, and to send as SNI. Empty uses the host that was connected to.
    + host: String
    // Whether the certificate of the server is checked.
    + verify: bool
}
```

```js
// A reply from the server, or one item of a reply.
+ class Value {
    // The first word of an error reply, such as `WRONGTYPE`, or the three letter format of a verbatim string, such as `txt`. Empty for every other kind.
    + code: String
    // The parts of an `array`, `set`, `push` or `map` reply, null otherwise. A `map` keeps its keys and values as one flat list: key, value, key, value, ...
    + items: ?Array[Value]
    // Which of the kinds this value is.
    + type: TYPE

    // Returns the number of items of an aggregate reply, or 0 for every other kind.
    + get count: uint
    // Returns the item at `index`. Backs `value[0]`.
    + fn get(index: uint) Value !LookupError
    // Returns whether this reply holds several items (`array`, `set`, `map` or `push`).
    + fn is_array() bool
    // Returns whether this is an error reply. Only replies nested in an array can be errors; a command that fails throws `server` instead.
    + fn is_error() bool
    // Returns whether this is the null reply.
    + fn is_null() bool
    // Returns a null value, what the server sends for a missing key.
    + static fn null() Value
    // Returns a string value, what most replies are.
    + static fn of(text: String) Value
    // Returns an array value holding `items`.
    + static fn of_array(items: Array[Value]) Value
    // Returns a bool value.
    + static fn of_bool(value: bool) Value
    // Returns a floating point value.
    + static fn of_float(number: float) Value
    // Returns an integer value.
    + static fn of_int(number: int) Value
    // Returns the items of an aggregate reply, or an empty array.
    + fn to_array() Array[Value]
    // Returns the value as a bool: a RESP3 bool as it is, `OK` and any number other than 0 as true, null and everything else as false.
    + fn to_bool() bool
    // Returns the value as a float; text is parsed, null is 0.
    + fn to_float() float
    // Returns the value as an integer; text is parsed, floats are truncated, null is 0.
    + fn to_int() int
    // Returns every item as an integer.
    + fn to_ints() Array[int]
    // Parses the value as JSON. Returns json null when the text is not valid JSON.
    + fn to_json() Value
    // Reads a field/value reply, such as `HGETALL` or `CONFIG GET`, as a map.
    + fn to_map() Map[Value]
    // Returns the value as text: the bytes of a string reply, the digits of a number, `1` or `0` for a bool, the message of an error, and "" for null and for aggregates.
    + fn to_string() String
    // The same as `to_map`, with the values as text.
    + fn to_string_map() Map[String]
    // Like `to_string`, but null for the null reply, which is how a missing key is told apart from an empty one.
    + fn to_string_or_null() ?String
    // Returns every item as text. Null items become "".
    + fn to_strings() Array[String]
    // Returns every item as text, keeping null items as null. `MGET` uses this.
    + fn to_strings_or_null() Array[?String]
    // Returns the value as an unsigned integer; negative numbers become 0.
    + fn to_uint() uint
}
```
