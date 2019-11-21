+++
title = "Riffing with React 007: First Hook"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "hooks", "tic-tac-toe" ]
date = "2019-11-21"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "hooks",
  "tic-tac-toe"
]
slug = "ticTacToe7"
type = "post"
+++

##### Estimated reading time: 15 minutes

Yup, we're still doing Tic Tac Toe. This time, I'm going to add React hooks to our code. Hooks allow us to _hook_ into the state and [lifecycle][lifecycle] methods of a React app from inside a `function` component, thereby minimizing the need for us to create `class` components. In the Tic Tac Toe codebase, the `Game` and `Board` components are class components whereas the `Square` component is a function component.

Target acquired: `Board` component.

## False target

Let's have a look at the code in the `Board` component which has to do with state management:

```
Nothing to see here
```

That's right, there is no code in the `Board` component that calls the `setState` function. Also, there is no code that uses any lifecycle methods either! While we can't make use of hooks here, this is a prime candidate to be converted to a function component. Here's what we have to do:

1. Remove the `class` declaration at the top of the file:

```
// export default class Board extends React.Component {
   export default function Board(props) {
```

2. Assign all functions apart from `render` to scoped variables:

```
    const renderSquare = i => {
        return (
            <Square
                key={i}
                value={this.props.squares[i]}
                onClick={() => this.props.onClick(i)}
                isWinner={this.isSquareInWinningMove(i)}
            />
        );
    }

    const isSquareInWinningMove = (i, props) => {
        let winnerInfo = props.winnerInfo;

        if(!winnerInfo) {
            return false;
        }

        return props.squares[i] === winnerInfo.winner &&
            winnerInfo.winningSquares.includes(i);
    }
```

3. Remove the `this` keyword in all occurences of `this.*`.

4. Remove the `render` function declaration. This is what the final component should look like:

```
    import React from 'react';
    import Square from './Square.js';

    export default function Board(props) {
        const renderSquare = i => {
            return (
                <Square
                    key={i}
                    value={props.squares[i]}
                    onClick={() => props.onClick(i)}
                    isWinner={isSquareInWinningMove(i)}
                />
            );       
        };

        const isSquareInWinningMove = (i, props) => {
            let winnerInfo = props.winnerInfo;

            if(!winnerInfo) {
                return false;
            }

            return props.squares[i] === winnerInfo.winner &&
                winnerInfo.winningSquares.includes(i);
        }
        
        let squareRows = [];

        for (let col = 0; col < 3; col++) {
            let squares = [];
            for (let row = 0; row < 3; row++) {
                const squareIndex = col * 3 + row;
                squares.push(
                    renderSquare(squareIndex));
            }
            squareRows.push(
                <div className="board-row" key={col}>
                    {squares}
                </div>);
        }

        return (
            <div>
                {squareRows}
            </div>
        );
    }
```

Looks good, right? Nope, it doesn't. We're defining the `renderSquare` and `isSquareInWinningMove` functions every time the `Board` component is rendered. We should move the function definitions outside the `Board` component:

```
import React from 'react';
import Square from './Square.js';

const isSquareInWinningMove = (i, props) => {
    let winnerInfo = props.winnerInfo;

    if(!winnerInfo) {
        return false;
    }

    return props.squares[i] === winnerInfo.winner &&
        winnerInfo.winningSquares.includes(i);
}

const renderSquare = (i, props) => {
    return (
       <Square
           key={i}
           value={props.squares[i]}
           onClick={() => props.onClick(i)}
           isWinner={isSquareInWinningMove(i, props)}
       />
   );       
};

export default function Board(props) {    
    let squareRows = [];

    for (let col = 0; col < 3; col++) {
        let squares = [];
        for (let row = 0; row < 3; row++) {
            const squareIndex = col * 3 + row;
            squares.push(
                renderSquare(squareIndex, props));
        }
        squareRows.push(
            <div className="board-row" key={col}>
                {squares}
            </div>);
    }

    return (
        <div>
            {squareRows}
        </div>
    );
}
```

Note that we had to add another argument (`props`) to both functions as a consequence of moving them outside the `Board` component function. Looks good now, right? Still no. Our tests have started to fail!

<img src="/board-function-fail.PNG" style="width: 50%" />

This makes sense. Now that our component is no longer a `class` component - it's literally just a function - we cannot access its members using the dot notation. How do we fix this? We can `export` the `renderSquare` function:

```
export function renderSquare(i, props) {
    return (
       <Square
           key={i}
           value={props.squares[i]}
           onClick={() => props.onClick(i)}
           isWinner={isSquareInWinningMove(i, props)}
       />
   );       
};
```

And then refactor our test: we no longer need to create a `Board` object. We can simply pass a mock `props` object to the `renderSquare` function.

```
import Board, { renderSquare } from './Board.js';
...
it("a Square should be returned", () => {
    let square = shallow(renderSquare(3, {
        squares: squares,
        onClick: onClick
    }));
    ...
});
```

Our tests are green again:

<img src="/board-fix-tests.PNG" style="width: 37%" />

That's about all we can do for the `Board` component. Next target: `Game`.

## Hard target

Here we are: staring down the refactoring barrel at the `Game` component. The following are code snippets of the component that deal with state managenent:

```
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

handleClick(i) {
    ...
    this.setState({
        history: history.concat([
            {
                squares: squares,
                location: this.getDisplayLocation(i)
            }
        ]),
        stepNumber: history.length,
        xIsNext: !this.state.xIsNext
    });
}

jumpTo(step) {
    this.setState({
        stepNumber: step,
        xIsNext: (step % 2) === 0
    });
}
```

Alright, time for our first hook: we're going to use the `useState` hook. As its name suggests the hook allows us to set state in a function component. First, we need to import the hook:

```
import React, { useState } from 'react';
```

Next, we'll start the tedious process of converting the `Game` component from a class component to a function component. The steps to carry out are the same as those for the `Board` component, except that during the process of conversion we'll also add the `useState` hook.

Here's how the hook works: the `useState` function takes a single argument which represents the initial state of the variable you're trying to, er, hookify. In our case, the initial state could be the whole state object - something like the following:

```
const initialState = {
    history: [
        {
            squares: Array(9).fill(null)
        }
    ],
    stepNumber: 0,
    xIsNext: true,
    isSortAsc: true
};
```

Or, we could break up the state object into its constituent variables and use the `useState` function for each of them. I've decided to follow the former approach since most of the constituent variables of our state object - e.g., `history`, `stepNumber`, and `xIsNext` - have to be updated as a single operation.

We can now replace the constructor that used to exist in the class component with the following:

```
const [state, setState] = useState(initialState);
```

The `useState` function returns an array, the first element of which is the state object and the second element is a function that we can use to update the state object. Note that it is purely coincidental that our update function is called `setState`, you can call it whatever you want. __Question__: does this mean that we would be resetting the state to `initialState` every time we render the `Game` component? Nope. React is smart enough to only set the state to `initialState` the first time the `useState` function gets called. Any subsequent calls will simply return the current state.

Next, we have to change the `this.setState` function call in `handleClick`:

```
const handleClick = i => {
    ...
    setState({
        ...state,
        history: history.concat([
            {
                squares: squares,
                location: getDisplayLocation(i)
            }
        ]),
        stepNumber: history.length,
        xIsNext: !state.xIsNext
    });
}
```

In case you're unfamiliar with the [`spread`][spread] operator (`...`), it basically tells the `setState` function to copy all enumerable properties from the current `state` object __and__ override any properties that we're providing it (in this case: `history`, `stepNumber`, and `xIsNext`).

Same deal for the `jumpTo` function:

```
const jumpTo = step => {
    setState({
        ...state,
        stepNumber: step,
        xIsNext: (step % 2) === 0
    });
}
```

Let's see if our tests still pass:

<img src="/useState-hook-fail.PNG" style="width: 75%" />

Hmm, all but one. Not bad! How do we fix this test, though? By removing the `assert` that is failing. Seriously. This is what the test looks like:

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

Do we really need to check the `isSortAsc` flag, given we're checking the output that depends on that flag immediately afterwards? I don't think so. I think this test is too close to the metal and is brittle too, since it will fail if we decide to change the flag's variable name in the future. Removing the `assert` on `isSortAsc` fixes everything:

<img src="/useState-hook-success.PNG" style="width: 37%" />

So there we have it: our first React hook. This is the final shape of our `Game` component:

```
import React, { useState} from 'react';
import Board from './Board.js';

const initialState = {
    history: [
        {
            squares: Array(9).fill(null)
        }
    ],
    stepNumber: 0,
    xIsNext: true,
    isSortAsc: true
};

const handleClick = (i, state, setState) => {
    const history = state.history
        .slice(0, state.stepNumber + 1);
    const current = history[history.length - 1];
    const squares = current.squares.slice();
    if (calculateWinner(squares) || squares[i]) {
        return;
    }
    squares[i] = state.xIsNext ? "X" : "O";

    setState({
        ...state,
        history: history.concat([
            {
                squares: squares,
                location: getDisplayLocation(i)
            }
        ]),
        stepNumber: history.length,
        xIsNext: !state.xIsNext
    });
}

const getDisplayLocation = index => {
    return "(" + 
      (index % 3 + 1) + ", " + 
      (Math.floor(index / 3) + 1) + 
    ")";
}

const jumpTo = (step, state, setState) => {
    setState({
        ...state,
        stepNumber: step,
        xIsNext: (step % 2) === 0
    });
}

const calculateWinner = squares => {
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
            return {
                winner: squares[a],
                winningSquares: lines[i]
            };
        }
    }
    return null;
}

export default function Game() {
    const [state, setState] = useState(initialState);

    const history = state.history;
    const current = state.history[state.stepNumber];
    const winnerInfo = calculateWinner(current.squares);

    let moves = history.map((step, move) => {
        const desc = move ?
            'Go to move #' + move + ' ' + step.location :
            'Go to game start';
        return (
            <li key={move}>
                <button 
                    style={state.stepNumber === move? 
                        {fontWeight: 'bold'}: {fontWeight: 'normal'}} 
                    onClick={() => jumpTo(move, state, setState)}>
                    {desc}
                </button>
            </li>
        );
    });

    if(!state.isSortAsc) {
        moves = moves.reverse();
    }

    let status;
    if (winnerInfo && winnerInfo.winner) {
        status = "Winner: " + winnerInfo.winner;
    } else if(!current.squares.includes(null)) {
        status = "Game ended in a draw";
    } else {
        status = "Next player: " + (state.xIsNext ? "X" : "O");
    }

    return (
        <div className="game">
            <div className="game-board">
                <Board
                    squares={current.squares}
                    onClick={i => handleClick(i, state, setState)}
                    winnerInfo={winnerInfo}
                />
            </div>
            <div className="game-info">
                <div>{status}</div>
                <label className="switch">
                    <input type="checkbox" 
                        checked={state.isSortAsc}
                        onChange={() => 
                            setState({
                                ...state, 
                                isSortAsc: !state.isSortAsc
                            })}
                    />
                    <span className="slider round"></span>
                </label>
                <label className="switch-text">
                    {state.isSortAsc? "Ascending": "Descending"}
                </label>
                <ol>{moves}</ol>
            </div>
        </div>
    );
}
```

[lifecycle]: https://reactjs.org/docs/state-and-lifecycle.html
[spread]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax