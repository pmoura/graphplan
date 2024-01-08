%    This file is part of the Prolog Graplan project.
%
%    The Prolog Graplan project is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    The Prolog Graplan project is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with the Prolog Graplan project.  If not, see <http://www.gnu.org/licenses/>.

% (C) 2011 Pierre Andrews

:- object(rocket,
	extends(graphplan)).

	:- info([
		version is 1:0:0,
		author is 'The Prolog GraphPlan Project; Logtalk port by Paulo Moura',
		date is 2024-01-08,
		comment is 'Rocket domain example.'
	]).

	rocket(rocket1).

	place(london).
	place(paris).

	cargo(a).
	cargo(b).
	cargo(c).
	cargo(d).

	can(move(Rocket,From,To),[at(Rocket,From), has_fuel(Rocket)]) :- %vehicle move only within city
		rocket(Rocket),
		place(From),
		place(To),
		From \= To.
	can(unload(Rocket, Place, Cargo),[at(Rocket,Place),in(Cargo,Rocket)]) :-
		rocket(Rocket),
		cargo(Cargo),
		place(Place).
	can(load(Rocket, Place, Cargo),[at(Rocket,Place),at(Cargo,Place)]) :-
		rocket(Rocket),
		cargo(Cargo),
		place(Place).

	adds(move(Rocket,_From,To),[at(Rocket, To)], at(Rocket,To)):-
		rocket(Rocket),
		place(To).
	adds(unload(Rocket, Place, Cargo),[at(Cargo,Place)], _) :-
		rocket(Rocket),
		cargo(Cargo),
		place(Place).
	adds(load(Rocket, _Place, Cargo),[in(Cargo,Rocket)], _) :-
		rocket(Rocket),
		cargo(Cargo).

	deletes(move(Rocket,From,_To),[at(Rocket,From), has_fuel(Rocket)]):-
		rocket(Rocket),
		place(From).
	deletes(unload(Rocket, _Place, Cargo),[in(Cargo,Rocket)]) :-
		rocket(Rocket),
		cargo(Cargo).
	deletes(load(Rocket, Place, Cargo),[at(Cargo,Place)]) :-
		rocket(Rocket),
		cargo(Cargo),
		place(Place).

:- end_object.
