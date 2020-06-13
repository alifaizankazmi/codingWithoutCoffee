+++
title = "Koping with KDB 008: ES6-style Template Literals in Q"
description = "q kdb es6 template literals"
tags = [ "q", "kdb", "es6", "template", "literals" ]
date = "2020-06-13"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb",
  "es6",
  "template",
  "literals"
]
slug = "qTemplateLiterals"
type = "post"
+++

##### Estimated reading time: 10 minutes

ES6 introduced the concept of _template strings_ or _template literals_ to Javascript. This made it easy to embed Javascript expressions within a string and to have the expressions evaluated at runtime. To take a trivial example, instead of having Javascript code like the following:

```
const name = "Aang";
const age = 112;

console.log("Hi, my name is " + name + " and I'm " + age + " years old");
```

You could reduce the cognitive load of all those pluses and quotes by having code like this instead:

```
console.log(`Hi, my name is ${name}, and I'm ${age} years old`);
```

Wouldn't it be nice if we could do the same in Q/kdb? Yes, it would be. Can it be done in Q/kdb? Why, yes, it can. 

## Opening up the Q toolbox

In order to process template strings in Q, we will need the following functionality from the language:

1. Parsing a given string to identify expressions enclosed in `${}`
2. Evaluating the expression, much like the `eval()` function in Javascript:

```
eval("1 + 1")
-> 2
```

The second piece of functionality can be achieved using the `value` function in Q:

```
x: 12
value "x"
-> 12
value "x + 12"
-> 24
```

What about the first one? Erm, there's some disappointment up ahead. Q has a function called `ssr` (short for `string-search-and-replace`) that can be used to replace parts of a string with another string. The following are some examples of how it can be used:

```
// simple string match (case-sensitive)
ssr["Aang is the Avatar";"a";"@"]
-> "A@ng is the Av@t@r"
// function execution on each simple string match
ssr["But Zuko is arguably cooler";"But";upper]
-> "BUT Zuko is arguably cooler"
// function execution on each regex match
ssr["And Iroh has a great story arc";"?o";upper]
-> "And IROh has a great STOry arc"
```

The last example seems to possess the seed of a solution for our problem. The `?` operator matches any single character preceding the `o` - in our case they are `r` and `t`. If we could use an operator that matched any number of characters then we could make use of it like so, assuming that operator was `*`:

```
x: 12
ssr["The value of x is ${x}.";"${*}";<function to evaluate string>]
```

The `*` operator is in fact used to match any number of characters when used with the `like` function:

```
"${someVariableName}" like "${*}"
-> 1b
```

But, and here's the disappointment I mentioned earlier, the operator doesn't work with the `ssr` function:

```
ssr["The value of x is ${x}.";"${*}";upper]
-> 'length
    [0] ssr["The value of x is ${x}.";"${*}";upper]
        ^
```

The [Kx Wiki][kx-ssr] leaves us this cryptic message about the use of `*` with `ssr`:

<img src="/q-ssr-regex.PNG" style="width: 90%" />

Ah well, back to the toolbox.

## Rummaging around

One other way to identify expressions enclosed in `${}` could be to split a string into a list of strings such that we can reason about items in the list. 

The `vs` function (short for `vector-from-scalar`) can be employed to split a string into a list of strings based on a delimiter:

```
"," vs "one,two,three"
-> "one"
  "two"
  "three"
```

We could use a two-step split to achieve a list of strings in a format that could help us distinguish string expressions from strings:

1. Split the string on `${`
2. Split each of the resulting strings on `}`

To take an example:

```
// Split the string on ${
"${" vs "The value of x is ${x}."
-> "The value of x is "
  "x}."
```

Using this split, we can identify that an item in the obtained list is a string expression if it contains `}`, which is the case for the last item in the list shown above. But we cannot call the `value` function on the item just yet, we'll need to run step 2 on each item of this list. We have two options:

1. Use the `each` iterator
2. Use the `each-both` (`'`) iterator 

Why consider `each-both` at all? Because of a little inconvenience with `each` - it has to accept a unary function:

```
// This will count the length of each string
// and return a list of lengths
count each ("Hello";"multi-verse")
-> 5 11
```

whereas `vs` is a binary function. If we try to invoke the function with an `each`, things fall apart:

```
"}" vs each "${" vs "The value of x is ${x}."
-> '
    [0] "}" vs each "${" vs "The value of x is ${x}."
                  ^
```

I said that `vs` is a binary function but that is not entirely true all the time. We can change it to a unary function by harnessing a [projection][projection]:

```
vs["}";] each "${" vs "The value of x is ${x}."
-> ,"The value of x is "
   (,"x";,".")
```

Note how we're calling `vs` differently now? We're using `bracket` notation this time whereas we were using what's called an `infix` notation before. By using bracket notation we're explicitly preventing Q's right-to-left interpreter from interpreting the token preceding `each` as a function - which was happening when the interpreter encountered `vs` to the left of `each` previously. Also note that we're binding `}` as the first argument to `vs` and leaving its second argument empty by terminating the function expression right after the semi-colon with `]`. The result is a unary projection that gets evaluated for each item of the string list.

It is more convenient to switch to the multi-valent form of `each`: `'`. This can be used in conjunction with an infix `vs` function call to achieve the same result as above:

```
"}" vs ' "${" vs "The value of x is ${x}."
-> ,"The value of x is "
   (,"x";,".")
```

## Eureka

The nested list that we've obtained has the following key properties:

1. Each item of the list will either be a single-item list or a two-item list.
2. If an item of the list is a single-item list, then we can be sure that is it __not__ a string expression - otherwise the second split would've caused it to split into two elements.
3. If an item of the list is a two-item list, then we can be sure that its first item is a string expression. This is because the string would've had the `}` delimiter before the second split. We can also be sure that the second (and last) item is __not__ a string expression because it would've followed the `}` delimiter before the second split.

These properties lead us to the following algorithm:

```
For each item i of the nested list l
    If i is a single-item list
        Return i
    If i is a two-item list
        e <- Evaluate the first item
        c <- Concatenate e with the second item
        Return c
Flatten the list
```

All of this can be achieved using a single-line of code in Q:

```
interpolate: {raze {$[1 < count[x];raze string[value[first[x]]],1_x;raze x]} each "}" vs ' "${" vs x}
```

But we can split it into multiple lines for easier readability:

```
interpolate:{
    firstSplit: "${" vs x;
    secondSplit: "}" vs ' firstSplit;
    : raze {$[1 < count[x];raze string[value[first[x]]],1_x;raze x]} each secondSplit
 }
```

Ok, I won't claim that it's any better. 

The following are examples of our function in action:

```
x: 22
interpolate "The value of x is ${x}"
-> "The value of x is 22"
.ak.x: 2
.tst.y: 4
z: 8
interpolate "${.ak.x} * 2 is ${.tst.y}. ${.tst.y} * 2 is ${z}"
-> "2 * 2 is 4. 4 * 2 is 8"
```

## Deconstruction

Here's what happens in the last line: we iterate through each item of the nested list. If the current item is a two-item list, then we evaluate the first string of the list using `value[first[x]]`, join it with the rest of the list using `1_x`, and then call `raze` to flatten the two-item list into a single string. If the item is a single-item list, then we just call `raze` on it to convert it from a list to a string. The following are examples of using `raze` in both ways:

```
raze ("one";"two")
-> "onetwo"
raze enlist "one"
-> "one
```

We have to make one final call to `raze` to flatten the outermost list - or what used to be the nested list stored in `secondSplit` - back into one string. Note the plethora of square brackets here:

```
raze string[value[first[x]]],1_x
```

This is a necessity due to the right-to-left nature of the Q interpreter. If we had left out the brackets to the `string` function like so:

```
raze string value[first[x]],1_x
```

then the join (`,`) operation between `value[first[x]]` and `1_x` would've yielded unexpected results based on the type of x:

```
x:1
1,"test"
-> 1
   "t"
   "e"
   "s"
   "t"
```

And the `string` function would've been executed in turn on the above result. Using square brackets for `string`, we forced the Q interpreter to only perform the join operation after the evaluated value had been converted to a string.

What if we left out the brackets to the `value` function, like so?

```
raze string[value first[x]],1_x
```

Turns out that's quite alright, since the order of operations is still the same as far as the join operation is concerned. In fact, we can even eliminate the square brackets for `first` for the same reason:

```
raze string[value first x],1_x
```

So the new shape of our function is as follows:

```
interpolate:{
    firstSplit: "${" vs x;
    secondSplit: "}" vs ' firstSplit;
    : raze {$[1 < count[x];raze string[value first x],1_x;raze x]} each secondSplit
 }
```

Are we using one too many razes? Yeah, I agree. Instead of first razing the inner list and then razing the outer list, we can combine `raze` with the `over` iterator to essentially accomplish a `fold`:

```
raze over ("one";("two";"three");"four")
-> onetwothreefour
```

This simplifies our function slightly:

```
interpolate:{
    firstSplit: "${" vs x;
    secondSplit: "}" vs ' firstSplit;
    : raze over {$[1 < count[x];string[value first x],1_x;x]} each secondSplit
 }
```

And achieves the same result:

```
.ak.x: 3
.tst.y: 6
z: 12
interpolate "${.ak.x} * 2 is ${.tst.y}. ${.tst.y} * 2 is ${z}"
-> "3 * 2 is 6. 6 * 2 is 12"
```

This works for other data types too, like dates and timestamps:

```
// .z.D and .z.P are system variables
// .z.D represents the current date (local)
// .z.P represents the current time (local), down to nanoseconds
interpolate "date: ${.z.D}, timestamp: ${.z.P}"
-> "date: 2020.06.13, timestamp: 2020.06.13D16:56:13.002316000"
```

There we have it: ES6-style template literals in Q.

[kx-ssr]: https://code.kx.com/q/basics/regex/
[projection]: https://code.kx.com/q/basics/application/