+++
author = "Sugu Sougoumarane"
published = 2017-09-18T07:15:00-07:00
slug = "2017-09-18-custom-sharding-with-vitess"
tags = []
title = "Custom Sharding With Vitess"
+++
<span
id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"></span>  

<span id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Vitess
supports a variety of predefined sharding algorithms that can suit
different needs. This is achieved by associating a **Vindex** with your
main sharding column. A Vindex essentially provides a mapping function
that converts your column value to a **keyspace\_id**. This keyspace\_id
is then used to decide the target shard.</span></span>

<span
id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"></span>  

<span id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">A
full description of VSchema and Vindexes can be found
[here](http://vitess.io/user-guide/vschema/)</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
However, such predefined vindexes will work only if you intend to shard
your system using Vitess. What if you're already sharded? Would it be
possible to make Vitess accommodate your sharding scheme? This blog
intends to cover such a use case.</span></span>

<span
id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"></span>

<span id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Vitess
is indeed capable of accommodating any sharding scheme because of its
pluggable Vindex API. In fact, all the predefined vindexes of Vitess are
plug-ins themselves. In order for Vitess to accommodate your sharding
scheme, all you have to do is define a Vindex that performs such a
mapping.</span></span>

<span
id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"></span>

<span id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span></span>

<span
id="docs-internal-guid-fdb68ccf-911f-c313-d3aa-a8cf02e0bfe4"></span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Use Case</span>
-------------------------------------------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The
following example is inspired from my conversations with [Simon
Mudd](https://github.com/sjmudd) of [Booking.com](http://booking.com/),
who had a database that was already sharded 4-way using a mod-based
scheme. Given an input column, say </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">user\_id</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">,
Booking.com’s sharding function yields values from 0-3, which decides
the target shard for each request.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">To
make a Vindex work for the above use case, you have to do two
things:</span>

1.  <span
    style="font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Assign
    keyranges to each of your shards</span>

2.  <span
    style="font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Define
    a Vindex that maps the input to a keyspace\_id such that it falls in
    the corresponding keyrange.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">In
Vitess, a keyspace id can be any binary string. For simplicity, let’s
restrict our keyspace ids to be the big-endian representation of a
64-bit number. If so, they will have a fixed length of 8 bytes. If we
were to uniformly split such keyspace ids into four shards, they would
be as follows:</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">keyrange (last value excluded)</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">abbreviated</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0x0000000000000000-0x4000000000000000</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">-40</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0x4000000000000000-0x8000000000000000</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">40-80</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0x8000000000000000-0xC000000000000000</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">80-C0</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0xC000000000000000-(highest number)</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">C0-</span>
</div></td>
</tr>
</tbody>
</table>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Now,
all we have to do is provide a function that generates a keyspace id
such that it remaps the mod function into this wider space. In the above
case, it could be achieved with the following expression: </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">(user\_id%4)&lt;&lt;62</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
The keyranges assigned to the original shards will be as follows:</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">shard</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">keyranges</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">-40</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">1</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">40-80</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">2</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">80-C0</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">3</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">C0-</span>
</div></td>
</tr>
</tbody>
</table>




<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Once
you have provided this Vindex, the application can go back and forth
between legacy code and Vitess because they should both route queries
the same way. After gaining confidence in the new system, you can fully
migrate to using Vitess.</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>



<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">How to reshard</span>
-------------------------------------------------------------------------------------------------------------------------------------

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Because
of the expanded set of possible keyspace ids, many strategies can be
adopted. The end goal is to produce more distinct numbers than the
original scheme in such a way that they continue to map to the same
shards.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Let's
see what it takes to go from 4 to 8 shards. These can be represented as:
</span><span
style="font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;"><span
style="font-family: &quot;courier new&quot; , &quot;courier&quot; , monospace;">-20-40-60-80-A0-C0-E0-</span></span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">With
this shard layout, a simple </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">user\_id%8&lt;&lt;61</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">
will not work. This is because the numbers produced by this function
will not fall in the same shard range as the ones produced by the \`mod
4’ function. Here is an illustration:</span>



<span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">user\_id%4&lt;&lt;62</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">input</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">%4</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0001</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">&lt;&lt; 62</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0100...0000</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Hex</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0x40...</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Mapped</span>
</div>
<div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Keyrange</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; font-weight: 700; vertical-align: baseline; white-space: pre-wrap;">40-80</span>
</div></td>
</tr>
</tbody>
</table>



<span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">user\_id%8&lt;&lt;61</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">input</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">%8</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">&lt;&lt; 61</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">1010...0000</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Hex</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0xA0...</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Mapped</span>
</div>
<div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Keyrange</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; font-weight: 700; vertical-align: baseline; white-space: pre-wrap;">80-C0 (different shard)</span>
</div></td>
</tr>
</tbody>
</table>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">For
things to work correctly, the new mapping function must yield values
that land in the same keyrange as before, which is not the case in the
above example.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">One
could devise a complicated bit-manipulation algorithm that generates new
values in a way that is backward compatible with the old function. One
such function would be: </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">(user\_id%4)&lt;&lt;62
+ ((user\_id&gt;&gt;2)%2)&lt;&lt;61)</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
While the original function generated two material bits, the new
function will generate three material bits. But the original two
material bits will be as before. For example, if the original function
produced </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">10…</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">,
the new function would produce </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">100…</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">
or </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">101…</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
This means that you can replace the original function with the new one,
and this function would work for four as well as eight shards.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Verifying
the correctness of the above formula is left as an exercise to the
reader.</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The
problem with this approach is that the formula gets progressively more
complex every time you reshard.</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The ReverseBits Strategy</span>
-----------------------------------------------------------------------------------------------------------------------------------------------



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">There
is a simpler approach: if we looked more closely at how the mod function
worked, it essentially truncates the more significant bits of the input
number. What if, instead of shifting the bits, we reversed them? The new
function would instead be: </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits(user\_id%4)</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
With this function, the original shard mappings will be different (1 & 2
will be swapped):</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">shard</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">original</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">new</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">-40</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">-40</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">1</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">40-80</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">80-C0</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">2</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">80-C0</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">40-80</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">3</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">C0-</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">C0-</span>
</div></td>
</tr>
</tbody>
</table>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The
advantage of this approach is that it later allows us to change the
vindex to </span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits(user\_id%8)</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
This would produce numbers that are backward compatible with the mod 4
scheme, but will produce twice the number of distinct output values.
Here is a repetition of the above example using the new
functions:</span>



<span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits(user\_id%4)</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">input</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">%4</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0001</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">1000...0000</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Hex</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0x80...</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Mapped</span>
</div>
<div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Keyrange</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; font-weight: 700; vertical-align: baseline; white-space: pre-wrap;">80-C0</span>
</div></td>
</tr>
</tbody>
</table>



<span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits(user\_id%8)</span>



<table>
<tbody>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">input</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">%8</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0000...0101</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">&lt;&lt; 62</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">1010...0000</span>
</div></td>
</tr>
<tr class="even">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Hex</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">0xA0...</span>
</div></td>
</tr>
<tr class="odd">
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Mapped</span>
</div>
<div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Keyrange</span>
</div></td>
<td><div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; font-weight: 700; vertical-align: baseline; white-space: pre-wrap;">80-C0 (pre-shard)</span>
</div>
<div style="line-height: 1.2; margin-bottom: 0pt; margin-top: 0pt;">
<span style="font-family: &quot;courier new&quot;; font-size: 11pt; font-weight: 700; vertical-align: baseline; white-space: pre-wrap;">A0-C0 (post-shard)</span>
</div></td>
</tr>
</tbody>
</table>




<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The
next obvious question is: why mod at all? What if we just used
</span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits(user\_id)</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">?
It turns out that this would also work. There was really no need to
perform the mod in the first place. Once you’ve transitioned to using
</span><span
style="font-family: &quot;courier new&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">ReverseBits</span><span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">,
you can shard at will from any number to any number. Over time, you can
forget that you ever used mod-based sharding.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">The
sample code for the above Custom Vindex is </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">available
here</span>](https://gist.github.com/sougou/96e40aa54526447ae0b24d50ae8ea4a8)<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">.
This Vindex is handy enough that we will look at adding it to the Vitess
list of predefined vindexes.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Can
you think of other ways to perform such migrations? Join us on our Slack
channel to share your ideas. You can send an email to </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">vitess@googlegroups.com</span>](mailto:vitess@googlegroups.com)<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">
to request an invite.</span>



<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">Happy
Sharding!</span>

<span
style="font-family: &quot;arial&quot;; font-size: 11pt; vertical-align: baseline; white-space: pre-wrap;">  
</span>
