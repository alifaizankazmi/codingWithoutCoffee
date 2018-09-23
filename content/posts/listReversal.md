+++
title = "Koping with KDB 001: List Reversal"
description = "list reversal"
tags = [ "kdb", "q", "list", "reverse" ]
date = "2018-09-22"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "listreversal"
type = "post"
+++

One of the first rules I learned when studying kdb+ was that the Q/kdb+ interpreter evaluates expressions from right to left, even though expressions are typed left-to-right. For instance, the result of the following expression:

    1*2+3

is `5`, since the addition operator and its operands are evaluated first and the result of the addition in turn becomes the second operand for the * operator.

Sound simple enough? I certainly thought so, until my forehead landed on my palm a few minutes later. 

## Recursion?

I was attempting to define a simple function that would return true if it were passed a list as its argument:

    isList: {[object] type object = 7h}

A breakdown of the above follows for the uninitiated:

* : is the assignment operator
* A function definition is encapsulated in curly brackets
* A function's parameters are encapsulated in square brackets inside the function definition
* = is the equality operator (since : takes care of assignment)
* Each datatype in kdb is represented by a special 16-bit integer. In this case, we want the integer that represents the list datatype - 7h (well, [not exactly] [code-kx-datatypes]).

Back to our function definition. If, like me, you didn't immediately notice what was wrong then here it is: the expression

    type object = 7h

is evaluated right-to-left, which means the expression is not performing the intended type check at all! From right to left, this expression contains two inner expressions evaluated in the following order:

    object = 7h
    type

So, `object = 7h` evaluates to a boolean value (`0b` or `1b`) which is then served as the argument to the type function. No wonder, then, that we get the following result when we invoke our function with a list of numbers:

    isList 1 2 3
    -1h

`-1h` is the numerical representation of the boolean datatype.

Here is the corrected version of the function:

    isList: {[object] 7h = type object}

Which gives us the expected result when invoked with a list of numbers:

    isList [1 2 3]
    1b

Why do I want such a function, you ask? Because I would like to ultimately define a function that takes a list as an argument and returns another list with its elements in the reverse order. Since kdb has no loops, one way we could achieve a list reversal is via recursion and for recursion to work (or, more precisely, to stop!) we need a base case. In this example, the base case would be the point where we have reduced the provided list to its last element. 

## Really? Recursion?

Wait, do we really need recursion? Given that Q is an array programming language (among other things), could we not just pass a list of indices as an argument to our list in order to obtain a new reversed list? Of course, we'll need to make sure the list of indices is in reverse, too. But that shouldn't be difficult. We can make use of the `til` function:

    til 3
    0 1 2

The function can be used to obtain a list of valid indices by using the `count` function:

    list: 1 2 3
    til count list
    0 1 2

Now, if we can reverse the list of indices then our problem should be solved:

    list 2 1 0
    3 2 1

The following is one strategy to reverse this list:

* The maximum valid index is `-1 + count list` (Am I the only one who came up with `count list - 1` first?)
* Subtracting a list of indices that is sorted in ascending order from the maximum valid index will yield a list that contains the same indices in reverse

In our case:

    indices: til count list
    2 - indices
    2 1 0

Great, now we need to wrap up all of this into a function. We can't name our function `reverse` since that name is already reserved (for a function the definition of which I'm too scared to find out just yet).

    reverseList: {
        [list] list (-1 + count list) - til count list
    }

This seems to work correctly:

    reverseList 1 2 3
    3 2 1

    reverseList "level"
    "level"
    reverseList 1 0 1
    1 0 1
    reverseList "Eva, can I stab bats in a cave?"
    "?evac a ni stab bats I nac ,avE"

Apologies, I got carried away with palindromes.

    reverseList 110b
    011b
    reverseList `a`b`c
    `c`b`a
    reverseList 2018.09.23 2018.09.22 2018.09.21
    2018.09.21 2018.09.22 2018.09.23

## Is this good enough?

Hardly. Why should we have to create a new list (i.e., the list of indices in reverse) in order to reverse a given list? Also, I don't like having to use parantheses to force the evaluation of an expression first - a sign that I'm still wet behind the ears vis-à-vis Q's right-to-left evaluation. Perhaps I should take a stab at recursion after all, or find a better solution as I continue to study Q and slowly shed the yoke imperative/non-array programming paradigms.

[code-kx-datatypes]: http://code.kx.com/q/ref/datatypes/