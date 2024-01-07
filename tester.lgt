
:- initialization((
	set_logtalk_flag(report, warnings),
	logtalk_load(basic_types(loader)),
	logtalk_load(sets(loader)),
	logtalk_load([
		graphplan,
		'examples/rocket'
	], [
		debug(on),
		source_data(on)
	]),
	logtalk_load(lgtunit(loader)),
	logtalk_load(tests, [hook(lgtunit)]),
	tests::run
)).
