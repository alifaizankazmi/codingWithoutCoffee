+++
title = "Koping with KDB 003: Fibonacci Sequence"
description = "fibonacci sequence"
tags = [ "kdb", "q", "fibonacci", "numbers" ]
date = "2018-10-06"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "fibonacci"
type = "post"
+++

##### Estimated reading time: 7 minutes

The title says it all. Let's see if we can come up with a function to generate a portion of the Fibonacci sequence. 

## [Insert repetitive heading here]

Here's what we'll need:

* A running list `l` of Fibonacci numbers generated so far
* A conditional operator which will either return `l` upon reaching a terminating condition or add a number `n` to `l` where `n` is the sum of the previous two numbers in `l`

In the [previous post][list-reversal-second-post], we used the `$` operator for conditional evaluation and we also looked at the `#` operator for retrieving a given number of items from the start or end of a list:

    $[1b;"Execute if true";"Execute if false"]
    -> "Execute if true"

    $[0b;"Execute if true";"Execute if false"]
    -> "Execute if false"

    list: 1 2 3
    1#list
    -> ,1
    2#list
    -> 1 2
    -2#list
    -> 2 3

In addition, there's the handy `sum` function:

    sum list
    -> 6

A solution is already writing itself:

    fibonacci: {[list;counter] 
      $[counter=0;
        list;
        fibonacci[list,sum -2#list;counter-1]
      ]
    }

Initiating sequence:

    fibonacci[(0;1);0]
    -> 0 1
    fibonacci[(0;1);1]
    -> 0 1 1
    fibonacci[(0;1);2]
    -> 0 1 1 2
    fibonacci[(0;1);5]
    -> 0 1 1 2 3 5 8
    fibonacci[(0;1);20]
    -> 0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946
  
Looks like it works. Is that really it? We haven't really learned anything new!

## Meet our new friend: the loopy slash

Yes, that's not what it's officially called. The `/` is technically an **adverb**: adverbs are supposedly higher-order functions that can modify the behaviour of a given function, somewhat similar to how adverbs in the English language modify the meaning of adjectives or verbs. More on adverbs will follow in later posts. For now, the book **Q for Mortals** has a [nice example][q-for-mortals-fibonacci-example] that generates the Fibonacci sequence for us:

    10 {x,sum -2#x}/ 1 1
    -> 1 1 2 3 5 8 13 21 34 55 89 144

From the looks of it, the loopy slash is a triadic adverb. It requires (in order from left to right):

1. The number of times `n` that it should execute a function `f`
2. A function `f`, encapsulated in curly brackets
3. A variable upon which `f` is meant to be executed `n` times - in this case the list (1;1)

What is `x`, you say? It's an **implicit** parameter. If you define a function in Q without specifying any parameters, you are allowed to reference `x`, `y`, and `z` as the first, second, and third implicit parameters in the function body:

    {x+y+z} [1;2;3]
    -> 6

Not really my cup of tea: I like to know what a function parameter represents by looking at the parameter's name. But implicit parameters can certainly be useful in case a function's parameters are inferable from the function name.

## Some scrubbing required

Something's off about both solutions: no, I'm not referring to the fact that my solution considers 0 to be the first number in the Fibonacci sequence whereas the solution from **Q for Mortals** doesn't. What's off to me is this: I like to see the act of function invocation as a conversation between the programmer and the program. As such, both solutions aren't well-suited to answering the question: "What are the first `n` numbers of the Fibonacci sequence?" What I'm looking for is this:

    fibonacci 5
    -> 0 1 1 2 3

A quick makeover of our function (with some added guards) gives us the following:

    fibonacci: {[counter] 
      $[counter<=0;
        ();
        $[counter=1;
          enlist 0
          fibonacciInner[(0;1);counter-2]
        ]
      ]
    }

    fibonacciInner: {[list;counter]
      $[counter=0;
        list;
        fibonacciInner[list,sum -2#list;counter-1]
      ]
    }

Note the `counter-2` since 0 and 1 are already the 1st and 2nd Fibonacci numbers. Also, the `enlist` function simply takes an atom and adds that to an empty list. Re-initiating sequence:

    fibonacci[5]
    -> 0 1 1 2 3
    fibonacci[10]
    -> 0 1 1 2 3 5 8 13 21 34

## A different question

What if I had a slightly different question: "Is `x` a Fibonacci number?"

One solution to the problem would look something like this: 

* Generate the next Fibonacci number `->` `f`<sub>`n`</sub>
* If `f`<sub>`n`</sub> = `x`, return "Yes!"
* If `f`<sub>`n`</sub> > `x`, return "No :("

Here's a first crack at a solution in Q:

```
isFibonacci: {[number;list] 
  $[number=last list;
    "Yes!"
    $[number<last list;
      "No :(";
      isFibonacci[number;list,sum -2#list]
    ]
  ]
}
```

The handy `last` function simply returns the last element of a given list.

```
isFibonacci[1;(0;1)]
-> "Yes!"
isFibonacci[2;(0;1)]
-> "Yes!"
isFibonacci[4;(0;1)]
-> "No :("
isFibonacci[5;(0;1)]
-> "Yes!"
isFibonacci[10946;(0;1)]
-> "Yes!"
```

Ugh, we shouldn't have to pass in the initial list (0;1) - but that can easily be cleaned up. One more thing that smells: why should we have to keep a list of **all** Fibonacci numbers at a given point in time? All we really need to keep are the last two numbers of the sequence in order to keep the recursive calls going. That's easily done:

```
isFibonacci: {[number;list] 
  $[number=last list;
    "Yes!"
    $[number<last list;
      "No :("
      isFibonacci[number;(last list),sum -2#list]
    ]
  ]
}
```

We have another problem - an edge-case:

```
isFibonacci[0;(0;1)]
-> "No :("
```

Here's the function (inelegantly) modified to cater to the edge case:

```
isFibonacci: {[number;list] 
  $[(number=0) or number=last list;
    "Yes!"
    $[number<last list;
      "No :("
      isFibonacci[number;(last list),sum -2#list]
    ]
  ]
}
```

```
isFibonacci[0;(0;1)]
-> "Yes!"
isFibonacci[1;(0;1)]
-> "Yes!"
isFibonacci[2;(0;1)]
-> "Yes!"
isFibonacci[4;(0;1)]
-> "No :("
isFibonacci[5;(0;1)]
-> "Yes!"
isFibonacci[10946;(0;1)]
-> "Yes!"
```

Yeah, that works for me.

[list-reversal-second-post]: https://codingwithoutcoffee.com/posts/listreversal2/
[q-for-mortals-fibonacci-example]: https://code.kx.com/q4m3/1_Q_Shock_and_Awe/#112-example-fibonacci-numbers