---
title: "How are shards named?"
shorten_nav_links: true
notoc: true
weight: 3
---

Shard names have the following characteristics:

- They represent a range, where the left number is included, but the right is not.
- Their notation is hexadecimal.
- They are left justified.
- A - prefix means: anything less than the RHS value.
- A - postfix means: anything greater than or equal to the LHS value.
- A plain - denotes the full keyrange.

An example of a shard name is `-80` and following the rules above this means:  `-80` == `00-80` == `0000-8000` == `000000-800000`

Similarly `80-` is not the same as `80-FF` because `80-FF` == `8000-FF00`. Therefore `FFFF` will be out of the `80-FF` range as `80-` means: ‘anything greater than or equal to `0x80`

A hash vindex produces an 8-byte number. This means that all numbers less than `0x8000000000000000` will fall in shard `-80`. Any number with the highest bit set will be >= `0x8000000000000000`, and will therefore belong to shard `80-`.
