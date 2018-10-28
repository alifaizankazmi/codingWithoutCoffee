+++
title = "Koping with KDB 005: Replace-All in a Table"
description = "replace all in kdb table"
tags = [ "kdb", "q", "table", "replace", "find" ]
date = "2018-10-21"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "replaceAll"
type = "post"
+++

##### Estimated reading time: 15 minutes

Yes, tables exist in KDB. And we're going to find a way to replace all occurences of one value in a table with another. First, we need to learn how to create a table.

---
Thanks to [Alex Hayden][alex-hayden-linkedin] for suggesting this exercise and for going over the Q code that I came up with!

Those of you who are already familiar with `q-sql` and are not interested in finding alternative solutions to this problem: feel free to skip this post.

---

## Some Karpentry

How do you create a table? The answer depends on whether the table is **keyed** or **unkeyed** - or, in relational database lingo, whether the table has a primary key or not. Since I'm such a hopeless contrarian, I'll start by creating a keyed table. The decision is not arbitrary, though: once we know how to create a keyed table the syntax to create an unkeyed table can be easily derived.

Here's a way to create a table `kt` (short for "keyed table") which is keyed on column `k` and has two other columns `c1` and `c2`:

```
kt:([k:1 2 3 4] c1:`a`b`c`d; c2:`e`f`g`h)
kt
-> k| c1 c2
   -| -----
   1| a  e
   2| b  f
   3| c  g
   4| d  h
```

The following is a breakdown of the syntax:

1. The key column is encapsulated in square brackets - there can be multiple key columns
2. The syntax to define a column is the same as the syntax to define a named list
2. Column definitions are delimited using a semi-colon (where the term **definition** refers to the column's name and values)

How do we create an unkeyed table, then? If an unkeyed table is a table that is not keyed on any column then it stands to reason that such a table should either have:

* No key column definition - no square brackets
* Or its definition should contain an empty pair of square brackets to indicate the absence of a key column.

Option 1 goes out the window since without the square brackets it would be difficult to distinguish between the definition of an unkeyed table and that of a list of lists:

```
ut:(c1:`a`b`c`d; c2:`e`f`g`h)
ut
-> a b c d
   e f g h
```

Option 2 it is: here's our unkeyed table:

```
ut:([] c1:`a`b`c`d; c2:`e`f`g`h)
ut
-> c1 c2
   -----
   a  e
   b  f
   c  g
   d  h
```

## The Flip Side (of Dictionaries)

There's another way to create a table: by using the `flip` function on what's called a [column dictionary][code-kx-column-dictionary] -  in short, a dictionary where each key maps to a list and all the lists are of the same length:

```
dict: `col1`col2`col3!(`a`b`c`;`d`e`f;`g`h`i)
dict
-> col1| `a`b`c
   col2| `d`e`f
   col3| `g`h`i

table: flip dict
table
-> col1 col2 col3
   --------------
   a    d    g
   b    e    h
   c    f    i
```

Incidentally, the `flip` function also works in reverse - you can flip a table to get a column dictionary:

```
flip table / (╯°□°)╯︵ ┻━━━━━┻
-> col1| a b c
   col2| d e f
   col3| g h i
```

The function, in other words, is performing a [transposition][transpose].

## Playing Around

Let's see how we can query the contents of a table - one that stores information about [digimon][digimon]:

```
name     | specialty level
---------| ------------------
Agumon   | Fire      Rookie
Seadramon| Ice       Champion
Tentomon | Nature    Rookie
Piedmon  | Darkness  Mega
```

Does indexing work on a keyed table?

```
digimon 0
`type
```

Nope. It works on unkeyed tables, though:

```
ut:([] c1:`a`b`c; c2:`d`e`f)
ut 0
-> c1| a
   c2| d
```

How do we access individual rows in a keyed table, then? We use the row's **key**:

```
digimon[`Agumon]
-> specialty| Fire
   level    | Rookie
```

What's that? Oh, yes. Each individual row in a table is a dictionary that maps one or more column names to column values. That implies that we can narrow down on one particular column value of a table row, if we so choose:

```
digimon[`Agumon][`specialty]
-> `Fire
```

Q offers convenient syntax to eliminate the second pair of square brackets by [indexing at depth][code-kx-indexing-at-depth]:

```
digimon[`Agumon;`specialty]
-> `Fire
```

For what it's worth, the `find (?)` operator also works as expected in that it returns the key which corresponds to a value:

```
digimon[`Agumon]?`Rookie
-> level
```

## Still Playing Around

Given that each row in our table is a dictionary, overwriting a row should be as simple as performing an assignment on the row's key:

```
digimon[`Seadramon]: `specialty`level!`Air`Rookie
digimon
-> name     | specialty level
   ---------| ------------------
   Agumon   | Fire      Rookie
   Seadramon| Air       Rookie
   Tentomon | Nature    Rookie
   Piedmon  | Darkness  Mega
```

Good. What happens if we mischievously add a third key-value pair?

```
digimon[`Seadramon]: `specialty`level`age!`Air`Rookie`100
-> `length
```

Also good. No, wait. Looks like our table now has an `age` column even though we got a `length` signal! 

```
digimon
-> name     | specialty level  age
   ---------| --------------------
   Agumon   | Fire      Rookie 
   Seadramon| Air       Rookie
   Tentomon | Nature    Rookie
   Piedmon  | Darkness  Mega
```

We can remove it using the `delete` function:

```
delete age from digimon
-> name     | specialty level
   ---------| ----------------
   Agumon   | Fire      Rookie
   Seadramon| Air       Rookie
   Tentomon | Nature    Rookie
   Piedmon  | Darkness  Mega
```

This looks suspicious: running the `delete` function immediately displays the result of the function in the console. Usually, there is no explicit result returned to the console for an in-place modification. Did the underlying table actually change?

```
digimon
-> name     | specialty level  age
   ---------| --------------------
   Agumon   | Fire      Rookie
   Seadramon| Air       Rookie
   Tentomon | Nature    Rookie
   Piedmon  | Darkness  Mega
```

Nope. The function just returned a new table that didn't have the `age` column. In order to make the `delete` function perform an in-place delete we need to refer to the table name as a symbol:

```
delete `age from digimon
```

Don't ask me why. Maybe I'll be able to answer this later.

Back to overwriting. Can we overwrite-at-depth too?

```
digimon[`Seadramon;`specialty]: `Water
digimon
-> name     | specialty level
   ---------| ------------------
   Agumon   | Fire      Rookie
   Seadramon| Water     Rookie
   Tentomon | Nature    Rookie
   Piedmon  | Darkness  Mega
```

Convenient.

## No More Playing Around

Now we turn to our real problem: what if we had to replace all occurrences of `Water` in our table with `Ice`? No, there isn't just one Water digimon - I sneakily added a few more:

```
digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Rookie
   Seadramon      | Water     Champion
   Tentomon       | Nature    Rookie
   Piedmon        | Darkness  Mega
   Gabumon        | Water     Rookie
   MetalSeadramon | Water     Mega
```

Given that each row in the table is a dictionary, one solution would look something like this:

```
For each row r in table t
  Find column c which has a value of `Water
  If c found
    Set c's value to `Ice
```

Here's the thought expressed in Q:

```
replaceAll:{[row;toFind;replaceWith]
  keyForValue: row?toFind;
  $[`=keyForValue;
      row;
      [row[keyForValue]:replaceWith;row];
    ]
}
```

The equality check passed to the `$` operator basically translates to: "Is `keyForValue` an empty symbol (a single backtick)," which it would be if the `find` operator found no matches.

Does it work?

```
replaceAll[;`Water;`Ice] each digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Rookie
   Seadramon      | Ice       Champion
   Tentomon       | Nature    Rookie
   Piedmon        | Darkness  Mega
   Gabumon        | Ice       Rookie
   MetalSeadramon | Ice       Mega
```

Maybe. This is the first time we're using a **projection** - in simple terms, a function which has a subset of its arguments already specified. In our case, we specified the `toFind` and `replaceWith` arguments and left the `row` argument empty. This means the resulting function is a monadic one which requires only the `row` parameter - provided by the `each` function.

Note that this function does **not** modify the table itself. It returns a new table with all the necessary replacements. This is fine since I prefer to avoid mutation wherever possible.

But there is a problem. What happens if the value that we want to replace occurs more than once in the **same** row? In such a case, the `find` operator will only return the first occurence of the value!

```
ut:([] c1:`d`b`c; c2:`d`e`f)
replaceAll[;`d;`D] each ut
-> c1 c2
   -----
   D  d
   b  e
   c  f
```

I'm not aware of a way to make the `find` function return all matches instead of just the first one. We could replace it with a function of our own - perhaps one that operators on the value of a key-value pair. The function would simply check if the current value is the one we want to replace. If it is, then the function would return the replacement value. Otherwise, it would simply return the value itself. In Q-speak:

```
{$[x=y;z;x]}[;2;20] each `a`b`c`d!2 1 0 2
-> a| 20
   b| 1
   c| 0
   d| 20
```

I'll ignore the persistent voice in my head that says: "It works the first time? There must be something wrong with it!" Let's create a re-usable function and let the tests do the talking.

```
replaceAll:{[obj;toReplace;replaceWith]
  {$[x=y;z;x]}[;toReplace;replaceWith] each obj
}

digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Rookie
   Seadramon      | Water     Champion
   Tentomon       | Nature    Rookie
   Piedmon        | Darkness  Mega
   Gabumon        | Water     Rookie
   MetalSeadramon | Water     Mega

replaceAll[;`Water;`Ice] each digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Rookie
   Seadramon      | Ice       Champion
   Tentomon       | Nature    Rookie
   Piedmon        | Darkness  Mega
   Gabumon        | Ice       Rookie
   MetalSeadramon | Ice       Mega

replaceAll[;`Rookie;`Novice] each digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Novice
   Seadramon      | Water     Champion
   Tentomon       | Nature    Novice
   Piedmon        | Darkness  Mega
   Gabumon        | Water     Novice
   MetalSeadramon | Water     Mega
```

Does this also work if the same value occurs multiple times in the same row?

```
ut:([] c1:`d`b`c; c2:`d`e`f)
replaceAll[;`d;`dee] each ut
-> c1  c2
   -------
   dee dee
   b   e
   c   f
```

Good. Also note that the same function works for keyed and unkeyed tables.

What if the value that we want to replace doesn't exist in the table?

```
replaceAll[;`fiddle;`dee] each ut
-> c1 c2
   -----
   d  d
   b  e
   c  f
```

Also good. Is the behaviour consistent with keyed tables?

```
replaceAll[;`Ultimate;`Omega] each digimon
-> name           | specialty level
   ---------------| ------------------
   Agumon         | Fire      Rookie
   Seadramon      | Water     Champion
   Tentomon       | Nature    Rookie
   Piedmon        | Darkness  Mega
   Gabumon        | Water     Novice
   MetalSeadramon | Water     Mega
```

Also also good.

## Are We About Done Here?

Yes and no. There is an alternative solution I have in mind for this problem but this post is getting bloated (and I'm reminiscing about Digimon) so I'll save that for the next post. Thanks for sticking around. 

[alex-hayden-linkedin]:https://www.linkedin.com/in/alex-hayden
[code-kx-column-dictionary]:https://code.kx.com/q4m3/5_Dictionaries/#531-definition-and-terminology
[transpose]:https://en.wikipedia.org/wiki/Transpose
[digimon]:https://en.wikipedia.org/wiki/Digimon
[code-kx-indexing-at-depth]:https://code.kx.com/q4m3/3_Lists/#382-indexing-at-depth