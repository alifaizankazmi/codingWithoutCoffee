+++
title = "Riffing with React 001: Surely You Jest"
description = "react enzyme tic tac toe"
tags = [ "react", "jest", "enzyme", "tic-tac-toe" ]
date = "2019-11-02"
location = "Glasgow, UK"
categories = [
  "react",
  "jest",
  "enzyme",
  "tic-tac-toe"
]
slug = "ticTacToeJest"
type = "post"
+++

##### Estimated reading time: 5 minutes

Welcome to the first of a series of posts about my efforts to understand the `React` framework. For this post, I'll be creating unit tests using `Jest` for the code shown in the ["Intro to React" tutorial][react-tutorial]. 

Why? Because I love unit tests. Also, and more importantly, later on in the tutorial we will be asked to add certain enhancements to the code. And how do we make sure our enhancements don't break existing functionality? By making sure we manually and exhaustively test each code pathway in the browser. __Psych__. By writing unit tests before we add the enhancements, of course! 

**N.B.**: This post assumes that you have already perused the earlier sections of the tutorial. Also, I won't cover the relatively boring stuff involved in setting up a development environment for React and Jest. We'll head straight to code-town.

### Square One

Let's start with the most low-level component in the [Tic Tac Toe codebase][react-tutorial-source-code]: the `Square` component. Why did I pick the most low-level component? Because there won't be a lot of cognitive overhead involved in understanding the simple component itself - making it easier to focus on writing tests. Also, the `Square` component isn't composed of any other components which makes it simple to test. For reference, here's the component:

```
import React from 'react';

export default function Square(props) {
    return (
        <button 
            className="square" 
            onClick={props.onClick}>
                {props.value}
        </button>
    );
}
```

Looking at the code, I can think of 3 things that my unit tests should be testing:

1. When a `Square` component is initialised it should consist of a single `button` <sup>*</sup>
2. When a `Square` component is initialised its `onClick` function should be the same as the one passed to it in its props
3. When a `Square` component is initialised its text value should be equal to the value passed to it in its props

<small>\* Depending on the component, such a test might not add a lot of value. Also, such a test would probably find a better home in [snapshot tests][snapshot-tests]. For this blog post, though, I've included it as a unit test for demonstration purposes. </small>

### Test 1

Let's start with test #1. It is advisable to group together related tests in `Jest` under what's called a `describe` block. Its syntax is as follows:

```
describe(blockName, function)
```

where `blockName` is a string and `function` is the function that will declare our tests in `test` or `it` blocks (the syntax of which is similar to that of `describe`). The function could also contain any code we need to be run before one or all of our tests inside the `beforeEach` or `beforeAll` blocks respectively. The following is an example using the `beforeAll` block:

```
import { assert } from 'chai';
import { shallow } from 'enzyme';

import Square from './Square.js';

describe("Given a square with props", () => {
    let square;

    beforeAll(() => {
        square = shallow(Square({
            onClick: () => {}, 
            value: "X"
        }));
    });

    it("it should consist of a single button", () => {
        assert.equal(square.find('button').length, 1);
    });
```
Note that I'm using the `chai` assertion library for my test assertions. Also, I'm using the `enzyme` testing utility to render the `Square` component using the `shallow` function. The function is handy when you want to test your root component as a unit without caring about its child components, or when you don't really have to fully mount a component in the DOM. `enzyme` does come with a `mount` function which achieves just that but we'll get to that later.

What does `square` get initialised to when we call the `shallow` function in the `beforeAll` block? To a `ShallowWrapper` object. This object has a `find` function that takes a CSS selector expression as an argument and returns another `ShallowWrapper` object which wraps the DOM nodes matched by the selector. Running this test with NPM in Visual Studio Code, I see that the test passes:

<img src="/square-test-1.PNG" style="width: 50%" />

Sweet. Can we be sure that we've got the test right, though? One way to find out: I'm going to change my assert from:

```
assert.equal(square.find('button').length, 1);
```

to

```
assert.equal(square.find('button').length, 0);
```

Running the test again, I get the following neat failure message:

<img src="/square-test-1-failed.PNG" style="width: 75%" />

### Test 2

In order to check that the function passed to our `Square` component in its props is the one that gets bound to its `onClick` event, we could use the `props` property on the `square` object and verify that the value of the `onClick` function is as expected. But what if we wanted to simulate the `onClick` event? Enter `Sinon.JS`: a library that lets you _spy_ on functions to determine whether and how often they get called. In our case, we'll create our spy using the `sinon.spy()` function and pass it as a prop to our `Square` component:

```
...
import sinon from 'sinon';
...

describe("Given a square with props", () => {
    let square;
    const onButtonClick = sinon.spy();

    beforeAll(() => {
        square = shallow(Square({
            onClick: onButtonClick, 
    ...
```

This is what our 2nd test looks like:

```
it("it should have an onClick function", () => {
    square.find('button').simulate('click');
    assert(onButtonClick.calledOnce);
});
```

The `simulate` function provided by `enzyme` can be invoked on a `ShallowWrapper` object to simulate an actual DOM event. The function takes the event name as its first argument and can optionally take an event object as a 2nd argument. The `calledOnce` property on our `sinon` spy function makes it easy to assert that the spy function was called once (since we only simulated the click event once).

This test passes:

<img src="/square-test-2.PNG" style="width: 50%" />

Looking good *.

<small>* The `enzyme` [docs][enzyme-simulate] for the function list a few gotchas. One of them being: "Even though the name would imply this simulates an actual event, .simulate() will in fact target the component's prop based on the event you give it. For example, .simulate('click') will actually get the onClick prop and call it."</small>

### Test 3

Did you think I saved the hardest for last? Huh, wonder where you got that outlandish idea! Our last test is quite simple: all we need to do is use the `text()` function on our `ShallowWrapper` and assert that it's equal to the value passed to the `Square` component in its props:

```
...

beforeAll(() => {
    square = shallow(Square({
        onClick: onButtonClick, 
        value: "X"
    }));
});

...

it("it should have a text value equal to its value prop",
    () => {
        assert.equal(square.find('button').text(), "X");    
    }
);
```

Hello, green.

<img src="/square-test-3.PNG" style="width: 60%" />

And the obligatory check to confirm that the test fails when it meets its failure condition:

```
it("it should have a text value equal to its value prop",
    () => {
        assert.equal(square.find('button').text(), "O");
    }
);
```

<img src="/square-test-3-failed.PNG" style="width: 75%" />

Finally, let's run all the three tests together:

<img src="/square-tests-all.PNG" style="width: 60%" />

Green country! <small>Apologies, Northeast Oklahoma.</small>

That covers the `Square` component nicely. Next, I'll cover the Board component which will give us an opportunity to look at the `mount` function provided by `enzyme`.

[react-tutorial]: https://reactjs.org/tutorial/tutorial.html
[snapshot-tests]: https://jestjs.io/docs/en/snapshot-testing
[react-tutorial-source-code]: https://codepen.io/gaearon/pen/gWWZgR?editors=0010
[enzyme-simulate]: https://airbnb.io/enzyme/docs/api/ShallowWrapper/simulate.html