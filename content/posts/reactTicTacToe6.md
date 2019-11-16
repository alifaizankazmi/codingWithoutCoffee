+++
title = "Riffing with React 006: Finishing Off"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-16"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToe6"
type = "post"
+++

##### Estimated reading time: 10 minutes

Alright, we're down to the last two [enhancements][react-tutorial]:

1. When someone wins, highlight the three squares that caused the win.
2. When no one wins, display a message about the result being a draw.

Let's cut to the chase.

## Win-win-win

Here's the `calculateWinner()` function:

```
function calculateWinner(squares) {
    const lines = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ];
    for (let i = 0; i < lines.length; i++) {
        const [a, b, c] = lines[i];
        if (squares[a] && 
            squares[a] === squares[b] && 
            squares[a] === squares[c]) {
            return squares[a];
        }
    }
    return null;
}
```

So, the function either returns null or it returns the winner as a string ('X' or 'O'). Based on this string value, we can figure out what squares to highlight - since if, for instance, the winner is 'X' then surely all the squares with a value of 'X' will constitue the winning move. 

Which component should take care of the highlighting? It can't be the `Game` component since it doesn't directly render the squares. It could be the `Board` component, then. The `Game` component will pass the winner to the `Board` component and in turn the component will conditionally set the `className` property of a `Square` component in its `renderSquare` function. 

Here's what I have in mind. The `Game` component's `render` function will now pass a `winner` prop to the `Board` component:

```
render() {
    ...
    return (
        <div className="game">
            <div className="game-board">
                <Board
                    squares={current.squares}
                    onClick={i => this.handleClick(i)}
                    winner={winner}
                />
    ...
}
```

And the `Board` component's `renderSquare` function will change as follows:

```
renderSquare(i) {
    return (
        <Square
            key={i}
            value={this.props.squares[i]}
            onClick={() => this.props.onClick(i)}
            className={this.isSquareInWinningMove(i)? 
                'winner': 
                ''}
        />
    );
}

isSquareInWinningMove(i) {
    let winner = this.props.winner;

    if(!winner) {
        return false;
    }

    return this.props.squares[i] === winner;
}
```

Here's the CSS for the `winner` class:

```
.winner .square {
  border: 2px solid green;
}
```

Is this going to work? Nope! The `<Square>` tag is not going to be a part of the DOM, so setting the `className` attribute on it will have no effect. Looks like we'll need to let each `Square` know whether it is part of a winning move through the props:

```
renderSquare(i) {
    return (
        <Square
            key={i}
            value={this.props.squares[i]}
            onClick={() => this.props.onClick(i)}
            isWinner={this.isSquareInWinningMove(i)}
        />
    );
}
```

And then the `Square` component will set its class as necessary:

```
return (
    <button 
        className={props.isWinner? "square winner": "square"} 
        onClick={props.onClick}>
        {props.value}
    </button>
);
```

Also, our CSS rule needs to change:

```
.square.winner {
  border: 2px solid green;
}
```

Does our code work? One way to find out: unit tests!

```
describe("When the X user makes a winning move", () => {
    let game;

    ...
    it("then the winning squares should get highlighted", () => {
        game.find('button.square')
            .filterWhere(square => square.text() === 'X')
            .forEach(square => 
                assert.isTrue(square.hasClass('winner')));

        game.find('button.square')
            .filterWhere(square => square.text() === 'O')
            .forEach(square => 
                assert.isFalse(square.hasClass('winner')));
    });
});

describe("When the O user makes a winning move", () => {
    let game;
    
    ...
    it("then the winning squares should get highlighted", () => {
        game.find('button.square')
            .filterWhere(square => square.text() === 'O')
            .forEach(square => 
                assert.isTrue(square.hasClass('winner')));

        game.find('button.square')
            .filterWhere(square => square.text() === 'X')
            .forEach(square => 
                assert.isFalse(square.hasClass('winner')));
    });
});

describe("When no user makes a winning move", () => {
    let game;

    ...
    it("then no squares should be highlighted", () => {
        game.find('button.square')
            .forEach(square => 
                assert.isFalse(square.hasClass('winner')));      
    });
});
```

All our unit tests pass:

<img src="/game-winning-squares-1.PNG" style="width: 37%" />

And the winning squares get nicely highlighted too:

<img src="/game-winning-squares-2.PNG" style="width: 37%" />

<img src="/game-winning-squares-3.PNG" style="width: 37%" />

The final showdown approaches.

## There are no winners here

So, all we have to do is display a message saying that the game has ended in a draw. The `Game` component's `render` function looks like a good place. In particular, the `else` branch here:

```
let status;
if (winner) {
    status = "Winner: " + winner;
} else {
    status = "Next player: " + (this.state.xIsNext ? "X" : "O");
}
```

Here's what I'm thinking: if `winner` is null __and__ there are no empty squares on the board then declare the game a draw.

```
if (winner) {
    status = "Winner: " + winner;
} else if(!current.squares.includes(null)) {
    status = "Game ended in a draw";
} else {
    status = "Next player: " + (this.state.xIsNext ? "X" : "O");
}
```

Oh hello, one of our tests failed!

<img src="/game-winning-squares-4.PNG" style="width: 75%" />

We simply need to fix the last `assert` in the `assertDrawState` function:

```
let assertDrawState = game => {
    assert.equal(getSquaresAsText(game),
        JSON.stringify([
            'X', 'O', 'X',
            'X', 'O', 'X' ,
            'O', 'X', 'O']));
    assert.equal(getStatusText(game),
        "Game ended in a draw");
};
```

Whoops, one more test needs fixing:

<img src="/game-winning-squares-5.PNG" style="width: 75%" />

We could probably store the draw message in a variable and re-use it across the failing tests, but I'm too lazy to do that now. All our tests are green:

<img src="/game-winning-squares-6.PNG" style="width: 37%" />

And we haven't compromised on test coverage:

<img src="/game-winning-squares-7.PNG" style="width: 75%" />

__And__ the game works:

<img src="/game-winning-squares-8.PNG" style="width: 37%" />

So...we're done with all the enhancements!

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html#wrapping-up