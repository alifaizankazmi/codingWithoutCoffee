+++
title = "Riffing with React 003: Jestation"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-09"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToeJest3"
type = "post"
+++

##### Estimated reading time: 25 minutes

See what I mean about the puns?

Welcome to the third and final post where I will create unit tests for the only remaining component in the ["Intro to React" tutorial][react-tutorial] - the `Game` component. It's the largest component in the codebase at around a hundred lines, so we'll take it apart in terms of different areas of functionality:

1. Setting up initial game state
2. Processing a move made by the user
3. Moving forwards/backwards in time
4. Determining when to end the game

### Initial State and Making Moves

The initial game state is set in the constructor function:


```
import React from 'react';
import Board from './Board.js';

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
            xIsNext: true
        };
    }
...
```

All we need to do is run the constructor function and do a few basic asserts:

```
import { assert } from 'chai';

import Game from './Game.js';

describe("Given a Game", () => {
    let game;

    beforeAll(() => {
        game = new Game({});
    });

    it("it should have the expected default state", () => {
        assert.equal(game.state.stepNumber, 0);
        assert.equal(game.state.xIsNext, true);

        assert.equal(game.state.history.length, 1);
        assert.deepEqual(game.state.history[0].squares, 
            Array(9).fill(null));
    });
});
```

<img src="/game-test-1.PNG" style="width: 70%" />

Easily done. Next, we turn to verifying the correctness of the code that deals with processing a move made by the user. We need to add more context here with regards to the user's move: has the user clicked inside an empty square? A filled square? What happens to the moves list when the user makes a valid move? What happens to the status label? What happens to my video game time while I'm typing this out? Erm, disregard that last one.

There are two functions that we need to focus on:

1. The `handleClick` function: this is where we update the game state.

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

2. The `render` function: this is where render the game state.

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
                    <button onClick={() => 
                        this.jumpTo(move)}>{desc}</button>
                </li>
            );
        });

        let status;
        if (winner) {
            status = "Winner: " + winner;
        } else {
            status = "Next player: " + 
                (this.state.xIsNext ? "X" : "O");
        }

        return (
            <div className="game">
                <div className="game-board">
                    <Board
                        squares={current.squares}
                        onClick={i => this.handleClick(i)}
                    />
                </div>
                <div className="game-info">
                    <div>{status}</div>
                    <ol>{moves}</ol>
                </div>
            </div>
        );
    }
```

For our first test, we will verify that when the first (empty) square is clicked then the game state is updated and rendered. Here's a first stab at it:

```
import { assert } from 'chai';
import { mount } from 'enzyme';

import React from 'react';
import Game from './Game.js';

describe("Given the user clicks a square in a new Game", () => {
    let game;

    beforeEach(() => {
        game = mount(<Game />);
    });

    it("the square should get an X", () => {
        game.find('button')
            .at(0)
            .simulate('click');

        assert.equal(game.state().stepNumber, 1);
        assert.isFalse(game.state().xIsNext);
        assert.equal(game.state().history.length, 2);
        assert.deepEqual(game.state().history[0].squares,
            Array(9).fill(null));
        assert.deepEqual(game.state().history[1].squares,
            ['X'].concat(Array(8).fill(null)));
    });
}
```

Look good? Not really. Well, kinda. First, we'll be simulating quite a few square clicks as we go about testing the `Game` component so it sounds like a good idea to introduce a new `clickSquare` function:

```
const clickSquare = (game, buttonIndex) => 
    game.find('button')
        .at(buttonIndex)
        .simulate('click');
```

And then use it in our test:

```
it("the square should get an X", () => {
    clickSquare(game, 0);

    assert.equal(game.state().stepNumber, 1);
...
```

Second, our test is verifying that the state of the game was _set_ correctly but it's not verifying if it was _rendered_ correctly. We should test the latter too. Actually, should we _only_ test the latter? Since if the state is rendered correctly then surely it would've been _set_ correctly in the first place? I think so. Third, there's way too many `assert`s in our unit test for my liking. I think it can be broken down into simpler tests. Here's how I would rewrite and split our test:

```
    beforeEach(() => {
        game = mount(<Game />);
        clickSquare(game, 0);
    });

    it("the square should get an X", () => {
        assert.equal(JSON.stringify(game.find('Square')
            .map(square => square.text())),
            JSON.stringify(['X'].concat(Array(8).fill(""))));
    });

    it("the status label should get updated", () => {
        assert.equal(game.find('.game-info div').text(),
            "Next player: O");
    }); 
```

These look much neater and much more user-focused to me, now that we're no longer inspecting the actual state of our component. This approach will also reduce the likelihood of our tests failing in case we refactored the code related to state management.

Why use `JSON.stringify` for array equality? It's a hack to get around the fact that `assert.equal`, when applied to arrays, checks for reference equality, not value equality.

Are we verifying everything that we were testing in our previous approach, though? Nope, we're no longer verifying that we're building a history of the state of the board. Let's do that:

```
it("the moves list should get updated", () => {
    assert.equal(
        JSON.stringify(game.find('.game-info li button')
            .map(button => button.text())),
        JSON.stringify([
            "Go to game start",
            "Go to move #1"]));
});
```

Thinking back to the earlier tests: we'll probably need to extract the text from all squares in multiple places. We can add another function to our test suite:

```
const getSquaresAsText = gameComponent =>
    JSON.stringify(gameComponent.find('Square')
        .map(square => square.text()));
```

And refactor the first test:

```
it("the square should get an X", () => {
    assert.equal(getSquaresAsText(game),
        JSON.stringify(['X'].concat(Array(8).fill(""))));
});
```

Oh, and I need to go back to refactor the other test, the one where we verified the default state. Remember how we just called the default constructor for the `Game` component and didn't actually mount it? Well, can't do that anymore if we want to check what actually got rendered.

```
describe("Given a Game", () => {
    let game;

    beforeAll(() => {
        game = mount(<Game />);
    });

    it("it should have an empty board", () => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify(Array(9).fill("")));
    });

    it("it should have the right status", () => {
        assert.equal(game.find('.game-info div').text(),
            "Next player: X");
    });
});
```

Anything we're missing? Yes, we should also verify that the moves list is empty:

```
    it("it should have an empty moves list", () => {
        assert.equal(
            JSON.stringify(game.find('.game-info li button')
                .map(button => button.text())),
            JSON.stringify(["Go to game start"]));
    });
```

Note that the initial length of the moves list is 1 since in the beginning of the game we still render the button that says "Go to game start". 

That does it for verifying the initial state and the first user move. Let's add three more tests:

1. Clicking on a used square should have no effect
2. Clicking on the second square should put an "O" in it
3. The moves list should get updated with each click

The first one is easy enough:

```
describe("Given the user clicks on a used square", () => {
    let game;

    beforeAll(() => {
        game = mount(<Game />);
        clickSquare(game, 0);
    });

    it("the click should have no effect", () => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify(['X']
                .concat(Array(8).fill(""))));
        assert.equal(getStatusText(game),
            "Next player: O");
        assert.equal(
            game.find('.game-info li button').length,
            2);

        clickSquare(game, 0);

        assert.equal(getSquaresAsText(game),
            JSON.stringify(['X']
                .concat(Array(8).fill(""))));
        assert.equal(getStatusText(game),
            "Next player: O");
        assert.equal(
            game.find('.game-info li button').length,
            2);
    });
});
```

Hmm, we're having to make the same set of assertions twice. Is it worth refactoring them into one re-usable function? Probably. Also, we can move the code to get the game's status into a re-usable function:

```
const getStatusText = gameComponent => 
    gameComponent.find('.game-info div').text();
...
describe("Given the user clicks on a used square", () => {
    let game;

    let assertExpectedState = game => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify(['X']
                .concat(Array(8).fill(""))));
        assert.equal(getStatusText(game),
        "Next player: O");
        assert.equal(
            JSON.stringify(game.find('.game-info li button')
                .map(button => button.text())),
            JSON.stringify([
                "Go to game start",
                "Go to move #1"]));
    };
...
it("the click should have no effect", () => {
    assertExpectedState(game);

    clickSquare(game, 0);

    assertExpectedState(game);
});
```

All good so far.

<img src="/game-test-2.PNG" style="width: 70%" />

Next, we tackle the user's second move. Verifying the expected behaviour for the second move can be done by borrowing a lot of the code that we used for verifying the first move:

```
describe("Given the user clicks on the second square", () => {
    let game;

    beforeEach(() => {
        game = mount(<Game />);
        clickSquare(game, 0);
        clickSquare(game, 1);
    });

    it("the square should have an O", () => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify(['X', 'O'].
                concat(Array(7).fill(""))));
    });

    it("the status label should get updated", () => {
        assert.equal(getStatusText(game),
            "Next player: X");
    });

    it("the moves list should get updated", () => {
        assert.equal(
            JSON.stringify(game.find('.game-info li button')
                .map(button => button.text())),
            JSON.stringify([
                "Go to game start",
                "Go to move #1",
                "Go to move #2"]));
    });
});
```

We've accomplished all we wanted to for this section!

<img src="/game-test-3.PNG" style="width: 70%" />

What's left is verifying that the code can time-travel and identify a winning/losing position.

## Time Travel and Knowing When To Stop

<small>(Not-so-veiled critique of Hollywood)</small>

I don't foresee lots of difficulty ahead since we've already verified from our tests that the moves list is getting updated with each move. Now all we need to do is simulate click events on a couple of buttones in the moves list and verify that the state of the game moves forwards/backwards in time. We could go ahead and start our test on a game that has had two moves already so that we can test the following scenarios:

1. Go back one move
2. Go forward one move
3. Move to the initial state

Here we go:

```
describe("Given a game with two moves", () => {
    const game = mount(<Game />);
    clickSquare(game, 0);
    clickSquare(game, 5);

    describe("When the user chooses to go back one move", () => {
        beforeAll(() => {
            game.find('.game-info li button')
                .at(1)
                .simulate('click')
        });

        it("the game board and status should go back one move", () => {
            assert.equal(getSquaresAsText(game),
            JSON.stringify(['X']
                .concat(Array(8).fill(""))));
            assert.equal(getStatusText(game),
                "Next player: O");
        });

        it("the moves list should not get updated", () => {
            assert.equal(
                JSON.stringify(game.find('.game-info li button')
                    .map(button => button.text())),
                JSON.stringify([
                    "Go to game start",
                    "Go to move #1",
                    "Go to move #2"]));
        });
    });
});
```

Note the nested `describe` block. It neatly groups together our individual tests. The second set of tests are pretty much along the lines of the first:

```
describe("When the user chooses to go forward one move", () => {
    beforeAll(() => {
        game.find('.game-info li button')
            .at(1)
            .simulate('click');
        game.find('.game-info li button')
            .at(2)
            .simulate('click');
    });

    it("the game board and status should go forward one move", () => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify([
                'X', '', '' ,
                '' , '', 'O',
                '' , '', ''
            ]));
        assert.equal(getStatusText(game),
            "Next player: X");
    });

    it("the moves list should not get updated", () => {
        assert.equal(
            JSON.stringify(game.find('.game-info li button')
                .map(button => button.text())),
            JSON.stringify([
                "Go to game start",
                "Go to move #1",
                "Go to move #2"]));
    });
});
```

As are the third set of tests. I won't list them here for brevity. You can have a look at them [here][tic-tac-toe-github].

Finally, we have reached the last set of tests - verifying that the game stops when:

1. The X user has made a winning move
2. The O user has made a winning move
3. There are no more moves possible (i.e., a draw)

Again, there's nothing new that we need to know for these tests - we can just build on top of earlier ones:

```
describe("When the X user makes a winning move", () => {
    let game;
    
    let assertWinningState = game => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify([
                'X', 'O', 'O',
                '' , 'X', '' ,
                '' , '' , 'X']));
        assert.equal(getStatusText(game),
            "Winner: X");
    };

    beforeAll(() => {
        game = mount(<Game />);
        clickSquare(game, 0);
        clickSquare(game, 1);
        clickSquare(game, 4);
        clickSquare(game, 2);
        clickSquare(game, 8);
    });

    it("then the status should get updated", () => {
        assert.equal(getStatusText(game),
            "Winner: X");        
    });

    it("then no more moves should be possible", () => {
        assertWinningState(game);

        clickSquare(game, 6);

        assertWinningState(game);
    });
});
```

A similar set of tests can be created for when the O user makes a winning move. You can have a look at them [here][tic-tac-toe-github].

Finally, the following is a group of tests to verify that no further moves are possible in a drawn state:

```
describe("When no user makes a winning move", () => {
    let game;

    let assertDrawState = game => {
        assert.equal(getSquaresAsText(game),
            JSON.stringify([
                'X', 'O', 'X',
                'X', 'O', 'X' ,
                'O', 'X', 'O']));
        assert.equal(getStatusText(game),
            "Next player: O");
    };

    beforeEach(() => {
        game = mount(<Game />);
        clickSquare(game, 0);
        clickSquare(game, 4);
        clickSquare(game, 3);
        clickSquare(game, 6);
        clickSquare(game, 2);
        clickSquare(game, 1);
        clickSquare(game, 7);
        clickSquare(game, 8);
        clickSquare(game, 5);
    });

    it("then the status should get updated", () => {
        assert.equal(getStatusText(game),
            "Next player: O");        
    });

    it("then no more moves should be possible", () => {
        assertDrawState(game);

        clickSquare(game, 5);

        assertDrawState(game);
    });
});
```

Phew. Here is the final list of unit tests for the `Game` component:

<img src="/game-test-4.PNG" style="width: 70%" />

And we have achieved 100% test coverage (excluding the `index.js` file). The `Game` component's tests take 5 seconds to run which is not ideal. My guess is most of the time is probably spent mounting the component since we use the `mount` function 8 different times. I'm not too bothered about it at this point.

<img src="/game-test-5.PNG" style="width: 70%" />

We're in a great position now to add enhancements to the game. Let's do that in the next post.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html
[tic-tac-toe-github]: https://github.com/alifaizankazmi/react-tic-tac-toe/tree/master/src