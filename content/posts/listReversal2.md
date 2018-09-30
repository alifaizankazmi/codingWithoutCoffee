+++
title = "Koping with KDB 002: More List Reversal"
description = "list reversal"
tags = [ "kdb", "q", "list", "reverse" ]
date = "2018-09-29"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "listreversal2"
type = "post"
+++

##### Estimated reading time: 10 minutes

In the previous [post][list-reversal-first-post] we stopped short of applying recursion to reverse a list since we found a quirkier way to do it. Let's see if the use of recursion results in simpler code.

## Give me your `ifs`, your `elses`...

Yes, it is possible to control a Q script's execution using conditional evaluation, although it is discouraged: restructuring your code to avoid conditional evaluation is preferred whenever possible.

Available to us is the `if` statement:

    n: 1
    if[n=1;message: "I don't think this is useful to us"]

    message
    -> "I don't think this is useful to us"

The if statement evaluates a given condition (`n=1`) and if the condition evaluates to a value greater than 0 (which represents the boolean `false`) then any statements following the condition are executed in order from left to right. In our case, we are assiging the string `"I don't think this is useful to us"` to the variable `message`. As an aside, notice that the concept of scope doesn't apply here: the variable `message` is defined inside the `if` statement but continues to be accessible outside of it!

Yes, this doesn't fit our use case: if we are to use recursion, we also need an `else` clause - something like the following:

    if base case reached
        return
    else
        continue list reversal

## ...or just give me your ternaries

Q supports an equivalent of the ternary operator `?` available in languages such as Java, JavaScript and C#:

    $[1b;"Execute if true";"Execute if false"]
    -> "Execute if true"

    $[0b;"Execute if true";"Execute if false"]
    -> "Execute if false"

The first expression given to the `$` operator (`1b` or `0b`) is the condition to evaluate. If the condition evaluates to true then the second expression is executed, otherwise the third one is. If you want to execute multiple expressions for one condition then you can encapsulate your conditions in square brackets:

    $[1b;[a:2;b:3];c:4]
    a
    -> 2
    b
    -> 3

I think we know enough to proceed with reversing our list. Onwards to recursion!

## A simple`(`r`)` example

Before we apply recursion to our problem, we can try testing it on a simpler problem to make sure it works as expected. We can define a recursive function which keeps adding 1 to a given number until the number is equal to 6:

    recur: {[number] $[number=6;"Done";recur[1 + number]]}

Looks like it works!

    recur 1
    -> "Done"

Can we be sure that recursion is taking place, though? Since I'm not aware of the equivalent of `println` in Q, one way to make sure that recursion is in fact happening is to pass a number greater than 6 to the function. In languages like Java this should generate a stack overflow since the recursive function would keep on calling itself until there was no more space on the stack. That's exactly what happens here, too:

    recur 7
    -> `stack
    -> @
    -> {[number] $[number=6;"Done";recur[1 + number]]}
    -> 2008

No idea what the `@` and `2008` mean. I'll probably come back to how Q displays exceptions later (Q exceptions prefer to be addressed as "signals").

## Finally, recursion

No, wait. There's one more operation we need before we can construct our function: the `join` operator, used to join two lists. The operator is simply a comma:

    1 2 3,4 5 6
    -> 1 2 3 4 5 6

    1,2 3 4
    -> 1 2 3 4

Sorry, one more thing: we also need a way to reduce the size of the list with each recursive call until we're left with a list of one element. Enter the `cut` (`_`) operator:

    list: 1 2 3

    1 _ list
    -> 2 3

    -1 _ list
    -> 1 2

At long last, here's our function:

    reverseList: {[list] 
        $[1 = count list;
            list;
            reverseList[1 _ list],-1 _ list
        ]
    }

    reverseList 1
    -> 1
    reverseList 1 2
    -> 2 1
    reverseList 1 2 3
    -> 3 2 1 2

Uh-oh, the last result is clearly wrong. Why? Let's do a dry run:

    reverseList 1 2 3 -> call reverseList[2 3]
    reverseList 2 3 -> call reverseList 3
    reverseList 3 -> return 3
    reverseList 2 3 -> return 3 joined with 2
    reverseList 1 2 3 -> return 3 2 joined with 1 2

Therein lies the fault: it would've been more obvious if I had formulated a proper algorithm:

    Given a list L
    Its reverse is a reverse of the list t(L) 
        (where t denotes the tail - e.g., t(1 2 3) is 2 3) 
    Joined with h(L) 
        (where h denotes the head - e.g., h(1 2 3) is 1)
    The reverse of a list with one element is the list itself

In short, the last expression we passed to the `$` operator is wrong. We should've used the `take` (`#`) operator:

    list: 1 2 3
    1#list
    -> ,1

The comma before `1` is just a way of indicating that `1` is not a number: it is a single-item list.

Here goes nothing:

    reverseList: {[list] 
        $[1 = count list;
            list;
            reverseList[1 _ list],1#list
        ]
    }

    reverseList 1
    -> 1
    reverseList 1 2
    -> 2 1
    reverseList 1 2 3
    -> 3 2 1
    reverseList "A string is a list of characters"
    -> "sretcarahc fo tsil a si gnirts A"
    reverseList "Sigh of relief"
    -> "feiler fo hgiS"

## Detour: Q's `reverse`

I mentioned earlier that Q already has a `reverse` function. What does it look like? We can type the function name in the Q prompt to find out:

    reverse
    -> |:

Is `|:` considered one operator? Is it two? Why isn't there an argument in the function body? Is `|:` meant to precede a list or succeed it? So many questions. We could answer the last one:

    |: 1 2 3
    -> `

    1 2 3 |:
    -> 3 2 1

Since `|: 1 2 3` returns a signal, looks like the correct way to use `|:` is definitely the second one. A cursory look at the various Q operators doesn't yield any answers as to how `|:` is interpreted. Maybe it's an operator (or two operators) coming from `k`, a language upon which Q is based. I have no difficulty putting this off for later (apologies if you do!).

## Tail Recursion

Our recursive function isn't [tail-recursive][tail-recursion]. Let's try to change it into one. We need some sort of an accumulator which will keep a running state of the reversed sublist. Once we get to a list of one element, we will simply join that element with the reversed sublist and make it the new head of the list. The following is a dry-run to demonstrate what I mean:

    reverseList 1 2 3 -> call reverseList[2 3] with accumulator set to 1
    reverseList 2 3 -> call reverseList 3 with accumulator set to 2 1
    reverseList 3 -> end of list, return 3 joined with accumulator

Here's our tail-recursive function:

    reverseList: {[list;acc] 
        $[1 = count list;
            list,acc;
            reverseList[1 _ list;(1#list),acc]
        ]
    }

Tail recursion makes the function slightly more difficult to follow, but it does go easy on the stack.

    reverseList[1 2 3;()]
    -> 3 2 1
    reverseList[`a`b`c`d;()]
    -> `d`c`b`a

Notice the ugly `()` that we need to pass as the initial value of the accumulator - `()` denotes an empty list. We can clean up the function by hiding the `()` in an inner function:

    reverseList: {[list] reverseListInner[list;()]}
    reverseListInner: {[list;acc] 
        $[1 = count list;
            list,acc;
            reverseListInner[1 _ list;(1#list),acc]
        ]
    }

Our solution obviously isn't as succinct as Q's, but we did learn the `$`, `_`, and `#` operators along the way.

    reverseList 1 2 3
    -> 3 2 1
    reverseList 1
    -> ,1

Ugh, looks like our function returns a list of one item when it's passed that item as an argument. Not really what we want. We could handle that case in our outer function:

    reverseList: {[list] 
        $[1 = count list;
            list;
            reverseListInner[list;()]
        ]
    }

    reverseList 1
    -> 1
    reverseList 1 2 3
    -> 3 2 1

To sum up, here's our solution:

    reverseList: {[list] 
        $[1 = count list;
            list;
            reverseListInner[list;()]
        ]
    }
    reverseListInner: {[list;acc] 
        $[1 = count list;
            list,acc;
            reverseListInner[1 _ list;(1#list),acc]
        ]
    }

It's ugly to make the same check (`1 = count list`) in two places for different purposes, but I'll call it a day at this point.

[list-reversal-first-post]: https://codingwithoutcoffee.netlify.com/posts/listreversal/
[tail-recursion]: https://en.wikipedia.org/wiki/Tail_call