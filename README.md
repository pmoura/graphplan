The Logtalk GraphPlan Project
=============================

This project is a port of the [Prolog GraphPlan Project](https://github.com/Mortimerp9/Prolog-Graphplan) to Logtalk. This readme file is adapted from the original readme file to reflect the port changes and how to use it. Notably, this port uses ordered sets and allows concurrently loading ad using multiple domains.

The [Graphplan algorithm](http://en.wikipedia.org/wiki/Graphplan) is an [automatic planning](http://en.wikipedia.org/wiki/Automated_planning) algorithm that can compute, given a set of rules, a plan of action to go from an initial state to a final state.

The algorithm was described by Blum and Furst in 1997 and published in:

> A. Blum and M. Furst (1997). Fast planning through planning graph analysis. Artificial intelligence. 90:281-300.

This project provides an open source (GPL v3) implementation of this planner in Logtalk.

How to use it
-------------

This port has been tested with most of the [Prolog backends](https://logtalk.org/download.html#requirements) supported by Logtalk and is quite simple to use.

There is a basic toy example of a planning domain in `examples/rocket.lgt`. This example provides the "rocket payload" scenario where a set or rockets can be used to move cargo between places.

Before all, you need to load the planner and the domain:

```text
?- logtalk_load([loader, 'examples/rocket']).
```

First of all we define the _world_ facts that can be used by the planner to do the inferences:

```logtalk
rocket(rocket1).
place(london).
place(paris).
cargo(a).
cargo(b).
cargo(c).
cargo(d).
```

The example predicates are very simple atomic predicates, but with our implementation, you can use any kind of predicates and perform inferences in the word definition predicates.

**Note that these _world_ predicates do not describe a changeable state but fixed facts that will not be changed during the planning (i.e. in our examples, the initial position of the rocket is not defined with such predicates).**

The planner can be called with the `plan/3` predicate, for instance:

```text
?- rocket::plan([at(a, london), at(rocket1, london), has_fuel(rocket1)], [at(a, paris)], Plan).
```

This predicate takes three arguments:

1. The initial state of the world.
2. The final state of the world that should be reached when the plan is completed.
3. The constructed plan.

The plan tries to find a set of actions to change the initial state to reach the final state. Thus you have to define these actions before you can find a plan.

Actions are defined with three predicates:

1. The *preconditions* required to perform an action: `can(Action, StateDefinition).`

	* first you define the action name,
	* second you define the required precondition as a set of state predicates

2. What the action *adds* to the current state of the world when it's completed: `adds(Action, ListOfAddedStatePredicates, _).`

    * first you define the action name,
	* second you define the list of added state predicates,
	* third you ignore this

3. What the action *removes* from the current state of the world when it's completed: `deletes(Action, ListOfDeletedStatePredicates).`

    * first you define the action name,
	* second you define the list of removed state predicates

And that's it. It seems complicated, but you can see the definition of the actions in the rocket example and you will see it's not that hard. For instance, the following action unloads a cargo from a rocket:

```logtalk
unload(Rocket, Place, Cargo).
```

1. **preconditions:** the cargo must be in the right place

```logtalk
can(unload(Rocket, Place, Cargo),[at(Rocket,Place),in(Cargo,Rocket)]) :-
	rocket(Rocket),
	cargo(Cargo),
	place(Place).
```

2. **added state:** the cargo is now in the new place

```logtalk
adds(unload(Rocket, Place, Cargo),[at(Cargo,Place)], _) :-
	rocket(Rocket),
	cargo(Cargo),
	place(Place).
```

3. **removed state:** the cargo is not in the rocket anymore


```logtalk
deletes(unload(Rocket, _Place, Cargo),[in(Cargo,Rocket)]) :-
	rocket(Rocket),
	cargo(Cargo).
```

When you call the `plan/3` predicate, you will get the complete plan (if one is possible). The current implementation can also print out the plan for simple viewing using the `write_plan/1` predicate. For example:

```text
?- rocket::(plan([at(a, london), at(rocket1, london), has_fuel(rocket1)], [at(a, paris)], Plan), write_plan(Plan)).

Step 1:
        load(rocket1,london,a)

Step 2:
        move(rocket1,london,paris)

Step 3:
        unload(rocket1,paris,a)

Plan = [[load(rocket1, london, a)], [move(rocket1, london, paris)], [unload(rocket1, paris, a)]] .
``` 

**Note that the graphplan algorithm can find actions that can be performed in parallel and thus you can have more than one action per step. Look into the `tests.lgt` file for examples to see how it works.**

Testing
-------

To run the tests manually, use the following goal:

```text
?- logtalk_load(tester).
```

To run the tests automatically, use the [`logtalk_tester`](https://logtalk.org/man/logtalk_tester.html) script. For example, to run the tests using the GNU Prolog backend:

```bash
$ logtalk_tester -p gnu
```

Contributors
============

This implementation is based on the original algorithm described by **Blum and Furst**.

The initial implementation was provided by [**Dr. Suresh Manandhar**](http://www-users.cs.york.ac.uk/~suresh/) from the University of York Computer Science department and slightly modified by [**Dr. Pierre Andrews**](http://disi.unitn.it/~andrews/).

The code is distributed under GPL v3. If you use it, please be sure to provide the right attribution and, if you wish, let us know about it.

You are welcome to contribute patches or improvements to this project. Dr. Manandhar and Andrews are providing the code as is and do not have any plans to provide support (new features, bug corrections) for this project, but I will make sure to push contributed patches to improve the code when I receive them.

If you want to contribute more examples, it would be great too.

Logtalk port by Paulo Moura.

Applications
============

Currently, this implementation of the graphplan has successfully been used for:

* Planning Human-Computer Dialogue by P. Andrews.

**If you use this planner for any other application, please let us know.**
