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

% (C) 2011 Suresh Manandhar, Pierre Andrews

% Graphplan Planner based on Blum & Furst 1997. Journal of AI, 90:281-300.
%  Pierre Andrews and Suresh Manandhar Nov 2006
%

:- object(graphplan).

	:- info([
		version is 1:0:0,
		author is 'The Prolog GraphPlan Project; Logtalk port by Paulo Moura',
		date is 2024-01-07,
		comment is 'The Graphplan algorithm is an automatic planning algorithm that can compute, given a set of rules, a plan of action to go from an initial state to a final state.'
	]).

	:- public([
		plan/3, write_plan/1,
		deletes/2, can/2, adds/3
	]).

	:- private(no_op_count/1).
	:- dynamic(no_op_count/1).

	:- private(mutex_action/3).
	:- dynamic(mutex_action/3).

	:- private(mutex_condition/3).
	:- dynamic(mutex_condition/3).

	:- private(plan_graph_del/3).
	:- dynamic(plan_graph_del/3).

	:- private(plan_graph_add/3).
	:- dynamic(plan_graph_add/3).

	:- private(plan_graph_pre/3).
	:- dynamic(plan_graph_pre/3).

	:- uses(list, [member/2]).
	:- uses(set, [as_set/2 as list_to_set/2, insert/3, subset/2, subtract/3]).

	plan(InitialState, FinalState, Plan) :-
		::retractall(no_op_count(_)),
		::retractall(mutex_action(_, _, _)),
		::retractall(mutex_condition(_, _, _)),
		::retractall(plan_graph_del(_, _, _)),
		::retractall(plan_graph_add(_, _, _)),
		::retractall(plan_graph_pre(_, _, _)),
		::assertz(no_op_count(0)),
		add_initial_conditions(InitialState),
		list_to_set(InitialState, InitialStateSet),
		list_to_set(FinalState, FinalStateSet),
		generate_graph_nodes(1, FinalStateSet, FinalLevel),
		find_plan(FinalLevel, FinalStateSet, InitialStateSet, [], PlanT),
		remove_no_ops(PlanT, Plan).

	find_plan(0, CurrentState, InitialState, Plan, Plan) :-
		subset(CurrentState, InitialState).
	find_plan(N, CurrentState, InitialState, Plan0, Plan) :-
		N > 0,
		find_current_level_actions(N, CurrentState,  [], CurLevelNActions, []),
		findall(Cond, (member(Action, CurLevelNActions), plan_graph(N, pre, Cond, Action)), PreConds),
		list_to_set(PreConds, MidState),
		% nl, write('Level  '), write(N),
		% nl, write('Actions : '), nl, write(CurLevelNActions),
		% nl, write('State   : '), nl, write(CurrentState), nl,nl,
		N1 is N - 1,
		find_plan(N1, MidState, InitialState, [CurLevelNActions| Plan0], Plan).

	find_current_level_actions(_, [], Actions, Actions, _).
	find_current_level_actions(N, CurrentState, Actions0, Actions, CurAdds0) :-
		member(Pred, CurrentState),
		choose_action_to_achieve_pred(N, Pred, Action),
		\+ (member(OtherAction, Actions0), ::mutex_action(N, Action, OtherAction)),
		findall(Cond, plan_graph(N, add, Cond, Action), AddCondsL),
		list_to_set(AddCondsL, AddConds),
		%% Plan minimality (as described in the paper) is equivalent to redundancy check
		%% There is no other action which has the same effect i.e. same add conditions
		\+ (member(OtherAdds,CurAdds0), subset(AddConds,OtherAdds), subset(OtherAdds,AddConds)),
		subtract(CurrentState, AddConds, CurrentStateMod),
		insert(Actions0, Action, Actions1),
		insert(CurAdds0, AddConds, CurAdds1),
		find_current_level_actions(N, CurrentStateMod, Actions1, Actions, CurAdds1).

	choose_action_to_achieve_pred(N, Pred, no_op(X)) :-  %% Generate shorter plans using the following strategy
		plan_graph(N, add, Pred, no_op(X)).                   %% Be lazy: prefer no ops

	choose_action_to_achieve_pred(N, Pred, OtherAction) :-    %% Choose real actions only if no ops fail
		plan_graph(N, add, Pred, OtherAction),
		OtherAction \= no_op(_).

	add_initial_conditions([]).
	add_initial_conditions([Pred|Conditions]) :-
		add_plan_graph(0, add, Pred, start),
		add_initial_conditions(Conditions).

	generate_graph_nodes(N, _, _) :-
		N > 30,
		%% The program is probably too slow beyond this point
		!,
		nl, nl, write('Bound reached'),
		nl, write('Terminating.....'),
		fail.
	generate_graph_nodes(N, FinalState, N1) :-
		N1 is N-1,
		%% Check if FinalState Conditions have been satisfied 
		%% and no mutual exclusion conditions have been violated
		get_nonmutex_addconds(FinalState, N1, []),
		% nl, write('Feasible Plan found at level '), write(N1),
		!.
	generate_graph_nodes(N, _, _) :-
		% Add no-ops
		add_no_op_nodes(N),
		fail.
	generate_graph_nodes(N, _, _) :-
		::can(Action, PreConditions),
		NPrev is N-1,
		get_nonmutex_addconds(PreConditions, NPrev, []),
		::deletes(Action, DelPreConditions),
		%% Instantiation Check
		(	ground(DelPreConditions) ->
			true
		;	nl, 
			write('Action not fully instantiated '), write(Action),
			nl,
			write('Del Conditions: '), write(DelPreConditions), nl
		),
		::adds(Action, AddConditions, _),
		%% Instantiation Check
		(	ground(AddConditions) ->
			true
		;	nl, 
			write('Action not fully instantiated '), write(Action),
			nl,
			write('Add Conditions: '), write(AddConditions), nl
		),
		add_graph_nodes(PreConditions, Action, N, pre),
		add_graph_nodes(DelPreConditions, Action, N, del),
		add_graph_nodes(AddConditions, Action, N, add),
	%	nl, write("Added Action: "), write(Action),
	%	nl,
		fail.
	generate_graph_nodes(N, FinalState, FinalLevel) :-
		% Propagate mutual exclusions
		mutex(N),
		N1 is N+1,
		!,
		generate_graph_nodes(N1, FinalState, FinalLevel),
		!.

	get_nonmutex_addconds([], _, _).
	get_nonmutex_addconds([Pred|Conditions], N, PrePreds) :-
		plan_graph(N, add, Pred, _),
		check_mutex(PrePreds, Pred, N),
		get_nonmutex_addconds(Conditions, N, [Pred|PrePreds]).
	
	check_mutex([], _, _).
	check_mutex([OtherPred|Others], Pred, N) :-
		\+ ::mutex_condition(N, Pred, OtherPred),
		check_mutex(Others, Pred, N).

	mutex(N) :-
		mutex_add_del_conflict(N),
		mutex_precond_conflict(N),
		mutex_add_add_conflict(N).

	mutex_add_del_conflict(N) :-
		plan_graph(N, del, Pred, Action2),
		(	plan_graph(N, add, Pred, Action1)
		;	plan_graph(N, pre, Pred, Action1)
		),
		Action1 \= Action2,
		insert_action_conflict(N, Action1, Action2),
		fail.
	mutex_add_del_conflict(_).

	insert_action_conflict(N, Action1, Action2) :-
		add_to_db(mutex_action(N, Action1, Action2)),
		add_to_db(mutex_action(N, Action2, Action1)).

	mutex_add_add_conflict(N) :-
		::mutex_action(N, Action1, Action2),
		plan_graph(N, add, Pred1, Action1),
		plan_graph(N, add, Pred2, Action2),
		Action1 \= Action2,
		Pred1 \= Pred2,
		\+ ::mutex_condition(N, Pred1, Pred2),
		\+ (
			plan_graph(N, add, Pred1, Action11),
			plan_graph(N, add, Pred2, Action22),
			Action11 \= Action22,
			\+ ::mutex_action(N, Action11, Action22)
		),
		add_to_db(mutex_condition(N, Pred1, Pred2)),
		add_to_db(mutex_condition(N, Pred2, Pred1)),
		fail.
	mutex_add_add_conflict(_).

	mutex_precond_conflict(N) :-
		N1 is N-1,
		mutex_condition(N1, Pred1, Pred2),
		plan_graph(N, pre, Pred1, Action1),
		plan_graph(N, pre, Pred2, Action2),
		Action1 \= Action2,
		insert_action_conflict(N, Action1, Action2),
		fail.
	mutex_precond_conflict(_).

	plan_graph(N, del, Pred, Action) :-
		::plan_graph_del(N, Pred, Action).
	plan_graph(N, pre, Pred, Action) :-
		::plan_graph_pre(N, Pred, Action).
	plan_graph(N, add, Pred, Action) :-
		::plan_graph_add(N, Pred, Action).

	add_plan_graph(N, del, Pred, Action) :-
		::plan_graph_del(N, Pred, Action),
		!.
	add_plan_graph(N, del, Pred, Action) :-
		::assertz(plan_graph_del(N, Pred, Action)).
	add_plan_graph(N, pre, Pred, Action) :-
		::plan_graph_pre(N, Pred, Action),
		!.
	add_plan_graph(N, pre, Pred, Action) :-
		::assertz(plan_graph_pre(N, Pred, Action)).
	add_plan_graph(N, add, Pred, Action) :-
		::plan_graph_add(N, Pred, Action),
		!.
	add_plan_graph(N, add, Pred, Action) :-
		::assertz(plan_graph_add(N, Pred, Action)).

	add_graph_nodes([], _, _, _).
	add_graph_nodes([Pred|Conditions], Action, N, Type) :-
		add_plan_graph(N, Type, Pred, Action),
		add_graph_nodes(Conditions, Action, N, Type).

	add_no_op_nodes(N) :-
		NPrev is N-1,
		plan_graph(NPrev, add, Pred, _),
		add_no_op_node(Pred, N),
		fail.
	add_no_op_nodes(_).

	add_no_op_node(Pred, N) :-
		\+ (plan_graph(N, add, Pred, no_op(C)), plan_graph(N, pre, Pred, no_op(C))),
		new_no_op_count(Count),
		add_plan_graph(N, add, Pred, no_op(Count)),
		add_plan_graph(N, pre, Pred, no_op(Count)).

	new_no_op_count(N) :-
		::retract(no_op_count(N)),
		N1 is N+1,
		::assertz(no_op_count(N1)).

	add_to_db(Clause) :-
		::Clause,
		!.
	add_to_db(Clause) :-
		::assertz(Clause).

	write_plan(Plan) :-
		write_plan(Plan, 1).

	write_plan([], _) :-
		nl.
	write_plan([Actions|Rest], N) :-
		nl, write('Step '), write(N), write(:), nl,
		write_list(Actions),
		N1 is N+1,
		write_plan(Rest, N1).

	write_list([]).
	write_list([no_op(_)| L]) :-
		!,
		write_list(L).
	write_list([X|L]) :-
		write('        '), write(X), nl,
		write_list(L).

	remove_no_ops([],[]).
	remove_no_ops([no_op(_)|L],R) :-
		!,
		remove_no_ops(L,R).
	remove_no_ops([X|L],[X1|R]) :-
		!,
		remove_no_ops(X,X1),
		remove_no_ops(L,R).
	remove_no_ops(X,X).

:- end_object.
