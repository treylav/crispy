/**
 * @description Crispy is an automated unit testing framework built in GML for GameMaker Studio 2.3+
 * https://github.com/bfrymire/crispy
 * Copyright (c) 2020-2021 bfrymire
 */

#macro CRISPY_VERSION "1.1.0"
#macro CRISPY_DATE "12/13/2020"
#macro CRISPY_NAME "Crispy"
#macro CRISPY_RUN true
#macro CRISPY_DEBUG false
#macro CRISPY_VERBOSITY 2 // {0|1|2}
#macro CRISPY_TIME_PRECISION 6
#macro CRISPY_PASS_MSG_SILENT "."
#macro CRISPY_FAIL_MSG_SILENT "F"
#macro CRISPY_PASS_MSG_VERBOSE "ok"
#macro CRISPY_FAIL_MSG_VERBOSE "Fail"

show_debug_message("Using " + CRISPY_NAME + " automated unit testing framework version " + CRISPY_VERSION);


// @param [name]
// @param [struct]
function TestRunner() constructor {

	// Give self cripsyStructUnpack() function
	crispyMixinStructUnpack(self);

	// @param log
	static addLog = function(_log) {
		array_push(logs, _log);
	}

	// @param instance
	static captureLogs = function(_inst) {
		switch (instanceof(_inst)) {
			case "CrispyLog":
				self.addLog(_inst);
				break;
			case "TestCase":
				var _logs_len = array_length(_inst.logs);
				for(var i = 0; i < _logs_len; i++) {
					self.addLog(_inst.logs[i]);
				}
				break;
			case "TestSuite":
				var _tests_len = array_length(_inst.tests);
				for(var k = 0; k < _tests_len; k++) {
					var _logs_len = array_length(_inst.tests[k].logs);
					for(var i = 0; i < _logs_len; i++) {
						self.addLog(_inst.tests[k].logs[i]);
					}
				}
				break;
			default:
				crispyErrorExpected(self, "captureLogs", "{CrispyLog|TestCase|TestSuite}", logger);
				break;
		}
	}

	// @param suite
	static addTestSuite = function(_suite) {
		var _inst = instanceof(_suite);
		if _inst != "TestSuite" {
			crispyErrorExpected(self, "addTestSuite", "TestSuite", _suite);
		}
		_suite.parent = self;
		array_push(self.suites, _suite);
	}


	// @param [string]
	// @param [count]
	static hr = function() {
		var _str = (argument_count > 0 && is_string(argument[0])) ? argument[0] : "-";
		var _count = (argument_count > 1 && is_real(argument[1])) ? clamp(floor(argument[1]), 0, 120) : 70;
		var _hr = "";
		repeat(_count) {
			_hr += _str;
		}
		return _hr;
	}

  	static run = function() {
		self.setUp();
		var _len = array_length(self.suites);
		for(var i = 0; i < _len; i++) {
			self.suites[i].run();
			self.captureLogs(self.suites[i]);
		}
		self.tearDown();
	}

	// @param [function]
	static setUp = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__setUp__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "setUp", "method function", argument[0]);
			}
		} else {
			self.logs = [];
			self.start_time = crispyGetTime();
			if is_method(self.__setUp__) {
				self.__setUp__();
			}
		}
	}

	// @param [name]
	// @param [function]
	static tearDown = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__tearDown__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "tearDown", "method function", argument[0]);
			}
		} else {
			// Get total run time
			self.stop_time = crispyGetTime();
			self.total_time = crispyGetTimeDiff(self.start_time, self.stop_time);
			self.display_time = crispyTimeConvert(self.total_time);

			// Display test results
			var _passed_tests = 0;
			var _len = array_length(self.logs);
			var _t = "";
			for(var i = 0; i < _len; i++) {
				if self.logs[i].pass {
					_t += CRISPY_PASS_MSG_SILENT;
				} else {
					_t += CRISPY_FAIL_MSG_SILENT;
				}
			}
			show_debug_message(_t);

			// Horizontal row
			show_debug_message(hr());

			// Show individual log messages
			for(var i = 0; i < _len; i++) {
				if logs[i].pass {
					_passed_tests += 1;
				}
				var _msg = logs[i].getMsg();
				if _msg != "" {
					show_debug_message(_msg);
				}
			}

			// Finish by showing entire time it took to run the suite
			var string_tests = _len == 1 ? "test" : "tests";
			show_debug_message("\n" + string(_len) + " " + string_tests + " ran in " + self.display_time + "s");

			if _passed_tests == _len {
				show_debug_message(string_upper(CRISPY_PASS_MSG_VERBOSE));
			}

			if is_method(self.__tearDown__) {
				self.__tearDown__();
			}
			
		}

	}

	__setUp__ = undefined;
	__tearDown__ = undefined;
	name = (argument_count > 0 && !is_string(argument[0])) ? argument[0] : "TestRunner";
	start_time = 0;
	stop_time = 0;
	total_time = 0;
	display_time = "0";
	suites = [];
	logs = [];

	// Struct unpacker
	if argument_count > 1 {
		self.crispyStructUnpack(argument[1]);
	}

}


// @param [name]
// @param [struct]
function TestSuite() constructor {

	// Give self cripsyStructUnpack() function
	crispyMixinStructUnpack(self);

	// @param case
	static addTestCase = function(_case) {
		var _inst = instanceof(_case);
		if _inst != "TestCase" {
			var _type_received = !is_undefined(_inst) ? _inst : typeof(_case);
			crispyErrorExpected(self, "addTestCase", "TestCase", _type_received);
		}
		_case.parent = self;
		array_push(self.tests, _case);
	}

	// @param [function]
	static setUp = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__setUp__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "setUp", "method function", argument[0]);
			}
		} else {
			if is_method(self.__setUp__) {
				self.__setUp__();
			}
		}
	}

	// @param [function]
	static tearDown = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__tearDown__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "tearDown", "method function", argument[0]);
			}
		} else {
			if is_method(self.__tearDown__) {
				self.__tearDown__();
			}
		}
	}

	static run = function() {
		self.setUp();
		var _len = array_length(self.tests);
		for(var i = 0; i < _len; i++) {
			self.tests[i].run();
		}
		self.tearDown();
	}

	// @param name
	static setName = function(_name) {
		if !is_string(_name) {
			crispyErrorExpected(self, "setName", "string", _name);
		}
		self.name = _name;
	}

	__setUp__ = undefined;
	__tearDown__ = undefined;
	parent = undefined;
	tests = [];
	name = (argument_count > 0 && !is_string(argument[0])) ? argument[0] : "TestSuite";


	// Struct unpacker
	if argument_count > 1 {
		self.crispyStructUnpack(argument[1]);
	}

}

/**
 * Creates a Test case object to run assertions.
 * @constructor
 * @param function
 * @param [name]
 */
function TestCase(_function) constructor {
	// Give self cripsyStructUnpack() function
	crispyMixinStructUnpack(self);

	if !is_method(_function) {
		crispyErrorExpected(self, "", "method function", _function);
	}

	static addLog = function(_log) {
		array_push(self.logs, _log);
	}

	static clearLogs = function() {
		self.logs = [];
	}

	/**
	 * Test that first and second are equal.
	 * The first and second will be checked for the same type first, then check if they're equal.
	 * @function
	 * @param {*} first - First value.
	 * @param {*} second - Second value to check against.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertEqual = function(_first, _second) {
		var _msg = (argument_count > 2) ? argument[2] : undefined;
		if typeof(_first) != typeof(_second) {
			self.addLog(new CrispyLog(self, {pass:false,msg:"Supplied typeof() values are not equal: " + typeof(_first) + " and " + typeof(_second) + "."}));
			return;
		}
		if _first == _second {
			self.addLog(new CrispyLog(self));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"first and second are not equal: " + string(_first) + ", " + string(_second)}));
		}
	}

	/**
	 * Test that first and second are not equal.
	 * @function
	 * @param {*} first - First type to check.
	 * @param {*} second - Second type to check against.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertNotEqual = function(_first, _second) {
		var _msg = (argument_count > 2) ? argument[2] : undefined;
		if _first != _second {
			self.addLog(new CrispyLog(self, {pass:true}));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"first and second are equal: " + string(_first) + ", " + string(_second)}));
		}
	}

	/**
	 * Test whether the provided expression is true.
	 * The test will first convert the expr to a boolean, then check if it equals true.
	 * @function
	 * @param {*} expr - Expression to check.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertTrue = function(_expr) {
		var _msg = (argument_count > 1) ? argument[1] : undefined;
		try {
			var _bool = bool(_expr);
		}
		catch(err) {
			self.addLog(new CrispyLog(self, {pass:false,helper_text:"Unable to convert " + typeof(_expr) + " into boolean. Cannot evaluate."}));
			return;
		}
		if _bool == true {
			self.addLog(new CrispyLog(self, {pass:true}));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"Expression is not true."}));
		}
	}

	/**
	 * Test whether the provided expression is false.
	 * The test will first convert the expr to a boolean, then check if it equals false.
	 * @function
	 * @param {*} expr - Expression to check.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertFalse = function(_expr) {
		var _msg = (argument_count > 1) ? argument[1] : undefined;
		try {
			var _bool = bool(_expr);
		}
		catch(err) {
			self.addLog(new CrispyLog(self, {pass:false,helper_text:"Unable to convert " + typeof(_expr) + " into boolean. Cannot evaluate."}));
			return;
		}
		if _bool == false {
			self.addLog(new CrispyLog(self, {pass:true}));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"Expression is not false."}));
		}
	}

	/**
	 * Test whether the provided expression is noone.
	 * @function
	 * @param {*} expr - Expression to check.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertIsNoone = function(_expr) {
		var _msg = (argument_count > 1) ? argument[1] : undefined;
		if _expr == -4 {
			self.addLog(new CrispyLog(self, {pass:true}));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"Expression is not noone."}));
		}
	}

	/**
	 * Test whether the provided expression is not noone.
	 * @function
	 * @param {*} expr - Expression to check.
	 * @param {string} [_msg] - Custom message to output on failure.
	 */
	static assertIsNotNoone = function(_expr) {
		var _msg = (argument_count > 1) ? argument[1] : undefined;
		if _expr != -4 {
			self.addLog(new CrispyLog(self, {pass:true}));
		} else {
			self.addLog(new CrispyLog(self, {pass:false,msg:_msg,helper_text:"Expression is noone."}));
		}
	}

	static setUp = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__setUp__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "setUp", "method function", argument[0]);
			}
		} else {
			self.clearLogs();
			if is_method(self.__setUp__) {
				self.__setUp__();
			}
		}
	}
	
	static tearDown = function() {
		if argument_count > 0 {
			if is_method(argument[0]) {
				self.__tearDown__ = method(self, argument[0]);
			} else {
				crispyErrorExpected(self, "tearDown", "method function", argument[0]);
			}
		} else {
			if is_method(self.__tearDown__) {
				self.__tearDown__();
			}
		}
	}

	static run = function() {
		self.setUp();
		self.test();
		self.tearDown();
	}

	static setName = function(_name) {
		if !is_string(_name) {
			crispyErrorExpected(self, "setName", "string", _name);
		}
		self.name = _name;
	}

	if argument_count > 1 {
		setName(argument[1]);
	} else {
		self.name = undefined;
	}
	__setUp__ = undefined;
	__tearDown__ = undefined;
	class = instanceof(self);
	parent = undefined;
	test = method(self, _function);
	logs = [];

	// Struct unpacker
	if argument_count > 2 {
		self.crispyStructUnpack(argument[2]);
	}

}

/**
 * Returns the current time in micro-seconds since the project started running
 * @function
 */
function crispyGetTime() {
	return get_timer();
}

/**
 * Returns the difference between two times
 * @function
 */
function crispyGetTimeDiff(_start_time, _stop_time) {
	if !is_real(_start_time) {
		crispyErrorExpected(self, "crispyGetTimeDiff", "number", _start_time);
	}
	if !is_real(_stop_time) {
		crispyErrorExpected(self, "crispyGetTimeDiff", "number", _stop_time);
	}
	return _stop_time - _start_time;
}

/**
 * Returns the given time in seconds as a string
 * @function
 * @param [number] time - Time in milliseconds.
 */
function crispyTimeConvert(_time) {
	if !is_real(_time) {
		crispyErrorExpected(self, "crispyTimeConvert", "number", _time);
	}
	return string_format(_time / 1000000, 0, CRISPY_TIME_PRECISION);
}

/**
 * Saves the result and output of assertion.
 * @constructor
 * @param {TestCase} _case - TestCase struct that ran the assertion.
 * @param [struct] Structure to replace existing constructor values.
 */
function CrispyLog(_case) constructor {
	// Give self cripsyStructUnpack() function
	crispyMixinStructUnpack(self);

	static getMsg = function() {
		if self.verbosity == 2 && self.display_name != "" {
			var _msg = self.display_name + " ";
		} else {
			var _msg = "";
		}
		switch(self.verbosity) {
			case 0:
				if self.pass {
					_msg += CRISPY_PASS_MSG_SILENT;
				} else {
					_msg += CRISPY_FAIL_MSG_SILENT;
				}
				break;
			case 1:
				/*
				if self.pass {
					_msg += CRISPY_PASS_MSG_VERBOSE;
				} else {
					_msg += CRISPY_FAIL_MSG_VERBOSE;
				}
				*/
				break;
			case 2:
				if self.pass {
					_msg += "..." + CRISPY_PASS_MSG_VERBOSE;
				} else {
					if !is_undefined(self.msg) && self.msg != "" {
						_msg += " - " + self.msg;
					} else {
						if !is_undefined(self.helper_text) {
							_msg += " - " + self.helper_text;
						}
					}
				}
				break;
		}
		return _msg;
	}

	self.verbosity = CRISPY_VERBOSITY;
	self.pass = true;
	self.msg = undefined;
	self.helper_text = undefined;
	self.class = _case.class;
	self.name = _case.name;

	var _display_name = "";
	if !is_undefined(self.name) {
		_display_name += self.name;
	}
	if !is_undefined(self.class) {
		if _display_name != "" {
			_display_name += "." + self.class;
		} else {
			_display_name += self.class;
		}
	}
	self.display_name = _display_name;

	// Struct unpacker
	if argument_count > 1 {
		self.crispyStructUnpack(argument[1]);
	}

}

/**
 * Mixin function that extends structs to have the crispyStructUnpack() function.
 * @function
 * @param {struct} _struct - Struct to give method variable to.
 */
function crispyMixinStructUnpack(_struct) {
	if !is_struct(_struct) {
		crispyErrorExpected(self, crispyMixinStructUnpack, "struct", _struct);
	}
	_struct.crispyStructUnpack = method(_struct, crispyStructUnpack);
}

/**
 * Helper function for structs that will replace a destination's variable name values with the given source's variable
 * 		name values.
 * @function
 * @param {struct} struct - Struct used to replace existing values with.
 * @param {boolean} [name_must_exist=true] - Boolean flag that prevents new variable names from
 * 		being added to the destination struct if the variable name does not already exist.
 */
function crispyStructUnpack(_struct) {
	var _name_must_exist = (argument_count > 1 && is_bool(argument[1])) ? argument[1] : true;
	if !is_struct(_struct) {
		crispyErrorExpected(self, "crispyStructUnpack", "struct", _struct);
	}
	var _names = variable_struct_get_names(_struct);
	var _len = array_length(_names);
	for(var i = 0; i < _len; i++) {
		var _name = _names[i];
		if crispyIsInternalVariable(_name) {
			if CRISPY_DEBUG {
				crispyDebugMessage("Variable names beginning and ending in double underscores are reserved for the framework. Skip unpacking struct name: " + _name);
			}
			continue;
		}
		var _value = variable_struct_get(_struct, _name);
		if _name_must_exist {
			if !variable_struct_exists(self, _name) {
				if CRISPY_DEBUG {
					crispyDebugMessage("Variable name " + _name + " not found in struct, skipping writing variable name.");
				}
				continue;
			}
		}
		variable_struct_set(self, _name, _value);
	}
}

/**
 * Helper function for Crispy to display its debug messages
 * @function
 * @param {string} message - Text to be displayed in the Output Window.
 */
function crispyDebugMessage(_message) {
	if !is_string(_message) {
		crispyErrorExpected(self, "crispyDebugMessage", "string", _message);
	}
	show_debug_message(CRISPY_NAME + ": " + _message);
}

/**
 * Helper function for Crispy to throw an error message that displays what type of value the function was expecting.
 * @function
 * @param {struct} _self - Struct that is calling the function, usually self.
 * @param {string} _name - String of the name of the function that is currently running the error message.
 * @param {string} _expected - String of the type of value expected to receive.
 * @param {*} _received - Value received.
 */
function crispyErrorExpected(_self, _name, _expected, _received) {
	var _char = string_ord_at(string_lower(_expected), 1);
	var _vowels = ["a", "e", "i", "o", "u"];
	var _len = array_length(_vowels);
	var _preposition = "a";
	for(var i = 0; i < _len; i++) {
		if _char == _vowels[i] {
			_preposition = "an";
			break;
		}
	}
	_name = _name == "" ? _name : "." + _name;
	var _msg = instanceof(_self) + _name + "() expected " + _preposition + " ";
	_msg += _expected + ", received " + typeof(_received) + ".";
	show_error(_msg, true);
}

/**
 * Helper function for Crispy that returns whether or not a given variable name follows internal variable
 * 		naming convention.
 * @function
 * @param {string} _name - Name of variable to check.
 */
function crispyIsInternalVariable(_name) {
	if !is_string(_name) {
		crispyErrorExpected("crispyIsInternalVariable", "", "string", _name);
	}
	if string_char_at(_name, 1) == "_" && string_char_at(_name, 2) == "_" {
		var _len = string_length(_name);
		if string_char_at(_name, _len) == "_" && string_char_at(_name, _len - 1) == "_" {
			return true;
		}
	}
	return false;
}
