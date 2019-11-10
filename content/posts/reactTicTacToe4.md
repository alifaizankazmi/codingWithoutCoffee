+++
title = "Riffing with React 004: "
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-10"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToe4"
type = "post"
+++

##### Estimated reading time: 5 minutes

Alright, with all that initial investment in setting up unit tests we can confidently make changes to the code without having to manually test the game for every change.

For this post, we're going to add the first two enhancements listed at the end of the [Intro to React tutorial][react-tutorial]:

1. Display the location for each move in the format (col, row) in the move history list.
2. Bold the currently selected item in the move list.

## You are (here, here)

What's the best place to record the location of a new move? Well, I don't think we have a choice: when the user clicks on a `Square`, the component's `onClick` event handler is called which runs the function passed to it in its props by the `Board` component, which itself has received the function from the `Game` component - namely, the `handleClick` function:

```
handleClick(i) {
    const history = this.state.history
        .slice(0, this.state.stepNumber + 1);
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

So, this is our enhancement's new home. Every time this function is called we will have access to the index of the `Square` that the user clicked. All we have to do is translate this index into a 2-dimensional address and save it to the component's state. The `render` function will then take care of displaying the address. How do we translate an index to a 2-dimensional address? This isn't so difficult: for a square in a 3x3 grid that has an index `i`, its column can be found by using the following expression:

```
i mod 3 + 1 // '+ 1' to account for 0-based array indices
```

So, for a board that had a diagonal of 3 X's from top-left to bottom-right the expression would yield the following results: 

```
0 mod 3 + 1 = 1
4 mod 3 + 1 = 2
8 mod 3 + 1 = 3
```

The expression to find the row from an index is as follows:

```
// '+ 1' to account for 0-based array indices
Math.floor(i / 3) + 1 
Math.floor(0 / 3) + 1 = 1
Math.floor(4 / 3) + 1 = 2
Math.floor(8 / 3) + 1 = 3
```

A simple function emerges in the Game component:

```
getDisplayLocation(index) {
  return "(" + 
    (index mod 3 + 1) + ", " + 
    (Math.floor(index / 3) + 1) + 
  ")";
}
```

Are you thinking what I'm thinking? I'm thinking how good it would be to get some Ben & Jerry's. But yes, I'm also thinking how good it would be to have some unit tests for this function. From our previous posts, we should already have some unit tests which should start failing the moment we hook this function up in the `render` function:

```
handleClick(i) {
  ...
  this.setState({
    history: history.concat([
      {
        squares: squares,
        location: this.getDisplayLocation(i),
      }
    ]),
  ...

render() {
  ...
  const moves = history.map((step, move)) => {
    const desc = move?
      'Go to move #' + move + ' ' + step.location:
      ...
  ...
```

Yes, they failed!

<img src="/game-test-location-fail.PNG" style="width: 75%" />

Looking at the error description of one of the tests, it's clear why:

<img src="/game-test-location-fail-desc.PNG" style="width: 75%" />

The tests can be easily fixed. Let's take our code for a manual run:

<img src="/game-location-1.PNG" style="width: 50%" />

<img src="/game-location-2.PNG" style="width: 50%" />

Looks good to me. And our test coverage is still 100%!

## Bold Moves

The next suggested enhancement is: __Bold the currently selected item in the move list.__ This can be achieved with a little CSS styling inside [JSX][react-jsx]. The move list is rendered in the `Game` component's `render()` function. We have access to the `stepNumber` variable inside the function, so in order to render the current move in bold we should just have to set the style on our `button` element conditionally based on whether the `stepNumber` is equal to `move`. If, like me, you're not overly familiar with CSS styling in JSX you might be tempted to try the following:

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

Note that `fontWeight: 'bold'` and `fontWeight: 'normal'` are JSX expressions hence they need to be enclosed in curly brackets.

Hmm, all our tests are still passing. This makes sense, since none of our tests is verifying any CSS styles. Let's do that. There's a few other libraries that provide convenient interfaces to verify CSS styles, but we're going to stick to the `props()` function provided by `enzyme` on the `ReactWrapper` object:

```
describe("Given the user clicks a square in a new Game", () => {
...
    it("the current move should be rendered in bold", () => {
        let lastMoveButton = 
            game.find('.game-info li button')
                .at(1);
        assert.equal(lastMoveButton.props().style.fontWeight, 
            'bold');
    });

    it("the first move should not be rendered in bold", () => {
        let firstMoveButton = 
            game.find('.game-info li button')
                .at(0);
        assert.equal(firstMoveButton.props().style.fontWeight, 
            'normal');
    });
```

The above takes care of the normal sequential flow of the game. We should also verify that if the user chooses to go back/forward in the moves list then the move that the user clicks on should be rendered in bold.

```
describe("Given a game with two moves", () => {
    const game = mount(<Game />);
    clickSquare(game, 0);
    clickSquare(game, 5);

    describe("When the user chooses to go back one move", () => {
    ...
        it("the selected move should be rendered in bold", () => {
            let selectedMoveButton = 
                game.find('.game-info li button')
                    .at(1);
            assert.equal(
                selectedMoveButton.props().style.fontWeight, 
                'bold');            
        });

        it("the latest move should not be rendered in bold", () => {
            let lastMoveButton =
                game.find('.game-info li button')
                    .at(2);
            assert.equal(
                lastMoveButton.props().style.fontWeight,
                'normal');
        });
    ...
```

All of our tests are green.

<img src="/move-bold-test.PNG" style="width: 25%" />

And the enhancement works on the game too:

<img src="/move-bold-1.PNG" style="width: 50%" />

<img src="/move-bold-2.PNG" style="width: 50%" />

This looks like a good place to stop.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html
[react-jsx]: https://reactjs.org/docs/introducing-jsx.html