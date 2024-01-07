
:- object(tests,
	extends(lgtunit)).

	:- info([
		version is 1:0:0,
		author is 'The Prolog GraphPlan Project; Logtalk port by Paulo Moura',
		date is 2024-01-07,
		comment is 'Tests for the "graphplan" library.'
	]).

	:- uses(rocket, [
		plan/3
	]).

	cover(graphplan).

	test(test1) :-
		plan([at(a, london), at(rocket1, london), has_fuel(rocket1)], [at(a, paris)], Plan),
		^^assertion(
			Plan == [[load(rocket1,london,a)],[move(rocket1,london,paris)],[unload(rocket1,paris,a)]]
		).

	test(test2) :-
		plan([at(a, london), at(b,london), at(rocket1, london), has_fuel(rocket1)], [at(a, paris), at(b,paris)], Plan),
		^^assertion(
			Plan == [[load(rocket1,london,a),load(rocket1,london,b)],[move(rocket1,london,paris)],[unload(rocket1,paris,a),unload(rocket1,paris,b)]]
		).

	test(test3) :-
		plan([at(a, london), at(b,london), at(c,london), at(rocket1, london), has_fuel(rocket1)], [at(a, paris), at(b,paris), at(c,paris)], Plan),
		^^assertion(
			Plan == [[load(rocket1,london,a),load(rocket1,london,b),load(rocket1,london,c)],[move(rocket1,london,paris)],[unload(rocket1,paris,a),unload(rocket1,paris,b),unload(rocket1,paris,c)]]
		).

:- end_object.
