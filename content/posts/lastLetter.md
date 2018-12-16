+++
title = "Koping with KDB 007: Last-Letter Game!"
description = "last letter periodic table"
tags = [ "kdb", "q", "last", "letter", "periodic", "table" ]
date = "2018-12-01"
location = "Glasgow, UK"
categories = [
  "q",
  "kdb"
]
slug = "lastLetter"
type = "post"
+++

##### Estimated reading time: 15 minutes

It was only a matter of time before I got around to good ol' text-based games. In this case, it's the Last Letter game at its simplest: you pick a word `w`<sub>1</sub>, your opponent picks a word `w`<sub>2</sub> that starts with `w`<sub>1</sub>'s last letter, then you pick `w`<sub>3</sub> that starts with `w`<sub>2</sub>'s last letter and so on. Our domain for this post is the periodic table. 

Here's an outline of how the game will be played:

```
The program picks a random element
If no pick is possible for you
    The program declares victory
Else
    You pick an element
    If your pick satisfies the game's rule
        The program attempts another pick
        If no pick is possible
            The program concedes to you
        Else
            The program makes the next pick
    Else
        The program refuses your pick
        You have to make another pick
```

## Where goeth my variables?

As Jessica Jones says, let's start at the beginning. Technically, the game will commence the moment the user loads up the program script (i.e., the `.q` file). Hence, the script will need to set the stage for the game - to wit, load all the elements of the periodic table into a list and pick a random element from that list. Loading all elements into a list should be simple enough, or so I thought.

```
begin:{
    elements: `oxygen`nitrogen`cadmium;
}

begin[] /running the function

elements
-> `elements
```

Err, why doesn't `elements` exist? Because it only exists inside `begin`: it's a local variable. How can we un-local-variable it? Perhaps we could define `elements` outside `begin`:

```
elements: `$() \empty symbol list
begin:{
    elements: `oxygen`nitrogen`cadmium;
}

begin[]

elements
-> `symbol$()
```

Nope, the `elements` variable that exists outside `begin` is not the same as that which gets created inside `begin`! It's time to introduce the [**global assign `::`**][global-assign] operator.

```
elements: `$()
begin:{
    elements:: `oxygen`nitrogen`cadmium;
}

begin[]

elements
-> `oxygen`nitrogen`cadmium
```

---

As an aside, note that the presence of the semi-colon at the end of the `begin` function results in its output being suppressed. If the semi-colon were removed and if `begin` were called again, the function would have returned the contents of `elements` to the console.

---

The `::` operator performs the following idempotent operation: if the variable to its left already exists, override its value. Otherwise, create it and assign it the value to the right of the operator. What happens if, for whatever reason, we have another `elements` variable defined in `begin` too?

```
elements: `$()
begin:{
    elements: `$();
    elements:: `oxygen`nitrogen`cadmium;
}

begin[]

elements
-> `$()
```

[Smeg][smeg]. In such a case, the global assign doesn't really do a global assign: it overrides the value of the variable local to the function within which it is called. 

While `::` would certainly work for us in the current situation, it's cleaner to define our variables in a [**namespace**][namespaces].

## A space for names

In simple terms, a namespace in Q is implemented as a dictionary that binds names to values. Such a dictionary is often called a **context**. A context may contain variables or nested contexts. In the following code snippet we are creating a `.game` context and binding the variable name `elements` to a list of 3 elements from the periodic table:

```
.game.elements: `oxygen`nitrogen`cadmium

.game.elements
-> `oxygen`nitrogen`cadmium
```

It's not mandated to begin the name of a context with a period but I like to use it as an easy way to distinguish context and variable names. 

If `.game` is truly a dictionary then we should be able to key into it:

```
.game[`elements]
-> `oxygen`nitrogen`cadmium
```

Take solace, JS developers.

Once we define a context with a variable in a .q file we can reference the variable anywhere within the file provided we use the variable's fully qualified name - in our case: `.game.elements`.

```
begin:{ .game.elements:`oxygen`nitrogen`cadmium; }
pickFirst:{ .game.elements 0 }

begin[]
pickFirst[]
-> `oxygen

```

Onwards!

## Random pickings

For the game to start, our program needs to pick an element at random. This is easily done using the `rand` keyword:

```
begin[]
rand .game.elements:
-> `oxygen
rand .game.elements:
-> `cadmium
```

Is it, though? Kx Systems says the following on [randomness][randomness]: *"Deal, rand, roll, and permute use a constant seed on q invocation: scripts using them can be repeated with the same results. You can see and change the value of the seed by using system command "\S".)"*

Hmm, what does **constant seed** mean? Does it mean the seed value is the same on each `q` invocation? Only one way to find out:

```
q \begin q session from the command prompt
\S
-> -314159i
exit 0 \close q session

q
\S
-> -314159i
```

Looks like it. So, do we wrap up and go home? Nope, we could always change the seed before we get our program to pick a random element. Something like this should do:

```
updateSeed:{ system "S ",string "i"$.z.T; }
```

Looking for `\S`, are you? Turns out, we can use system commands in that form at the `q` prompt but not inside `q` expressions:

```
q
\S 5
\S
-> 5i

updateSeed:{\S 5}
-> `\
```

Instead, we need to prefix the system command with "system " and drop the backward slash:

```
updateSeed:{ system "S ",string "i"$.z.T; }
updateSeed[]
\S
-> 64595546i
```

The expression `.z.T` returns the current time in the form `hh:mm:ss.uuu` where `uuu` represents millisesconds. The expression `"i"$`, in turn, converts the current time down to its equivalent milliseconds since midnight. Technically, `"i"$` is equivalent to Integer.parseInt() in Java - the `i` suffix represents 32-bit signed integer values. The interger value, though, needs to be converted to a string because the `system` function expects a string value that contains both the command ("S") and its argument(s). Finally, note that we're using the `join (,)` operator to concatenate the string `"S "` with the output from `string "i"$.z.T`.

Taken as a whole, the expression sets the current seed to the number of milliseconds since midnight. We now have enough to get our program to pick a random element and return it to the console.

## Showing the pick

Our `begin` function looks something like this:

```
begin:{
    updateSeed[];
    .game.elements: `oxygen`nitrogen`cadmium;
}
```

Picking a random element from `.game.elements` is easy:

```
begin:{
    updateSeed[];
    .game.elements: `oxygen`nitrogen`cadmium;
    .game.picked: rand .game.elements;
}
```
This works insofar as picking a random element is concerned. How do we print the picked element to the console? The last expression in any KDB function is the return statement. Hence, we could do something like this:

```
begin:{
    updateSeed[];
    .game.elements: `oxygen`nitrogen`cadmium;
    .game.picked: rand .game.elements;
    "I pick ",string .game.picked;
}

begin[]
-> "I pick oxygen"
```

Alright! Next, we can write up a simple function to check whether the current pick has resulted in a winning position. The current pick is a winning pick if there are no more elements left that can fulfil the last-letter rule.

```
isWin:{
    :`=findLast[.game.picked];
};

findLast:{[element]
    lastLetter:last string element;
    :rand .game.elements[where (string .game.elements) like lastLetter,"*"]
}
```

Ok, two functions. The `findLast` function uses the `where` function to get a list of indices of elements in `.game.elements` that start with the current pick's last letter. Note the round brackets around `string .game.elements`: `q` is evaluated from right-to-left and without the brackets the expression `.game.elements like lastLetter,"*"` would have been evaluated before the `string` function. 

If `lastLetter`'s value were `"n"` then the `where` expression would evaluate to `where (string .game.elements) like "n*"`. In our limited list of elements, the expression should return `nitrogen`:

```
.game.elements
-> `oxygen`nitrogen`cadmium
.game.elements[where (string .game.elements) like "n*"]
-> ,`nitrogen
```

Strictly speaking, we don't really need the `rand` function inside `findLast`: all we need to determine is whether **any** element is left in `.game.elements` that fulfils the last-letter rule. However, using `rand` here means we can re-use the `findLast` function when the program needs to pick the next element based on the human user's selection.

## Still picking

We can now have a `pick` function for our program to start off the game:

```
pick:{
    .game.picked: rand .game.elements;
    .game.elements: remove[.game.picked];
    $[isWin[];
        "I pick", (string .game.picked), ". There is no element left that begins with ", (last string .game.picked), ". I win!";
        "I pick ", string .game.picked
    ]
}

remove:{[element] 
    :.game.elements[where .game.elements<>element]
}
```

Wondering what `<>` is? It's the `not equal` operator. The pick function will now be called from within the `begin` function:

```
begin:{
    updateSeed[];
    .game.elements: `hydrogen`helium`lithium`beryllium`boron`carbon`nitrogen`oxygen`
    :pick[]
}

begin[]
-> "I pick beryllium. There is no element left that begins with m. I win!"
begin[]
-> "I pick hydrogen"
```

## Your turn

It's time to deal with the human user's turn now. Going back to our outline:

```
You pick an element
    If your pick satisfies the game's rule
        The program attempts another pick
        If no pick is possible
            The program concedes to you
        Else
            The program makes the next pick
    Else
        The program refuses your pick
        You have to make another pick
```

Let's create a function that the human user will need to invoke in order to submit their pick. The function will take a single string argument - the user's pick:

```
turn:{[element]
    elementSymbol:`$element;
    /Is the user's pick valid?
}
```

The expression ``$element` converts the user's pick - which will be provided as a string - to a symbol. This is needed because we store all elements as symbols in `.game.elements`. 

Hmm, we need an expression to determine whether the user's pick is a valid one: whether it starts with the computer's pick's last letter. It may be cleaner to put such an expression into a separate function. Let's call it `isValidChoice`:

```
isValidChoice:{[element] 
    :((last string .game.picked)=first string element) & element in .game.elements
}
```

Quite an eyeful. Let's break it down from right-to-left:

* `element in .game.elements`: This expression will return true if the user's pick is present in `.game.elements`. In other words, if the user has picked a valid element.
* `(last string .game.picked)=first string element`: This expression will return true if the user's pick's first letter is the same as the program's pick's last letter. Again, we need the round brackets to force `q` to evaluate the expression `last string .game.picked` as a whole. 

Here's our `turn` function:

```
turn:{[element] 
    elementSymbol:`$element;
    $[isValidChoice elementSymbol;
        [
            .game.elements: remove[elementSymbol];
            n:findLast[elementSymbol];
            $[`=n;
                message:"I can't find any element that begins with ", (last element), ". You win!";
                message:pickNext[n]
            ];
        ]; 
        message:"Please pick an element that starts with ",(last string .game.picked), "."
    ];
    :message;
}

pickNext:{[element] 
    .game.picked: element;
    .game.elements: remove[element];
    $[isWin[];
        "I pick ", (string .game.picked), ". There is no element left that begins with ", (last string .game.picked), ". I win!";
        "I pick ", string .game.picked
    ]
}
```

It looks like we have everything we need for our game to run! Let's give it a go.

## Game-ium time

The `.q` file for the game can be found [here][last-letter-script-file]. Notice something weird about the code in the file? The little space before the closing curly bracket for every function definition? That space is needed because within a function definition in `q` every line needs to be indented even if the line contains nothing more than a closing curly bracket. If we were to leave the space out then `q` would not recognise the end of the function.

To load the file simply start a `Q` session - for convenience you can first `cd` to the directory where your .q file is located - and then run `\l [fileName]`.

```
q
\l last-letter-periodic-table.q
-> "I pick tenessine"
```

Alright! Let's play:

```
turn "einsteinium"
-> "I pick molybdenum"
turn "mercury"
-> "I pick ytterbium"
turn "manganese"
-> "I pick europium"
turn "magnesium"
-> "I pick meitnerium"
turn "moscovium"
-> "I pick mendelevium. There is no element left that begins with m. I win!"
```

Smeg. At least the game works. Here's another run:

```
-> "I pick neon"
turn "niob"
-> "I pick barium"
turn "manganese"
-> "I pick erbium"
turn "mendelevium"
-> "I pick magnesium"
turn "moscovium"
-> "I pick mercury"
turn "yttrium"
-> "I pick meitnerium"
turn "munchium"
-> "Please pick an element that starts with m."
turn "molybdenum"
-> "I can't find any element that begins with m. You win!"
```

Good, although it's unfortunate that a lot of the elements' names end in "m". The good thing is we can always replace the list of elements with a list from a completely different domain.

[global-assign]: https://code.kx.com/q4m3/6_Functions/#632-assigning-global-variables-within-a-function
[smeg]:https://en.wikipedia.org/wiki/List_of_Red_Dwarf_concepts#Smeg
[namespaces]: https://code.kx.com/q4m3/12_Workspace_Organization/#121-namespaces
[randomness]: https://code.kx.com/q/ref/random/#setting-the-seed1
[last-letter-script-file]: https://github.com/alifaizankazmi/codingWithoutCoffee/blob/master/content/code/last-letter-periodic-table.q