+++
title = "Riffing with React 001: Tic-tac-toe"
description = "react tic tac toe"
tags = [ "react", "tic-tac-toe" ]
date = "2019-05-28"
location = "Glasgow, UK"
categories = [
  "react",
  "tic-tac-toe"
]
slug = "ticTacToe"
type = "post"
draft = "true"
+++

##### Estimated reading time: 10 minutes

Welcome to the first of a series of posts about my efforts to understand the React framework. For this post, I'll be going through the ["Intro to React" tutorial][react-tutorial]'s `Wrapping Up` section. This post assumes that you have already perused the earlier sections of the tutorial. Let's dig in!

## You are (here, here)

The following is an attempt to make the first improvement listed in the `Wrapping Up` section: __Display the location for each move in the format (col, row) in the move history list.__

Hmm, where is the best place to add such code? 

<sub>_(psst, you can get the source code for the tutorial [here][react-tutorial-source-code])</sub>_

It's probably best if the component that has knowledge of the square that the user clicked on is responsible for supplying the location for the "Go to..." buttons. Let's start at the top component: `Game`. It would be great if we could add our code right in the `render()` function since that function renders the "Go to..." buttons:

```
  render() {
    const history = this.state.history;
    const current = history[this.state.stepNumber];
    const winner = calculateWinner(current.squares);

    const moves = history.map((step, move) => {
      const desc = move ?
        'Go to move #' + move :
        'Go to game start';
      return (
        <li key={move}>
          <button onClick={() => this.jumpTo(move)}>
            {desc}
          </button>
        </li>
      );
    });
    ...
```

Hmm, we do have access to the squares here. But that's not really the information we want: we want to know the __move__ that led from one state of squares (i.e., the tic-tac-toe board at a given point in time, referred to as `squares` from now on) to the next. We could do a diff of two adjacent squares to find out the move that led from one to the next, but that doesn't seem worth the effort (I miss you, array programming languages). How about the `handleClick(i)` function instead?

```
  handleClick(i) {
    const history = this.state.history.slice(
      0, 
      this.state.stepNumber + 1
    );
    const current = history[history.length - 1];
    const squares = current.squares.slice();
    if (calculateWinner(squares) || squares[i]) {
      return;
    }
    squares[i] = this.state.xIsNext ? "X" : "O";
    this.setState({
      history: history.concat([
        {
          squares: squares
        }
      ]),
      stepNumber: history.length,
      xIsNext: !this.state.xIsNext
    });
  }
```

We definitely know the move inside this function, but this function obviously isn't rendering anything. So, the most we can do in this function as far as our objective is concerned is to add the location of the current move in the appropriate format to the component's state. This location can then be accessed in the component's `render()` function.

Let's do a quick test: we're now adding a __moveLocation__ field to our state - set to '(1, 1)' for now - in the `handleClick(i)` function:

```
this.setState({
  history: history.concat([
    {
      squares: squares,
      moveLocation: '(1, 1)',
    }
  ]),
  ...
```

And we're reading the field in the `render()` function:

```
render() {
  ...
  const moves = history.map((step, move)) => {
    const desc = move?
      'Go to move #' + move + ' ' + step.moveLocation:
      ...
  ...
```

This works!

<img src="/squares-location-test.PNG" style="width: 50%" />

Now that we know our approach works, we need to figure out how to get a two-dimensional location from an array index: even though we are showing squares in a 3x3 grid each square is still simply an item in an array.

This isn't so difficult: for a square in a 3x3 grid that has an index `i`, its column can be found by using the following expression:

```
i % 3 + 1 // '+ 1' to account for 0-based array indices
```

Looking at the moves in the board above, the expression yields the following results:

```
0 % 3 + 1 = 1
4 % 3 + 1 = 2
5 % 3 + 1 = 3
```

The expression to find the row from an index is as follows:

```
Math.floor(i / 3) + 1 // '+ 1' to account for 0-based array indices

Math.floor(0 / 3) + 1 = 1
Math.floor(4 / 3) + 1 = 2
Math.floor(5 / 3) + 1 = 2
```

A simple function emerges in the Game component:

```
getColAndRow(i) {
  return "(" + 
    (i % 3 + 1) + ", " + 
    (Math.floor(i / 3) + 1) + 
  ")";
}
```

This can now be plugged in place of our hard-coded '(1, 1)':

```
handleClick(i) {
  ...
  this.setState({
    history: history.concat([
      {
        squares: squares,
        location: this.getColAndRow(i),
      }
    ]),
  ...
```

Et voilà!

<img src="/squares-location-final.PNG" style="width: 50%" />

## Make a bold move

The next suggested improvement is: __Bold the currently selected item in the move list.__ This can be achieved with a little CSS styling inside [JSX][react-jsx]. The move list is rendered in the `Game` component's `render()` function:

```
render() {
  ...
  const desc = move ?
    'Go to move #' + move :
    'Go to game start';
    return (
      <li key={move}>
        <button onClick={() => 
          this.jumpTo(move)}>{desc}
        </button>
      </li>
    );
    ...
}
```

We have access to the `stepNumber` variable inside the function, so in order to render the current move in bold we should just have to set the style on our `button` element conditionally based on whether the `stepNumber` is equal to `move`. If, like me, you're not overly familiar with CSS styling in JSX you might be tempted to try the following:

```
render() {
  ...
  const className = this.state.stepNumber === move? "
    bold": ""; 
  //Assuming the relevant CSS class rule exists
  ...
  <button className={className]}...
  ...
}
```

Why is the attribute called `className` instead of `class`? Because `class` is a reserved keyword in Javascript: since JSX is an extension of Javascript it needs another keyword to disambiguate between a Javascript `class` and a CSS `class`.

While the code shown above would work, there is a more concise (albeit slightly unclean) way to achieve the same by using CSS properties inside JSX:

```
...
<button style={this.state.stepNumber === move? 
  {fontWeight: 'bold'}: {fontWeight: 'normal'}} 
  onClick={() => this.jumpTo(move)}>
    {desc}
</button>
...
```

Note that `fontWeight: 'bold'` and `fontWeight: 'normal'` are JSX expressions, hence they need to be enclosed in curly brackets.

<img src="/bold-move-initial.PNG" style="width: 32.85%" />
<img src="/bold-move-2.PNG" style="width: 32.85%" />
<img src="/bold-move-3.PNG" style="width: 32.85%" />

## Back to squares 1 to 9

Next up: __Rewrite Board to use two loops to make the squares instead of hardcoding them.__

This is how we are currently rendering the squares:

```
  render() {
    return (
      <div>
        <div className="board-row">
          {this.renderSquare(0)}
          {this.renderSquare(1)}
          {this.renderSquare(2)}
        </div>
        <div className="board-row">
          {this.renderSquare(3)}
          {this.renderSquare(4)}
          {this.renderSquare(5)}
        </div>
        <div className="board-row">
          {this.renderSquare(6)}
          {this.renderSquare(7)}
          {this.renderSquare(8)}
        </div>
      </div>
    );
  }
```

Given we're asked to use two loops, it stands to reason that the second loop will be nested inside the first: the first loop will create the three `div`s shown above and the second will create the squares. Something like this:

```
render() {
    let squareDivs = [];

    for(let col = 0; col < 3; col++) {
      let squareChildren = [];
      for(let row = 0; row < 3; row++) {
        const squareIndex = col * 3 + row;
        squareChildren.push(
          this.renderSquare(squareIndex)
          );
      }
      squareDivs.push(
        <div className="board-row">
          {squareChildren}
        </div>
        );
    }

    return (
      <div>
        {squareDivs}
      </div>
    );  
}
```

Yes, you can simply add JSX expressions to an array and pass the array to React (provided React knows how to render them)!

There is a problem though. If you run the code with the change shown above you'll see an error similar to the following:

*Warning: Each child in a list should have a unique "key" prop.%s%s See https://fb.me/react-warning-keys for more information.%s*

Now that we are passing an array to React, we need to make sure each JSX expression in the array has its `key` attribute set to a unique value. This applies to the `squareChildren` array __as well as__ the `squareDivs` array, which means we need to modify the `Board` component's `renderSquare(i)` function:

```
  renderSquare(i) {
    return (
      <Square
        key={i}
        value={this.props.squares[i]}
        onClick={() => this.props.onClick(i)}
      />
    );
  }
```

And also the `render()` function:

```
render() {
  ...
  squareDivs.push(
    <div className="board-row" key={col}>
      {squareChildren}
    </div>);
  ...
}
```

We're halfway through the suggested improvements! Sounds like a good place to take a break.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html
[react-tutorial-source-code]: https://codepen.io/gaearon/pen/gWWZgR?editors=0010
[react-jsx]: https://reactjs.org/docs/introducing-jsx.html