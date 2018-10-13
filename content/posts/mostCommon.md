+++
title = "Koping with KDB 004: Most Common Item"
description = "most common item"
tags = [ "kdb", "q", "item", "common", "list" ]
date = "2018-10-10"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "mostCommon"
type = "post"
+++

##### Estimated reading time: 10 minutes

The near-immortal code newbie's problem: to retrieve the most common item in a list - aka the **mode**. 

In algorithmic terms, a simple solution to the problem is to iterate through the list and store the count of each item. The item with the greatest count is, therefore, the mode. 

In terms of data structures, such a simple solution would use the quintessential **map** or **dictionary** - or any structure that supports pairing between a **key** (the item in our list) and a **value** (the item's count). Does KDB have dictionaries? Certainly.

## Bang (!)

A dictionary in KDB defines, as expected, an association between a list of keys and a list of values - where both lists are of the same size. That is also how a dictionary is physically stored in KDB: as two lists. Dictionaries are created using the `!` operator - read as **bang**. The operator is meant to be preceded with a list of keys and succeeded with a list of values:

```
1 2 3!`one`two`three
-> 1| one
   2| two
   3| three
```

Wondering what those backticks (`) are for? They represent the **symbol** datatype.

---
Symbols look a bit like strings but they are in fact not at all like strings: strings in KDB are stored as a list of characters whereas symbols are atomic. Also, two or more equivalent symbols point to the same location in memory. The following symbols are equivalent:

```
symbol1:`one
symbol2:`one
```
---

## Get/set while the getting/setting's good

Getting/setting a value for a key in a dictionary is pretty simple. To get the value for a key from a dictionary, simply pass the key to the dictionary in square brackets - a bit like invoking a function:

```
dictionary: 1 2 3!`one`two`three

dictionary[1]
-> `one
dictionary[2]
-> `two
```

To set a value for a key, pass the key to the dictionary in square brackets and set the value using the assignment operator (`:`):

```
dictionary[4]:`four
dictionary
-> 1| one
   2| two
   3| three
   4| four
```

## Loop me no loopings

We will need to iterate through all the items in a list for our solution to work. Thus far, we've achieved this using recursion. We also looked at the `over` (`/`) adverb in the [previous post][fibonacci]. So, which route do we take? Hint: we don't have to take either. Turns out, simply passing a list to a monadic function results in that function being invoked on each item of the list:

```
words:`one`two`three`three
string words /Convert each item to a string
-> "one"
   "two"
   "three"
   "three"

numbers:1 2 3 4
{x+2*x} numbers
-> 3 6 9 12
```

What if we defined a monadic function that accepts an atom and simply adds/updates the item's count in a dictionary?

```
dictionary:()!()
{dictionary[x]+:1} words
dictionary
-> one  | 1
   two  | 1
   three| 2
```
Alright! Now all we need to do is to find the key with the greatest count. Finding the maximum count is easy enough: we can use the `max` function:

```
max dictionary
-> 2
```

But we want to find the **key** which has the greatest count. Enter the `find (?)` operator:

```
dictionary?1
-> `one
dictionary?max dictionary
-> `three
```

Let's put it all together:

```
dictionary:()!()
getMode:{[list] 
  {dictionary[x]+:1} list;
  dictionary?max dictionary
}

getMode words
-> `three
getMode 1 2 3 3 4 5 6 6 6
-> 6
```

## Not clean enough

Why do we have to initialise `dictionary` outside `getMode`? The only purpose it serves is to help calculate the mode, nothing more. We should be initialising it inside the function. **N.B.:** If you're trying this out yourself, you can either start a new Q session to get rid of the `dictionary` variable or run:

```
delete dictionary from `.
```

More on namespaces later. For now, here's our updated function:

```
getMode:{[list] 
  dictionary:()!();
  {dictionary[x]+:1} list;
  dictionary?max dictionary
}

getMode words
-> `type
```

Say what? The function definition looks good, and the interpreter doesn't complain about the syntax. What's going on? The answer has to do with variable scoping: when we defined `dictionary` outside `getMode`, the variable was set up to be accessible to any function within the Q session. When we define `dictionary` inside `getMode` the variable only exists inside `getMode` - it's not even accessible inside the lambda function (`{dictionary[x]+:1}`) defined within `getMode`! 

If you're thinking how I figured this out simply by looking at ``type`: I didn't. I had help from a white knight KDB developer. Anyhow, one way to get around this is to make the lambda function binary so that it accepts a dictionary as well as a list of items:

```
{x[y]+:1;x}[()!();words]
-> one  | 1
   two  | 1
   three| 2
```

Note that now we need to enapsulate the parameters passed to our function within square brackets.

---
What happens if we omit the square brackets?

```
{x[y]+:1;x}()!();words
-> `two`three`two`one`two`two`two`one`three`three`one`three`three`three`one`one`...
```

Ugh, I need to call in the white knight again.

---

Here's our updated solution:

```
getMode:{[list] 
  dictionary:{x[y]+:1;x}[()!();list];
  dictionary?max dictionary
}

getMode words
`three
```

## What if I told you...

...that there is a function in Q which can be used instead of our lambda function, and which is likely optimised to deal with large lists? Meet the `group` function:

```
group words
-> one  | ,0
   two  | ,1
   three| 2 3
```

Don't give me that look. Yes, I know it returns a slightly different result: it returns a dictionary where the keys are the items from the list and the values are indices of where said keys occur in the list. We can still use this dictionary to find the most common key like so:

```
count each group words
-> one   | 1
   two   | 1
   three | 2
```

The `each` function takes the function preceding it and applies it to each item of the non-atomic object succeeding it. In this case, the `count` function is run on each key-value pair and the function operates on the value - which is the list of indices. If we hadn't used `each` then the `count` function would have counted the size of the dictionary:

```
count group words
-> 3
```

Here's our solution updated to use `group`:

```
getModeWithGroup:{[list] 
  dictionary:count each group list;
  dictionary?max dictionary
}

getModeWithGroup words
`three
```

## Crunching some numbers

I mentioned that the `group` function is likely optimised to deal with large lists. Time to back up that proposition - using the `time and space (\ts)` function:

```
\ts:1000 til 100000
-> 165 1048672
```

The `\ts` function returns the time taken to run the function (in milliseconds) followed by the space used during function execution (in bytes). The format is as follows:

`\ts:<number of times to execute><function to execute>`

Back to our number-crunching. First, we need to generate a large list using the `deal (?)` operator (nope, it's not the find operator in this context):

```
words:100000?`one`two`three
count words
-> 100000
```

The operator is preceded with the required size of the list and succeeded with a list of values to randomly pick from until the list is of the required size.

```
\ts:1000 getMode words
-> 9021 4718928

\ts:1000 getModeWithGroup words
-> 1572 2621680
```

Seems fairly conclusive: the `getModeWithGroup` function takes roughly 1/6th of the time taken by the `getMode` function and consumes almost half the space.

[fibonacci]: [https://codingwithoutcoffee.netlify.com/posts/fibonacci/]
[ascii-caterpillar]: [https://www.asciiart.eu/animals/insects/caterpillars]
[code-kx-generic-null]: [https://code.kx.com/wiki/Reference/ColonColon#::_.28generic_null.2Fglobal_amend.2Fcreate_view.2Fidentity_function.29]
