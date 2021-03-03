---
author: "Sugu Sougoumarane"
published: 2017-09-18T07:15:00-07:00
slug: "2017-09-18-custom-sharding-with-vitess"
tags: []
title: "Custom Sharding With Vitess"
---

Vitess supports a variety of predefined sharding algorithms that can suit different needs. This is achieved by associating a **Vindex** with your main sharding column. A Vindex essentially provides a mapping function that converts your column value to a **keyspace_id**. This keyspace_id is then used to decide the target shard.

A full description of VSchema and Vindexes can be found
[here](http://vitess.io/user-guide/vschema/). However, such predefined vindexes will work only if you intend to shard your system using Vitess. What if you're already sharded? Would it be
possible to make Vitess accommodate your sharding scheme? This blog
intends to cover such a use case.

Vitess is indeed capable of accommodating any sharding scheme because of its pluggable Vindex API. In fact, all the predefined vindexes of Vitess are plug-ins themselves. In order for Vitess to accommodate your sharding scheme, all you have to do is define a Vindex that performs such a mapping.

### Use Case

The following example is inspired from my conversations with [Simon
Mudd](https://github.com/sjmudd) of [Booking.com](http://booking.com/), who had a database that was already sharded 4-way using a mod-based scheme. Given an input column, say `user_id`, Booking.com’s sharding function yields values from 0-3, which decides the target shard for each request.

To make a Vindex work for the above use case, you have to do two
things:

1. Assign keyranges to each of your shards
2. Define a Vindex that maps the input to a `keyspace_id` such that it falls in the corresponding keyrange.

In Vitess, a keyspace id can be any binary string. For simplicity, let’s restrict our keyspace ids to be the big-endian representation of a 64-bit number. If so, they will have a fixed length of 8 bytes. If we were to uniformly split such `keyspace ids` into four shards, they would be as follows:

| keyrange (last value excluded)        | abbreviated |
|---------------------------------------|-------------|
| 0x0000000000000000-0x4000000000000000 | -40         |
| 0x4000000000000000-0x8000000000000000 | 40-80       |
| 0x8000000000000000-0xC000000000000000 | 80-C0       |
| 0xC000000000000000-(highest number)   | C0-         |


Now, all we have to do is provide a function that generates a keyspace id
such that it remaps the mod function into this wider space. In the above
case, it could be achieved with the following expression: `(user_id%4)<<62`.The keyranges assigned to the original shards will be as follows:

| shard | keyranges |
|-------|-----------|
| 0     | -40       |
| 1     | 40-80     |
| 2     | 80-C0     |
| 3     | c0-       |

Once you have provided this Vindex, the application can go back and forth between legacy code and Vitess because they should both route queries the same way. After gaining confidence in the new system, you can fully migrate to using Vitess.

### How to reshard

Because of the expanded set of possible keyspace ids, many strategies can be adopted. The end goal is to produce more distinct numbers than the original scheme in such a way that they continue to map to the same shards.

Let's see what it takes to go from 4 to 8 shards. These can be represented as: `-20-40-60-80-A0-C0-E0-`.

With this shard layout, a simple `user_id%8<<61` will not work. This is because the numbers produced by this function will not fall in the same shard range as the ones produced by the `mod 4` function. Here is an illustration:

`user_id%4<<62`

| input           | 0000...0101 |
|-----------------|-------------|
| %4              | 0000...0001 |
| << 62           | 0100...0000 |
| Hex             | 0x40...     |
| Mapped Keyrange | **40-80**   |


`user_id%8<<61`

| input           | 0000...0101                 |
|-----------------|-----------------------------|
| %8              | 0000...0101                 |
| << 61           | 1010...0000                 |
| Hex             | 0xA0...                     |
| Mapped Keyrange | **80-C0 (different shard)** |


For things to work correctly, the new mapping function must yield values that land in the same keyrange as before, which is not the case in the above example.

One could devise a complicated bit-manipulation algorithm that generates new values in a way that is backward compatible with the old function. One such function would be: `(user_id%4)<<62 + ((user_id>>2)%2)<<61)`. While the original function generated two material bits, the new function will generate three material bits. But the original two material bits will be as before. For example, if the original function produced `10…`,
the new function would produce `100…` or `101…`. This means that you can replace the original function with the new one, and this function would work for four as well as eight shards.

Verifying the correctness of the above formula is left as an exercise to the reader.

The problem with this approach is that the formula gets progressively more complex every time you reshard.

### The ReverseBits Strategy

There is a simpler approach: if we looked more closely at how the  od function worked, it essentially truncates the more significant bits of the input number. What if, instead of shifting the bits, we reversed them  The new function would instead be: `ReverseBits(user_id%4)`. With this function, the original shard mappings will be different (1 & 2 will be swapped):

| shard | original | new   |
|-------|----------|-------|
| 0     | -40      | -40   |
|  1    | 40-80    | 80-C0 |
| 2     | 80-C0    | 40-80 |
| 3     | C0-      | C0-   |

The advantage of this approach is that it later allows us to change the vindex to `ReverseBits(user_id%8)`. This would produce numbers that are backward compatible with the mod 4 scheme, but will produce twice the number of distinct output values. Here is a repetition of the above example using the new functions:

`ReverseBits(user_id%4)`

| input           | 0000...0101 |
|-----------------|-------------|
| %4              | 0000...0101 |
| ReverseBits     | 1000...0000 |
| Hex             | 0x80...     |
| Mapped Keyrange | **80-C0**   |

`ReverseBits(user_id%8)`

| input           | 0000...0101                                  |
|-----------------|----------------------------------------------|
| %8              | 0000...0101                                  |
| << 62           | 1010...0000                                  |
| Hex             | 0xA0...                                      |
| Mapped Keyrange | **80-C0 (pre-shard)**<br>**A0-C0 (post-shard)** |

The next obvious question is: why mod at all? What if we just used `ReverseBits(user_id)`? It turns out that this would also work. There was really no need to perform the mod in the first place. Once you’ve transitioned to using `ReverseBits`, you can shard at will from any number to any number. Over time, you can forget that you ever used mod-based sharding.

This is now available as a predefined Vindex as [reverse_bits](https://github.com/vitessio/vitess/blob/master/go/vt/vtgate/vindexes/reverse_bits.go).

Can you think of other ways to perform such migrations? Join us on our Slack channel to share your ideas. You can send an email to [vitess@googlegroups.com](mailto:vitess@googlegroups.com)
to request an invite.

Happy Sharding!
