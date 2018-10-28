+++
title = "Koping with KDB 006: More Replace-All in a Table"
description = "replace all in kdb table"
tags = [ "kdb", "q", "table", "replace", "find" ]
date = "2018-10-28"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "replaceAll2"
type = "post"
+++

##### Estimated reading time: 15 minutes

In the [previous post][replace-all], I mentioned there was an alternative solution to this problem. Let's try it out.

## Angle of attack

Our previous solution involved breaking a table into its constituent rows - where each row is a Q dictionary. Another solution is to break a table into its constituent columns (not to be confused with **column names**) - where each column is a list.

To recap, given the following keyed table:

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

We can obtain a row using its key:

```
digimon `Agumon
-> specialty| Fire
   level    | Rookie
```

How do we obtain a column? Well, we can access one individual cell in a column like so:

```
digimon[`Agumon;`specialty]
-> `Fire
```

Wouldn't it be nice if we could use some sort of a wild-card for the row's key such that the key's value would be iteratively bound to the key of every row in the table? In other words, wouldn't it be nice if we could find a way to output all the values of a column? Enter [elision][elision].

## A fancy word for blanks

To **elide** a value (typically a key or an index) is to leave it blank. The following is an example of eliding a table row's key:

```
digimon[;`specialty]
-> name           |
   ---------------|-----
   Agumon         | Fire
   Seadramon      | Water
   Tentomon       | Nature
   Piedmon        | Darkness
   Gabumon        | Water
   MetalSeadramon | Water
```

Good. Our solution beckons.

## Some thinking required

Let's see how we can use a column-oriented approach to solve the problem we solved last time: replacing all occurrences of `Water` with `Ice`. Here's a stab at it in English:

```
For each column name c in table t
  Find c's list of values l
  For each value v in l
  If v is `Water
    Change v to `Ice
```

Once again, we'll try to come up with a solution that doesn't involve mutation. Note that there is a wrinkle since we're using a column-oriented approach: we need to be able to distinguish the key column from the non-key columns. After all, we wouldn't want our solution to change the table's keys! What's more, our solution needs to be applicable to both keyed and unkeyed tables.

## Show me the columns

Let's consider the `digimon` table alongside the following unkeyed table:

```
ut
-> c1 c2
   -----
   a  c
   c  d
   c  c
```

Since we need the list of values under each column, we'll have to obtain the column names for a given table to iterate over. The `cols` function can be used here:

```
cols ut
-> `c1`c2
cols digimon
-> `name`specialty`level
```

Ugh, note that the function returns the key column name for `digimon`. We need a way to remove that from the list. Enter the `value` function:

```
value digimon
-> specialty level
   ------------------
   Fire      Rookie
   Water     Champion
   Nature    Rookie
   Darkness  Mega
   Water     Rookie
   Water     Mega

cols value digimon
-> `specialty`level
```

Great. Let's define a function that will return a list of non-key columns for a given table:

```
getCols:{[table] 
  if[98h=type table; 
    :cols table
  ] 
  if[99h=type table; 
    :cols value table
  ]
}
```

`98h` is the datatype for an unkeyed table; `99h` for a keyed one (and also for a dictionary!). Also note that the `colon` (`:`) at the end of each `if` clause represents an explicit return value. Let's take our function for a spin:

```
getCols ut
-> `c1`c2
getCols digimon
-> `specialty`level
```

Good. Note that if we passed a dictionary to our function then it would attempt to invoke `cols value` on the dictionary and return a signal. Let's not worry about that for now.

## Gotta list 'em all!

Now we move on to obtaining a list of values for each column. Once again, we'll need to come up with a function that works for keyed as well as unkeyed tables. Let's play with an inline function first:


```
{x[;y]}[ut;] each getCols ut
-> a c c
   c d c
```

Here's what's happening: we're defining an inline function that takes two arguments: `x` being a table and `y` being the name of a column present in the table. The first argument is fixed with `[ut;]` and the second argument is provided using `each getCols ut`.

Does the same function work for `digimon`?

```
{x[;y]}[digimon;] each getCols digimon
-> (+(,`name)!,`Agumon`Seadramon`Tentomon`Piedmon`Gabumon`MetalSeadramon)!`Fire`..
   (+(,`name)!,`Agumon`Seadramon`Tentomon`Piedmon`Gabumon`MetalSeadramon)!`Rooki..
```

Great. I can't explain exactly what's happening here but I do know this: the inline function returns different data types for unkeyed and keyed tables respectively:

```
type ut[;`c1]
-> 11h / a symbol list
type digimon[;`specialty]
-> 99h /a table!
```

This is apparent if we invoke our inline function with a specific column name for each table:

```
ut[;`c1]
-> `a`c`c
digimon[;`specialty]
-> name           |
   ---------------| -----
   Agumon         | Fire
   Seadramon      | Water
...
```

What do we need to do to make sure the output of `digimon[;```specialty]` is a list? We just need to apply the `value` function on the result:

```
value digimon[;`specialty]
-> `Fire`Water`Nature`Darkness`Water`Water
```

Alright! So looks like what we need is a function that returns an iteration function appropriate for a table based on whether the table is keyed or unkeyed:

```
getIterator:{
  if[98h=type x; 
    :{x[;y]}
  ]
  if[99h=type x;
    :{value x[;y]}
  ]
}

getIterator ut
-> {x[;y]}
getIterator digimon
-> {value x[;y]}
```

Good. Next up: defining a simple replace function that works at the level of a list.

## Search and Replace

This should be simple enough:

```
replace:{[list;toReplace;replaceWith]
  {$[x=y;z;x]}[;toReplace;replaceWith] each list
}

replace[`a`b`c;`c;`cc]
-> `a`b`cc
```

Is that all? Not really. Since we're breaking up a table into a list of lists (one list per column) and transforming each list we'll also need to package the transformed lists into a table. We'll need to be careful about keyed and unkeyed tables again.

## Almost there

What we need to is something like this:

```
Given a list of transformed lists l
Create a dictionary d by pairing a list of column names c with l
If the original table o was keyed
  Flip d to create a table td
  Join td with o's key column to create t
  Key t on its first column
Else
  Flip d to create table t
```

It's easier to handle the case of an unkeyed table first:

```
tabulate:{[table;list]
  if[98h=type table;
    :flip(getCols table)!list
  ]
}
```

Notice that due to Q's right-to-left evaluation we need to encapsulate `getCols table` in round brackets so that its ouput serves as the list of keys for the dictionary that we're creating on the fly using the `bang` (`!`) operator. If we hadn't used square brackets then `table` would have been treated as the list of keys instead. After creating our on-the-fly dictionary, we're simply flipping it to create an unkeyed table. We can test our function by feeding it a mock list:

```
ut
-> c1 c2
   -----
   a  c
   c  d
   c  c

tabulate[ut;(`a`C`C;`C`d`C)] / mock list where `c is replaced with `C
-> c1 c2
   -----
   a  C
   C  d
   C  C
```

Great! So we can be sure that given a list (of lists) and an unkeyed table our function will spit out a new table that has the same columns as the input table and the same data as the input list.

Let's add some code to handle the case of a keyed table:

```
tabulate:{[table;list]
  if[98h=type table;
    :flip(getCols table)!list
  ]

  if[99h=type table;
    :1!(key obj)^flip (getCols table)!list
  ]
}
```

Ok, there's some new toys to unpack here:

* The `key` (`!`) operator is preceded with a positive integer `p` and succeeded with a table `t`. It returns a table `tp` that is keyed on the `p`th column (example provided below)
* The `coalesce` (`^`) operator is preceded and succeeded with two tables and it returns them merged. It's not necessary for the two tables to be of the same type (keyed or unkeyed)

Here's an example of using the `key` operator on our table `ut`:

```
1!ut
-> c2| c2
   --|---
   a | c
   c | d
   c | c
```

And here's an example of using the `coalesce` operator to merge two tables:

```
ut2:([] c3:`k`l`m; c4:`u`i`o)
ut^ut2
-> c1 c2 c3 c4
   -----------
   a  c  k  u
   c  d  l  i
   c  c  m  o
```

Let's take our `tabulate` function for a spin with the `digimon` table:

```
tabulate[digimon;(`Ice`Ice`Ice`Ice`Ice`Ice;`Mega`Mega`Mega`Mega`Mega`Mega)]
-> name          | specialty level
   --------------|----------------
   Agumon        | Ice       Mega
   Seadramon     | Ice       Mega
   Tentomon      | Ice       Mega
   Piedmon       | Ice       Mega
   Gabumon       | Ice       Mega
   MetalSeadramon| Ice       Mega
```

It works! Time to put the legos together.

## Watch your step

We have the following functions at our disposal:

```
getCols:{[table] 
  if[98h=type table; 
    :cols table
  ] 
  if[99h=type table; 
    :cols value table
  ]
}

getIterator:{
  if[98h=type x; 
    :{x[;y]}
  ]
  if[99h=type x;
    :{value x[;y]}
  ]
}

replace:{[list;toReplace;replaceWith]
  {$[x=y;z;x]}[;toReplace;replaceWith] each list
}

tabulate:{[table;list]
  if[98h=type table;
    :flip(getCols table)!list
  ]

  if[99h=type table;
    :1!(key obj)^flip (getCols table)!list
  ]
}
```

Something like this?

```
replaceAll:{[table;toReplace;replaceWith]
  tabulate[table;] replace[;toReplace;replaceWith] each (getIterator[table])[table;] each getCols table
}
```

That's an eyeful! We can refactor it to be more palatable:

```
replaceAll:{[table;toReplace;replaceWith]
  columns: getCols table;
  iterator: getIterator[table];
  transformed: replace[;toReplace;replaceWith] each iterator[table;] each columns;
  tabulate[table;transformed];
}

replaceAll[ut;`c;`cc]
-> c1 c2
   -----
   a  cc
   cc d
   cc cc

replaceAll[digimon;`Water;`Ice]
-> name          | specialty level
   --------------|-------------------
   Agumon        | Fire      Rookie
   Seadramon     | Ice       Champion
   Tentomon      | Nature    Rookie
   Piedmon       | Darkness  Mega
   Gabumon       | Ice       Rookie
   MetalSeadramon| Ice       Mega
```

Still an eyeful. This solution is a lot more verbose and complex compared to the previous one. But we did prove that an alternative solution exists and we picked up some new toys along the way.

[replace-all]:https://codingwithoutcoffee.com/posts/replaceall/
[elision]:https://code.kx.com/q4m3/3_Lists/#310-elided-indices