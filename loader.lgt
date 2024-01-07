
:- initialization((
	logtalk_load(basic_types(loader)),
	logtalk_load(sets(loader)),
	logtalk_load([
		graphplan
	], [
		optimize(on),
		portability(warning)
	])
)).
