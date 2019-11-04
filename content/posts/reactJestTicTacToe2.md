+++
title = "Riffing with React 002: Jest Another Day"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-04"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToeJest2"
type = "post"
+++

##### Estimated reading time: 5 minutes

Fair warning: the puns tend to get more laboured the deeper I dive into the code.

Welcome to the second post where I continue to create unit tests for the code shown in the ["Intro to React" tutorial][react-tutorial]. In this post we're looking at the `Board` component, shown below in full:

```
import React from 'react';
import Square from './Square.js';

export default class Board extends React.Component {
    renderSquare(i) {
        return (
            <Square
                value={this.props.squares[i]}
                onClick={() => this.props.onClick(i)}
            />
        );
    }

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
}
```

First impressions? I think we need the following tests:

1. When the `renderSquare` function is called it should return a `Square` component
2. The `Board` component should have 9 squares as its children
3. Each square should have its onClick function and its value passed to it from the `Board` component

### Test 1

We can initialise a `Board` component using its constructor and call the `renderSquare` function on it - no need to mount the component or even use the `shallow` function to wrap the `Board` component just yet. In order to test the `renderSquare` function, we need to pass it a number that represents the location of a square on the board which we want to render into a component. Easier shown than said, to be honest: 

```
import { assert } from 'chai';
import { shallow } from 'enzyme';

import Board from './Board.js';

describe("When renderSquare is called", () => {
    const squares = [
        "X", "O", "", 
        "O", "X", "", 
        "X", "O", ""
    ];

    it("a Square should be returned", () => {
        let board = new Board({
            squares: squares,
            onClick: () => {}
        });
        let square = shallow(board.renderSquare(3));
        let squareButton = square.find('button');

        assert.equal(squareButton.text(), "O");
    });
});
```

See? We're verifying that if `renderSquare` is asked to render the 4th square then it should return a `Square` component that has a value corresponding to the value in `squares[3]`. Is that all that we need to test? Nope, I left out verifying that the `Board` component passes the right function to the `Square` component in the `onClick` prop - when the `onClick` event is triggered for the 4<sup>th</sup> square then we should expect the `Board` component's `onClick` function to be called with the number 3. To test this, we need to enlist `sinon`'s help again:

```
describe("When renderSquare is called", () => {
    const onClick = sinon.spy();
    ...
    it("a Square should be returned", () => {
        let board = new Board({
            squares: squares,
            onClick: onClick
        });
        let square = shallow(board.renderSquare(3));
        let squareButton = square.find('button');

        assert.equal(squareButton.text(), "O");

        squareButton.simulate('click');
        assert.equal(onClick.getCall(0).args[0], 3);        
    });   
```

The `getCall(0)` function is new: it retrieves the context for the first time our spy function(`onClick`) was called. The context provides access to some goodies such as the value of `this` when the spy was called, the value returned by the spy function (if defined), and the arguments with which the spy function was called. This is what we're using to verify our test. Since we can be sure that the `onClick` function will only ever be called with one argument, it's safe for us to access the `args` array's first item from our spy function's context. The test passes!

<img src="/board-test-1.PNG" style="width: 50%" />

I'm going to move on to the next test - we're only testing one square in this test but we'll get to test all the squares in the next one.

### Test 2 (3, really)

It's a simple matter of counting that the board has 9 squares under it in the DOM, right?

```
describe("Given a Board created with squares", () => {
    let board;
    const onClick = sinon.spy();
    const squares = [
        "X", "O", "", 
        "O", "X", "", 
        "X", "O", ""
    ];

    beforeAll(() => {
        board = shallow(
            <Board 
                squares={squares} 
                onClick={onClick} 
            />
        );
    });

    it("it should have 9 squares", () => {
        assert.equal(board.find('Square').length, 9);
    });
});
```

Well, the test passes but it's not going to be very useful when we write up the last test because we will be testing each `Square` component's value and its `onClick` prop anyway. So, it's a good idea to ignore Test 2 and move on to Test 3:

```
it("each square should have the correct value", () => {
    let squareButtons = board.find('button');
    squareButtons.forEach((button, index) => {
        assert.equal(button.text(), squares[index]);
    });
});

it("each square should have the right onClick behaviour", () => {
    let squareButtons = board.find('button');
    squareButtons.forEach((button, index) => {
        button.simulate('click');
        assert.equal(
            onClick.getCall(index).args[0], index);
    });
});
```

Yup, both tests are more or less the same as our first test. The only difference is that here we are testing the `Board` component's initialization, not just the `renderSquare` function. Where the `renderSquare` test provided a ground-level view, these tests provide a view at a higher altitude.

There's something here that can be improved: in each of the `it` blocks we're iterating over the list of buttons and verifying each button's value and `onClick` function. What if, for any reason, a future code change resulted in the `Board` component rendering less than 9 squares? Our tests would still pass! A better course of action is to iterate over the `squares` array instead:

```
it("each square should have the correct value", () => {
    let mountedSquareValues = 
        board.find('button')
            .map(node => node.text());
    assert.deepEqual(mountedSquareValues, squares);
});
```

And we have our first failing test:

<img src="/board-test-2-failed.PNG" style="width: 85%" />

Say what?

Ah, silly me. I'm still using the `shallow` function to initialise the `Board` component:

```
beforeAll(() => {
    board = shallow(
        <Board 
            squares={squares} 
            onClick={onClick} 
        />
    );
});
```

Looks like the function doesn't initialise each of the `Square` components, which makes sense. We need to replace this with the `mount` function:

```
...
import { mount, shallow } from 'enzyme';

...
beforeAll(() => {
    board = mount(
        <Board 
            squares={squares} 
            onClick={onClick} 
        />
    );
});
...
it("each square should have the correct value", () => {
    let mountedSquareValues = 
        board.find('button')
            .map(node => node.text());
    assert.deepEqual(mountedSquareValues, squares);
});

it("each square should have the right onClick behaviour", () => {
    let squareButtons = board.find('button');
    assert.equal(squareButtons.length, squares.length);
    squareButtons.forEach((button, index) => {
        button.simulate('click');
        assert.equal(
            onClick.getCall(index).args[0], index);
    });
});
```

Both tests pass now:

<img src="/board-test-2.PNG" style="width: 70%" />

And a final run is all green:

<img src="/board-test-all.PNG" style="width: 70%" />

The `Board` component is now fully covered. We'll cover the top-level `Game` component in the next post.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html