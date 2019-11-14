+++
title = "Riffing with React 005: More Enhancements"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-14"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToe5"
type = "post"
+++

##### Estimated reading time: 10 minutes

Let's do it to it. Keep a high signal-to-noise ratio. Get straight to the meat. Of the matter. Yes, ok.

We'll work on the following enhancements in this post, as listed in the [Intro to React tutorial][react-tutorial]:

1. Rewrite Board to use two loops to make the squares instead of hardcoding them.
2. Add a toggle button that lets you sort the moves in either ascending or descending order.

## Loop the loop

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
    let squareRows = [];

    for (let col = 0; col < 3; col++) {
        let squares = [];
        for (let row = 0; row < 3; row++) {
            const squareIndex = col * 3 + row;
            squares.push(
                this.renderSquare(squareIndex));
        }
        squareRows.push(
            <div className="board-row">
                {squares}
            </div>);
    }

    return (
        <div>
            {squareRows}
        </div>
    );
```

Yes, you can simply add JSX expressions to an array and pass the array to React (provided React knows how to render the items in the array)!

There is a problem though. If you run the code with the change shown above you'll see an error similar to the following:

<img src="/loop-key-error.PNG" />

Makes sense. Now that we are passing an array to React, we need to make sure each JSX expression in the array has its `key` attribute set to a unique value. This applies to the `squares` array __as well as__ the `squareRows` array, which means we need to modify the `Board` component's `renderSquare(i)` function:

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
    squareRows.push(
        <div className="board-row" key={col}>
            {squares}
        </div>);
    ...
}
```

This fixes stuff:

<img src="/loop-key-fix.PNG" style="width: 33%" />

And the game still works:

<img src="/loop-key-game.PNG" style="width: 33%" />

So that's that!

## Toggle the toggle

So we need to keep track of the current sorting order, hence we would need a new state variable. Add it where? To the `Game` component, since the component's `render()` function takes care of rendering the moves list:

```
render() {
    ...

    const moves = history.map((step, move) => {
        const desc = move ?
            'Go to move #' + move + ' ' + step.location :
            'Go to game start';
        return (
            <li key={move}>
                <button 
                    style={this.state.stepNumber === move? 
                        {fontWeight: 'bold'}: {fontWeight: 'normal'}} 
                    onClick={() => this.jumpTo(move)}>
                    {desc}
                </button>
            </li>
        );
    });    
    ...
}
```

We'll add our new variable to the initial `state` that is set in the `Game` component's constructor:

```
export default class Game extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            history: [
                {
                    squares: Array(9).fill(null)
                }
            ],
            stepNumber: 0,
            xIsNext: true,
            isSortAsc: true
        };
    }
```

And we'll hook up the new variable in the `render()` function:

```
render() {
    ...

    const moves = history.map((step, move) => {
        const desc = move ?
            'Go to move #' + move + ' ' + step.location :
            'Go to game start';
        return (
            <li key={move}>
                <button 
                    style={this.state.stepNumber === move? 
                        {fontWeight: 'bold'}: {fontWeight: 'normal'}} 
                    onClick={() => this.jumpTo(move)}>
                    {desc}
                </button>
            </li>
        );
    });  

    if(!this.state.isSortAsc) {
        moves = moves.reverse();
    }  
    ...
}
```

Lastly, we need to add a toggle button to the game using which we will toggle the sorting order of the moves list. I've borrowed the CSS and HTML code for a toggle button from [W3Schools][w3c-toggle-button] and used it in the `render()` function:

```
render(){
    ...
    <div className="game-info">
        <div>{status}</div>
        <label className="switch">
            <input type="checkbox" 
                checked={this.state.isSortAsc}
                onChange={() => 
                    this.setState({isSortAsc: !this.state.isSortAsc})}
            />
            <span className="slider round"></span>
        </label>
        <label className="switch-text">
            {this.state.isSortAsc? "Ascending": "Descending"}
        </label>
        <ol>{moves}</ol>
    </div>
    ...
}
```

Did any of our unit tests fail from this change? Nope, because the initial sort order is set to ascending and we never toggle it in our tests. Let's add a test or two for this new feature. We already have one that checks the contents of the moves list when two moves have been made:

```
it("the moves list should get updated", () => {
    assert.equal(
        JSON.stringify(game.find('.game-info li button')
            .map(button => button.text())),
        JSON.stringify([
            "Go to game start",
            "Go to move #1 (1, 1)",
            "Go to move #2 (2, 1)"]));
});
```

I think we could just rename this test to clarify its new intent:

```
it(`the moves list should get updated and get 
    displayed in ascending order by default`, () => {
    assert.equal(
        JSON.stringify(game.find('.game-info li button')
            .map(button => button.text())),
        JSON.stringify([
            "Go to game start",
            "Go to move #1 (1, 1)",
            "Go to move #2 (2, 1)"]));
});
```

And add another one to check the contents of the moves list when the user has toggled the toggle button to show the moves in descending order:

```
it(`the moves list should be sorted in
    descending order when the toggle button
    is clicked`, () => {
    let toggleButton = game.find('.game-info input');
    toggleButton.simulate('change');

    assert.isFalse(game.state().isSortAsc);
    assert.equal(
        JSON.stringify(game.find('.game-info li button')
            .map(button => button.text())),
        JSON.stringify([
            "Go to move #2 (2, 1)",
            "Go to move #1 (1, 1)",
            "Go to game start"]));        
});
```

All green!

<img src="/game-toggle-all-tests.PNG" style="width: 33%" />

Let's have a look at the actual game too. I see our new toggle button:

<img src="/game-toggle-initial.PNG" style="width: 33%" />

Make a couple of moves and they end up being listed in ascending order as expected:

<img src="/game-toggle-ascending.PNG" style="width: 37%" />

Click the toggle button and the moves get reversed:

<img src="/game-toggle-descending.PNG" style="width: 37%" />

We shouldn't really have to test clicking on each individual button in the move list since we've just moved the buttons around, we haven't changed their `onClick` functions. But I tested them anyway.

So, we're done with 4 of the 6 enhancements! I'll deal with the last two in the next post.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html#wrapping-up
[w3c-toggle-button]: https://www.w3schools.com/howto/howto_css_switch.asp