/**
 * @preserve IntegraXor Web SCADA - JavaScript Number Formatter
 * http://www.integraxor.com/
 * author: KPL, KHL
 * (c)2011 ecava
 * Dual licensed under the MIT or GPL Version 2 licenses.
 */

////////////////////////////////////////////////////////////////////////////////
// param: Mask & Value
////////////////////////////////////////////////////////////////////////////////

this['formatNumber'] = function(m, v){
	var prefix, suffix;
	if (m) {
		var i1, i2, i;
		i1 = m.indexOf("#"), i2 = m.indexOf("0");
		if (i1 < 0) i1 = 0;
		if (i2 < 0) i2 = 0;
		i = i1 < i2 ? i1 : i2;
		if (i > 0) {
			prefix = m.substring(0, i);
			m = m.substring(i)
		}

		i1 = m.lastIndexOf("#"), i2 = m.lastIndexOf("0");
		i = i1 > i2 ? i1 : i2;
		if (i > 0 && i < m.length - 1) {
			suffix = m.substring(i)
			m = m.substring(0, i)
		}
	}

	if (!m || isNaN(+v)) {
		return v; //return as it is.
	}
	//convert any string to number according to formation sign.
	var v = m.charAt(0) == '-'? -v: +v;
	var isNegative = v<0? v= -v: 0; //process only abs(), and turn on flag.

	//search for separator for grp & decimal, anything not digit, not +/- sign, not #.
	var result = m.match(/[^\d\-\+#]/g);
	var Decimal = (result && result[result.length-1]) || '.'; //treat the right most symbol as decimal
	var Group = (result && result[1] && result[0]) || ',';  //treat the left most symbol as group separator

	//split the decimal for the format string if any.
	var m = m.split( Decimal);
	//Fix the decimal first, toFixed will auto fill trailing zero.
	v = v.toFixed( m[1] && m[1].length);
	v = +(v) + ''; //convert number to string to trim off *all* trailing decimal zero(es)

	//fill back any trailing zero according to format
	var pos_trail_zero = m[1] && m[1].lastIndexOf('0'); //look for last zero in format
	var part = v.split('.');
	//integer will get !part[1]
	if (!part[1] || part[1] && part[1].length <= pos_trail_zero) {
		v = (+v).toFixed( pos_trail_zero+1);
	}
	var szSep = m[0].split( Group); //look for separator
	m[0] = szSep.join(''); //join back without separator for counting the pos of any leading 0.

	var pos_lead_zero = m[0] && m[0].indexOf('0');
	if (pos_lead_zero > -1 ) {
		while (part[0].length < (m[0].length - pos_lead_zero)) {
			part[0] = '0' + part[0];
		}
	}
	else if (+part[0] == 0){
		part[0] = '';
	}

	v = v.split('.');
	v[0] = part[0];

	//process the first group separator from decimal (.) only, the rest ignore.
	//get the length of the last slice of split result.
	var pos_separator = ( szSep[1] && szSep[ szSep.length-1].length);
	if (pos_separator) {
		var integer = v[0];
		var str = '';
		var offset = integer.length % pos_separator;
		for (var i=0, l=integer.length; i<l; i++) {

			str += integer.charAt(i); //ie6 only support charAt for sz.
			//-pos_separator so that won't trail separator on full length
			if (!((i-offset+1)%pos_separator) && i<l-pos_separator ) {
				str += Group;
			}
		}
		v[0] = str;
	}

	v[1] = (m[1] && v[1])? Decimal+v[1] : "";
	return (prefix || "") + ((isNegative?'-':'') + v[0] + v[1]) + (suffix || ""); //put back any negation and combine integer and fraction.
};
/**
 * @preserve XDate v0.8
 * Docs & Licensing: http://arshaw.com/xdate/
 */

/*
 * Internal Architecture
 * ---------------------
 * An XDate wraps a native Date. The native Date is stored in the '0' property of the object.
 * UTC-mode is determined by whether the internal native Date's toString method is set to
 * Date.prototype.toUTCString (see getUTCMode).
 *
 */

var XDate = (function(Date, Math, Array, undefined) {


/** @const */ var FULLYEAR     = 0;
/** @const */ var MONTH        = 1;
/** @const */ var DATE         = 2;
/** @const */ var HOURS        = 3;
/** @const */ var MINUTES      = 4;
/** @const */ var SECONDS      = 5;
/** @const */ var MILLISECONDS = 6;
/** @const */ var DAY          = 7;
/** @const */ var YEAR         = 8;
/** @const */ var WEEK         = 9;
/** @const */ var DAY_MS = 86400000;
var ISO_FORMAT_STRING = "yyyy-MM-dd'T'HH:mm:ss(.fff)";
var ISO_FORMAT_STRING_TZ = ISO_FORMAT_STRING + "zzz";


var methodSubjects = [
	'FullYear',     // 0
	'Month',        // 1
	'Date',         // 2
	'Hours',        // 3
	'Minutes',      // 4
	'Seconds',      // 5
	'Milliseconds', // 6
	'Day',          // 7
	'Year'          // 8
];
var subjectPlurals = [
	'Years',        // 0
	'Months',       // 1
	'Days'          // 2
];
var unitsWithin = [
	12,   // months in year
	31,   // days in month (sort of)
	24,   // hours in day
	60,   // minutes in hour
	60,   // seconds in minute
	1000, // milliseconds in second
	1     //
];
var formatStringRE = new RegExp(
	"(([a-zA-Z])\\2*)|" + // 1, 2
	"(\\(" + "(('.*?'|\\(.*?\\)|.)*?)" + "\\))|" + // 3, 4, 5 (allows for 1 level of inner quotes or parens)
	"('(.*?)')" // 6, 7
);
var UTC = Date.UTC;
var toUTCString = Date.prototype.toUTCString;
var proto = XDate.prototype;



// This makes an XDate look pretty in Firebug and Web Inspector.
// It makes an XDate seem array-like, and displays [ <internal-date>.toString() ]
proto.length = 1;
proto.splice = Array.prototype.splice;




/* Constructor
---------------------------------------------------------------------------------*/

// TODO: in future, I'd change signature for the constructor regarding the `true` utc-mode param. ~ashaw
//   I'd move the boolean to be the *first* argument. Still optional. Seems cleaner.
//   I'd remove it from the `xdate`, `nativeDate`, and `milliseconds` constructors.
//      (because you can simply call .setUTCMode(true) after)
//   And I'd only leave it for the y/m/d/h/m/s/m and `dateString` constructors
//      (because those are the only constructors that need it for DST-gap data-loss reasons)
//   Should do this for 1.0

function XDate() {
	return init(
		(this instanceof XDate) ? this : new XDate(),
		arguments
	);
}


function init(xdate, args) {
	var len = args.length;
	var utcMode;
	if (isBoolean(args[len-1])) {
		utcMode = args[--len];
		args = slice(args, 0, len);
	}
	if (!len) {
		xdate[0] = new Date();
	}
	else if (len == 1) {
		var arg = args[0];
		if (arg instanceof Date || isNumber(arg)) {
			xdate[0] = new Date(+arg);
		}
		else if (arg instanceof XDate) {
			xdate[0] = _clone(arg);
		}
		else if (isString(arg)) {
			xdate[0] = new Date(0);
			xdate = parse(arg, utcMode || false, xdate);
		}
	}
	else {
		xdate[0] = new Date(UTC.apply(Date, args));
		if (!utcMode) {
			xdate[0] = coerceToLocal(xdate[0]);
		}
	}
	if (isBoolean(utcMode)) {
		setUTCMode(xdate, utcMode);
	}
	return xdate;
}



/* UTC Mode Methods
---------------------------------------------------------------------------------*/


proto.getUTCMode = methodize(getUTCMode);
function getUTCMode(xdate) {
	return xdate[0].toString === toUTCString;
};


proto.setUTCMode = methodize(setUTCMode);
function setUTCMode(xdate, utcMode, doCoercion) {
	if (utcMode) {
		if (!getUTCMode(xdate)) {
			if (doCoercion) {
				xdate[0] = coerceToUTC(xdate[0]);
			}
			xdate[0].toString = toUTCString;
		}
	}else{
		if (getUTCMode(xdate)) {
			if (doCoercion) {
				xdate[0] = coerceToLocal(xdate[0]);
			}else{
				xdate[0] = new Date(+xdate[0]);
			}
			// toString will have been cleared
		}
	}
	return xdate; // for chaining
}


proto.getTimezoneOffset = function() {
	if (getUTCMode(this)) {
		return 0;
	}else{
		return this[0].getTimezoneOffset();
	}
};



/* get / set / add / diff Methods (except for week-related)
---------------------------------------------------------------------------------*/


each(methodSubjects, function(subject, fieldIndex) {

	proto['get' + subject] = function() {
		return _getField(this[0], getUTCMode(this), fieldIndex);
	};
	
	if (fieldIndex != YEAR) { // because there is no getUTCYear
	
		proto['getUTC' + subject] = function() {
			return _getField(this[0], true, fieldIndex);
		};
		
	}

	if (fieldIndex != DAY) { // because there is no setDay or setUTCDay
	                         // and the add* and diff* methods use DATE instead
		
		proto['set' + subject] = function(value) {
			_set(this, fieldIndex, value, arguments, getUTCMode(this));
			return this; // for chaining
		};
		
		if (fieldIndex != YEAR) { // because there is no setUTCYear
		                          // and the add* and diff* methods use FULLYEAR instead
			
			proto['setUTC' + subject] = function(value) {
				_set(this, fieldIndex, value, arguments, true);
				return this; // for chaining
			};
			
			proto['add' + (subjectPlurals[fieldIndex] || subject)] = function(delta, preventOverflow) {
				_add(this, fieldIndex, delta, preventOverflow);
				return this; // for chaining
			};
			
			proto['diff' + (subjectPlurals[fieldIndex] || subject)] = function(otherDate) {
				return _diff(this, otherDate, fieldIndex);
			};
			
		}
		
	}

});


function _set(xdate, fieldIndex, value, args, useUTC) {
	var getField = curry(_getField, xdate[0], useUTC);
	var setField = curry(_setField, xdate[0], useUTC);
	var expectedMonth;
	var preventOverflow = false;
	if (args.length == 2 && isBoolean(args[1])) {
		preventOverflow = args[1];
		args = [ value ];
	}
	if (fieldIndex == MONTH) {
		expectedMonth = (value % 12 + 12) % 12;
	}else{
		expectedMonth = getField(MONTH);
	}
	setField(fieldIndex, args);
	if (preventOverflow && getField(MONTH) != expectedMonth) {
		setField(MONTH, [ getField(MONTH) - 1 ]);
		setField(DATE, [ getDaysInMonth(getField(FULLYEAR), getField(MONTH)) ]);
	}
}


function _add(xdate, fieldIndex, delta, preventOverflow) {
	delta = Number(delta);
	var intDelta = Math.floor(delta);
	xdate['set' + methodSubjects[fieldIndex]](
		xdate['get' + methodSubjects[fieldIndex]]() + intDelta,
		preventOverflow || false
	);
	if (intDelta != delta && fieldIndex < MILLISECONDS) {
		_add(xdate, fieldIndex+1, (delta-intDelta)*unitsWithin[fieldIndex], preventOverflow);
	}
}


function _diff(xdate1, xdate2, fieldIndex) { // fieldIndex=FULLYEAR is for years, fieldIndex=DATE is for days
	xdate1 = xdate1.clone().setUTCMode(true, true);
	xdate2 = XDate(xdate2).setUTCMode(true, true);
	var v = 0;
	if (fieldIndex == FULLYEAR || fieldIndex == MONTH) {
		for (var i=MILLISECONDS, methodName; i>=fieldIndex; i--) {
			v /= unitsWithin[i];
			v += _getField(xdate2, false, i) - _getField(xdate1, false, i);
		}
		if (fieldIndex == MONTH) {
			v += (xdate2.getFullYear() - xdate1.getFullYear()) * 12;
		}
	}
	else if (fieldIndex == DATE) {
		var clear1 = xdate1.toDate().setUTCHours(0, 0, 0, 0); // returns an ms value
		var clear2 = xdate2.toDate().setUTCHours(0, 0, 0, 0); // returns an ms value
		v = Math.round((clear2 - clear1) / DAY_MS) + ((xdate2 - clear2) - (xdate1 - clear1)) / DAY_MS;
	}
	else {
		v = (xdate2 - xdate1) / [
			3600000, // milliseconds in hour
			60000,   // milliseconds in minute
			1000,    // milliseconds in second
			1        //
			][fieldIndex - 3];
	}
	return v;
}



/* Week Methods
---------------------------------------------------------------------------------*/


proto.getWeek = function() {
	return _getWeek(curry(_getField, this, false));
};


proto.getUTCWeek = function() {
	return _getWeek(curry(_getField, this, true));
};


proto.setWeek = function(n, year) {
	_setWeek(this, n, year, false);
	return this; // for chaining
};


proto.setUTCWeek = function(n, year) {
	_setWeek(this, n, year, true);
	return this; // for chaining
};


proto.addWeeks = function(delta) {
	return this.addDays(Number(delta) * 7);
};


proto.diffWeeks = function(otherDate) {
	return _diff(this, otherDate, DATE) / 7;
};


function _getWeek(getField) {
	return getWeek(getField(FULLYEAR), getField(MONTH), getField(DATE));
}


function getWeek(year, month, date) {
	var d = new Date(UTC(year, month, date));
	var week1 = getWeek1(
		getWeekYear(year, month, date)
	);
	return Math.floor(Math.round((d - week1) / DAY_MS) / 7) + 1;
}


function getWeekYear(year, month, date) { // get the year that the date's week # belongs to
	var d = new Date(UTC(year, month, date));
	if (d < getWeek1(year)) {
		return year - 1;
	}
	else if (d >= getWeek1(year + 1)) {
		return year + 1;
	}
	return year;
}


function getWeek1(year) { // returns Date of first week of year, in UTC
	var d = new Date(UTC(year, 0, 4));
	d.setUTCDate(d.getUTCDate() - (d.getUTCDay() + 6) % 7); // make it Monday of the week
	return d;
}


function _setWeek(xdate, n, year, useUTC) {
	var getField = curry(_getField, xdate, useUTC);
	var setField = curry(_setField, xdate, useUTC);

	if (year === undefined) {
		year = getWeekYear(
			getField(FULLYEAR),
			getField(MONTH),
			getField(DATE)
		);
	}

	var week1 = getWeek1(year);
	if (!useUTC) {
		week1 = coerceToLocal(week1);
	}

	xdate.setTime(+week1);
	setField(DATE, [ getField(DATE) + (n-1) * 7 ]); // would have used xdate.addUTCWeeks :(
		// n-1 because n is 1-based
}



/* Parsing
---------------------------------------------------------------------------------*/


XDate.parsers = [
	parseISO
];


XDate.parse = function(str) {
	return +XDate(''+str);
};


function parse(str, utcMode, xdate) {
	var parsers = XDate.parsers;
	var i = 0;
	var res;
	for (; i<parsers.length; i++) {
		res = parsers[i](str, utcMode, xdate);
		if (res) {
			return res;
		}
	}
	xdate[0] = new Date(str);
	return xdate;
}


function parseISO(str, utcMode, xdate) {
	var m = str.match(/^(\d{4})(-(\d{2})(-(\d{2})([T ](\d{2}):(\d{2})(:(\d{2})(\.(\d+))?)?(Z|(([-+])(\d{2})(:?(\d{2}))?))?)?)?)?$/);
	if (m) {
		var d = new Date(UTC(
			m[1],
			m[3] ? m[3] - 1 : 0,
			m[5] || 1,
			m[7] || 0,
			m[8] || 0,
			m[10] || 0,
			m[12] ? Number('0.' + m[12]) * 1000 : 0
		));
		if (m[13]) { // has gmt offset or Z
			if (m[14]) { // has gmt offset
				d.setUTCMinutes(
					d.getUTCMinutes() +
					(m[15] == '-' ? 1 : -1) * (Number(m[16]) * 60 + (m[18] ? Number(m[18]) : 0))
				);
			}
		}else{ // no specified timezone
			if (!utcMode) {
				d = coerceToLocal(d);
			}
		}
		return xdate.setTime(+d);
	}
}



/* Formatting
---------------------------------------------------------------------------------*/


proto.toString = function(formatString, settings, uniqueness) {
	if (formatString === undefined || !valid(this)) {
		return this[0].toString(); // already accounts for utc-mode (might be toUTCString)
	}else{
		return format(this, formatString, settings, uniqueness, getUTCMode(this));
	}
};


proto.toUTCString = proto.toGMTString = function(formatString, settings, uniqueness) {
	if (formatString === undefined || !valid(this)) {
		return this[0].toUTCString();
	}else{
		return format(this, formatString, settings, uniqueness, true);
	}
};


proto.toISOString = function() {
	return this.toUTCString(ISO_FORMAT_STRING_TZ);
};


XDate.defaultLocale = '';
XDate.locales = {
	'': {
		monthNames: ['January','February','March','April','May','June','July','August','September','October','November','December'],
		monthNamesShort: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
		dayNames: ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],
		dayNamesShort: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
		amDesignator: 'AM',
		pmDesignator: 'PM'
	}
};
XDate.formatters = {
	i: ISO_FORMAT_STRING,
	u: ISO_FORMAT_STRING_TZ
};


function format(xdate, formatString, settings, uniqueness, useUTC) {

	var locales = XDate.locales;
	var defaultLocaleSettings = locales[XDate.defaultLocale] || {};
	var getField = curry(_getField, xdate, useUTC);
	
	settings = (isString(settings) ? locales[settings] : settings) || {};
	
	function getSetting(name) {
		return settings[name] || defaultLocaleSettings[name];
	}
	
	function getFieldAndTrace(fieldIndex) {
		if (uniqueness) {
			var i = (fieldIndex == DAY ? DATE : fieldIndex) - 1;
			for (; i>=0; i--) {
				uniqueness.push(getField(i));
			}
		}
		return getField(fieldIndex);
	}
	
	return _format(xdate, formatString, getFieldAndTrace, getSetting, useUTC);
}


function _format(xdate, formatString, getField, getSetting, useUTC) {
	var m;
	var subout;
	var out = '';
	while (m = formatString.match(formatStringRE)) {
		out += formatString.substr(0, m.index);
		if (m[1]) { // consecutive alphabetic characters
			out += processTokenString(xdate, m[1], getField, getSetting, useUTC);
		}
		else if (m[3]) { // parenthesis
			subout = _format(xdate, m[4], getField, getSetting, useUTC);
			if (parseInt(subout.replace(/\D/g, ''), 10)) { // if any of the numbers are non-zero. or no numbers at all
				out += subout;
			}
		}
		else { // else if (m[6]) { // single quotes
			out += m[7] || "'"; // if inner is blank, meaning 2 consecutive quotes = literal single quote
		}
		formatString = formatString.substr(m.index + m[0].length);
	}
	return out + formatString;
}


function processTokenString(xdate, tokenString, getField, getSetting, useUTC) {
	var end = tokenString.length;
	var replacement;
	var out = '';
	while (end > 0) {
		replacement = getTokenReplacement(xdate, tokenString.substr(0, end), getField, getSetting, useUTC);
		if (replacement !== undefined) {
			out += replacement;
			tokenString = tokenString.substr(end);
			end = tokenString.length;
		}else{
			end--;
		}
	}
	return out + tokenString;
}


function getTokenReplacement(xdate, token, getField, getSetting, useUTC) {
	var formatter = XDate.formatters[token];
	if (isString(formatter)) {
		return _format(xdate, formatter, getField, getSetting, useUTC);
	}
	else if (isFunction(formatter)) {
		return formatter(xdate, useUTC || false, getSetting);
	}
	switch (token) {
		case 'fff'  : return zeroPad(getField(MILLISECONDS), 3);
		case 's'    : return getField(SECONDS);
		case 'ss'   : return zeroPad(getField(SECONDS));
		case 'm'    : return getField(MINUTES);
		case 'mm'   : return zeroPad(getField(MINUTES));
		case 'h'    : return getField(HOURS) % 12 || 12;
		case 'hh'   : return zeroPad(getField(HOURS) % 12 || 12);
		case 'H'    : return getField(HOURS);
		case 'HH'   : return zeroPad(getField(HOURS));
		case 'd'    : return getField(DATE);
		case 'dd'   : return zeroPad(getField(DATE));
		case 'ddd'  : return getSetting('dayNamesShort')[getField(DAY)] || '';
		case 'dddd' : return getSetting('dayNames')[getField(DAY)] || '';
		case 'M'    : return getField(MONTH) + 1;
		case 'MM'   : return zeroPad(getField(MONTH) + 1);
		case 'MMM'  : return getSetting('monthNamesShort')[getField(MONTH)] || '';
		case 'MMMM' : return getSetting('monthNames')[getField(MONTH)] || '';
		case 'yy'   : return (getField(FULLYEAR)+'').substring(2);
		case 'yyyy' : return getField(FULLYEAR);
		case 't'    : return _getDesignator(getField, getSetting).substr(0, 1).toLowerCase();
		case 'tt'   : return _getDesignator(getField, getSetting).toLowerCase();
		case 'T'    : return _getDesignator(getField, getSetting).substr(0, 1);
		case 'TT'   : return _getDesignator(getField, getSetting);
		case 'z'    :
		case 'zz'   :
		case 'zzz'  : return useUTC ? 'Z' : _getTZString(xdate, token);
		case 'w'    : return _getWeek(getField);
		case 'ww'   : return zeroPad(_getWeek(getField));
		case 'S'    :
			var d = getField(DATE);
			if (d > 10 && d < 20) return 'th';
			return ['st', 'nd', 'rd'][d % 10 - 1] || 'th';
	}
}


function _getTZString(xdate, token) {
	var tzo = xdate.getTimezoneOffset();
	var sign = tzo < 0 ? '+' : '-';
	var hours = Math.floor(Math.abs(tzo) / 60);
	var minutes = Math.abs(tzo) % 60;
	var out = hours;
	if (token == 'zz') {
		out = zeroPad(hours);
	}
	else if (token == 'zzz') {
		out = zeroPad(hours) + ':' + zeroPad(minutes);
	}
	return sign + out;
}


function _getDesignator(getField, getSetting) {
	return getField(HOURS) < 12 ? getSetting('amDesignator') : getSetting('pmDesignator');
}



/* Misc Methods
---------------------------------------------------------------------------------*/


each(
	[ // other getters
		'getTime',
		'valueOf',
		'toDateString',
		'toTimeString',
		'toLocaleString',
		'toLocaleDateString',
		'toLocaleTimeString',
		'toJSON'
	],
	function(methodName) {
		proto[methodName] = function() {
			return this[0][methodName]();
		};
	}
);


proto.setTime = function(t) {
	this[0].setTime(t);
	return this; // for chaining
};


proto.valid = methodize(valid);
function valid(xdate) {
	return !isNaN(+xdate[0]);
}


proto.clone = function() {
	return new XDate(this);
};


proto.clearTime = function() {
	return this.setHours(0, 0, 0, 0); // will return an XDate for chaining
};


proto.toDate = function() {
	return new Date(+this[0]);
};



/* Misc Class Methods
---------------------------------------------------------------------------------*/


XDate.now = function() {
	return +new Date();
};


XDate.today = function() {
	return new XDate().clearTime();
};


XDate.UTC = UTC;


XDate.getDaysInMonth = getDaysInMonth;



/* Internal Utilities
---------------------------------------------------------------------------------*/


function _clone(xdate) { // returns the internal Date object that should be used
	var d = new Date(+xdate[0]);
	if (getUTCMode(xdate)) {
		d.toString = toUTCString;
	}
	return d;
}


function _getField(d, useUTC, fieldIndex) {
	return d['get' + (useUTC ? 'UTC' : '') + methodSubjects[fieldIndex]]();
}


function _setField(d, useUTC, fieldIndex, args) {
	d['set' + (useUTC ? 'UTC' : '') + methodSubjects[fieldIndex]].apply(d, args);
}



/* Date Math Utilities
---------------------------------------------------------------------------------*/


function coerceToUTC(date) {
	return new Date(UTC(
		date.getFullYear(),
		date.getMonth(),
		date.getDate(),
		date.getHours(),
		date.getMinutes(),
		date.getSeconds(),
		date.getMilliseconds()
	));
}


function coerceToLocal(date) {
	return new Date(
		date.getUTCFullYear(),
		date.getUTCMonth(),
		date.getUTCDate(),
		date.getUTCHours(),
		date.getUTCMinutes(),
		date.getUTCSeconds(),
		date.getUTCMilliseconds()
	);
}


function getDaysInMonth(year, month) {
	return 32 - new Date(UTC(year, month, 32)).getUTCDate();
}



/* General Utilities
---------------------------------------------------------------------------------*/


function methodize(f) {
	return function() {
		return f.apply(undefined, [this].concat(slice(arguments)));
	};
}


function curry(f) {
	var firstArgs = slice(arguments, 1);
	return function() {
		return f.apply(undefined, firstArgs.concat(slice(arguments)));
	};
}


function slice(a, start, end) {
	return Array.prototype.slice.call(
		a,
		start || 0, // start and end cannot be undefined for IE
		end===undefined ? a.length : end
	);
}


function each(a, f) {
	for (var i=0; i<a.length; i++) {
		f(a[i], i);
	};
}


function isString(arg) {
	return typeof arg == 'string';
}


function isNumber(arg) {
	return typeof arg == 'number';
}


function isBoolean(arg) {
	return typeof arg == 'boolean';
}


function isFunction(arg) {
	return typeof arg == 'function';
}


function zeroPad(n, len) {
	len = len || 2;
	n += '';
	while (n.length < len) {
		n = '0' + n;
	}
	return n;
}



// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
	module.exports = XDate;
}

// AMD
if (typeof define === 'function' && define.amd) {
	define([], function() {
		return XDate;
	});
}


return XDate;

})(Date, Math, Array);

/*
 * Swipe 2.0
 *
 * Brad Birdsall
 * Copyright 2013, MIT License
 *
 */

function Swipe(container, options) {

	"use strict";

	// utilities
	var noop = function () {
	}; // simple no operation function
	var offloadFn = function (fn) {
		setTimeout(fn || noop, 0)
	}; // offload a functions execution

	// check browser capabilities
	var browser = {
		addEventListener: !!window.addEventListener,
		touch: ('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch,
		transitions: (function (temp) {
			var props = ['transitionProperty', 'WebkitTransition', 'MozTransition', 'OTransition', 'msTransition'];
			for (var i in props) if (temp.style[props[i]] !== undefined) return true;
			return false;
		})(document.createElement('swipe'))
	};

	// quit if no root element
	if (!container) return;
	var element = $fly(container).find("> .items-wrap")[0];
	var slides, slidePos, width, length;
	options = options || {};
	var index = parseInt(options.startSlide, 10) || 0;
	var speed = options.speed || 300;
	options.continuous = options.continuous !== undefined ? options.continuous : true;

	function setup() {

		// cache slides
		slides = element.children;
		length = slides.length;

		// set continuous to false if only one slide
		if (slides.length < 2) options.continuous = false;

		//special case if two slides
		if (browser.transitions && options.continuous && slides.length < 3) {
			element.appendChild(slides[0].cloneNode(true));
			element.appendChild(element.children[1].cloneNode(true));
			slides = element.children;
		}

		// create an array to store current positions of each slide
		slidePos = new Array(slides.length);

		// determine width of each slide
		width = container.getBoundingClientRect().width || container.offsetWidth;

		element.style.width = (slides.length * width) + 'px';

		// stack elements
		var pos = slides.length;
		while (pos--) {

			var slide = slides[pos];

			slide.style.width = width + 'px';
			slide.setAttribute('data-index', pos);

			if (browser.transitions) {
				slide.style.left = (pos * -width) + 'px';
				move(pos, index > pos ? -width : (index < pos ? width : 0), 0);
			}

		}

		// reposition elements before and after index
		if (options.continuous && browser.transitions) {
			move(circle(index - 1), -width, 0);
			move(circle(index + 1), width, 0);
		}

		if (!browser.transitions) element.style.left = (index * -width) + 'px';

		container.style.visibility = 'visible';

	}

	function prev() {

		if (options.continuous) slide(index - 1);
		else if (index) slide(index - 1);

	}

	function next() {

		if (options.continuous) slide(index + 1);
		else if (index < slides.length - 1) slide(index + 1);

	}

	function circle(index) {

		// a simple positive modulo using slides.length
		return (slides.length + (index % slides.length)) % slides.length;

	}

	function slide(to, slideSpeed) {

		// do nothing if already on requested slide
		if (index == to) return;

		if (browser.transitions) {

			var direction = Math.abs(index - to) / (index - to); // 1: backward, -1: forward

			// get the actual position of the slide
			if (options.continuous) {
				var natural_direction = direction;
				direction = -slidePos[circle(to)] / width;

				// if going forward but to < index, use to = slides.length + to
				// if going backward but to > index, use to = -slides.length + to
				if (direction !== natural_direction) to = -direction * slides.length + to;

			}

			var diff = Math.abs(index - to) - 1;

			// move all the slides between index and to in the right direction
			while (diff--) move(circle((to > index ? to : index) - diff - 1), width * direction, 0);

			to = circle(to);

			move(index, width * direction, slideSpeed || speed);
			move(to, 0, slideSpeed || speed);

			if (options.continuous) move(circle(to - direction), -(width * direction), 0); // we need to get the next in place

		} else {

			to = circle(to);
			animate(index * -width, to * -width, slideSpeed || speed);
			//no fallback for a circular continuous if the browser does not accept transitions
		}

		index = to;
		offloadFn(options.callback && options.callback(index, slides[index]));
	}

	function move(index, dist, speed) {

		translate(index, dist, speed);
		slidePos[index] = dist;

	}

	function translate(index, dist, speed) {

		var slide = slides[index];
		var style = slide && slide.style;

		if (!style) return;

		style.webkitTransitionDuration =
			style.MozTransitionDuration =
				style.msTransitionDuration =
					style.OTransitionDuration =
						style.transitionDuration = speed + 'ms';

		style.webkitTransform = 'translate(' + dist + 'px,0)' + 'translateZ(0)';
		style.msTransform =
			style.MozTransform =
				style.OTransform = 'translateX(' + dist + 'px)';

	}

	function animate(from, to, speed) {

		// if not an animation, just reposition
		if (!speed) {

			element.style.left = to + 'px';
			return;

		}

		var start = +new Date;

		var timer = setInterval(function () {

			var timeElap = +new Date - start;

			if (timeElap > speed) {

				element.style.left = to + 'px';

				if (delay) begin();

				options.transitionEnd && options.transitionEnd.call(event, index, slides[index]);

				clearInterval(timer);
				return;

			}

			element.style.left = (( (to - from) * (Math.floor((timeElap / speed) * 100) / 100) ) + from) + 'px';

		}, 4);

	}

	// setup auto slideshow
	var delay = options.auto || 0;
	var interval;

	function begin() {

		interval = setTimeout(next, delay);

	}

	function stop() {

		delay = 0;
		clearTimeout(interval);

	}


	// setup initial vars
	var start = {};
	var delta = {};
	var isScrolling;

	// setup event capturing
	var events = {

		handleEvent: function (event) {

			switch (event.type) {
				case 'touchstart':
					this.start(event);
					break;
				case 'touchmove':
					this.move(event);
					break;
				case 'touchend':
					offloadFn(this.end(event));
					break;
				case 'webkitTransitionEnd':
				case 'msTransitionEnd':
				case 'oTransitionEnd':
				case 'otransitionend':
				case 'transitionend':
					offloadFn(this.transitionEnd(event));
					break;
				case 'resize':
					offloadFn(setup);
					break;
			}

			if (options.stopPropagation) event.stopPropagation();

		},
		start: function (event) {

			var touches = event.touches[0];

			// measure start values
			start = {

				// get initial touch coords
				x: touches.pageX,
				y: touches.pageY,

				// store time to determine touch duration
				time: +new Date

			};

			// used for testing first move event
			isScrolling = undefined;

			// reset delta and end measurements
			delta = {};

			// attach touchmove and touchend listeners
			element.addEventListener('touchmove', this, false);
			element.addEventListener('touchend', this, false);

		},
		move: function (event) {

			// ensure swiping with one touch and not pinching
			if (event.touches.length > 1 || event.scale && event.scale !== 1) return

			if (options.disableScroll) event.preventDefault();

			var touches = event.touches[0];

			// measure change in x and y
			delta = {
				x: touches.pageX - start.x,
				y: touches.pageY - start.y
			}

			// determine if scrolling test has run - one time test
			if (typeof isScrolling == 'undefined') {
				isScrolling = !!( isScrolling || Math.abs(delta.x) < Math.abs(delta.y) );
			}

			// if user is not trying to scroll vertically
			if (!isScrolling) {

				// prevent native scrolling
				event.preventDefault();

				// stop slideshow
				stop();

				// increase resistance if first or last slide
				if (options.continuous) { // we don't add resistance at the end

					translate(circle(index - 1), delta.x + slidePos[circle(index - 1)], 0);
					translate(index, delta.x + slidePos[index], 0);
					translate(circle(index + 1), delta.x + slidePos[circle(index + 1)], 0);

				} else {

					delta.x =
						delta.x /
						( (!index && delta.x > 0               // if first slide and sliding left
							|| index == slides.length - 1        // or if last slide and sliding right
							&& delta.x < 0                       // and if sliding at all
						) ?
							( Math.abs(delta.x) / width + 1 )      // determine resistance level
							: 1 );                                 // no resistance if false

					// translate 1:1
					translate(index - 1, delta.x + slidePos[index - 1], 0);
					translate(index, delta.x + slidePos[index], 0);
					translate(index + 1, delta.x + slidePos[index + 1], 0);
				}

			}

		},
		end: function (event) {

			// measure duration
			var duration = +new Date - start.time;

			// determine if slide attempt triggers next/prev slide
			var isValidSlide =
				Number(duration) < 250               // if slide duration is less than 250ms
				&& Math.abs(delta.x) > 20            // and if slide amt is greater than 20px
				|| Math.abs(delta.x) > width / 2;      // or if slide amt is greater than half the width

			// determine if slide attempt is past start and end
			var isPastBounds =
				!index && delta.x > 0                            // if first slide and slide amt is greater than 0
				|| index == slides.length - 1 && delta.x < 0;    // or if last slide and slide amt is less than 0

			if (options.continuous) isPastBounds = false;

			// determine direction of swipe (true:right, false:left)
			var direction = delta.x < 0;

			// if not scrolling vertically
			if (!isScrolling) {

				if (isValidSlide && !isPastBounds) {

					if (direction) {

						if (options.continuous) { // we need to get the next in this direction in place

							move(circle(index - 1), -width, 0);
							move(circle(index + 2), width, 0);

						} else {
							move(index - 1, -width, 0);
						}

						move(index, slidePos[index] - width, speed);
						move(circle(index + 1), slidePos[circle(index + 1)] - width, speed);
						index = circle(index + 1);

					} else {
						if (options.continuous) { // we need to get the next in this direction in place

							move(circle(index + 1), width, 0);
							move(circle(index - 2), -width, 0);

						} else {
							move(index + 1, width, 0);
						}

						move(index, slidePos[index] + width, speed);
						move(circle(index - 1), slidePos[circle(index - 1)] + width, speed);
						index = circle(index - 1);

					}

					options.callback && options.callback(index, slides[index]);

				} else {

					if (options.continuous) {

						move(circle(index - 1), -width, speed);
						move(index, 0, speed);
						move(circle(index + 1), width, speed);

					} else {

						move(index - 1, -width, speed);
						move(index, 0, speed);
						move(index + 1, width, speed);
					}

				}

			}

			// kill touchmove and touchend event listeners until touchstart called again
			element.removeEventListener('touchmove', events, false)
			element.removeEventListener('touchend', events, false)

		},
		transitionEnd: function (event) {

			if (parseInt(event.target.getAttribute('data-index'), 10) == index) {

				if (delay) begin();

				options.transitionEnd && options.transitionEnd.call(event, index, slides[index]);

			}

		}

	}

	// trigger setup
	setup();

	// start auto slideshow if applicable
	if (delay) begin();


	// add event listeners
	if (browser.addEventListener) {

		// set touchstart event on element
		if (browser.touch) element.addEventListener('touchstart', events, false);

		if (browser.transitions) {
			element.addEventListener('webkitTransitionEnd', events, false);
			element.addEventListener('msTransitionEnd', events, false);
			element.addEventListener('oTransitionEnd', events, false);
			element.addEventListener('otransitionend', events, false);
			element.addEventListener('transitionend', events, false);
		}

		// set resize event on window
		window.addEventListener('resize', events, false);

	} else {

		window.onresize = function () {
			setup()
		}; // to play nice with old IE

	}

	// expose the Swipe API
	return {
		setup: function () {

			setup();

		},

		refresh: function () {
			setup();
		},
		slide: function (to, speed) {

			// cancel slideshow
			stop();

			slide(to, speed);

		},
		prev: function () {

			// cancel slideshow
			stop();

			prev();

		},
		next: function () {

			// cancel slideshow
			stop();

			next();

		},
		stop: function () {

			// cancel slideshow
			stop();

		},
		getPos: function () {

			// return current index position
			return index;

		},
		getNumSlides: function () {

			// return total number of slides
			return length;
		},
		kill: function () {

			// cancel slideshow
			stop();

			// reset element
			element.style.width = '';
			element.style.left = '';

			// reset slides
			var pos = slides.length;
			while (pos--) {

				var slide = slides[pos];
				slide.style.width = '';
				slide.style.left = '';

				if (browser.transitions) translate(pos, 0, 0);

			}

			// removed event listeners
			if (browser.addEventListener) {

				// remove current event listeners
				element.removeEventListener('touchstart', events, false);
				element.removeEventListener('webkitTransitionEnd', events, false);
				element.removeEventListener('msTransitionEnd', events, false);
				element.removeEventListener('oTransitionEnd', events, false);
				element.removeEventListener('otransitionend', events, false);
				element.removeEventListener('transitionend', events, false);
				window.removeEventListener('resize', events, false);

			}
			else {

				window.onresize = null;

			}

		}
	}

}


if (window.jQuery || window.Zepto) {
	(function ($) {
		$.fn.Swipe = function (params) {
			return this.each(function () {
				$(this).data('Swipe', new Swipe($(this)[0], params));
			});
		}
	})(window.jQuery || window.Zepto)
}

/*!
 * jQuery Transit - CSS3 transitions and transformations
 * (c) 2011-2014 Rico Sta. Cruz
 * MIT Licensed.
 *
 * http://ricostacruz.com/jquery.transit
 * http://github.com/rstacruz/jquery.transit
 */

/* jshint expr: true */

;(function (root, factory) {

	if (typeof define === 'function' && define.amd) {
		define(['jquery'], factory);
	} else if (typeof exports === 'object') {
		module.exports = factory(require('jquery'));
	} else {
		factory(root.jQuery);
	}

}(this, function($) {

	$.transit = {
		version: "0.9.12",

		// Map of $.css() keys to values for 'transitionProperty'.
		// See https://developer.mozilla.org/en/CSS/CSS_transitions#Properties_that_can_be_animated
		propertyMap: {
			marginLeft    : 'margin',
			marginRight   : 'margin',
			marginBottom  : 'margin',
			marginTop     : 'margin',
			paddingLeft   : 'padding',
			paddingRight  : 'padding',
			paddingBottom : 'padding',
			paddingTop    : 'padding'
		},

		// Will simply transition "instantly" if false
		enabled: true,

		// Set this to false if you don't want to use the transition end property.
		useTransitionEnd: false
	};

	var div = document.createElement('div');
	var support = {};

	// Helper function to get the proper vendor property name.
	// (`transition` => `WebkitTransition`)
	function getVendorPropertyName(prop) {
		// Handle unprefixed versions (FF16+, for example)
		if (prop in div.style) return prop;

		var prefixes = ['Moz', 'Webkit', 'O', 'ms'];
		var prop_ = prop.charAt(0).toUpperCase() + prop.substr(1);

		for (var i=0; i<prefixes.length; ++i) {
			var vendorProp = prefixes[i] + prop_;
			if (vendorProp in div.style) { return vendorProp; }
		}
	}

	// Helper function to check if transform3D is supported.
	// Should return true for Webkits and Firefox 10+.
	function checkTransform3dSupport() {
		div.style[support.transform] = '';
		div.style[support.transform] = 'rotateY(90deg)';
		return div.style[support.transform] !== '';
	}

	var isChrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;

	// Check for the browser's transitions support.
	support.transition      = getVendorPropertyName('transition');
	support.transitionDelay = getVendorPropertyName('transitionDelay');
	support.transform       = getVendorPropertyName('transform');
	support.transformOrigin = getVendorPropertyName('transformOrigin');
	support.filter          = getVendorPropertyName('Filter');
	support.transform3d     = checkTransform3dSupport();

	var eventNames = {
		'transition':       'transitionend',
		'MozTransition':    'transitionend',
		'OTransition':      'oTransitionEnd',
		'WebkitTransition': 'webkitTransitionEnd',
		'msTransition':     'MSTransitionEnd'
	};

	// Detect the 'transitionend' event needed.
	var transitionEnd = support.transitionEnd = eventNames[support.transition] || null;

	// Populate jQuery's `$.support` with the vendor prefixes we know.
	// As per [jQuery's cssHooks documentation](http://api.jquery.com/jQuery.cssHooks/),
	// we set $.support.transition to a string of the actual property name used.
	for (var key in support) {
		if (support.hasOwnProperty(key) && typeof $.support[key] === 'undefined') {
			$.support[key] = support[key];
		}
	}

	// Avoid memory leak in IE.
	div = null;

	// ## $.cssEase
	// List of easing aliases that you can use with `$.fn.transition`.
	$.cssEase = {
		'_default':       'ease',
		'in':             'ease-in',
		'out':            'ease-out',
		'in-out':         'ease-in-out',
		'snap':           'cubic-bezier(0,1,.5,1)',
		// Penner equations
		'easeInCubic':    'cubic-bezier(.550,.055,.675,.190)',
		'easeOutCubic':   'cubic-bezier(.215,.61,.355,1)',
		'easeInOutCubic': 'cubic-bezier(.645,.045,.355,1)',
		'easeInCirc':     'cubic-bezier(.6,.04,.98,.335)',
		'easeOutCirc':    'cubic-bezier(.075,.82,.165,1)',
		'easeInOutCirc':  'cubic-bezier(.785,.135,.15,.86)',
		'easeInExpo':     'cubic-bezier(.95,.05,.795,.035)',
		'easeOutExpo':    'cubic-bezier(.19,1,.22,1)',
		'easeInOutExpo':  'cubic-bezier(1,0,0,1)',
		'easeInQuad':     'cubic-bezier(.55,.085,.68,.53)',
		'easeOutQuad':    'cubic-bezier(.25,.46,.45,.94)',
		'easeInOutQuad':  'cubic-bezier(.455,.03,.515,.955)',
		'easeInQuart':    'cubic-bezier(.895,.03,.685,.22)',
		'easeOutQuart':   'cubic-bezier(.165,.84,.44,1)',
		'easeInOutQuart': 'cubic-bezier(.77,0,.175,1)',
		'easeInQuint':    'cubic-bezier(.755,.05,.855,.06)',
		'easeOutQuint':   'cubic-bezier(.23,1,.32,1)',
		'easeInOutQuint': 'cubic-bezier(.86,0,.07,1)',
		'easeInSine':     'cubic-bezier(.47,0,.745,.715)',
		'easeOutSine':    'cubic-bezier(.39,.575,.565,1)',
		'easeInOutSine':  'cubic-bezier(.445,.05,.55,.95)',
		'easeInBack':     'cubic-bezier(.6,-.28,.735,.045)',
		'easeOutBack':    'cubic-bezier(.175, .885,.32,1.275)',
		'easeInOutBack':  'cubic-bezier(.68,-.55,.265,1.55)'
	};

	// ## 'transform' CSS hook
	// Allows you to use the `transform` property in CSS.
	//
	//     $("#hello").css({ transform: "rotate(90deg)" });
	//
	//     $("#hello").css('transform');
	//     //=> { rotate: '90deg' }
	//
	$.cssHooks['transit:transform'] = {
		// The getter returns a `Transform` object.
		get: function(elem) {
			return $(elem).data('transform') || new Transform();
		},

		// The setter accepts a `Transform` object or a string.
		set: function(elem, v) {
			var value = v;

			if (!(value instanceof Transform)) {
				value = new Transform(value);
			}

			// We've seen the 3D version of Scale() not work in Chrome when the
			// element being scaled extends outside of the viewport.  Thus, we're
			// forcing Chrome to not use the 3d transforms as well.  Not sure if
			// translate is affectede, but not risking it.  Detection code from
			// http://davidwalsh.name/detecting-google-chrome-javascript
			if (support.transform === 'WebkitTransform' && !isChrome) {
				elem.style[support.transform] = value.toString(true);
			} else {
				elem.style[support.transform] = value.toString();
			}

			$(elem).data('transform', value);
		}
	};

	// Add a CSS hook for `.css({ transform: '...' })`.
	// In jQuery 1.8+, this will intentionally override the default `transform`
	// CSS hook so it'll play well with Transit. (see issue #62)
	$.cssHooks.transform = {
		set: $.cssHooks['transit:transform'].set
	};

	// ## 'filter' CSS hook
	// Allows you to use the `filter` property in CSS.
	//
	//     $("#hello").css({ filter: 'blur(10px)' });
	//
	$.cssHooks.filter = {
		get: function(elem) {
			return elem.style[support.filter];
		},
		set: function(elem, value) {
			elem.style[support.filter] = value;
		}
	};

	// jQuery 1.8+ supports prefix-free transitions, so these polyfills will not
	// be necessary.
	if ($.fn.jquery < "1.8") {
		// ## 'transformOrigin' CSS hook
		// Allows the use for `transformOrigin` to define where scaling and rotation
		// is pivoted.
		//
		//     $("#hello").css({ transformOrigin: '0 0' });
		//
		$.cssHooks.transformOrigin = {
			get: function(elem) {
				return elem.style[support.transformOrigin];
			},
			set: function(elem, value) {
				elem.style[support.transformOrigin] = value;
			}
		};

		// ## 'transition' CSS hook
		// Allows you to use the `transition` property in CSS.
		//
		//     $("#hello").css({ transition: 'all 0 ease 0' });
		//
		$.cssHooks.transition = {
			get: function(elem) {
				return elem.style[support.transition];
			},
			set: function(elem, value) {
				elem.style[support.transition] = value;
			}
		};
	}

	// ## Other CSS hooks
	// Allows you to rotate, scale and translate.
	registerCssHook('scale');
	registerCssHook('scaleX');
	registerCssHook('scaleY');
	registerCssHook('translate');
	registerCssHook('rotate');
	registerCssHook('rotateX');
	registerCssHook('rotateY');
	registerCssHook('rotate3d');
	registerCssHook('perspective');
	registerCssHook('skewX');
	registerCssHook('skewY');
	registerCssHook('x', true);
	registerCssHook('y', true);

	// ## Transform class
	// This is the main class of a transformation property that powers
	// `$.fn.css({ transform: '...' })`.
	//
	// This is, in essence, a dictionary object with key/values as `-transform`
	// properties.
	//
	//     var t = new Transform("rotate(90) scale(4)");
	//
	//     t.rotate             //=> "90deg"
	//     t.scale              //=> "4,4"
	//
	// Setters are accounted for.
	//
	//     t.set('rotate', 4)
	//     t.rotate             //=> "4deg"
	//
	// Convert it to a CSS string using the `toString()` and `toString(true)` (for WebKit)
	// functions.
	//
	//     t.toString()         //=> "rotate(90deg) scale(4,4)"
	//     t.toString(true)     //=> "rotate(90deg) scale3d(4,4,0)" (WebKit version)
	//
	function Transform(str) {
		if (typeof str === 'string') { this.parse(str); }
		return this;
	}

	Transform.prototype = {
		// ### setFromString()
		// Sets a property from a string.
		//
		//     t.setFromString('scale', '2,4');
		//     // Same as set('scale', '2', '4');
		//
		setFromString: function(prop, val) {
			var args =
				(typeof val === 'string')  ? val.split(',') :
					(val.constructor === Array) ? val :
						[ val ];

			args.unshift(prop);

			Transform.prototype.set.apply(this, args);
		},

		// ### set()
		// Sets a property.
		//
		//     t.set('scale', 2, 4);
		//
		set: function(prop) {
			var args = Array.prototype.slice.apply(arguments, [1]);
			if (this.setter[prop]) {
				this.setter[prop].apply(this, args);
			} else {
				this[prop] = args.join(',');
			}
		},

		get: function(prop) {
			if (this.getter[prop]) {
				return this.getter[prop].apply(this);
			} else {
				return this[prop] || 0;
			}
		},

		setter: {
			// ### rotate
			//
			//     .css({ rotate: 30 })
			//     .css({ rotate: "30" })
			//     .css({ rotate: "30deg" })
			//     .css({ rotate: "30deg" })
			//
			rotate: function(theta) {
				this.rotate = unit(theta, 'deg');
			},

			rotateX: function(theta) {
				this.rotateX = unit(theta, 'deg');
			},

			rotateY: function(theta) {
				this.rotateY = unit(theta, 'deg');
			},

			// ### scale
			//
			//     .css({ scale: 9 })      //=> "scale(9,9)"
			//     .css({ scale: '3,2' })  //=> "scale(3,2)"
			//
			scale: function(x, y) {
				if (y === undefined) { y = x; }
				this.scale = x + "," + y;
			},

			// ### skewX + skewY
			skewX: function(x) {
				this.skewX = unit(x, 'deg');
			},

			skewY: function(y) {
				this.skewY = unit(y, 'deg');
			},

			// ### perspectvie
			perspective: function(dist) {
				this.perspective = unit(dist, 'px');
			},

			// ### x / y
			// Translations. Notice how this keeps the other value.
			//
			//     .css({ x: 4 })       //=> "translate(4px, 0)"
			//     .css({ y: 10 })      //=> "translate(4px, 10px)"
			//
			x: function(x) {
				this.set('translate', x, null);
			},

			y: function(y) {
				this.set('translate', null, y);
			},

			// ### translate
			// Notice how this keeps the other value.
			//
			//     .css({ translate: '2, 5' })    //=> "translate(2px, 5px)"
			//
			translate: function(x, y) {
				if (this._translateX === undefined) { this._translateX = 0; }
				if (this._translateY === undefined) { this._translateY = 0; }

				if (x !== null && x !== undefined) { this._translateX = unit(x, 'px'); }
				if (y !== null && y !== undefined) { this._translateY = unit(y, 'px'); }

				this.translate = this._translateX + "," + this._translateY;
			}
		},

		getter: {
			x: function() {
				return this._translateX || 0;
			},

			y: function() {
				return this._translateY || 0;
			},

			scale: function() {
				var s = (this.scale || "1,1").split(',');
				if (s[0]) { s[0] = parseFloat(s[0]); }
				if (s[1]) { s[1] = parseFloat(s[1]); }

				// "2.5,2.5" => 2.5
				// "2.5,1" => [2.5,1]
				return (s[0] === s[1]) ? s[0] : s;
			},

			rotate3d: function() {
				var s = (this.rotate3d || "0,0,0,0deg").split(',');
				for (var i=0; i<=3; ++i) {
					if (s[i]) { s[i] = parseFloat(s[i]); }
				}
				if (s[3]) { s[3] = unit(s[3], 'deg'); }

				return s;
			}
		},

		// ### parse()
		// Parses from a string. Called on constructor.
		parse: function(str) {
			var self = this;
			str.replace(/([a-zA-Z0-9]+)\((.*?)\)/g, function(x, prop, val) {
				self.setFromString(prop, val);
			});
		},

		// ### toString()
		// Converts to a `transition` CSS property string. If `use3d` is given,
		// it converts to a `-webkit-transition` CSS property string instead.
		toString: function(use3d) {
			var re = [];

			for (var i in this) {
				if (this.hasOwnProperty(i)) {
					// Don't use 3D transformations if the browser can't support it.
					if ((!support.transform3d) && (
						(i === 'rotateX') ||
						(i === 'rotateY') ||
						(i === 'perspective') ||
						(i === 'transformOrigin'))) { continue; }

					if (i[0] !== '_') {
						if (use3d && (i === 'scale')) {
							re.push(i + "3d(" + this[i] + ",1)");
						} else if (use3d && (i === 'translate')) {
							re.push(i + "3d(" + this[i] + ",0)");
						} else {
							re.push(i + "(" + this[i] + ")");
						}
					}
				}
			}

			return re.join(" ");
		}
	};

	function callOrQueue(self, queue, fn) {
		if (queue === true) {
			self.queue(fn);
		} else if (queue) {
			self.queue(queue, fn);
		} else {
			self.each(function () {
				fn.call(this);
			});
		}
	}

	// ### getProperties(dict)
	// Returns properties (for `transition-property`) for dictionary `props`. The
	// value of `props` is what you would expect in `$.css(...)`.
	function getProperties(props) {
		var re = [];

		$.each(props, function(key) {
			key = $.camelCase(key); // Convert "text-align" => "textAlign"
			key = $.transit.propertyMap[key] || $.cssProps[key] || key;
			key = uncamel(key); // Convert back to dasherized

			// Get vendor specify propertie
			if (support[key])
				key = uncamel(support[key]);

			if ($.inArray(key, re) === -1) { re.push(key); }
		});

		return re;
	}

	// ### getTransition()
	// Returns the transition string to be used for the `transition` CSS property.
	//
	// Example:
	//
	//     getTransition({ opacity: 1, rotate: 30 }, 500, 'ease');
	//     //=> 'opacity 500ms ease, -webkit-transform 500ms ease'
	//
	function getTransition(properties, duration, easing, delay) {
		// Get the CSS properties needed.
		var props = getProperties(properties);

		// Account for aliases (`in` => `ease-in`).
		if ($.cssEase[easing]) { easing = $.cssEase[easing]; }

		// Build the duration/easing/delay attributes for it.
		var attribs = '' + toMS(duration) + ' ' + easing;
		if (parseInt(delay, 10) > 0) { attribs += ' ' + toMS(delay); }

		// For more properties, add them this way:
		// "margin 200ms ease, padding 200ms ease, ..."
		var transitions = [];
		$.each(props, function(i, name) {
			transitions.push(name + ' ' + attribs);
		});

		return transitions.join(', ');
	}

	// ## $.fn.transition
	// Works like $.fn.animate(), but uses CSS transitions.
	//
	//     $("...").transition({ opacity: 0.1, scale: 0.3 });
	//
	//     // Specific duration
	//     $("...").transition({ opacity: 0.1, scale: 0.3 }, 500);
	//
	//     // With duration and easing
	//     $("...").transition({ opacity: 0.1, scale: 0.3 }, 500, 'in');
	//
	//     // With callback
	//     $("...").transition({ opacity: 0.1, scale: 0.3 }, function() { ... });
	//
	//     // With everything
	//     $("...").transition({ opacity: 0.1, scale: 0.3 }, 500, 'in', function() { ... });
	//
	//     // Alternate syntax
	//     $("...").transition({
	//       opacity: 0.1,
	//       duration: 200,
	//       delay: 40,
	//       easing: 'in',
	//       complete: function() { /* ... */ }
	//      });
	//
	$.fn.transition = $.fn.transit = function(properties, duration, easing, callback) {
		var self  = this;
		var delay = 0;
		var queue = true;

		var theseProperties = $.extend(true, {}, properties);

		// Account for `.transition(properties, callback)`.
		if (typeof duration === 'function') {
			callback = duration;
			duration = undefined;
		}

		// Account for `.transition(properties, options)`.
		if (typeof duration === 'object') {
			easing = duration.easing;
			delay = duration.delay || 0;
			queue = typeof duration.queue === "undefined" ? true : duration.queue;
			callback = duration.complete;
			duration = duration.duration;
		}

		// Account for `.transition(properties, duration, callback)`.
		if (typeof easing === 'function') {
			callback = easing;
			easing = undefined;
		}

		// Alternate syntax.
		if (typeof theseProperties.easing !== 'undefined') {
			easing = theseProperties.easing;
			delete theseProperties.easing;
		}

		if (typeof theseProperties.duration !== 'undefined') {
			duration = theseProperties.duration;
			delete theseProperties.duration;
		}

		if (typeof theseProperties.complete !== 'undefined') {
			callback = theseProperties.complete;
			delete theseProperties.complete;
		}

		if (typeof theseProperties.queue !== 'undefined') {
			queue = theseProperties.queue;
			delete theseProperties.queue;
		}

		if (typeof theseProperties.delay !== 'undefined') {
			delay = theseProperties.delay;
			delete theseProperties.delay;
		}

		// Set defaults. (`400` duration, `ease` easing)
		if (typeof duration === 'undefined') { duration = $.fx.speeds._default; }
		if (typeof easing === 'undefined')   { easing = $.cssEase._default; }

		duration = toMS(duration);

		// Build the `transition` property.
		var transitionValue = getTransition(theseProperties, duration, easing, delay);

		// Compute delay until callback.
		// If this becomes 0, don't bother setting the transition property.
		var work = $.transit.enabled && support.transition;
		var i = work ? (parseInt(duration, 10) + parseInt(delay, 10)) : 0;

		// If there's nothing to do...
		if (i === 0) {
			var fn = function(next) {
				self.css(theseProperties);
				if (callback) { callback.apply(self); }
				if (next) { next(); }
			};

			callOrQueue(self, queue, fn);
			return self;
		}

		// Save the old transitions of each element so we can restore it later.
		var oldTransitions = {};

		var run = function(nextCall) {
			var bound = false;

			// Prepare the callback.
			var cb = function() {
				if (bound) { self.unbind(transitionEnd, cb); }

				if (i > 0) {
					self.each(function() {
						this.style[support.transition] = (oldTransitions[this] || null);
					});
				}

				if (typeof callback === 'function') { callback.apply(self); }
				if (typeof nextCall === 'function') { nextCall(); }
			};

			if ((i > 0) && (transitionEnd) && ($.transit.useTransitionEnd)) {
				// Use the 'transitionend' event if it's available.
				bound = true;
				self.bind(transitionEnd, cb);
			} else {
				// Fallback to timers if the 'transitionend' event isn't supported.
				window.setTimeout(cb, i);
			}

			// Apply transitions.
			self.each(function() {
				if (i > 0) {
					this.style[support.transition] = transitionValue;
				}
				$(this).css(theseProperties);
			});
		};

		// Defer running. This allows the browser to paint any pending CSS it hasn't
		// painted yet before doing the transitions.
		var deferredRun = function(next) {
			this.offsetWidth; // force a repaint
			run(next);
		};

		// Use jQuery's fx queue.
		callOrQueue(self, queue, deferredRun);

		// Chainability.
		return this;
	};

	function registerCssHook(prop, isPixels) {
		// For certain properties, the 'px' should not be implied.
		if (!isPixels) { $.cssNumber[prop] = true; }

		$.transit.propertyMap[prop] = support.transform;

		$.cssHooks[prop] = {
			get: function(elem) {
				var t = $(elem).css('transit:transform');
				return t.get(prop);
			},

			set: function(elem, value) {
				var t = $(elem).css('transit:transform');
				t.setFromString(prop, value);

				$(elem).css({ 'transit:transform': t });
			}
		};

	}

	// ### uncamel(str)
	// Converts a camelcase string to a dasherized string.
	// (`marginLeft` => `margin-left`)
	function uncamel(str) {
		return str.replace(/([A-Z])/g, function(letter) { return '-' + letter.toLowerCase(); });
	}

	// ### unit(number, unit)
	// Ensures that number `number` has a unit. If no unit is found, assume the
	// default is `unit`.
	//
	//     unit(2, 'px')          //=> "2px"
	//     unit("30deg", 'rad')   //=> "30deg"
	//
	function unit(i, units) {
		if ((typeof i === "string") && (!i.match(/^[\-0-9\.]+$/))) {
			return i;
		} else {
			return "" + i + units;
		}
	}

	// ### toMS(duration)
	// Converts given `duration` to a millisecond string.
	//
	// toMS('fast') => $.fx.speeds[i] => "200ms"
	// toMS('normal') //=> $.fx.speeds._default => "400ms"
	// toMS(10) //=> '10ms'
	// toMS('100ms') //=> '100ms'
	//
	function toMS(duration) {
		var i = duration;

		// Allow string durations like 'fast' and 'slow', without overriding numeric values.
		if (typeof i === 'string' && (!i.match(/^[\-0-9\.]+/))) { i = $.fx.speeds[i] || $.fx.speeds._default; }

		return unit(i, 'ms');
	}

	// Export some functions for testable-ness.
	$.transit.getTransitionValue = getTransition;

	return $;
}));
//     JavaScript Expression Parser (JSEP) 0.3.0
//     JSEP may be freely distributed under the MIT License
//     http://jsep.from.so/

/*global module: true, exports: true, console: true */
(function (root) {
	'use strict';
	// Node Types
	// ----------

	// This is the full set of types that any JSEP node can be.
	// Store them here to save space when minified
	var COMPOUND = 'Compound',
		IDENTIFIER = 'Identifier',
		MEMBER_EXP = 'MemberExpression',
		LITERAL = 'Literal',
		THIS_EXP = 'ThisExpression',
		CALL_EXP = 'CallExpression',
		UNARY_EXP = 'UnaryExpression',
		BINARY_EXP = 'BinaryExpression',
		LOGICAL_EXP = 'LogicalExpression',
		CONDITIONAL_EXP = 'ConditionalExpression',
		ARRAY_EXP = 'ArrayExpression',

		PERIOD_CODE = 46, // '.'
		COMMA_CODE  = 44, // ','
		SQUOTE_CODE = 39, // single quote
		DQUOTE_CODE = 34, // double quotes
		OPAREN_CODE = 40, // (
		CPAREN_CODE = 41, // )
		OBRACK_CODE = 91, // [
		CBRACK_CODE = 93, // ]
		QUMARK_CODE = 63, // ?
		SEMCOL_CODE = 59, // ;
		COLON_CODE  = 58, // :

		throwError = function(message, index) {
			var error = new Error(message + ' at character ' + index);
			error.index = index;
			error.description = message;
			throw error;
		},

	// Operations
	// ----------

	// Set `t` to `true` to save space (when minified, not gzipped)
		t = true,
	// Use a quickly-accessible map to store all of the unary operators
	// Values are set to `true` (it really doesn't matter)
		unary_ops = {'-': t, '!': t, '~': t, '+': t},
	// Also use a map for the binary operations but set their values to their
	// binary precedence for quick reference:
	// see [Order of operations](http://en.wikipedia.org/wiki/Order_of_operations#Programming_language)
		binary_ops = {
			'||': 1, '&&': 2, '|': 3,  '^': 4,  '&': 5,
			'==': 6, '!=': 6, '===': 6, '!==': 6,
			'<': 7,  '>': 7,  '<=': 7,  '>=': 7,
			'<<':8,  '>>': 8, '>>>': 8,
			'+': 9, '-': 9,
			'*': 10, '/': 10, '%': 10
		},
	// Get return the longest key length of any object
		getMaxKeyLen = function(obj) {
			var max_len = 0, len;
			for(var key in obj) {
				if((len = key.length) > max_len && obj.hasOwnProperty(key)) {
					max_len = len;
				}
			}
			return max_len;
		},
		max_unop_len = getMaxKeyLen(unary_ops),
		max_binop_len = getMaxKeyLen(binary_ops),
	// Literals
	// ----------
	// Store the values to return for the various literals we may encounter
		literals = {
			'true': true,
			'false': false,
			'null': null
		},
	// Except for `this`, which is special. This could be changed to something like `'self'` as well
		this_str = 'this',
	// Returns the precedence of a binary operator or `0` if it isn't a binary operator
		binaryPrecedence = function(op_val) {
			return binary_ops[op_val] || 0;
		},
	// Utility function (gets called from multiple places)
	// Also note that `a && b` and `a || b` are *logical* expressions, not binary expressions
		createBinaryExpression = function (operator, left, right) {
			var type = (operator === '||' || operator === '&&') ? LOGICAL_EXP : BINARY_EXP;
			return {
				type: type,
				operator: operator,
				left: left,
				right: right
			};
		},
	// `ch` is a character code in the next three functions
		isDecimalDigit = function(ch) {
			return (ch >= 48 && ch <= 57); // 0...9
		},
		isIdentifierStart = function(ch) {
			return (ch === 36) || (ch === 95) || // `$` and `_`
				(ch >= 65 && ch <= 90) || // A...Z
				(ch >= 97 && ch <= 122); // a...z
		},
		isIdentifierPart = function(ch) {
			return (ch === 36) || (ch === 95) || // `$` and `_`
				(ch >= 65 && ch <= 90) || // A...Z
				(ch >= 97 && ch <= 122) || // a...z
				(ch >= 48 && ch <= 57); // 0...9
		},

	// Parsing
	// -------
	// `expr` is a string with the passed in expression
		jsep = function(expr) {
			// `index` stores the character number we are currently at while `length` is a constant
			// All of the gobbles below will modify `index` as we move along
			var index = 0,
				charAtFunc = expr.charAt,
				charCodeAtFunc = expr.charCodeAt,
				exprI = function(i) { return charAtFunc.call(expr, i); },
				exprICode = function(i) { return charCodeAtFunc.call(expr, i); },
				length = expr.length,

			// Push `index` up to the next non-space character
				gobbleSpaces = function() {
					var ch = exprICode(index);
					// space or tab
					while(ch === 32 || ch === 9) {
						ch = exprICode(++index);
					}
				},

			// The main parsing function. Much of this code is dedicated to ternary expressions
				gobbleExpression = function() {
					var test = gobbleBinaryExpression(),
						consequent, alternate;
					gobbleSpaces();
					if(exprICode(index) === QUMARK_CODE) {
						// Ternary expression: test ? consequent : alternate
						index++;
						consequent = gobbleExpression();
						if(!consequent) {
							throwError('Expected expression', index);
						}
						gobbleSpaces();
						if(exprICode(index) === COLON_CODE) {
							index++;
							alternate = gobbleExpression();
							if(!alternate) {
								throwError('Expected expression', index);
							}
							return {
								type: CONDITIONAL_EXP,
								test: test,
								consequent: consequent,
								alternate: alternate
							};
						} else {
							throwError('Expected :', index);
						}
					} else {
						return test;
					}
				},

			// Search for the operation portion of the string (e.g. `+`, `===`)
			// Start by taking the longest possible binary operations (3 characters: `===`, `!==`, `>>>`)
			// and move down from 3 to 2 to 1 character until a matching binary operation is found
			// then, return that binary operation
				gobbleBinaryOp = function() {
					gobbleSpaces();
					var biop, to_check = expr.substr(index, max_binop_len), tc_len = to_check.length;
					while(tc_len > 0) {
						if(binary_ops.hasOwnProperty(to_check)) {
							index += tc_len;
							return to_check;
						}
						to_check = to_check.substr(0, --tc_len);
					}
					return false;
				},

			// This function is responsible for gobbling an individual expression,
			// e.g. `1`, `1+2`, `a+(b*2)-Math.sqrt(2)`
				gobbleBinaryExpression = function() {
					var ch_i, node, biop, prec, stack, biop_info, left, right, i;

					// First, try to get the leftmost thing
					// Then, check to see if there's a binary operator operating on that leftmost thing
					left = gobbleToken();
					biop = gobbleBinaryOp();

					// If there wasn't a binary operator, just return the leftmost node
					if(!biop) {
						return left;
					}

					// Otherwise, we need to start a stack to properly place the binary operations in their
					// precedence structure
					biop_info = { value: biop, prec: binaryPrecedence(biop)};

					right = gobbleToken();
					if(!right) {
						throwError("Expected expression after " + biop, index);
					}
					stack = [left, biop_info, right];

					// Properly deal with precedence using [recursive descent](http://www.engr.mun.ca/~theo/Misc/exp_parsing.htm)
					while((biop = gobbleBinaryOp())) {
						prec = binaryPrecedence(biop);

						if(prec === 0) {
							break;
						}
						biop_info = { value: biop, prec: prec };

						// Reduce: make a binary expression from the three topmost entries.
						while ((stack.length > 2) && (prec <= stack[stack.length - 2].prec)) {
							right = stack.pop();
							biop = stack.pop().value;
							left = stack.pop();
							node = createBinaryExpression(biop, left, right);
							stack.push(node);
						}

						node = gobbleToken();
						if(!node) {
							throwError("Expected expression after " + biop, index);
						}
						stack.push(biop_info, node);
					}

					i = stack.length - 1;
					node = stack[i];
					while(i > 1) {
						node = createBinaryExpression(stack[i - 1].value, stack[i - 2], node);
						i -= 2;
					}
					return node;
				},

			// An individual part of a binary expression:
			// e.g. `foo.bar(baz)`, `1`, `"abc"`, `(a % 2)` (because it's in parenthesis)
				gobbleToken = function() {
					var ch, to_check, tc_len;

					gobbleSpaces();
					ch = exprICode(index);

					if(isDecimalDigit(ch) || ch === PERIOD_CODE) {
						// Char code 46 is a dot `.` which can start off a numeric literal
						return gobbleNumericLiteral();
					} else if(ch === SQUOTE_CODE || ch === DQUOTE_CODE) {
						// Single or double quotes
						return gobbleStringLiteral();
					} else if(isIdentifierStart(ch) || ch === OPAREN_CODE) { // open parenthesis
						// `foo`, `bar.baz`
						return gobbleVariable();
					} else if (ch === OBRACK_CODE) {
						return gobbleArray();
					} else {
						to_check = expr.substr(index, max_unop_len);
						tc_len = to_check.length;
						while(tc_len > 0) {
							if(unary_ops.hasOwnProperty(to_check)) {
								index += tc_len;
								return {
									type: UNARY_EXP,
									operator: to_check,
									argument: gobbleToken(),
									prefix: true
								};
							}
							to_check = to_check.substr(0, --tc_len);
						}

						return false;
					}
				},
			// Parse simple numeric literals: `12`, `3.4`, `.5`. Do this by using a string to
			// keep track of everything in the numeric literal and then calling `parseFloat` on that string
				gobbleNumericLiteral = function() {
					var number = '', ch, chCode;
					while(isDecimalDigit(exprICode(index))) {
						number += exprI(index++);
					}

					if(exprICode(index) === PERIOD_CODE) { // can start with a decimal marker
						number += exprI(index++);

						while(isDecimalDigit(exprICode(index))) {
							number += exprI(index++);
						}
					}

					ch = exprI(index);
					if(ch === 'e' || ch === 'E') { // exponent marker
						number += exprI(index++);
						ch = exprI(index);
						if(ch === '+' || ch === '-') { // exponent sign
							number += exprI(index++);
						}
						while(isDecimalDigit(exprICode(index))) { //exponent itself
							number += exprI(index++);
						}
						if(!isDecimalDigit(exprICode(index-1)) ) {
							throwError('Expected exponent (' + number + exprI(index) + ')', index);
						}
					}


					chCode = exprICode(index);
					// Check to make sure this isn't a variable name that start with a number (123abc)
					if(isIdentifierStart(chCode)) {
						throwError('Variable names cannot start with a number (' +
						number + exprI(index) + ')', index);
					} else if(chCode === PERIOD_CODE) {
						throwError('Unexpected period', index);
					}

					return {
						type: LITERAL,
						value: parseFloat(number),
						raw: number
					};
				},

			// Parses a string literal, staring with single or double quotes with basic support for escape codes
			// e.g. `"hello world"`, `'this is\nJSEP'`
				gobbleStringLiteral = function() {
					var str = '', quote = exprI(index++), closed = false, ch;

					while(index < length) {
						ch = exprI(index++);
						if(ch === quote) {
							closed = true;
							break;
						} else if(ch === '\\') {
							// Check for all of the common escape codes
							ch = exprI(index++);
							switch(ch) {
								case 'n': str += '\n'; break;
								case 'r': str += '\r'; break;
								case 't': str += '\t'; break;
								case 'b': str += '\b'; break;
								case 'f': str += '\f'; break;
								case 'v': str += '\x0B'; break;
							}
						} else {
							str += ch;
						}
					}

					if(!closed) {
						throwError('Unclosed quote after "'+str+'"', index);
					}

					return {
						type: LITERAL,
						value: str,
						raw: quote + str + quote
					};
				},

			// Gobbles only identifiers
			// e.g.: `foo`, `_value`, `$x1`
			// Also, this function checks if that identifier is a literal:
			// (e.g. `true`, `false`, `null`) or `this`
				gobbleIdentifier = function() {
					var ch = exprICode(index), start = index, identifier;

					if(isIdentifierStart(ch)) {
						index++;
					} else {
						throwError('Unexpected ' + exprI(index), index);
					}

					while(index < length) {
						ch = exprICode(index);
						if(isIdentifierPart(ch)) {
							index++;
						} else {
							break;
						}
					}
					identifier = expr.slice(start, index);

					if(literals.hasOwnProperty(identifier)) {
						return {
							type: LITERAL,
							value: literals[identifier],
							raw: identifier
						};
					} else if(identifier === this_str) {
						return { type: THIS_EXP };
					} else {
						return {
							type: IDENTIFIER,
							name: identifier
						};
					}
				},

			// Gobbles a list of arguments within the context of a function call
			// or array literal. This function also assumes that the opening character
			// `(` or `[` has already been gobbled, and gobbles expressions and commas
			// until the terminator character `)` or `]` is encountered.
			// e.g. `foo(bar, baz)`, `my_func()`, or `[bar, baz]`
				gobbleArguments = function(termination) {
					var ch_i, args = [], node;
					while(index < length) {
						gobbleSpaces();
						ch_i = exprICode(index);
						if(ch_i === termination) { // done parsing
							index++;
							break;
						} else if (ch_i === COMMA_CODE) { // between expressions
							index++;
						} else {
							node = gobbleExpression();
							if(!node || node.type === COMPOUND) {
								throwError('Expected comma', index);
							}
							args.push(node);
						}
					}
					return args;
				},

			// Gobble a non-literal variable name. This variable name may include properties
			// e.g. `foo`, `bar.baz`, `foo['bar'].baz`
			// It also gobbles function calls:
			// e.g. `Math.acos(obj.angle)`
				gobbleVariable = function() {
					var ch_i, node;
					ch_i = exprICode(index);

					if(ch_i === OPAREN_CODE) {
						node = gobbleGroup();
					} else {
						node = gobbleIdentifier();
					}
					gobbleSpaces();
					ch_i = exprICode(index);
					while(ch_i === PERIOD_CODE || ch_i === OBRACK_CODE || ch_i === OPAREN_CODE) {
						index++;
						if(ch_i === PERIOD_CODE) {
							gobbleSpaces();
							node = {
								type: MEMBER_EXP,
								computed: false,
								object: node,
								property: gobbleIdentifier()
							};
						} else if(ch_i === OBRACK_CODE) {
							node = {
								type: MEMBER_EXP,
								computed: true,
								object: node,
								property: gobbleExpression()
							};
							gobbleSpaces();
							ch_i = exprICode(index);
							if(ch_i !== CBRACK_CODE) {
								throwError('Unclosed [', index);
							}
							index++;
						} else if(ch_i === OPAREN_CODE) {
							// A function call is being made; gobble all the arguments
							node = {
								type: CALL_EXP,
								'arguments': gobbleArguments(CPAREN_CODE),
								callee: node
							};
						}
						gobbleSpaces();
						ch_i = exprICode(index);
					}
					return node;
				},

			// Responsible for parsing a group of things within parentheses `()`
			// This function assumes that it needs to gobble the opening parenthesis
			// and then tries to gobble everything within that parenthesis, assuming
			// that the next thing it should see is the close parenthesis. If not,
			// then the expression probably doesn't have a `)`
				gobbleGroup = function() {
					index++;
					var node = gobbleExpression();
					gobbleSpaces();
					if(exprICode(index) === CPAREN_CODE) {
						index++;
						return node;
					} else {
						throwError('Unclosed (', index);
					}
				},

			// Responsible for parsing Array literals `[1, 2, 3]`
			// This function assumes that it needs to gobble the opening bracket
			// and then tries to gobble the expressions as arguments.
				gobbleArray = function() {
					index++;
					return {
						type: ARRAY_EXP,
						elements: gobbleArguments(CBRACK_CODE)
					};
				},

				nodes = [], ch_i, node;

			while(index < length) {
				ch_i = exprICode(index);

				// Expressions can be separated by semicolons, commas, or just inferred without any
				// separators
				if(ch_i === SEMCOL_CODE || ch_i === COMMA_CODE) {
					index++; // ignore separators
				} else {
					// Try to gobble each expression individually
					if((node = gobbleExpression())) {
						nodes.push(node);
						// If we weren't able to find a binary expression and are out of room, then
						// the expression passed in probably has too much
					} else if(index < length) {
						throwError('Unexpected "' + exprI(index) + '"', index);
					}
				}
			}

			// If there's only one expression just try returning the expression
			if(nodes.length === 1) {
				return nodes[0];
			} else {
				return {
					type: COMPOUND,
					body: nodes
				};
			}
		};

	// To be filled in by the template
	jsep.version = '0.3.0';
	jsep.toString = function() { return 'JavaScript Expression Parser (JSEP) v' + jsep.version; };

	/**
	 * @method jsep.addUnaryOp
	 * @param {string} op_name The name of the unary op to add
	 * @return jsep
	 */
	jsep.addUnaryOp = function(op_name) {
		unary_ops[op_name] = t; return this;
	};

	/**
	 * @method jsep.addBinaryOp
	 * @param {string} op_name The name of the binary op to add
	 * @param {number} precedence The precedence of the binary op (can be a float)
	 * @return jsep
	 */
	jsep.addBinaryOp = function(op_name, precedence) {
		max_binop_len = Math.max(op_name.length, max_binop_len);
		binary_ops[op_name] = precedence;
		return this;
	};

	/**
	 * @method jsep.removeUnaryOp
	 * @param {string} op_name The name of the unary op to remove
	 * @return jsep
	 */
	jsep.removeUnaryOp = function(op_name) {
		delete unary_ops[op_name];
		if(op_name.length === max_unop_len) {
			max_unop_len = getMaxKeyLen(unary_ops);
		}
		return this;
	};

	/**
	 * @method jsep.removeBinaryOp
	 * @param {string} op_name The name of the binary op to remove
	 * @return jsep
	 */
	jsep.removeBinaryOp = function(op_name) {
		delete binary_ops[op_name];
		if(op_name.length === max_binop_len) {
			max_binop_len = getMaxKeyLen(binary_ops);
		}
		return this;
	};

	// In desktop environments, have a way to restore the old value for `jsep`
	if (typeof exports === 'undefined') {
		var old_jsep = root.jsep;
		// The star of the show! It's a function!
		root.jsep = jsep;
		// And a courteous function willing to move out of the way for other similarly-named objects!
		jsep.noConflict = function() {
			if(root.jsep === jsep) {
				root.jsep = old_jsep;
			}
			return jsep;
		};
	} else {
		// In Node.JS environments
		if (typeof module !== 'undefined' && module.exports) {
			exports = module.exports = jsep;
		} else {
			exports.parse = jsep;
		}
	}
}(this));
/*
 * Scroller
 * http://github.com/zynga/scroller
 *
 * Copyright 2011, Zynga Inc.
 * Licensed under the MIT License.
 * https://raw.github.com/zynga/scroller/master/MIT-LICENSE.txt
 *
 * Based on the work of: Unify Project (unify-project.org)
 * http://unify-project.org
 * Copyright 2011, Deutsche Telekom AG
 * License: MIT + Apache (V2)
 */

/**
 * Generic animation class with support for dropped frames both optional easing and duration.
 *
 * Optional duration is useful when the lifetime is defined by another condition than time
 * e.g. speed of an animating object, etc.
 *
 * Dropped frame logic allows to keep using the same updater logic independent from the actual
 * rendering. This eases a lot of cases where it might be pretty complex to break down a state
 * based on the pure time difference.
 */
(function(global) {
	var time = Date.now || function() {
		return +new Date();
	};
	var desiredFrames = 60;
	var millisecondsPerSecond = 1000;
	var running = {};
	var counter = 1;

	// Create namespaces
	if (!global.core) {
		global.core = { effect : {} };

	} else if (!core.effect) {
		core.effect = {};
	}

	core.effect.Animate = {

		/**
		 * A requestAnimationFrame wrapper / polyfill.
		 *
		 * @param callback {Function} The callback to be invoked before the next repaint.
		 * @param root {HTMLElement} The root element for the repaint
		 */
		requestAnimationFrame: (function() {

			// Check for request animation Frame support
			var requestFrame = global.requestAnimationFrame || global.webkitRequestAnimationFrame || global.mozRequestAnimationFrame || global.oRequestAnimationFrame;
			var isNative = !!requestFrame;

			if (requestFrame && !/requestAnimationFrame\(\)\s*\{\s*\[native code\]\s*\}/i.test(requestFrame.toString())) {
				isNative = false;
			}

			if (isNative) {
				return function(callback, root) {
					requestFrame(callback, root)
				};
			}

			var TARGET_FPS = 60;
			var requests = {};
			var requestCount = 0;
			var rafHandle = 1;
			var intervalHandle = null;
			var lastActive = +new Date();

			return function(callback, root) {
				var callbackHandle = rafHandle++;

				// Store callback
				requests[callbackHandle] = callback;
				requestCount++;

				// Create timeout at first request
				if (intervalHandle === null) {

					intervalHandle = setInterval(function() {

						var time = +new Date();
						var currentRequests = requests;

						// Reset data structure before executing callbacks
						requests = {};
						requestCount = 0;

						for(var key in currentRequests) {
							if (currentRequests.hasOwnProperty(key)) {
								currentRequests[key](time);
								lastActive = time;
							}
						}

						// Disable the timeout when nothing happens for a certain
						// period of time
						if (time - lastActive > 2500) {
							clearInterval(intervalHandle);
							intervalHandle = null;
						}

					}, 1000 / TARGET_FPS);
				}

				return callbackHandle;
			};

		})(),


		/**
		 * Stops the given animation.
		 *
		 * @param id {Integer} Unique animation ID
		 * @return {Boolean} Whether the animation was stopped (aka, was running before)
		 */
		stop: function(id) {
			var cleared = running[id] != null;
			if (cleared) {
				running[id] = null;
			}

			return cleared;
		},


		/**
		 * Whether the given animation is still running.
		 *
		 * @param id {Integer} Unique animation ID
		 * @return {Boolean} Whether the animation is still running
		 */
		isRunning: function(id) {
			return running[id] != null;
		},


		/**
		 * Start the animation.
		 *
		 * @param stepCallback {Function} Pointer to function which is executed on every step.
		 *   Signature of the method should be `function(percent, now, virtual) { return continueWithAnimation; }`
		 * @param verifyCallback {Function} Executed before every animation step.
		 *   Signature of the method should be `function() { return continueWithAnimation; }`
		 * @param completedCallback {Function}
		 *   Signature of the method should be `function(droppedFrames, finishedAnimation) {}`
		 * @param duration {Integer} Milliseconds to run the animation
		 * @param easingMethod {Function} Pointer to easing function
		 *   Signature of the method should be `function(percent) { return modifiedValue; }`
		 * @param root {Element ? document.body} Render root, when available. Used for internal
		 *   usage of requestAnimationFrame.
		 * @return {Integer} Identifier of animation. Can be used to stop it any time.
		 */
		start: function(stepCallback, verifyCallback, completedCallback, duration, easingMethod, root) {

			var start = time();
			var lastFrame = start;
			var percent = 0;
			var dropCounter = 0;
			var id = counter++;

			if (!root) {
				root = document.body;
			}

			// Compacting running db automatically every few new animations
			if (id % 20 === 0) {
				var newRunning = {};
				for (var usedId in running) {
					newRunning[usedId] = true;
				}
				running = newRunning;
			}

			// This is the internal step method which is called every few milliseconds
			var step = function(virtual) {

				// Normalize virtual value
				var render = virtual !== true;

				// Get current time
				var now = time();

				// Verification is executed before next animation step
				if (!running[id] || (verifyCallback && !verifyCallback(id))) {

					running[id] = null;
					completedCallback && completedCallback(desiredFrames - (dropCounter / ((now - start) / millisecondsPerSecond)), id, false);
					return;

				}

				// For the current rendering to apply let's update omitted steps in memory.
				// This is important to bring internal state variables up-to-date with progress in time.
				if (render) {

					var droppedFrames = Math.round((now - lastFrame) / (millisecondsPerSecond / desiredFrames)) - 1;
					for (var j = 0; j < Math.min(droppedFrames, 4); j++) {
						step(true);
						dropCounter++;
					}

				}

				// Compute percent value
				if (duration) {
					percent = (now - start) / duration;
					if (percent > 1) {
						percent = 1;
					}
				}

				// Execute step callback, then...
				var value = easingMethod ? easingMethod(percent) : percent;
				if ((stepCallback(value, now, render) === false || percent === 1) && render) {
					running[id] = null;
					completedCallback && completedCallback(desiredFrames - (dropCounter / ((now - start) / millisecondsPerSecond)), id, percent === 1 || duration == null);
				} else if (render) {
					lastFrame = now;
					core.effect.Animate.requestAnimationFrame(step, root);
				}
			};

			// Mark as running
			running[id] = true;

			// Init first step
			core.effect.Animate.requestAnimationFrame(step, root);

			// Return unique animation ID
			return id;
		}
	};
})(this);


/*
 * Scroller
 * http://github.com/zynga/scroller
 *
 * Copyright 2011, Zynga Inc.
 * Licensed under the MIT License.
 * https://raw.github.com/zynga/scroller/master/MIT-LICENSE.txt
 *
 * Based on the work of: Unify Project (unify-project.org)
 * http://unify-project.org
 * Copyright 2011, Deutsche Telekom AG
 * License: MIT + Apache (V2)
 */

var Scroller;

(function() {
	var NOOP = function(){};

	/**
	 * A pure logic 'component' for 'virtual' scrolling/zooming.
	 */
	Scroller = function(callback, options) {

		this.__callback = callback;

		this.options = {

			/** Enable scrolling on x-axis */
			scrollingX: true,

			/** Enable scrolling on y-axis */
			scrollingY: true,

			/** Enable animations for deceleration, snap back, zooming and scrolling */
			animating: true,

			/** duration for animations triggered by scrollTo/zoomTo */
			animationDuration: 250,

			/** Enable bouncing (content can be slowly moved outside and jumps back after releasing) */
			bouncing: true,

			/** Enable locking to the main axis if user moves only slightly on one of them at start */
			locking: true,

			/** Enable pagination mode (switching between full page content panes) */
			paging: false,

			/** Enable snapping of content to a configured pixel grid */
			snapping: false,

			/** Enable zooming of content via API, fingers and mouse wheel */
			zooming: false,

			/** Minimum zoom level */
			minZoom: 0.5,

			/** Maximum zoom level */
			maxZoom: 3,

			/** Multiply or decrease scrolling speed **/
			speedMultiplier: 1,

			/** Callback that is fired on the later of touch end or deceleration end,
			 provided that another scrolling action has not begun. Used to know
			 when to fade out a scrollbar. */
			scrollingComplete: NOOP,

			/** This configures the amount of change applied to deceleration when reaching boundaries  **/
			penetrationDeceleration : 0.03,

			/** This configures the amount of change applied to acceleration when reaching boundaries  **/
			penetrationAcceleration : 0.08

		};

		for (var key in options) {
			this.options[key] = options[key];
		}

	};


	// Easing Equations (c) 2003 Robert Penner, all rights reserved.
	// Open source under the BSD License.

	/**
	 * @param pos {Number} position between 0 (start of effect) and 1 (end of effect)
	 **/
	var easeOutCubic = function(pos) {
		return (Math.pow((pos - 1), 3) + 1);
	};

	/**
	 * @param pos {Number} position between 0 (start of effect) and 1 (end of effect)
	 **/
	var easeInOutCubic = function(pos) {
		if ((pos /= 0.5) < 1) {
			return 0.5 * Math.pow(pos, 3);
		}

		return 0.5 * (Math.pow((pos - 2), 3) + 2);
	};


	var members = {

		/*
		 ---------------------------------------------------------------------------
		 INTERNAL FIELDS :: STATUS
		 ---------------------------------------------------------------------------
		 */

		/** {Boolean} Whether only a single finger is used in touch handling */
		__isSingleTouch: false,

		/** {Boolean} Whether a touch event sequence is in progress */
		__isTracking: false,

		/** {Boolean} Whether a deceleration animation went to completion. */
		__didDecelerationComplete: false,

		/**
		 * {Boolean} Whether a gesture zoom/rotate event is in progress. Activates when
		 * a gesturestart event happens. This has higher priority than dragging.
		 */
		__isGesturing: false,

		/**
		 * {Boolean} Whether the user has moved by such a distance that we have enabled
		 * dragging mode. Hint: It's only enabled after some pixels of movement to
		 * not interrupt with clicks etc.
		 */
		__isDragging: false,

		/**
		 * {Boolean} Not touching and dragging anymore, and smoothly animating the
		 * touch sequence using deceleration.
		 */
		__isDecelerating: false,

		/**
		 * {Boolean} Smoothly animating the currently configured change
		 */
		__isAnimating: false,



		/*
		 ---------------------------------------------------------------------------
		 INTERNAL FIELDS :: DIMENSIONS
		 ---------------------------------------------------------------------------
		 */

		/** {Integer} Available outer left position (from document perspective) */
		__clientLeft: 0,

		/** {Integer} Available outer top position (from document perspective) */
		__clientTop: 0,

		/** {Integer} Available outer width */
		__clientWidth: 0,

		/** {Integer} Available outer height */
		__clientHeight: 0,

		/** {Integer} Outer width of content */
		__contentWidth: 0,

		/** {Integer} Outer height of content */
		__contentHeight: 0,

		/** {Integer} Snapping width for content */
		__snapWidth: 100,

		/** {Integer} Snapping height for content */
		__snapHeight: 100,

		/** {Integer} Height to assign to refresh area */
		__refreshHeight: null,

		/** {Boolean} Whether the refresh process is enabled when the event is released now */
		__refreshActive: false,

		/** {Function} Callback to execute on activation. This is for signalling the user about a refresh is about to happen when he release */
		__refreshActivate: null,

		/** {Function} Callback to execute on deactivation. This is for signalling the user about the refresh being cancelled */
		__refreshDeactivate: null,

		/** {Function} Callback to execute to start the actual refresh. Call {@link #refreshFinish} when done */
		__refreshStart: null,

		/** {Number} Zoom level */
		__zoomLevel: 1,

		/** {Number} Scroll position on x-axis */
		__scrollLeft: 0,

		/** {Number} Scroll position on y-axis */
		__scrollTop: 0,

		/** {Integer} Maximum allowed scroll position on x-axis */
		__maxScrollLeft: 0,

		/** {Integer} Maximum allowed scroll position on y-axis */
		__maxScrollTop: 0,

		/* {Number} Scheduled left position (final position when animating) */
		__scheduledLeft: 0,

		/* {Number} Scheduled top position (final position when animating) */
		__scheduledTop: 0,

		/* {Number} Scheduled zoom level (final scale when animating) */
		__scheduledZoom: 0,



		/*
		 ---------------------------------------------------------------------------
		 INTERNAL FIELDS :: LAST POSITIONS
		 ---------------------------------------------------------------------------
		 */

		/** {Number} Left position of finger at start */
		__lastTouchLeft: null,

		/** {Number} Top position of finger at start */
		__lastTouchTop: null,

		/** {Date} Timestamp of last move of finger. Used to limit tracking range for deceleration speed. */
		__lastTouchMove: null,

		/** {Array} List of positions, uses three indexes for each state: left, top, timestamp */
		__positions: null,



		/*
		 ---------------------------------------------------------------------------
		 INTERNAL FIELDS :: DECELERATION SUPPORT
		 ---------------------------------------------------------------------------
		 */

		/** {Integer} Minimum left scroll position during deceleration */
		__minDecelerationScrollLeft: null,

		/** {Integer} Minimum top scroll position during deceleration */
		__minDecelerationScrollTop: null,

		/** {Integer} Maximum left scroll position during deceleration */
		__maxDecelerationScrollLeft: null,

		/** {Integer} Maximum top scroll position during deceleration */
		__maxDecelerationScrollTop: null,

		/** {Number} Current factor to modify horizontal scroll position with on every step */
		__decelerationVelocityX: null,

		/** {Number} Current factor to modify vertical scroll position with on every step */
		__decelerationVelocityY: null,



		/*
		 ---------------------------------------------------------------------------
		 PUBLIC API
		 ---------------------------------------------------------------------------
		 */

		/**
		 * Configures the dimensions of the client (outer) and content (inner) elements.
		 * Requires the available space for the outer element and the outer size of the inner element.
		 * All values which are falsy (null or zero etc.) are ignored and the old value is kept.
		 *
		 * @param clientWidth {Integer ? null} Inner width of outer element
		 * @param clientHeight {Integer ? null} Inner height of outer element
		 * @param contentWidth {Integer ? null} Outer width of inner element
		 * @param contentHeight {Integer ? null} Outer height of inner element
		 */
		setDimensions: function(clientWidth, clientHeight, contentWidth, contentHeight) {

			var self = this;

			// Only update values which are defined
			if (clientWidth === +clientWidth) {
				self.__clientWidth = clientWidth;
			}

			if (clientHeight === +clientHeight) {
				self.__clientHeight = clientHeight;
			}

			if (contentWidth === +contentWidth) {
				self.__contentWidth = contentWidth;
			}

			if (contentHeight === +contentHeight) {
				self.__contentHeight = contentHeight;
			}

			// Refresh maximums
			self.__computeScrollMax();

			// Refresh scroll position
			self.scrollTo(self.__scrollLeft, self.__scrollTop, true);

		},


		/**
		 * Sets the client coordinates in relation to the document.
		 *
		 * @param left {Integer ? 0} Left position of outer element
		 * @param top {Integer ? 0} Top position of outer element
		 */
		setPosition: function(left, top) {

			var self = this;

			self.__clientLeft = left || 0;
			self.__clientTop = top || 0;

		},


		/**
		 * Configures the snapping (when snapping is active)
		 *
		 * @param width {Integer} Snapping width
		 * @param height {Integer} Snapping height
		 */
		setSnapSize: function(width, height) {

			var self = this;

			self.__snapWidth = width;
			self.__snapHeight = height;

		},


		/**
		 * Activates pull-to-refresh. A special zone on the top of the list to start a list refresh whenever
		 * the user event is released during visibility of this zone. This was introduced by some apps on iOS like
		 * the official Twitter client.
		 *
		 * @param height {Integer} Height of pull-to-refresh zone on top of rendered list
		 * @param activateCallback {Function} Callback to execute on activation. This is for signalling the user about a refresh is about to happen when he release.
		 * @param deactivateCallback {Function} Callback to execute on deactivation. This is for signalling the user about the refresh being cancelled.
		 * @param startCallback {Function} Callback to execute to start the real async refresh action. Call {@link #finishPullToRefresh} after finish of refresh.
		 */
		activatePullToRefresh: function(height, activateCallback, deactivateCallback, startCallback) {

			var self = this;

			self.__refreshHeight = height;
			self.__refreshActivate = activateCallback;
			self.__refreshDeactivate = deactivateCallback;
			self.__refreshStart = startCallback;

		},


		/**
		 * Starts pull-to-refresh manually.
		 */
		triggerPullToRefresh: function() {
			// Use publish instead of scrollTo to allow scrolling to out of boundary position
			// We don't need to normalize scrollLeft, zoomLevel, etc. here because we only y-scrolling when pull-to-refresh is enabled
			this.__publish(this.__scrollLeft, -this.__refreshHeight, this.__zoomLevel, true);

			if (this.__refreshStart) {
				this.__refreshStart();
			}
		},


		/**
		 * Signalizes that pull-to-refresh is finished.
		 */
		finishPullToRefresh: function() {

			var self = this;

			self.__refreshActive = false;
			if (self.__refreshDeactivate) {
				self.__refreshDeactivate();
			}

			self.scrollTo(self.__scrollLeft, self.__scrollTop, true);

		},


		/**
		 * Returns the scroll position and zooming values
		 *
		 * @return {Map} `left` and `top` scroll position and `zoom` level
		 */
		getValues: function() {

			var self = this;

			return {
				left: self.__scrollLeft,
				top: self.__scrollTop,
				zoom: self.__zoomLevel
			};

		},


		/**
		 * Returns the maximum scroll values
		 *
		 * @return {Map} `left` and `top` maximum scroll values
		 */
		getScrollMax: function() {

			var self = this;

			return {
				left: self.__maxScrollLeft,
				top: self.__maxScrollTop
			};

		},


		/**
		 * Zooms to the given level. Supports optional animation. Zooms
		 * the center when no coordinates are given.
		 *
		 * @param level {Number} Level to zoom to
		 * @param animate {Boolean ? false} Whether to use animation
		 * @param originLeft {Number ? null} Zoom in at given left coordinate
		 * @param originTop {Number ? null} Zoom in at given top coordinate
		 * @param callback {Function ? null} A callback that gets fired when the zoom is complete.
		 */
		zoomTo: function(level, animate, originLeft, originTop, callback) {

			var self = this;

			if (!self.options.zooming) {
				throw new Error("Zooming is not enabled!");
			}

			// Add callback if exists
			if(callback) {
				self.__zoomComplete = callback;
			}

			// Stop deceleration
			if (self.__isDecelerating) {
				core.effect.Animate.stop(self.__isDecelerating);
				self.__isDecelerating = false;
			}

			var oldLevel = self.__zoomLevel;

			// Normalize input origin to center of viewport if not defined
			if (originLeft == null) {
				originLeft = self.__clientWidth / 2;
			}

			if (originTop == null) {
				originTop = self.__clientHeight / 2;
			}

			// Limit level according to configuration
			level = Math.max(Math.min(level, self.options.maxZoom), self.options.minZoom);

			// Recompute maximum values while temporary tweaking maximum scroll ranges
			self.__computeScrollMax(level);

			// Recompute left and top coordinates based on new zoom level
			var left = ((originLeft + self.__scrollLeft) * level / oldLevel) - originLeft;
			var top = ((originTop + self.__scrollTop) * level / oldLevel) - originTop;

			// Limit x-axis
			if (left > self.__maxScrollLeft) {
				left = self.__maxScrollLeft;
			} else if (left < 0) {
				left = 0;
			}

			// Limit y-axis
			if (top > self.__maxScrollTop) {
				top = self.__maxScrollTop;
			} else if (top < 0) {
				top = 0;
			}

			// Push values out
			self.__publish(left, top, level, animate);

		},


		/**
		 * Zooms the content by the given factor.
		 *
		 * @param factor {Number} Zoom by given factor
		 * @param animate {Boolean ? false} Whether to use animation
		 * @param originLeft {Number ? 0} Zoom in at given left coordinate
		 * @param originTop {Number ? 0} Zoom in at given top coordinate
		 * @param callback {Function ? null} A callback that gets fired when the zoom is complete.
		 */
		zoomBy: function(factor, animate, originLeft, originTop, callback) {

			var self = this;

			self.zoomTo(self.__zoomLevel * factor, animate, originLeft, originTop, callback);

		},


		/**
		 * Scrolls to the given position. Respect limitations and snapping automatically.
		 *
		 * @param left {Number?null} Horizontal scroll position, keeps current if value is <code>null</code>
		 * @param top {Number?null} Vertical scroll position, keeps current if value is <code>null</code>
		 * @param animate {Boolean?false} Whether the scrolling should happen using an animation
		 * @param zoom {Number?null} Zoom level to go to
		 */
		scrollTo: function(left, top, animate, zoom) {

			var self = this;

			// Stop deceleration
			if (self.__isDecelerating) {
				core.effect.Animate.stop(self.__isDecelerating);
				self.__isDecelerating = false;
			}

			// Correct coordinates based on new zoom level
			if (zoom != null && zoom !== self.__zoomLevel) {

				if (!self.options.zooming) {
					throw new Error("Zooming is not enabled!");
				}

				left *= zoom;
				top *= zoom;

				// Recompute maximum values while temporary tweaking maximum scroll ranges
				self.__computeScrollMax(zoom);

			} else {

				// Keep zoom when not defined
				zoom = self.__zoomLevel;

			}

			if (!self.options.scrollingX) {

				left = self.__scrollLeft;

			} else {

				if (self.options.paging) {
					left = Math.round(left / self.__clientWidth) * self.__clientWidth;
				} else if (self.options.snapping) {
					left = Math.round(left / self.__snapWidth) * self.__snapWidth;
				}

			}

			if (!self.options.scrollingY) {

				top = self.__scrollTop;

			} else {

				if (self.options.paging) {
					top = Math.round(top / self.__clientHeight) * self.__clientHeight;
				} else if (self.options.snapping) {
					top = Math.round(top / self.__snapHeight) * self.__snapHeight;
				}

			}

			// Limit for allowed ranges
			left = Math.max(Math.min(self.__maxScrollLeft, left), 0);
			top = Math.max(Math.min(self.__maxScrollTop, top), 0);

			// Don't animate when no change detected, still call publish to make sure
			// that rendered position is really in-sync with internal data
			if (left === self.__scrollLeft && top === self.__scrollTop) {
				animate = false;
			}

			// Publish new values
			self.__publish(left, top, zoom, animate);

		},


		/**
		 * Scroll by the given offset
		 *
		 * @param left {Number ? 0} Scroll x-axis by given offset
		 * @param top {Number ? 0} Scroll x-axis by given offset
		 * @param animate {Boolean ? false} Whether to animate the given change
		 */
		scrollBy: function(left, top, animate) {

			var self = this;

			var startLeft = self.__isAnimating ? self.__scheduledLeft : self.__scrollLeft;
			var startTop = self.__isAnimating ? self.__scheduledTop : self.__scrollTop;

			self.scrollTo(startLeft + (left || 0), startTop + (top || 0), animate);

		},



		/*
		 ---------------------------------------------------------------------------
		 EVENT CALLBACKS
		 ---------------------------------------------------------------------------
		 */

		/**
		 * Mouse wheel handler for zooming support
		 */
		doMouseZoom: function(wheelDelta, timeStamp, pageX, pageY) {

			var self = this;
			var change = wheelDelta > 0 ? 0.97 : 1.03;

			return self.zoomTo(self.__zoomLevel * change, false, pageX - self.__clientLeft, pageY - self.__clientTop);

		},


		/**
		 * Touch start handler for scrolling support
		 */
		doTouchStart: function(touches, timeStamp) {

			// Array-like check is enough here
			if (touches.length == null) {
				throw new Error("Invalid touch list: " + touches);
			}

			if (timeStamp instanceof Date) {
				timeStamp = timeStamp.valueOf();
			}
			if (typeof timeStamp !== "number") {
				throw new Error("Invalid timestamp value: " + timeStamp);
			}

			var self = this;

			// Reset interruptedAnimation flag
			self.__interruptedAnimation = true;

			// Stop deceleration
			if (self.__isDecelerating) {
				core.effect.Animate.stop(self.__isDecelerating);
				self.__isDecelerating = false;
				self.__interruptedAnimation = true;
			}

			// Stop animation
			if (self.__isAnimating) {
				core.effect.Animate.stop(self.__isAnimating);
				self.__isAnimating = false;
				self.__interruptedAnimation = true;
			}

			// Use center point when dealing with two fingers
			var currentTouchLeft, currentTouchTop;
			var isSingleTouch = touches.length === 1;
			if (isSingleTouch) {
				currentTouchLeft = touches[0].pageX;
				currentTouchTop = touches[0].pageY;
			} else {
				currentTouchLeft = Math.abs(touches[0].pageX + touches[1].pageX) / 2;
				currentTouchTop = Math.abs(touches[0].pageY + touches[1].pageY) / 2;
			}

			// Store initial positions
			self.__initialTouchLeft = currentTouchLeft;
			self.__initialTouchTop = currentTouchTop;

			// Store current zoom level
			self.__zoomLevelStart = self.__zoomLevel;

			// Store initial touch positions
			self.__lastTouchLeft = currentTouchLeft;
			self.__lastTouchTop = currentTouchTop;

			// Store initial move time stamp
			self.__lastTouchMove = timeStamp;

			// Reset initial scale
			self.__lastScale = 1;

			// Reset locking flags
			self.__enableScrollX = !isSingleTouch && self.options.scrollingX;
			self.__enableScrollY = !isSingleTouch && self.options.scrollingY;

			// Reset tracking flag
			self.__isTracking = true;

			// Reset deceleration complete flag
			self.__didDecelerationComplete = false;

			// Dragging starts directly with two fingers, otherwise lazy with an offset
			self.__isDragging = !isSingleTouch;

			// Some features are disabled in multi touch scenarios
			self.__isSingleTouch = isSingleTouch;

			// Clearing data structure
			self.__positions = [];

		},


		/**
		 * Touch move handler for scrolling support
		 */
		doTouchMove: function(touches, timeStamp, scale) {

			// Array-like check is enough here
			if (touches.length == null) {
				throw new Error("Invalid touch list: " + touches);
			}

			if (timeStamp instanceof Date) {
				timeStamp = timeStamp.valueOf();
			}
			if (typeof timeStamp !== "number") {
				throw new Error("Invalid timestamp value: " + timeStamp);
			}

			var self = this;

			// Ignore event when tracking is not enabled (event might be outside of element)
			if (!self.__isTracking) {
				return;
			}


			var currentTouchLeft, currentTouchTop;

			// Compute move based around of center of fingers
			if (touches.length === 2) {
				currentTouchLeft = Math.abs(touches[0].pageX + touches[1].pageX) / 2;
				currentTouchTop = Math.abs(touches[0].pageY + touches[1].pageY) / 2;
			} else {
				currentTouchLeft = touches[0].pageX;
				currentTouchTop = touches[0].pageY;
			}

			var positions = self.__positions;

			// Are we already is dragging mode?
			if (self.__isDragging) {

				// Compute move distance
				var moveX = currentTouchLeft - self.__lastTouchLeft;
				var moveY = currentTouchTop - self.__lastTouchTop;

				// Read previous scroll position and zooming
				var scrollLeft = self.__scrollLeft;
				var scrollTop = self.__scrollTop;
				var level = self.__zoomLevel;

				// Work with scaling
				if (scale != null && self.options.zooming) {

					var oldLevel = level;

					// Recompute level based on previous scale and new scale
					level = level / self.__lastScale * scale;

					// Limit level according to configuration
					level = Math.max(Math.min(level, self.options.maxZoom), self.options.minZoom);

					// Only do further compution when change happened
					if (oldLevel !== level) {

						// Compute relative event position to container
						var currentTouchLeftRel = currentTouchLeft - self.__clientLeft;
						var currentTouchTopRel = currentTouchTop - self.__clientTop;

						// Recompute left and top coordinates based on new zoom level
						scrollLeft = ((currentTouchLeftRel + scrollLeft) * level / oldLevel) - currentTouchLeftRel;
						scrollTop = ((currentTouchTopRel + scrollTop) * level / oldLevel) - currentTouchTopRel;

						// Recompute max scroll values
						self.__computeScrollMax(level);

					}
				}

				if (self.__enableScrollX) {

					scrollLeft -= moveX * this.options.speedMultiplier;
					var maxScrollLeft = self.__maxScrollLeft;

					if (scrollLeft > maxScrollLeft || scrollLeft < 0) {

						// Slow down on the edges
						if (self.options.bouncing) {

							scrollLeft += (moveX / 2  * this.options.speedMultiplier);

						} else if (scrollLeft > maxScrollLeft) {

							scrollLeft = maxScrollLeft;

						} else {

							scrollLeft = 0;

						}
					}
				}

				// Compute new vertical scroll position
				if (self.__enableScrollY) {

					scrollTop -= moveY * this.options.speedMultiplier;
					var maxScrollTop = self.__maxScrollTop;

					if (scrollTop > maxScrollTop || scrollTop < 0) {

						// Slow down on the edges
						if (self.options.bouncing) {

							scrollTop += (moveY / 2 * this.options.speedMultiplier);

							// Support pull-to-refresh (only when only y is scrollable)
							if (!self.__enableScrollX && self.__refreshHeight != null) {

								if (!self.__refreshActive && scrollTop <= -self.__refreshHeight) {

									self.__refreshActive = true;
									if (self.__refreshActivate) {
										self.__refreshActivate();
									}

								} else if (self.__refreshActive && scrollTop > -self.__refreshHeight) {

									self.__refreshActive = false;
									if (self.__refreshDeactivate) {
										self.__refreshDeactivate();
									}

								}
							}

						} else if (scrollTop > maxScrollTop) {

							scrollTop = maxScrollTop;

						} else {

							scrollTop = 0;

						}
					}
				}

				// Keep list from growing infinitely (holding min 10, max 20 measure points)
				if (positions.length > 60) {
					positions.splice(0, 30);
				}

				// Track scroll movement for decleration
				positions.push(scrollLeft, scrollTop, timeStamp);

				// Sync scroll position
				self.__publish(scrollLeft, scrollTop, level);

				// Otherwise figure out whether we are switching into dragging mode now.
			} else {

				var minimumTrackingForScroll = self.options.locking ? 3 : 0;
				var minimumTrackingForDrag = 5;

				var distanceX = Math.abs(currentTouchLeft - self.__initialTouchLeft);
				var distanceY = Math.abs(currentTouchTop - self.__initialTouchTop);

				self.__enableScrollX = self.options.scrollingX && distanceX >= minimumTrackingForScroll;
				self.__enableScrollY = self.options.scrollingY && distanceY >= minimumTrackingForScroll;

				positions.push(self.__scrollLeft, self.__scrollTop, timeStamp);

				self.__isDragging = (self.__enableScrollX || self.__enableScrollY) && (distanceX >= minimumTrackingForDrag || distanceY >= minimumTrackingForDrag);
				if (self.__isDragging) {
					self.__interruptedAnimation = false;
				}

			}

			// Update last touch positions and time stamp for next event
			self.__lastTouchLeft = currentTouchLeft;
			self.__lastTouchTop = currentTouchTop;
			self.__lastTouchMove = timeStamp;
			self.__lastScale = scale;

		},


		/**
		 * Touch end handler for scrolling support
		 */
		doTouchEnd: function(timeStamp) {

			if (timeStamp instanceof Date) {
				timeStamp = timeStamp.valueOf();
			}
			if (typeof timeStamp !== "number") {
				throw new Error("Invalid timestamp value: " + timeStamp);
			}

			var self = this;

			// Ignore event when tracking is not enabled (no touchstart event on element)
			// This is required as this listener ('touchmove') sits on the document and not on the element itself.
			if (!self.__isTracking) {
				return;
			}

			// Not touching anymore (when two finger hit the screen there are two touch end events)
			self.__isTracking = false;

			// Be sure to reset the dragging flag now. Here we also detect whether
			// the finger has moved fast enough to switch into a deceleration animation.
			if (self.__isDragging) {

				// Reset dragging flag
				self.__isDragging = false;

				// Start deceleration
				// Verify that the last move detected was in some relevant time frame
				if (self.__isSingleTouch && self.options.animating && (timeStamp - self.__lastTouchMove) <= 100) {

					// Then figure out what the scroll position was about 100ms ago
					var positions = self.__positions;
					var endPos = positions.length - 1;
					var startPos = endPos;

					// Move pointer to position measured 100ms ago
					for (var i = endPos; i > 0 && positions[i] > (self.__lastTouchMove - 100); i -= 3) {
						startPos = i;
					}

					// If start and stop position is identical in a 100ms timeframe,
					// we cannot compute any useful deceleration.
					if (startPos !== endPos) {

						// Compute relative movement between these two points
						var timeOffset = positions[endPos] - positions[startPos];
						var movedLeft = self.__scrollLeft - positions[startPos - 2];
						var movedTop = self.__scrollTop - positions[startPos - 1];

						// Based on 50ms compute the movement to apply for each render step
						self.__decelerationVelocityX = movedLeft / timeOffset * (1000 / 60);
						self.__decelerationVelocityY = movedTop / timeOffset * (1000 / 60);

						// How much velocity is required to start the deceleration
						var minVelocityToStartDeceleration = self.options.paging || self.options.snapping ? 4 : 1;

						// Verify that we have enough velocity to start deceleration
						if (Math.abs(self.__decelerationVelocityX) > minVelocityToStartDeceleration || Math.abs(self.__decelerationVelocityY) > minVelocityToStartDeceleration) {

							// Deactivate pull-to-refresh when decelerating
							if (!self.__refreshActive) {
								self.__startDeceleration(timeStamp);
							}
						}
					} else {
						self.options.scrollingComplete();
					}
				} else if ((timeStamp - self.__lastTouchMove) > 100) {
					self.options.scrollingComplete();
				}
			}

			// If this was a slower move it is per default non decelerated, but this
			// still means that we want snap back to the bounds which is done here.
			// This is placed outside the condition above to improve edge case stability
			// e.g. touchend fired without enabled dragging. This should normally do not
			// have modified the scroll positions or even showed the scrollbars though.
			if (!self.__isDecelerating) {

				if (self.__refreshActive && self.__refreshStart) {

					// Use publish instead of scrollTo to allow scrolling to out of boundary position
					// We don't need to normalize scrollLeft, zoomLevel, etc. here because we only y-scrolling when pull-to-refresh is enabled
					self.__publish(self.__scrollLeft, -self.__refreshHeight, self.__zoomLevel, true);

					if (self.__refreshStart) {
						self.__refreshStart();
					}

				} else {

					if (self.__interruptedAnimation || self.__isDragging) {
						self.options.scrollingComplete();
					}
					self.scrollTo(self.__scrollLeft, self.__scrollTop, true, self.__zoomLevel);

					// Directly signalize deactivation (nothing todo on refresh?)
					if (self.__refreshActive) {

						self.__refreshActive = false;
						if (self.__refreshDeactivate) {
							self.__refreshDeactivate();
						}

					}
				}
			}

			// Fully cleanup list
			self.__positions.length = 0;

		},



		/*
		 ---------------------------------------------------------------------------
		 PRIVATE API
		 ---------------------------------------------------------------------------
		 */

		/**
		 * Applies the scroll position to the content element
		 *
		 * @param left {Number} Left scroll position
		 * @param top {Number} Top scroll position
		 * @param animate {Boolean?false} Whether animation should be used to move to the new coordinates
		 */
		__publish: function(left, top, zoom, animate) {

			var self = this;

			// Remember whether we had an animation, then we try to continue based on the current "drive" of the animation
			var wasAnimating = self.__isAnimating;
			if (wasAnimating) {
				core.effect.Animate.stop(wasAnimating);
				self.__isAnimating = false;
			}

			if (animate && self.options.animating) {

				// Keep scheduled positions for scrollBy/zoomBy functionality
				self.__scheduledLeft = left;
				self.__scheduledTop = top;
				self.__scheduledZoom = zoom;

				var oldLeft = self.__scrollLeft;
				var oldTop = self.__scrollTop;
				var oldZoom = self.__zoomLevel;

				var diffLeft = left - oldLeft;
				var diffTop = top - oldTop;
				var diffZoom = zoom - oldZoom;

				var step = function(percent, now, render) {

					if (render) {

						self.__scrollLeft = oldLeft + (diffLeft * percent);
						self.__scrollTop = oldTop + (diffTop * percent);
						self.__zoomLevel = oldZoom + (diffZoom * percent);

						// Push values out
						if (self.__callback) {
							self.__callback(self.__scrollLeft, self.__scrollTop, self.__zoomLevel);
						}

					}
				};

				var verify = function(id) {
					return self.__isAnimating === id;
				};

				var completed = function(renderedFramesPerSecond, animationId, wasFinished) {
					if (animationId === self.__isAnimating) {
						self.__isAnimating = false;
					}
					if (self.__didDecelerationComplete || wasFinished) {
						self.options.scrollingComplete();
					}

					if (self.options.zooming) {
						self.__computeScrollMax();
						if(self.__zoomComplete) {
							self.__zoomComplete();
							self.__zoomComplete = null;
						}
					}
				};

				// When continuing based on previous animation we choose an ease-out animation instead of ease-in-out
				self.__isAnimating = core.effect.Animate.start(step, verify, completed, self.options.animationDuration, wasAnimating ? easeOutCubic : easeInOutCubic);

			} else {

				self.__scheduledLeft = self.__scrollLeft = left;
				self.__scheduledTop = self.__scrollTop = top;
				self.__scheduledZoom = self.__zoomLevel = zoom;

				// Push values out
				if (self.__callback) {
					self.__callback(left, top, zoom);
				}

				// Fix max scroll ranges
				if (self.options.zooming) {
					self.__computeScrollMax();
					if(self.__zoomComplete) {
						self.__zoomComplete();
						self.__zoomComplete = null;
					}
				}
			}
		},


		/**
		 * Recomputes scroll minimum values based on client dimensions and content dimensions.
		 */
		__computeScrollMax: function(zoomLevel) {

			var self = this;

			if (zoomLevel == null) {
				zoomLevel = self.__zoomLevel;
			}

			self.__maxScrollLeft = Math.max((self.__contentWidth * zoomLevel) - self.__clientWidth, 0);
			self.__maxScrollTop = Math.max((self.__contentHeight * zoomLevel) - self.__clientHeight, 0);

		},



		/*
		 ---------------------------------------------------------------------------
		 ANIMATION (DECELERATION) SUPPORT
		 ---------------------------------------------------------------------------
		 */

		/**
		 * Called when a touch sequence end and the speed of the finger was high enough
		 * to switch into deceleration mode.
		 */
		__startDeceleration: function(timeStamp) {

			var self = this;

			if (self.options.paging) {

				var scrollLeft = Math.max(Math.min(self.__scrollLeft, self.__maxScrollLeft), 0);
				var scrollTop = Math.max(Math.min(self.__scrollTop, self.__maxScrollTop), 0);
				var clientWidth = self.__clientWidth;
				var clientHeight = self.__clientHeight;

				// We limit deceleration not to the min/max values of the allowed range, but to the size of the visible client area.
				// Each page should have exactly the size of the client area.
				self.__minDecelerationScrollLeft = Math.floor(scrollLeft / clientWidth) * clientWidth;
				self.__minDecelerationScrollTop = Math.floor(scrollTop / clientHeight) * clientHeight;
				self.__maxDecelerationScrollLeft = Math.ceil(scrollLeft / clientWidth) * clientWidth;
				self.__maxDecelerationScrollTop = Math.ceil(scrollTop / clientHeight) * clientHeight;

			} else {

				self.__minDecelerationScrollLeft = 0;
				self.__minDecelerationScrollTop = 0;
				self.__maxDecelerationScrollLeft = self.__maxScrollLeft;
				self.__maxDecelerationScrollTop = self.__maxScrollTop;

			}

			// Wrap class method
			var step = function(percent, now, render) {
				self.__stepThroughDeceleration(render);
			};

			// How much velocity is required to keep the deceleration running
			var minVelocityToKeepDecelerating = self.options.snapping ? 4 : 0.1;

			// Detect whether it's still worth to continue animating steps
			// If we are already slow enough to not being user perceivable anymore, we stop the whole process here.
			var verify = function() {
				var shouldContinue = Math.abs(self.__decelerationVelocityX) >= minVelocityToKeepDecelerating || Math.abs(self.__decelerationVelocityY) >= minVelocityToKeepDecelerating;
				if (!shouldContinue) {
					self.__didDecelerationComplete = true;
				}
				return shouldContinue;
			};

			var completed = function(renderedFramesPerSecond, animationId, wasFinished) {
				self.__isDecelerating = false;
				if (self.__didDecelerationComplete) {
					self.options.scrollingComplete();
				}

				// Animate to grid when snapping is active, otherwise just fix out-of-boundary positions
				self.scrollTo(self.__scrollLeft, self.__scrollTop, self.options.snapping);
			};

			// Start animation and switch on flag
			self.__isDecelerating = core.effect.Animate.start(step, verify, completed);

		},


		/**
		 * Called on every step of the animation
		 *
		 * @param inMemory {Boolean?false} Whether to not render the current step, but keep it in memory only. Used internally only!
		 */
		__stepThroughDeceleration: function(render) {

			var self = this;


			//
			// COMPUTE NEXT SCROLL POSITION
			//

			// Add deceleration to scroll position
			var scrollLeft = self.__scrollLeft + self.__decelerationVelocityX;
			var scrollTop = self.__scrollTop + self.__decelerationVelocityY;


			//
			// HARD LIMIT SCROLL POSITION FOR NON BOUNCING MODE
			//

			if (!self.options.bouncing) {

				var scrollLeftFixed = Math.max(Math.min(self.__maxDecelerationScrollLeft, scrollLeft), self.__minDecelerationScrollLeft);
				if (scrollLeftFixed !== scrollLeft) {
					scrollLeft = scrollLeftFixed;
					self.__decelerationVelocityX = 0;
				}

				var scrollTopFixed = Math.max(Math.min(self.__maxDecelerationScrollTop, scrollTop), self.__minDecelerationScrollTop);
				if (scrollTopFixed !== scrollTop) {
					scrollTop = scrollTopFixed;
					self.__decelerationVelocityY = 0;
				}

			}


			//
			// UPDATE SCROLL POSITION
			//

			if (render) {

				self.__publish(scrollLeft, scrollTop, self.__zoomLevel);

			} else {

				self.__scrollLeft = scrollLeft;
				self.__scrollTop = scrollTop;

			}


			//
			// SLOW DOWN
			//

			// Slow down velocity on every iteration
			if (!self.options.paging) {

				// This is the factor applied to every iteration of the animation
				// to slow down the process. This should emulate natural behavior where
				// objects slow down when the initiator of the movement is removed
				var frictionFactor = 0.95;

				self.__decelerationVelocityX *= frictionFactor;
				self.__decelerationVelocityY *= frictionFactor;

			}


			//
			// BOUNCING SUPPORT
			//

			if (self.options.bouncing) {

				var scrollOutsideX = 0;
				var scrollOutsideY = 0;

				// This configures the amount of change applied to deceleration/acceleration when reaching boundaries
				var penetrationDeceleration = self.options.penetrationDeceleration;
				var penetrationAcceleration = self.options.penetrationAcceleration;

				// Check limits
				if (scrollLeft < self.__minDecelerationScrollLeft) {
					scrollOutsideX = self.__minDecelerationScrollLeft - scrollLeft;
				} else if (scrollLeft > self.__maxDecelerationScrollLeft) {
					scrollOutsideX = self.__maxDecelerationScrollLeft - scrollLeft;
				}

				if (scrollTop < self.__minDecelerationScrollTop) {
					scrollOutsideY = self.__minDecelerationScrollTop - scrollTop;
				} else if (scrollTop > self.__maxDecelerationScrollTop) {
					scrollOutsideY = self.__maxDecelerationScrollTop - scrollTop;
				}

				// Slow down until slow enough, then flip back to snap position
				if (scrollOutsideX !== 0) {
					if (scrollOutsideX * self.__decelerationVelocityX <= 0) {
						self.__decelerationVelocityX += scrollOutsideX * penetrationDeceleration;
					} else {
						self.__decelerationVelocityX = scrollOutsideX * penetrationAcceleration;
					}
				}

				if (scrollOutsideY !== 0) {
					if (scrollOutsideY * self.__decelerationVelocityY <= 0) {
						self.__decelerationVelocityY += scrollOutsideY * penetrationDeceleration;
					} else {
						self.__decelerationVelocityY = scrollOutsideY * penetrationAcceleration;
					}
				}
			}
		}
	};

	// Copy over members to prototype
	for (var key in members) {
		Scroller.prototype[key] = members[key];
	}

})();
var EasyScroller = function(content, options) {
	
	this.content = content;
	this.container = content.parentNode;
	this.options = options || {};

	// create Scroller instance
	var that = this;
	this.scroller = new Scroller(function(left, top, zoom) {
		that.render(left, top, zoom);
	}, options);

	// bind events
	this.bindEvents();

	// the content element needs a correct transform origin for zooming
	this.content.style[EasyScroller.vendorPrefix + 'TransformOrigin'] = "left top";

	// reflow for the first time
	this.reflow();

};

EasyScroller.prototype.render = (function() {
	
	var docStyle = document.documentElement.style;
	
	var engine;
	if (window.opera && Object.prototype.toString.call(opera) === '[object Opera]') {
		engine = 'presto';
	} else if ('MozAppearance' in docStyle) {
		engine = 'gecko';
	} else if ('WebkitAppearance' in docStyle) {
		engine = 'webkit';
	} else if (typeof navigator.cpuClass === 'string') {
		engine = 'trident';
	}
	
	var vendorPrefix = EasyScroller.vendorPrefix = {
		trident: 'ms',
		gecko: 'Moz',
		webkit: 'Webkit',
		presto: 'O'
	}[engine];
	
	var helperElem = document.createElement("div");
	var undef;
	
	var perspectiveProperty = vendorPrefix + "Perspective";
	var transformProperty = vendorPrefix + "Transform";
	
	if (helperElem.style[perspectiveProperty] !== undef) {
		
		return function(left, top, zoom) {
			this.content.style[transformProperty] = 'translate3d(' + (-left) + 'px,' + (-top) + 'px,0) scale(' + zoom + ')';
		};	
		
	} else if (helperElem.style[transformProperty] !== undef) {
		
		return function(left, top, zoom) {
			this.content.style[transformProperty] = 'translate(' + (-left) + 'px,' + (-top) + 'px) scale(' + zoom + ')';
		};
		
	} else {
		
		return function(left, top, zoom) {
			this.content.style.marginLeft = left ? (-left/zoom) + 'px' : '';
			this.content.style.marginTop = top ? (-top/zoom) + 'px' : '';
			this.content.style.zoom = zoom || '';
		};
		
	}
})();

EasyScroller.prototype.reflow = function() {

	// set the right scroller dimensions
	this.scroller.setDimensions(this.container.clientWidth, this.container.clientHeight, this.content.offsetWidth, this.content.offsetHeight);

	// refresh the position for zooming purposes
	var rect = this.container.getBoundingClientRect();
	this.scroller.setPosition(rect.left + this.container.clientLeft, rect.top + this.container.clientTop);
	
};

EasyScroller.prototype.bindEvents = function() {

	var that = this;

	// reflow handling
	window.addEventListener("resize", function() {
		that.reflow();
	}, false);

	// touch devices bind touch events
	if ('ontouchstart' in window) {

		this.container.addEventListener("touchstart", function(e) {

			// Don't react if initial down happens on a form element
			if (e.touches[0] && e.touches[0].target && e.touches[0].target.tagName.match(/input|textarea|select/i)) {
				return;
			}

			that.scroller.doTouchStart(e.touches, e.timeStamp);
			e.preventDefault();

		}, false);

		document.addEventListener("touchmove", function(e) {
			that.scroller.doTouchMove(e.touches, e.timeStamp, e.scale);
		}, false);

		document.addEventListener("touchend", function(e) {
			that.scroller.doTouchEnd(e.timeStamp);
		}, false);

		document.addEventListener("touchcancel", function(e) {
			that.scroller.doTouchEnd(e.timeStamp);
		}, false);

	// non-touch bind mouse events
	} else {
		
		var mousedown = false;

		this.container.addEventListener("mousedown", function(e) {

			if (e.target.tagName.match(/input|textarea|select/i)) {
				return;
			}
		
			that.scroller.doTouchStart([{
				pageX: e.pageX,
				pageY: e.pageY
			}], e.timeStamp);

			mousedown = true;
			e.preventDefault();

		}, false);

		document.addEventListener("mousemove", function(e) {

			if (!mousedown) {
				return;
			}
			
			that.scroller.doTouchMove([{
				pageX: e.pageX,
				pageY: e.pageY
			}], e.timeStamp);

			mousedown = true;

		}, false);

		document.addEventListener("mouseup", function(e) {

			if (!mousedown) {
				return;
			}
			
			that.scroller.doTouchEnd(e.timeStamp);

			mousedown = false;

		}, false);

		this.container.addEventListener("mousewheel", function(e) {
			if(that.options.zooming) {
				that.scroller.doMouseZoom(e.wheelDelta, e.timeStamp, e.pageX, e.pageY);	
				e.preventDefault();
			}
		}, false);

	}

};

// automatically attach an EasyScroller to elements found with the right data attributes
document.addEventListener("DOMContentLoaded", function() {
	
	var elements = document.querySelectorAll('[data-scrollable],[data-zoomable]'), element;
	for (var i = 0; i < elements.length; i++) {

		element = elements[i];
		var scrollable = element.dataset.scrollable;
		var zoomable = element.dataset.zoomable || '';
		var zoomOptions = zoomable.split('-');
		var minZoom = zoomOptions.length > 1 && parseFloat(zoomOptions[0]);
		var maxZoom = zoomOptions.length > 1 && parseFloat(zoomOptions[1]);

		new EasyScroller(element, {
			scrollingX: scrollable === 'true' || scrollable === 'x',
			scrollingY: scrollable === 'true' || scrollable === 'y',
			zooming: zoomable === 'true' || zoomOptions.length > 1,
			minZoom: minZoom,
			maxZoom: maxZoom
		});

	};

}, false);
;(function () {
	'use strict';

	/**
	 * @preserve FastClick: polyfill to remove click delays on browsers with touch UIs.
	 *
	 * @codingstandard ftlabs-jsv2
	 * @copyright The Financial Times Limited [All Rights Reserved]
	 * @license MIT License (see LICENSE.txt)
	 */

	/*jslint browser:true, node:true*/
	/*global define, Event, Node*/


	/**
	 * Instantiate fast-clicking listeners on the specified layer.
	 *
	 * @constructor
	 * @param {Element} layer The layer to listen on
	 * @param {Object} [options={}] The options to override the defaults
	 */
	function FastClick(layer, options) {
		var oldOnClick;

		options = options || {};

		/**
		 * Whether a click is currently being tracked.
		 *
		 * @type boolean
		 */
		this.trackingClick = false;


		/**
		 * Timestamp for when click tracking started.
		 *
		 * @type number
		 */
		this.trackingClickStart = 0;


		/**
		 * The element being tracked for a click.
		 *
		 * @type EventTarget
		 */
		this.targetElement = null;


		/**
		 * X-coordinate of touch start event.
		 *
		 * @type number
		 */
		this.touchStartX = 0;


		/**
		 * Y-coordinate of touch start event.
		 *
		 * @type number
		 */
		this.touchStartY = 0;


		/**
		 * ID of the last touch, retrieved from Touch.identifier.
		 *
		 * @type number
		 */
		this.lastTouchIdentifier = 0;


		/**
		 * Touchmove boundary, beyond which a click will be cancelled.
		 *
		 * @type number
		 */
		this.touchBoundary = options.touchBoundary || 10;


		/**
		 * The FastClick layer.
		 *
		 * @type Element
		 */
		this.layer = layer;

		/**
		 * The minimum time between tap(touchstart and touchend) events
		 *
		 * @type number
		 */
		this.tapDelay = options.tapDelay || 200;

		/**
		 * The maximum time for a tap
		 *
		 * @type number
		 */
		this.tapTimeout = options.tapTimeout || 700;

		if (FastClick.notNeeded(layer)) {
			return;
		}

		// Some old versions of Android don't have Function.prototype.bind
		function bind(method, context) {
			return function() { return method.apply(context, arguments); };
		}


		var methods = ['onMouse', 'onClick', 'onTouchStart', 'onTouchMove', 'onTouchEnd', 'onTouchCancel'];
		var context = this;
		for (var i = 0, l = methods.length; i < l; i++) {
			context[methods[i]] = bind(context[methods[i]], context);
		}

		// Set up event handlers as required
		if (deviceIsAndroid) {
			layer.addEventListener('mouseover', this.onMouse, true);
			layer.addEventListener('mousedown', this.onMouse, true);
			layer.addEventListener('mouseup', this.onMouse, true);
		}

		layer.addEventListener('click', this.onClick, true);
		layer.addEventListener('touchstart', this.onTouchStart, false);
		layer.addEventListener('touchmove', this.onTouchMove, false);
		layer.addEventListener('touchend', this.onTouchEnd, false);
		layer.addEventListener('touchcancel', this.onTouchCancel, false);

		// Hack is required for browsers that don't support Event#stopImmediatePropagation (e.g. Android 2)
		// which is how FastClick normally stops click events bubbling to callbacks registered on the FastClick
		// layer when they are cancelled.
		if (!Event.prototype.stopImmediatePropagation) {
			layer.removeEventListener = function(type, callback, capture) {
				var rmv = Node.prototype.removeEventListener;
				if (type === 'click') {
					rmv.call(layer, type, callback.hijacked || callback, capture);
				} else {
					rmv.call(layer, type, callback, capture);
				}
			};

			layer.addEventListener = function(type, callback, capture) {
				var adv = Node.prototype.addEventListener;
				if (type === 'click') {
					adv.call(layer, type, callback.hijacked || (callback.hijacked = function(event) {
						if (!event.propagationStopped) {
							callback(event);
						}
					}), capture);
				} else {
					adv.call(layer, type, callback, capture);
				}
			};
		}

		// If a handler is already declared in the element's onclick attribute, it will be fired before
		// FastClick's onClick handler. Fix this by pulling out the user-defined handler function and
		// adding it as listener.
		if (typeof layer.onclick === 'function') {

			// Android browser on at least 3.2 requires a new reference to the function in layer.onclick
			// - the old one won't work if passed to addEventListener directly.
			oldOnClick = layer.onclick;
			layer.addEventListener('click', function(event) {
				oldOnClick(event);
			}, false);
			layer.onclick = null;
		}
	}

	/**
	 * Windows Phone 8.1 fakes user agent string to look like Android and iPhone.
	 *
	 * @type boolean
	 */
	var deviceIsWindowsPhone = navigator.userAgent.indexOf("Windows Phone") >= 0;

	/**
	 * Android requires exceptions.
	 *
	 * @type boolean
	 */
	var deviceIsAndroid = navigator.userAgent.indexOf('Android') > 0 && !deviceIsWindowsPhone;


	/**
	 * iOS requires exceptions.
	 *
	 * @type boolean
	 */
	var deviceIsIOS = /iP(ad|hone|od)/.test(navigator.userAgent) && !deviceIsWindowsPhone;


	/**
	 * iOS 4 requires an exception for select elements.
	 *
	 * @type boolean
	 */
	var deviceIsIOS4 = deviceIsIOS && (/OS 4_\d(_\d)?/).test(navigator.userAgent);


	/**
	 * iOS 6.0-7.* requires the target element to be manually derived
	 *
	 * @type boolean
	 */
	var deviceIsIOSWithBadTarget = deviceIsIOS && (/OS [6-7]_\d/).test(navigator.userAgent);

	/**
	 * BlackBerry requires exceptions.
	 *
	 * @type boolean
	 */
	var deviceIsBlackBerry10 = navigator.userAgent.indexOf('BB10') > 0;

	/**
	 * Determine whether a given element requires a native click.
	 *
	 * @param {EventTarget|Element} target Target DOM element
	 * @returns {boolean} Returns true if the element needs a native click
	 */
	FastClick.prototype.needsClick = function(target) {
		switch (target.nodeName.toLowerCase()) {

			// Don't send a synthetic click to disabled inputs (issue #62)
			case 'button':
			case 'select':
			case 'textarea':
				if (target.disabled) {
					return true;
				}

				break;
			case 'input':

				// File inputs need real clicks on iOS 6 due to a browser bug (issue #68)
				if ((deviceIsIOS && target.type === 'file') || target.disabled) {
					return true;
				}

				break;
			case 'label':
			case 'iframe': // iOS8 homescreen apps can prevent events bubbling into frames
			case 'video':
				return true;
		}

		return (/\bneedsclick\b/).test(target.className);
	};


	/**
	 * Determine whether a given element requires a call to focus to simulate click into element.
	 *
	 * @param {EventTarget|Element} target Target DOM element
	 * @returns {boolean} Returns true if the element requires a call to focus to simulate native click.
	 */
	FastClick.prototype.needsFocus = function(target) {
		switch (target.nodeName.toLowerCase()) {
			case 'textarea':
				return true;
			case 'select':
				return !deviceIsAndroid;
			case 'input':
				switch (target.type) {
					case 'button':
					case 'checkbox':
					case 'file':
					case 'image':
					case 'radio':
					case 'submit':
						return false;
				}

				// No point in attempting to focus disabled inputs
				return !target.disabled && !target.readOnly;
			default:
				return (/\bneedsfocus\b/).test(target.className);
		}
	};


	/**
	 * Send a click event to the specified element.
	 *
	 * @param {EventTarget|Element} targetElement
	 * @param {Event} event
	 */
	FastClick.prototype.sendClick = function(targetElement, event) {
		var clickEvent, touch;

		// On some Android devices activeElement needs to be blurred otherwise the synthetic click will have no effect (#24)
		if (document.activeElement && document.activeElement !== targetElement) {
			document.activeElement.blur();
		}

		touch = event.changedTouches[0];

		// Synthesise a click event, with an extra attribute so it can be tracked
		clickEvent = document.createEvent('MouseEvents');
		clickEvent.initMouseEvent(this.determineEventType(targetElement), true, true, window, 1, touch.screenX, touch.screenY, touch.clientX, touch.clientY, false, false, false, false, 0, null);
		clickEvent.forwardedTouchEvent = true;
		targetElement.dispatchEvent(clickEvent);
	};

	FastClick.prototype.determineEventType = function(targetElement) {

		//Issue #159: Android Chrome Select Box does not open with a synthetic click event
		if (deviceIsAndroid && targetElement.tagName.toLowerCase() === 'select') {
			return 'mousedown';
		}

		return 'click';
	};


	/**
	 * @param {EventTarget|Element} targetElement
	 */
	FastClick.prototype.focus = function(targetElement) {
		var length;

		// Issue #160: on iOS 7, some input elements (e.g. date datetime month) throw a vague TypeError on setSelectionRange. These elements don't have an integer value for the selectionStart and selectionEnd properties, but unfortunately that can't be used for detection because accessing the properties also throws a TypeError. Just check the type instead. Filed as Apple bug #15122724.
		if (deviceIsIOS && targetElement.setSelectionRange && targetElement.type.indexOf('date') !== 0 && targetElement.type !== 'time' && targetElement.type !== 'month') {
			length = targetElement.value.length;
			targetElement.setSelectionRange(length, length);
		} else {
			targetElement.focus();
		}
	};


	/**
	 * Check whether the given target element is a child of a scrollable layer and if so, set a flag on it.
	 *
	 * @param {EventTarget|Element} targetElement
	 */
	FastClick.prototype.updateScrollParent = function(targetElement) {
		var scrollParent, parentElement;

		scrollParent = targetElement.fastClickScrollParent;

		// Attempt to discover whether the target element is contained within a scrollable layer. Re-check if the
		// target element was moved to another parent.
		if (!scrollParent || !scrollParent.contains(targetElement)) {
			parentElement = targetElement;
			do {
				if (parentElement.scrollHeight > parentElement.offsetHeight) {
					scrollParent = parentElement;
					targetElement.fastClickScrollParent = parentElement;
					break;
				}

				parentElement = parentElement.parentElement;
			} while (parentElement);
		}

		// Always update the scroll top tracker if possible.
		if (scrollParent) {
			scrollParent.fastClickLastScrollTop = scrollParent.scrollTop;
		}
	};


	/**
	 * @param {EventTarget} targetElement
	 * @returns {Element|EventTarget}
	 */
	FastClick.prototype.getTargetElementFromEventTarget = function(eventTarget) {

		// On some older browsers (notably Safari on iOS 4.1 - see issue #56) the event target may be a text node.
		if (eventTarget.nodeType === Node.TEXT_NODE) {
			return eventTarget.parentNode;
		}

		return eventTarget;
	};


	/**
	 * On touch start, record the position and scroll offset.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.onTouchStart = function(event) {
		var targetElement, touch, selection;

		// Ignore multiple touches, otherwise pinch-to-zoom is prevented if both fingers are on the FastClick element (issue #111).
		if (event.targetTouches.length > 1) {
			return true;
		}

		targetElement = this.getTargetElementFromEventTarget(event.target);
		touch = event.targetTouches[0];

		if (deviceIsIOS) {

			// Only trusted events will deselect text on iOS (issue #49)
			selection = window.getSelection();
			if (selection.rangeCount && !selection.isCollapsed) {
				return true;
			}

			if (!deviceIsIOS4) {

				// Weird things happen on iOS when an alert or confirm dialog is opened from a click event callback (issue #23):
				// when the user next taps anywhere else on the page, new touchstart and touchend events are dispatched
				// with the same identifier as the touch event that previously triggered the click that triggered the alert.
				// Sadly, there is an issue on iOS 4 that causes some normal touch events to have the same identifier as an
				// immediately preceeding touch event (issue #52), so this fix is unavailable on that platform.
				// Issue 120: touch.identifier is 0 when Chrome dev tools 'Emulate touch events' is set with an iOS device UA string,
				// which causes all touch events to be ignored. As this block only applies to iOS, and iOS identifiers are always long,
				// random integers, it's safe to to continue if the identifier is 0 here.
				if (touch.identifier && touch.identifier === this.lastTouchIdentifier) {
					event.preventDefault();
					return false;
				}

				this.lastTouchIdentifier = touch.identifier;

				// If the target element is a child of a scrollable layer (using -webkit-overflow-scrolling: touch) and:
				// 1) the user does a fling scroll on the scrollable layer
				// 2) the user stops the fling scroll with another tap
				// then the event.target of the last 'touchend' event will be the element that was under the user's finger
				// when the fling scroll was started, causing FastClick to send a click event to that layer - unless a check
				// is made to ensure that a parent layer was not scrolled before sending a synthetic click (issue #42).
				this.updateScrollParent(targetElement);
			}
		}

		this.trackingClick = true;
		this.trackingClickStart = event.timeStamp;
		this.targetElement = targetElement;

		this.touchStartX = touch.pageX;
		this.touchStartY = touch.pageY;

		// Prevent phantom clicks on fast double-tap (issue #36)
		if ((event.timeStamp - this.lastClickTime) < this.tapDelay) {
			event.preventDefault();
		}

		return true;
	};


	/**
	 * Based on a touchmove event object, check whether the touch has moved past a boundary since it started.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.touchHasMoved = function(event) {
		var touch = event.changedTouches[0], boundary = this.touchBoundary;

		if (Math.abs(touch.pageX - this.touchStartX) > boundary || Math.abs(touch.pageY - this.touchStartY) > boundary) {
			return true;
		}

		return false;
	};


	/**
	 * Update the last position.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.onTouchMove = function(event) {
		if (!this.trackingClick) {
			return true;
		}

		// If the touch has moved, cancel the click tracking
		if (this.targetElement !== this.getTargetElementFromEventTarget(event.target) || this.touchHasMoved(event)) {
			this.trackingClick = false;
			this.targetElement = null;
		}

		return true;
	};


	/**
	 * Attempt to find the labelled control for the given label element.
	 *
	 * @param {EventTarget|HTMLLabelElement} labelElement
	 * @returns {Element|null}
	 */
	FastClick.prototype.findControl = function(labelElement) {

		// Fast path for newer browsers supporting the HTML5 control attribute
		if (labelElement.control !== undefined) {
			return labelElement.control;
		}

		// All browsers under test that support touch events also support the HTML5 htmlFor attribute
		if (labelElement.htmlFor) {
			return document.getElementById(labelElement.htmlFor);
		}

		// If no for attribute exists, attempt to retrieve the first labellable descendant element
		// the list of which is defined here: http://www.w3.org/TR/html5/forms.html#category-label
		return labelElement.querySelector('button, input:not([type=hidden]), keygen, meter, output, progress, select, textarea');
	};


	/**
	 * On touch end, determine whether to send a click event at once.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.onTouchEnd = function(event) {
		var forElement, trackingClickStart, targetTagName, scrollParent, touch, targetElement = this.targetElement;

		if (!this.trackingClick) {
			return true;
		}

		// Prevent phantom clicks on fast double-tap (issue #36)
		if ((event.timeStamp - this.lastClickTime) < this.tapDelay) {
			this.cancelNextClick = true;
			return true;
		}

		if ((event.timeStamp - this.trackingClickStart) > this.tapTimeout) {
			return true;
		}

		// Reset to prevent wrong click cancel on input (issue #156).
		this.cancelNextClick = false;

		this.lastClickTime = event.timeStamp;

		trackingClickStart = this.trackingClickStart;
		this.trackingClick = false;
		this.trackingClickStart = 0;

		// On some iOS devices, the targetElement supplied with the event is invalid if the layer
		// is performing a transition or scroll, and has to be re-detected manually. Note that
		// for this to function correctly, it must be called *after* the event target is checked!
		// See issue #57; also filed as rdar://13048589 .
		if (deviceIsIOSWithBadTarget) {
			touch = event.changedTouches[0];

			// In certain cases arguments of elementFromPoint can be negative, so prevent setting targetElement to null
			targetElement = document.elementFromPoint(touch.pageX - window.pageXOffset, touch.pageY - window.pageYOffset) || targetElement;
			targetElement.fastClickScrollParent = this.targetElement.fastClickScrollParent;
		}

		targetTagName = targetElement.tagName.toLowerCase();
		if (targetTagName === 'label') {
			forElement = this.findControl(targetElement);
			if (forElement) {
				this.focus(targetElement);
				if (deviceIsAndroid) {
					return false;
				}

				targetElement = forElement;
			}
		} else if (this.needsFocus(targetElement)) {

			// Case 1: If the touch started a while ago (best guess is 100ms based on tests for issue #36) then focus will be triggered anyway. Return early and unset the target element reference so that the subsequent click will be allowed through.
			// Case 2: Without this exception for input elements tapped when the document is contained in an iframe, then any inputted text won't be visible even though the value attribute is updated as the user types (issue #37).
			if ((event.timeStamp - trackingClickStart) > 100 || (deviceIsIOS && window.top !== window && targetTagName === 'input')) {
				this.targetElement = null;
				return false;
			}

			this.focus(targetElement);
			this.sendClick(targetElement, event);

			// Select elements need the event to go through on iOS 4, otherwise the selector menu won't open.
			// Also this breaks opening selects when VoiceOver is active on iOS6, iOS7 (and possibly others)
			if (!deviceIsIOS || targetTagName !== 'select') {
				this.targetElement = null;
				event.preventDefault();
			}

			return false;
		}

		if (deviceIsIOS && !deviceIsIOS4) {

			// Don't send a synthetic click event if the target element is contained within a parent layer that was scrolled
			// and this tap is being used to stop the scrolling (usually initiated by a fling - issue #42).
			scrollParent = targetElement.fastClickScrollParent;
			if (scrollParent && scrollParent.fastClickLastScrollTop !== scrollParent.scrollTop) {
				return true;
			}
		}

		// Prevent the actual click from going though - unless the target node is marked as requiring
		// real clicks or if it is in the whitelist in which case only non-programmatic clicks are permitted.
		if (!this.needsClick(targetElement)) {
			event.preventDefault();
			this.sendClick(targetElement, event);
		}

		return false;
	};


	/**
	 * On touch cancel, stop tracking the click.
	 *
	 * @returns {void}
	 */
	FastClick.prototype.onTouchCancel = function() {
		this.trackingClick = false;
		this.targetElement = null;
	};


	/**
	 * Determine mouse events which should be permitted.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.onMouse = function(event) {

		// If a target element was never set (because a touch event was never fired) allow the event
		if (!this.targetElement) {
			return true;
		}

		if (event.forwardedTouchEvent) {
			return true;
		}

		// Programmatically generated events targeting a specific element should be permitted
		if (!event.cancelable) {
			return true;
		}

		// Derive and check the target element to see whether the mouse event needs to be permitted;
		// unless explicitly enabled, prevent non-touch click events from triggering actions,
		// to prevent ghost/doubleclicks.
		if (!this.needsClick(this.targetElement) || this.cancelNextClick) {

			// Prevent any user-added listeners declared on FastClick element from being fired.
			if (event.stopImmediatePropagation) {
				event.stopImmediatePropagation();
			} else {

				// Part of the hack for browsers that don't support Event#stopImmediatePropagation (e.g. Android 2)
				event.propagationStopped = true;
			}

			// Cancel the event
			event.stopPropagation();
			event.preventDefault();

			return false;
		}

		// If the mouse event is permitted, return true for the action to go through.
		return true;
	};


	/**
	 * On actual clicks, determine whether this is a touch-generated click, a click action occurring
	 * naturally after a delay after a touch (which needs to be cancelled to avoid duplication), or
	 * an actual click which should be permitted.
	 *
	 * @param {Event} event
	 * @returns {boolean}
	 */
	FastClick.prototype.onClick = function(event) {
		var permitted;

		// It's possible for another FastClick-like library delivered with third-party code to fire a click event before FastClick does (issue #44). In that case, set the click-tracking flag back to false and return early. This will cause onTouchEnd to return early.
		if (this.trackingClick) {
			this.targetElement = null;
			this.trackingClick = false;
			return true;
		}

		// Very odd behaviour on iOS (issue #18): if a submit element is present inside a form and the user hits enter in the iOS simulator or clicks the Go button on the pop-up OS keyboard the a kind of 'fake' click event will be triggered with the submit-type input element as the target.
		if (event.target.type === 'submit' && event.detail === 0) {
			return true;
		}

		permitted = this.onMouse(event);

		// Only unset targetElement if the click is not permitted. This will ensure that the check for !targetElement in onMouse fails and the browser's click doesn't go through.
		if (!permitted) {
			this.targetElement = null;
		}

		// If clicks are permitted, return true for the action to go through.
		return permitted;
	};


	/**
	 * Remove all FastClick's event listeners.
	 *
	 * @returns {void}
	 */
	FastClick.prototype.destroy = function() {
		var layer = this.layer;

		if (deviceIsAndroid) {
			layer.removeEventListener('mouseover', this.onMouse, true);
			layer.removeEventListener('mousedown', this.onMouse, true);
			layer.removeEventListener('mouseup', this.onMouse, true);
		}

		layer.removeEventListener('click', this.onClick, true);
		layer.removeEventListener('touchstart', this.onTouchStart, false);
		layer.removeEventListener('touchmove', this.onTouchMove, false);
		layer.removeEventListener('touchend', this.onTouchEnd, false);
		layer.removeEventListener('touchcancel', this.onTouchCancel, false);
	};


	/**
	 * Check whether FastClick is needed.
	 *
	 * @param {Element} layer The layer to listen on
	 */
	FastClick.notNeeded = function(layer) {
		var metaViewport;
		var chromeVersion;
		var blackberryVersion;
		var firefoxVersion;

		// Devices that don't support touch don't need FastClick
		if (typeof window.ontouchstart === 'undefined') {
			return true;
		}

		// Chrome version - zero for other browsers
		chromeVersion = +(/Chrome\/([0-9]+)/.exec(navigator.userAgent) || [,0])[1];

		if (chromeVersion) {

			if (deviceIsAndroid) {
				metaViewport = document.querySelector('meta[name=viewport]');

				if (metaViewport) {
					// Chrome on Android with user-scalable="no" doesn't need FastClick (issue #89)
					if (metaViewport.content.indexOf('user-scalable=no') !== -1) {
						return true;
					}
					// Chrome 32 and above with width=device-width or less don't need FastClick
					if (chromeVersion > 31 && document.documentElement.scrollWidth <= window.outerWidth) {
						return true;
					}
				}

				// Chrome desktop doesn't need FastClick (issue #15)
			} else {
				return true;
			}
		}

		if (deviceIsBlackBerry10) {
			blackberryVersion = navigator.userAgent.match(/Version\/([0-9]*)\.([0-9]*)/);

			// BlackBerry 10.3+ does not require Fastclick library.
			// https://github.com/ftlabs/fastclick/issues/251
			if (blackberryVersion[1] >= 10 && blackberryVersion[2] >= 3) {
				metaViewport = document.querySelector('meta[name=viewport]');

				if (metaViewport) {
					// user-scalable=no eliminates click delay.
					if (metaViewport.content.indexOf('user-scalable=no') !== -1) {
						return true;
					}
					// width=device-width (or less than device-width) eliminates click delay.
					if (document.documentElement.scrollWidth <= window.outerWidth) {
						return true;
					}
				}
			}
		}

		// IE10 with -ms-touch-action: none or manipulation, which disables double-tap-to-zoom (issue #97)
		if (layer.style.msTouchAction === 'none' || layer.style.touchAction === 'manipulation') {
			return true;
		}

		// Firefox version - zero for other browsers
		firefoxVersion = +(/Firefox\/([0-9]+)/.exec(navigator.userAgent) || [,0])[1];

		if (firefoxVersion >= 27) {
			// Firefox 27+ does not have tap delay if the content is not zoomable - https://bugzilla.mozilla.org/show_bug.cgi?id=922896

			metaViewport = document.querySelector('meta[name=viewport]');
			if (metaViewport && (metaViewport.content.indexOf('user-scalable=no') !== -1 || document.documentElement.scrollWidth <= window.outerWidth)) {
				return true;
			}
		}

		// IE11: prefixed -ms-touch-action is no longer supported and it's recomended to use non-prefixed version
		// http://msdn.microsoft.com/en-us/library/windows/apps/Hh767313.aspx
		if (layer.style.touchAction === 'none' || layer.style.touchAction === 'manipulation') {
			return true;
		}

		return false;
	};


	/**
	 * Factory method for creating a FastClick object
	 *
	 * @param {Element} layer The layer to listen on
	 * @param {Object} [options={}] The options to override the defaults
	 */
	FastClick.attach = function(layer, options) {
		return new FastClick(layer, options);
	};


	if (typeof define === 'function' && typeof define.amd === 'object' && define.amd) {

		// AMD. Register as an anonymous module.
		define(function() {
			return FastClick;
		});
	} else if (typeof module !== 'undefined' && module.exports) {
		module.exports = FastClick.attach;
		module.exports.FastClick = FastClick;
	} else {
		window.FastClick = FastClick;
	}
}());
/*! Hammer.JS - v2.0.4 - 2014-09-28
 * http://hammerjs.github.io/
 *
 * Copyright (c) 2014 Jorik Tangelder;
 * Licensed under the MIT license */
(function(window, document, exportName, undefined) {
	'use strict';

	var VENDOR_PREFIXES = ['', 'webkit', 'moz', 'MS', 'ms', 'o'];
	var TEST_ELEMENT = document.createElement('div');

	var TYPE_FUNCTION = 'function';

	var round = Math.round;
	var abs = Math.abs;
	var now = Date.now;

	/**
	 * set a timeout with a given scope
	 * @param {Function} fn
	 * @param {Number} timeout
	 * @param {Object} context
	 * @returns {number}
	 */
	function setTimeoutContext(fn, timeout, context) {
		return setTimeout(bindFn(fn, context), timeout);
	}

	/**
	 * if the argument is an array, we want to execute the fn on each entry
	 * if it aint an array we don't want to do a thing.
	 * this is used by all the methods that accept a single and array argument.
	 * @param {*|Array} arg
	 * @param {String} fn
	 * @param {Object} [context]
	 * @returns {Boolean}
	 */
	function invokeArrayArg(arg, fn, context) {
		if (Array.isArray(arg)) {
			each(arg, context[fn], context);
			return true;
		}
		return false;
	}

	/**
	 * walk objects and arrays
	 * @param {Object} obj
	 * @param {Function} iterator
	 * @param {Object} context
	 */
	function each(obj, iterator, context) {
		var i;

		if (!obj) {
			return;
		}

		if (obj.forEach) {
			obj.forEach(iterator, context);
		} else if (obj.length !== undefined) {
			i = 0;
			while (i < obj.length) {
				iterator.call(context, obj[i], i, obj);
				i++;
			}
		} else {
			for (i in obj) {
				obj.hasOwnProperty(i) && iterator.call(context, obj[i], i, obj);
			}
		}
	}

	/**
	 * extend object.
	 * means that properties in dest will be overwritten by the ones in src.
	 * @param {Object} dest
	 * @param {Object} src
	 * @param {Boolean} [merge]
	 * @returns {Object} dest
	 */
	function extend(dest, src, merge) {
		var keys = Object.keys(src);
		var i = 0;
		while (i < keys.length) {
			if (!merge || (merge && dest[keys[i]] === undefined)) {
				dest[keys[i]] = src[keys[i]];
			}
			i++;
		}
		return dest;
	}

	/**
	 * merge the values from src in the dest.
	 * means that properties that exist in dest will not be overwritten by src
	 * @param {Object} dest
	 * @param {Object} src
	 * @returns {Object} dest
	 */
	function merge(dest, src) {
		return extend(dest, src, true);
	}

	/**
	 * simple class inheritance
	 * @param {Function} child
	 * @param {Function} base
	 * @param {Object} [properties]
	 */
	function inherit(child, base, properties) {
		var baseP = base.prototype,
			childP;

		childP = child.prototype = Object.create(baseP);
		childP.constructor = child;
		childP._super = baseP;

		if (properties) {
			extend(childP, properties);
		}
	}

	/**
	 * simple function bind
	 * @param {Function} fn
	 * @param {Object} context
	 * @returns {Function}
	 */
	function bindFn(fn, context) {
		return function boundFn() {
			return fn.apply(context, arguments);
		};
	}

	/**
	 * let a boolean value also be a function that must return a boolean
	 * this first item in args will be used as the context
	 * @param {Boolean|Function} val
	 * @param {Array} [args]
	 * @returns {Boolean}
	 */
	function boolOrFn(val, args) {
		if (typeof val == TYPE_FUNCTION) {
			return val.apply(args ? args[0] || undefined : undefined, args);
		}
		return val;
	}

	/**
	 * use the val2 when val1 is undefined
	 * @param {*} val1
	 * @param {*} val2
	 * @returns {*}
	 */
	function ifUndefined(val1, val2) {
		return (val1 === undefined) ? val2 : val1;
	}

	/**
	 * addEventListener with multiple events at once
	 * @param {EventTarget} target
	 * @param {String} types
	 * @param {Function} handler
	 */
	function addEventListeners(target, types, handler) {
		each(splitStr(types), function(type) {
			target.addEventListener(type, handler, false);
		});
	}

	/**
	 * removeEventListener with multiple events at once
	 * @param {EventTarget} target
	 * @param {String} types
	 * @param {Function} handler
	 */
	function removeEventListeners(target, types, handler) {
		each(splitStr(types), function(type) {
			target.removeEventListener(type, handler, false);
		});
	}

	/**
	 * find if a node is in the given parent
	 * @method hasParent
	 * @param {HTMLElement} node
	 * @param {HTMLElement} parent
	 * @return {Boolean} found
	 */
	function hasParent(node, parent) {
		while (node) {
			if (node == parent) {
				return true;
			}
			node = node.parentNode;
		}
		return false;
	}

	/**
	 * small indexOf wrapper
	 * @param {String} str
	 * @param {String} find
	 * @returns {Boolean} found
	 */
	function inStr(str, find) {
		return str.indexOf(find) > -1;
	}

	/**
	 * split string on whitespace
	 * @param {String} str
	 * @returns {Array} words
	 */
	function splitStr(str) {
		return str.trim().split(/\s+/g);
	}

	/**
	 * find if a array contains the object using indexOf or a simple polyFill
	 * @param {Array} src
	 * @param {String} find
	 * @param {String} [findByKey]
	 * @return {Boolean|Number} false when not found, or the index
	 */
	function inArray(src, find, findByKey) {
		if (src.indexOf && !findByKey) {
			return src.indexOf(find);
		} else {
			var i = 0;
			while (i < src.length) {
				if ((findByKey && src[i][findByKey] == find) || (!findByKey && src[i] === find)) {
					return i;
				}
				i++;
			}
			return -1;
		}
	}

	/**
	 * convert array-like objects to real arrays
	 * @param {Object} obj
	 * @returns {Array}
	 */
	function toArray(obj) {
		return Array.prototype.slice.call(obj, 0);
	}

	/**
	 * unique array with objects based on a key (like 'id') or just by the array's value
	 * @param {Array} src [{id:1},{id:2},{id:1}]
	 * @param {String} [key]
	 * @param {Boolean} [sort=False]
	 * @returns {Array} [{id:1},{id:2}]
	 */
	function uniqueArray(src, key, sort) {
		var results = [];
		var values = [];
		var i = 0;

		while (i < src.length) {
			var val = key ? src[i][key] : src[i];
			if (inArray(values, val) < 0) {
				results.push(src[i]);
			}
			values[i] = val;
			i++;
		}

		if (sort) {
			if (!key) {
				results = results.sort();
			} else {
				results = results.sort(function sortUniqueArray(a, b) {
					return a[key] > b[key];
				});
			}
		}

		return results;
	}

	/**
	 * get the prefixed property
	 * @param {Object} obj
	 * @param {String} property
	 * @returns {String|Undefined} prefixed
	 */
	function prefixed(obj, property) {
		var prefix, prop;
		var camelProp = property[0].toUpperCase() + property.slice(1);

		var i = 0;
		while (i < VENDOR_PREFIXES.length) {
			prefix = VENDOR_PREFIXES[i];
			prop = (prefix) ? prefix + camelProp : property;

			if (prop in obj) {
				return prop;
			}
			i++;
		}
		return undefined;
	}

	/**
	 * get a unique id
	 * @returns {number} uniqueId
	 */
	var _uniqueId = 1;
	function uniqueId() {
		return _uniqueId++;
	}

	/**
	 * get the window object of an element
	 * @param {HTMLElement} element
	 * @returns {DocumentView|Window}
	 */
	function getWindowForElement(element) {
		var doc = element.ownerDocument;
		return (doc.defaultView || doc.parentWindow);
	}

	var MOBILE_REGEX = /mobile|tablet|ip(ad|hone|od)|android/i;

	var SUPPORT_TOUCH = ('ontouchstart' in window);
	var SUPPORT_POINTER_EVENTS = prefixed(window, 'PointerEvent') !== undefined;
	var SUPPORT_ONLY_TOUCH = SUPPORT_TOUCH && MOBILE_REGEX.test(navigator.userAgent);

	var INPUT_TYPE_TOUCH = 'touch';
	var INPUT_TYPE_PEN = 'pen';
	var INPUT_TYPE_MOUSE = 'mouse';
	var INPUT_TYPE_KINECT = 'kinect';

	var COMPUTE_INTERVAL = 25;

	var INPUT_START = 1;
	var INPUT_MOVE = 2;
	var INPUT_END = 4;
	var INPUT_CANCEL = 8;

	var DIRECTION_NONE = 1;
	var DIRECTION_LEFT = 2;
	var DIRECTION_RIGHT = 4;
	var DIRECTION_UP = 8;
	var DIRECTION_DOWN = 16;

	var DIRECTION_HORIZONTAL = DIRECTION_LEFT | DIRECTION_RIGHT;
	var DIRECTION_VERTICAL = DIRECTION_UP | DIRECTION_DOWN;
	var DIRECTION_ALL = DIRECTION_HORIZONTAL | DIRECTION_VERTICAL;

	var PROPS_XY = ['x', 'y'];
	var PROPS_CLIENT_XY = ['clientX', 'clientY'];

	/**
	 * create new input type manager
	 * @param {Manager} manager
	 * @param {Function} callback
	 * @returns {Input}
	 * @constructor
	 */
	function Input(manager, callback) {
		var self = this;
		this.manager = manager;
		this.callback = callback;
		this.element = manager.element;
		this.target = manager.options.inputTarget;

		// smaller wrapper around the handler, for the scope and the enabled state of the manager,
		// so when disabled the input events are completely bypassed.
		this.domHandler = function(ev) {
			if (boolOrFn(manager.options.enable, [manager])) {
				self.handler(ev);
			}
		};

		this.init();

	}

	Input.prototype = {
		/**
		 * should handle the inputEvent data and trigger the callback
		 * @virtual
		 */
		handler: function() { },

		/**
		 * bind the events
		 */
		init: function() {
			this.evEl && addEventListeners(this.element, this.evEl, this.domHandler);
			this.evTarget && addEventListeners(this.target, this.evTarget, this.domHandler);
			this.evWin && addEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
		},

		/**
		 * unbind the events
		 */
		destroy: function() {
			this.evEl && removeEventListeners(this.element, this.evEl, this.domHandler);
			this.evTarget && removeEventListeners(this.target, this.evTarget, this.domHandler);
			this.evWin && removeEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
		}
	};

	/**
	 * create new input type manager
	 * called by the Manager constructor
	 * @param {Hammer} manager
	 * @returns {Input}
	 */
	function createInputInstance(manager) {
		var Type;
		var inputClass = manager.options.inputClass;

		if (inputClass) {
			Type = inputClass;
		} else if (SUPPORT_POINTER_EVENTS) {
			Type = PointerEventInput;
		} else if (SUPPORT_ONLY_TOUCH) {
			Type = TouchInput;
		} else if (!SUPPORT_TOUCH) {
			Type = MouseInput;
		} else {
			Type = TouchMouseInput;
		}
		return new (Type)(manager, inputHandler);
	}

	/**
	 * handle input events
	 * @param {Manager} manager
	 * @param {String} eventType
	 * @param {Object} input
	 */
	function inputHandler(manager, eventType, input) {
		var pointersLen = input.pointers.length;
		var changedPointersLen = input.changedPointers.length;
		var isFirst = (eventType & INPUT_START && (pointersLen - changedPointersLen === 0));
		var isFinal = (eventType & (INPUT_END | INPUT_CANCEL) && (pointersLen - changedPointersLen === 0));

		input.isFirst = !!isFirst;
		input.isFinal = !!isFinal;

		if (isFirst) {
			manager.session = {};
		}

		// source event is the normalized value of the domEvents
		// like 'touchstart, mouseup, pointerdown'
		input.eventType = eventType;

		// compute scale, rotation etc
		computeInputData(manager, input);

		// emit secret event
		manager.emit('hammer.input', input);

		manager.recognize(input);
		manager.session.prevInput = input;
	}

	/**
	 * extend the data with some usable properties like scale, rotate, velocity etc
	 * @param {Object} manager
	 * @param {Object} input
	 */
	function computeInputData(manager, input) {
		var session = manager.session;
		var pointers = input.pointers;
		var pointersLength = pointers.length;

		// store the first input to calculate the distance and direction
		if (!session.firstInput) {
			session.firstInput = simpleCloneInputData(input);
		}

		// to compute scale and rotation we need to store the multiple touches
		if (pointersLength > 1 && !session.firstMultiple) {
			session.firstMultiple = simpleCloneInputData(input);
		} else if (pointersLength === 1) {
			session.firstMultiple = false;
		}

		var firstInput = session.firstInput;
		var firstMultiple = session.firstMultiple;
		var offsetCenter = firstMultiple ? firstMultiple.center : firstInput.center;

		var center = input.center = getCenter(pointers);
		input.timeStamp = now();
		input.deltaTime = input.timeStamp - firstInput.timeStamp;

		input.angle = getAngle(offsetCenter, center);
		input.distance = getDistance(offsetCenter, center);

		computeDeltaXY(session, input);
		input.offsetDirection = getDirection(input.deltaX, input.deltaY);

		input.scale = firstMultiple ? getScale(firstMultiple.pointers, pointers) : 1;
		input.rotation = firstMultiple ? getRotation(firstMultiple.pointers, pointers) : 0;

		computeIntervalInputData(session, input);

		// find the correct target
		var target = manager.element;
		if (hasParent(input.srcEvent.target, target)) {
			target = input.srcEvent.target;
		}
		input.target = target;
	}

	function computeDeltaXY(session, input) {
		var center = input.center;
		var offset = session.offsetDelta || {};
		var prevDelta = session.prevDelta || {};
		var prevInput = session.prevInput || {};

		if (input.eventType === INPUT_START || prevInput.eventType === INPUT_END) {
			prevDelta = session.prevDelta = {
				x: prevInput.deltaX || 0,
				y: prevInput.deltaY || 0
			};

			offset = session.offsetDelta = {
				x: center.x,
				y: center.y
			};
		}

		input.deltaX = prevDelta.x + (center.x - offset.x);
		input.deltaY = prevDelta.y + (center.y - offset.y);
	}

	/**
	 * velocity is calculated every x ms
	 * @param {Object} session
	 * @param {Object} input
	 */
	function computeIntervalInputData(session, input) {
		var last = session.lastInterval || input,
			deltaTime = input.timeStamp - last.timeStamp,
			velocity, velocityX, velocityY, direction;

		if (input.eventType != INPUT_CANCEL && (deltaTime > COMPUTE_INTERVAL || last.velocity === undefined)) {
			var deltaX = last.deltaX - input.deltaX;
			var deltaY = last.deltaY - input.deltaY;

			var v = getVelocity(deltaTime, deltaX, deltaY);
			velocityX = v.x;
			velocityY = v.y;
			velocity = (abs(v.x) > abs(v.y)) ? v.x : v.y;
			direction = getDirection(deltaX, deltaY);

			session.lastInterval = input;
		} else {
			// use latest velocity info if it doesn't overtake a minimum period
			velocity = last.velocity;
			velocityX = last.velocityX;
			velocityY = last.velocityY;
			direction = last.direction;
		}

		input.velocity = velocity;
		input.velocityX = velocityX;
		input.velocityY = velocityY;
		input.direction = direction;
	}

	/**
	 * create a simple clone from the input used for storage of firstInput and firstMultiple
	 * @param {Object} input
	 * @returns {Object} clonedInputData
	 */
	function simpleCloneInputData(input) {
		// make a simple copy of the pointers because we will get a reference if we don't
		// we only need clientXY for the calculations
		var pointers = [];
		var i = 0;
		while (i < input.pointers.length) {
			pointers[i] = {
				clientX: round(input.pointers[i].clientX),
				clientY: round(input.pointers[i].clientY)
			};
			i++;
		}

		return {
			timeStamp: now(),
			pointers: pointers,
			center: getCenter(pointers),
			deltaX: input.deltaX,
			deltaY: input.deltaY
		};
	}

	/**
	 * get the center of all the pointers
	 * @param {Array} pointers
	 * @return {Object} center contains `x` and `y` properties
	 */
	function getCenter(pointers) {
		var pointersLength = pointers.length;

		// no need to loop when only one touch
		if (pointersLength === 1) {
			return {
				x: round(pointers[0].clientX),
				y: round(pointers[0].clientY)
			};
		}

		var x = 0, y = 0, i = 0;
		while (i < pointersLength) {
			x += pointers[i].clientX;
			y += pointers[i].clientY;
			i++;
		}

		return {
			x: round(x / pointersLength),
			y: round(y / pointersLength)
		};
	}

	/**
	 * calculate the velocity between two points. unit is in px per ms.
	 * @param {Number} deltaTime
	 * @param {Number} x
	 * @param {Number} y
	 * @return {Object} velocity `x` and `y`
	 */
	function getVelocity(deltaTime, x, y) {
		return {
			x: x / deltaTime || 0,
			y: y / deltaTime || 0
		};
	}

	/**
	 * get the direction between two points
	 * @param {Number} x
	 * @param {Number} y
	 * @return {Number} direction
	 */
	function getDirection(x, y) {
		if (x === y) {
			return DIRECTION_NONE;
		}

		if (abs(x) >= abs(y)) {
			return x > 0 ? DIRECTION_LEFT : DIRECTION_RIGHT;
		}
		return y > 0 ? DIRECTION_UP : DIRECTION_DOWN;
	}

	/**
	 * calculate the absolute distance between two points
	 * @param {Object} p1 {x, y}
	 * @param {Object} p2 {x, y}
	 * @param {Array} [props] containing x and y keys
	 * @return {Number} distance
	 */
	function getDistance(p1, p2, props) {
		if (!props) {
			props = PROPS_XY;
		}
		var x = p2[props[0]] - p1[props[0]],
			y = p2[props[1]] - p1[props[1]];

		return Math.sqrt((x * x) + (y * y));
	}

	/**
	 * calculate the angle between two coordinates
	 * @param {Object} p1
	 * @param {Object} p2
	 * @param {Array} [props] containing x and y keys
	 * @return {Number} angle
	 */
	function getAngle(p1, p2, props) {
		if (!props) {
			props = PROPS_XY;
		}
		var x = p2[props[0]] - p1[props[0]],
			y = p2[props[1]] - p1[props[1]];
		return Math.atan2(y, x) * 180 / Math.PI;
	}

	/**
	 * calculate the rotation degrees between two pointersets
	 * @param {Array} start array of pointers
	 * @param {Array} end array of pointers
	 * @return {Number} rotation
	 */
	function getRotation(start, end) {
		return getAngle(end[1], end[0], PROPS_CLIENT_XY) - getAngle(start[1], start[0], PROPS_CLIENT_XY);
	}

	/**
	 * calculate the scale factor between two pointersets
	 * no scale is 1, and goes down to 0 when pinched together, and bigger when pinched out
	 * @param {Array} start array of pointers
	 * @param {Array} end array of pointers
	 * @return {Number} scale
	 */
	function getScale(start, end) {
		return getDistance(end[0], end[1], PROPS_CLIENT_XY) / getDistance(start[0], start[1], PROPS_CLIENT_XY);
	}

	var MOUSE_INPUT_MAP = {
		mousedown: INPUT_START,
		mousemove: INPUT_MOVE,
		mouseup: INPUT_END
	};

	var MOUSE_ELEMENT_EVENTS = 'mousedown';
	var MOUSE_WINDOW_EVENTS = 'mousemove mouseup';

	/**
	 * Mouse events input
	 * @constructor
	 * @extends Input
	 */
	function MouseInput() {
		this.evEl = MOUSE_ELEMENT_EVENTS;
		this.evWin = MOUSE_WINDOW_EVENTS;

		this.allow = true; // used by Input.TouchMouse to disable mouse events
		this.pressed = false; // mousedown state

		Input.apply(this, arguments);
	}

	inherit(MouseInput, Input, {
		/**
		 * handle mouse events
		 * @param {Object} ev
		 */
		handler: function MEhandler(ev) {
			var eventType = MOUSE_INPUT_MAP[ev.type];

			// on start we want to have the left mouse button down
			if (eventType & INPUT_START && ev.button === 0) {
				this.pressed = true;
			}

			if (eventType & INPUT_MOVE && ev.which !== 1) {
				eventType = INPUT_END;
			}

			// mouse must be down, and mouse events are allowed (see the TouchMouse input)
			if (!this.pressed || !this.allow) {
				return;
			}

			if (eventType & INPUT_END) {
				this.pressed = false;
			}

			this.callback(this.manager, eventType, {
				pointers: [ev],
				changedPointers: [ev],
				pointerType: INPUT_TYPE_MOUSE,
				srcEvent: ev
			});
		}
	});

	var POINTER_INPUT_MAP = {
		pointerdown: INPUT_START,
		pointermove: INPUT_MOVE,
		pointerup: INPUT_END,
		pointercancel: INPUT_CANCEL,
		pointerout: INPUT_CANCEL
	};

// in IE10 the pointer types is defined as an enum
	var IE10_POINTER_TYPE_ENUM = {
		2: INPUT_TYPE_TOUCH,
		3: INPUT_TYPE_PEN,
		4: INPUT_TYPE_MOUSE,
		5: INPUT_TYPE_KINECT // see https://twitter.com/jacobrossi/status/480596438489890816
	};

	var POINTER_ELEMENT_EVENTS = 'pointerdown';
	var POINTER_WINDOW_EVENTS = 'pointermove pointerup pointercancel';

// IE10 has prefixed support, and case-sensitive
	if (window.MSPointerEvent) {
		POINTER_ELEMENT_EVENTS = 'MSPointerDown';
		POINTER_WINDOW_EVENTS = 'MSPointerMove MSPointerUp MSPointerCancel';
	}

	/**
	 * Pointer events input
	 * @constructor
	 * @extends Input
	 */
	function PointerEventInput() {
		this.evEl = POINTER_ELEMENT_EVENTS;
		this.evWin = POINTER_WINDOW_EVENTS;

		Input.apply(this, arguments);

		this.store = (this.manager.session.pointerEvents = []);
	}

	inherit(PointerEventInput, Input, {
		/**
		 * handle mouse events
		 * @param {Object} ev
		 */
		handler: function PEhandler(ev) {
			var store = this.store;
			var removePointer = false;

			var eventTypeNormalized = ev.type.toLowerCase().replace('ms', '');
			var eventType = POINTER_INPUT_MAP[eventTypeNormalized];
			var pointerType = IE10_POINTER_TYPE_ENUM[ev.pointerType] || ev.pointerType;

			var isTouch = (pointerType == INPUT_TYPE_TOUCH);

			// get index of the event in the store
			var storeIndex = inArray(store, ev.pointerId, 'pointerId');

			// start and mouse must be down
			if (eventType & INPUT_START && (ev.button === 0 || isTouch)) {
				if (storeIndex < 0) {
					store.push(ev);
					storeIndex = store.length - 1;
				}
			} else if (eventType & (INPUT_END | INPUT_CANCEL)) {
				removePointer = true;
			}

			// it not found, so the pointer hasn't been down (so it's probably a hover)
			if (storeIndex < 0) {
				return;
			}

			// update the event in the store
			store[storeIndex] = ev;

			this.callback(this.manager, eventType, {
				pointers: store,
				changedPointers: [ev],
				pointerType: pointerType,
				srcEvent: ev
			});

			if (removePointer) {
				// remove from the store
				store.splice(storeIndex, 1);
			}
		}
	});

	var SINGLE_TOUCH_INPUT_MAP = {
		touchstart: INPUT_START,
		touchmove: INPUT_MOVE,
		touchend: INPUT_END,
		touchcancel: INPUT_CANCEL
	};

	var SINGLE_TOUCH_TARGET_EVENTS = 'touchstart';
	var SINGLE_TOUCH_WINDOW_EVENTS = 'touchstart touchmove touchend touchcancel';

	/**
	 * Touch events input
	 * @constructor
	 * @extends Input
	 */
	function SingleTouchInput() {
		this.evTarget = SINGLE_TOUCH_TARGET_EVENTS;
		this.evWin = SINGLE_TOUCH_WINDOW_EVENTS;
		this.started = false;

		Input.apply(this, arguments);
	}

	inherit(SingleTouchInput, Input, {
		handler: function TEhandler(ev) {
			var type = SINGLE_TOUCH_INPUT_MAP[ev.type];

			// should we handle the touch events?
			if (type === INPUT_START) {
				this.started = true;
			}

			if (!this.started) {
				return;
			}

			var touches = normalizeSingleTouches.call(this, ev, type);

			// when done, reset the started state
			if (type & (INPUT_END | INPUT_CANCEL) && touches[0].length - touches[1].length === 0) {
				this.started = false;
			}

			this.callback(this.manager, type, {
				pointers: touches[0],
				changedPointers: touches[1],
				pointerType: INPUT_TYPE_TOUCH,
				srcEvent: ev
			});
		}
	});

	/**
	 * @this {TouchInput}
	 * @param {Object} ev
	 * @param {Number} type flag
	 * @returns {undefined|Array} [all, changed]
	 */
	function normalizeSingleTouches(ev, type) {
		var all = toArray(ev.touches);
		var changed = toArray(ev.changedTouches);

		if (type & (INPUT_END | INPUT_CANCEL)) {
			all = uniqueArray(all.concat(changed), 'identifier', true);
		}

		return [all, changed];
	}

	var TOUCH_INPUT_MAP = {
		touchstart: INPUT_START,
		touchmove: INPUT_MOVE,
		touchend: INPUT_END,
		touchcancel: INPUT_CANCEL
	};

	var TOUCH_TARGET_EVENTS = 'touchstart touchmove touchend touchcancel';

	/**
	 * Multi-user touch events input
	 * @constructor
	 * @extends Input
	 */
	function TouchInput() {
		this.evTarget = TOUCH_TARGET_EVENTS;
		this.targetIds = {};

		Input.apply(this, arguments);
	}

	inherit(TouchInput, Input, {
		handler: function MTEhandler(ev) {
			var type = TOUCH_INPUT_MAP[ev.type];
			var touches = getTouches.call(this, ev, type);
			if (!touches) {
				return;
			}

			this.callback(this.manager, type, {
				pointers: touches[0],
				changedPointers: touches[1],
				pointerType: INPUT_TYPE_TOUCH,
				srcEvent: ev
			});
		}
	});

	/**
	 * @this {TouchInput}
	 * @param {Object} ev
	 * @param {Number} type flag
	 * @returns {undefined|Array} [all, changed]
	 */
	function getTouches(ev, type) {
		var allTouches = toArray(ev.touches);
		var targetIds = this.targetIds;

		// when there is only one touch, the process can be simplified
		if (type & (INPUT_START | INPUT_MOVE) && allTouches.length === 1) {
			targetIds[allTouches[0].identifier] = true;
			return [allTouches, allTouches];
		}

		var i,
			targetTouches,
			changedTouches = toArray(ev.changedTouches),
			changedTargetTouches = [],
			target = this.target;

		// get target touches from touches
		targetTouches = allTouches.filter(function(touch) {
			return hasParent(touch.target, target);
		});

		// collect touches
		if (type === INPUT_START) {
			i = 0;
			while (i < targetTouches.length) {
				targetIds[targetTouches[i].identifier] = true;
				i++;
			}
		}

		// filter changed touches to only contain touches that exist in the collected target ids
		i = 0;
		while (i < changedTouches.length) {
			if (targetIds[changedTouches[i].identifier]) {
				changedTargetTouches.push(changedTouches[i]);
			}

			// cleanup removed touches
			if (type & (INPUT_END | INPUT_CANCEL)) {
				delete targetIds[changedTouches[i].identifier];
			}
			i++;
		}

		if (!changedTargetTouches.length) {
			return;
		}

		return [
			// merge targetTouches with changedTargetTouches so it contains ALL touches, including 'end' and 'cancel'
			uniqueArray(targetTouches.concat(changedTargetTouches), 'identifier', true),
			changedTargetTouches
		];
	}

	/**
	 * Combined touch and mouse input
	 *
	 * Touch has a higher priority then mouse, and while touching no mouse events are allowed.
	 * This because touch devices also emit mouse events while doing a touch.
	 *
	 * @constructor
	 * @extends Input
	 */
	function TouchMouseInput() {
		Input.apply(this, arguments);

		var handler = bindFn(this.handler, this);
		this.touch = new TouchInput(this.manager, handler);
		this.mouse = new MouseInput(this.manager, handler);
	}

	inherit(TouchMouseInput, Input, {
		/**
		 * handle mouse and touch events
		 * @param {Hammer} manager
		 * @param {String} inputEvent
		 * @param {Object} inputData
		 */
		handler: function TMEhandler(manager, inputEvent, inputData) {
			var isTouch = (inputData.pointerType == INPUT_TYPE_TOUCH),
				isMouse = (inputData.pointerType == INPUT_TYPE_MOUSE);

			// when we're in a touch event, so  block all upcoming mouse events
			// most mobile browser also emit mouseevents, right after touchstart
			if (isTouch) {
				this.mouse.allow = false;
			} else if (isMouse && !this.mouse.allow) {
				return;
			}

			// reset the allowMouse when we're done
			if (inputEvent & (INPUT_END | INPUT_CANCEL)) {
				this.mouse.allow = true;
			}

			this.callback(manager, inputEvent, inputData);
		},

		/**
		 * remove the event listeners
		 */
		destroy: function destroy() {
			this.touch.destroy();
			this.mouse.destroy();
		}
	});

	var PREFIXED_TOUCH_ACTION = prefixed(TEST_ELEMENT.style, 'touchAction');
	var NATIVE_TOUCH_ACTION = PREFIXED_TOUCH_ACTION !== undefined;

// magical touchAction value
	var TOUCH_ACTION_COMPUTE = 'compute';
	var TOUCH_ACTION_AUTO = 'auto';
	var TOUCH_ACTION_MANIPULATION = 'manipulation'; // not implemented
	var TOUCH_ACTION_NONE = 'none';
	var TOUCH_ACTION_PAN_X = 'pan-x';
	var TOUCH_ACTION_PAN_Y = 'pan-y';

	/**
	 * Touch Action
	 * sets the touchAction property or uses the js alternative
	 * @param {Manager} manager
	 * @param {String} value
	 * @constructor
	 */
	function TouchAction(manager, value) {
		this.manager = manager;
		this.set(value);
	}

	TouchAction.prototype = {
		/**
		 * set the touchAction value on the element or enable the polyfill
		 * @param {String} value
		 */
		set: function(value) {
			// find out the touch-action by the event handlers
			if (value == TOUCH_ACTION_COMPUTE) {
				value = this.compute();
			}

			if (NATIVE_TOUCH_ACTION) {
				this.manager.element.style[PREFIXED_TOUCH_ACTION] = value;
			}
			this.actions = value.toLowerCase().trim();
		},

		/**
		 * just re-set the touchAction value
		 */
		update: function() {
			this.set(this.manager.options.touchAction);
		},

		/**
		 * compute the value for the touchAction property based on the recognizer's settings
		 * @returns {String} value
		 */
		compute: function() {
			var actions = [];
			each(this.manager.recognizers, function(recognizer) {
				if (boolOrFn(recognizer.options.enable, [recognizer])) {
					actions = actions.concat(recognizer.getTouchAction());
				}
			});
			return cleanTouchActions(actions.join(' '));
		},

		/**
		 * this method is called on each input cycle and provides the preventing of the browser behavior
		 * @param {Object} input
		 */
		preventDefaults: function(input) {
			// not needed with native support for the touchAction property
			if (NATIVE_TOUCH_ACTION) {
				return;
			}

			var srcEvent = input.srcEvent;
			var direction = input.offsetDirection;

			// if the touch action did prevented once this session
			if (this.manager.session.prevented) {
				srcEvent.preventDefault();
				return;
			}

			var actions = this.actions;
			var hasNone = inStr(actions, TOUCH_ACTION_NONE);
			var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y);
			var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X);

			if (hasNone ||
				(hasPanY && direction & DIRECTION_HORIZONTAL) ||
				(hasPanX && direction & DIRECTION_VERTICAL)) {
				return this.preventSrc(srcEvent);
			}
		},

		/**
		 * call preventDefault to prevent the browser's default behavior (scrolling in most cases)
		 * @param {Object} srcEvent
		 */
		preventSrc: function(srcEvent) {
			this.manager.session.prevented = true;
			srcEvent.preventDefault();
		}
	};

	/**
	 * when the touchActions are collected they are not a valid value, so we need to clean things up. *
	 * @param {String} actions
	 * @returns {*}
	 */
	function cleanTouchActions(actions) {
		// none
		if (inStr(actions, TOUCH_ACTION_NONE)) {
			return TOUCH_ACTION_NONE;
		}

		var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X);
		var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y);

		// pan-x and pan-y can be combined
		if (hasPanX && hasPanY) {
			return TOUCH_ACTION_PAN_X + ' ' + TOUCH_ACTION_PAN_Y;
		}

		// pan-x OR pan-y
		if (hasPanX || hasPanY) {
			return hasPanX ? TOUCH_ACTION_PAN_X : TOUCH_ACTION_PAN_Y;
		}

		// manipulation
		if (inStr(actions, TOUCH_ACTION_MANIPULATION)) {
			return TOUCH_ACTION_MANIPULATION;
		}

		return TOUCH_ACTION_AUTO;
	}

	/**
	 * Recognizer flow explained; *
	 * All recognizers have the initial state of POSSIBLE when a input session starts.
	 * The definition of a input session is from the first input until the last input, with all it's movement in it. *
	 * Example session for mouse-input: mousedown -> mousemove -> mouseup
	 *
	 * On each recognizing cycle (see Manager.recognize) the .recognize() method is executed
	 * which determines with state it should be.
	 *
	 * If the recognizer has the state FAILED, CANCELLED or RECOGNIZED (equals ENDED), it is reset to
	 * POSSIBLE to give it another change on the next cycle.
	 *
	 *               Possible
	 *                  |
	 *            +-----+---------------+
	 *            |                     |
	 *      +-----+-----+               |
	 *      |           |               |
	 *   Failed      Cancelled          |
	 *                          +-------+------+
	 *                          |              |
	 *                      Recognized       Began
	 *                                         |
	 *                                      Changed
	 *                                         |
	 *                                  Ended/Recognized
	 */
	var STATE_POSSIBLE = 1;
	var STATE_BEGAN = 2;
	var STATE_CHANGED = 4;
	var STATE_ENDED = 8;
	var STATE_RECOGNIZED = STATE_ENDED;
	var STATE_CANCELLED = 16;
	var STATE_FAILED = 32;

	/**
	 * Recognizer
	 * Every recognizer needs to extend from this class.
	 * @constructor
	 * @param {Object} options
	 */
	function Recognizer(options) {
		this.id = uniqueId();

		this.manager = null;
		this.options = merge(options || {}, this.defaults);

		// default is enable true
		this.options.enable = ifUndefined(this.options.enable, true);

		this.state = STATE_POSSIBLE;

		this.simultaneous = {};
		this.requireFail = [];
	}

	Recognizer.prototype = {
		/**
		 * @virtual
		 * @type {Object}
		 */
		defaults: {},

		/**
		 * set options
		 * @param {Object} options
		 * @return {Recognizer}
		 */
		set: function(options) {
			extend(this.options, options);

			// also update the touchAction, in case something changed about the directions/enabled state
			this.manager && this.manager.touchAction.update();
			return this;
		},

		/**
		 * recognize simultaneous with an other recognizer.
		 * @param {Recognizer} otherRecognizer
		 * @returns {Recognizer} this
		 */
		recognizeWith: function(otherRecognizer) {
			if (invokeArrayArg(otherRecognizer, 'recognizeWith', this)) {
				return this;
			}

			var simultaneous = this.simultaneous;
			otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
			if (!simultaneous[otherRecognizer.id]) {
				simultaneous[otherRecognizer.id] = otherRecognizer;
				otherRecognizer.recognizeWith(this);
			}
			return this;
		},

		/**
		 * drop the simultaneous link. it doesnt remove the link on the other recognizer.
		 * @param {Recognizer} otherRecognizer
		 * @returns {Recognizer} this
		 */
		dropRecognizeWith: function(otherRecognizer) {
			if (invokeArrayArg(otherRecognizer, 'dropRecognizeWith', this)) {
				return this;
			}

			otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
			delete this.simultaneous[otherRecognizer.id];
			return this;
		},

		/**
		 * recognizer can only run when an other is failing
		 * @param {Recognizer} otherRecognizer
		 * @returns {Recognizer} this
		 */
		requireFailure: function(otherRecognizer) {
			if (invokeArrayArg(otherRecognizer, 'requireFailure', this)) {
				return this;
			}

			var requireFail = this.requireFail;
			otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
			if (inArray(requireFail, otherRecognizer) === -1) {
				requireFail.push(otherRecognizer);
				otherRecognizer.requireFailure(this);
			}
			return this;
		},

		/**
		 * drop the requireFailure link. it does not remove the link on the other recognizer.
		 * @param {Recognizer} otherRecognizer
		 * @returns {Recognizer} this
		 */
		dropRequireFailure: function(otherRecognizer) {
			if (invokeArrayArg(otherRecognizer, 'dropRequireFailure', this)) {
				return this;
			}

			otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
			var index = inArray(this.requireFail, otherRecognizer);
			if (index > -1) {
				this.requireFail.splice(index, 1);
			}
			return this;
		},

		/**
		 * has require failures boolean
		 * @returns {boolean}
		 */
		hasRequireFailures: function() {
			return this.requireFail.length > 0;
		},

		/**
		 * if the recognizer can recognize simultaneous with an other recognizer
		 * @param {Recognizer} otherRecognizer
		 * @returns {Boolean}
		 */
		canRecognizeWith: function(otherRecognizer) {
			return !!this.simultaneous[otherRecognizer.id];
		},

		/**
		 * You should use `tryEmit` instead of `emit` directly to check
		 * that all the needed recognizers has failed before emitting.
		 * @param {Object} input
		 */
		emit: function(input) {
			var self = this;
			var state = this.state;

			function emit(withState) {
				self.manager.emit(self.options.event + (withState ? stateStr(state) : ''), input);
			}

			// 'panstart' and 'panmove'
			if (state < STATE_ENDED) {
				emit(true);
			}

			emit(); // simple 'eventName' events

			// panend and pancancel
			if (state >= STATE_ENDED) {
				emit(true);
			}
		},

		/**
		 * Check that all the require failure recognizers has failed,
		 * if true, it emits a gesture event,
		 * otherwise, setup the state to FAILED.
		 * @param {Object} input
		 */
		tryEmit: function(input) {
			if (this.canEmit()) {
				return this.emit(input);
			}
			// it's failing anyway
			this.state = STATE_FAILED;
		},

		/**
		 * can we emit?
		 * @returns {boolean}
		 */
		canEmit: function() {
			var i = 0;
			while (i < this.requireFail.length) {
				if (!(this.requireFail[i].state & (STATE_FAILED | STATE_POSSIBLE))) {
					return false;
				}
				i++;
			}
			return true;
		},

		/**
		 * update the recognizer
		 * @param {Object} inputData
		 */
		recognize: function(inputData) {
			// make a new copy of the inputData
			// so we can change the inputData without messing up the other recognizers
			var inputDataClone = extend({}, inputData);

			// is is enabled and allow recognizing?
			if (!boolOrFn(this.options.enable, [this, inputDataClone])) {
				this.reset();
				this.state = STATE_FAILED;
				return;
			}

			// reset when we've reached the end
			if (this.state & (STATE_RECOGNIZED | STATE_CANCELLED | STATE_FAILED)) {
				this.state = STATE_POSSIBLE;
			}

			this.state = this.process(inputDataClone);

			// the recognizer has recognized a gesture
			// so trigger an event
			if (this.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED | STATE_CANCELLED)) {
				this.tryEmit(inputDataClone);
			}
		},

		/**
		 * return the state of the recognizer
		 * the actual recognizing happens in this method
		 * @virtual
		 * @param {Object} inputData
		 * @returns {Const} STATE
		 */
		process: function(inputData) { }, // jshint ignore:line

		/**
		 * return the preferred touch-action
		 * @virtual
		 * @returns {Array}
		 */
		getTouchAction: function() { },

		/**
		 * called when the gesture isn't allowed to recognize
		 * like when another is being recognized or it is disabled
		 * @virtual
		 */
		reset: function() { }
	};

	/**
	 * get a usable string, used as event postfix
	 * @param {Const} state
	 * @returns {String} state
	 */
	function stateStr(state) {
		if (state & STATE_CANCELLED) {
			return 'cancel';
		} else if (state & STATE_ENDED) {
			return 'end';
		} else if (state & STATE_CHANGED) {
			return 'move';
		} else if (state & STATE_BEGAN) {
			return 'start';
		}
		return '';
	}

	/**
	 * direction cons to string
	 * @param {Const} direction
	 * @returns {String}
	 */
	function directionStr(direction) {
		if (direction == DIRECTION_DOWN) {
			return 'down';
		} else if (direction == DIRECTION_UP) {
			return 'up';
		} else if (direction == DIRECTION_LEFT) {
			return 'left';
		} else if (direction == DIRECTION_RIGHT) {
			return 'right';
		}
		return '';
	}

	/**
	 * get a recognizer by name if it is bound to a manager
	 * @param {Recognizer|String} otherRecognizer
	 * @param {Recognizer} recognizer
	 * @returns {Recognizer}
	 */
	function getRecognizerByNameIfManager(otherRecognizer, recognizer) {
		var manager = recognizer.manager;
		if (manager) {
			return manager.get(otherRecognizer);
		}
		return otherRecognizer;
	}

	/**
	 * This recognizer is just used as a base for the simple attribute recognizers.
	 * @constructor
	 * @extends Recognizer
	 */
	function AttrRecognizer() {
		Recognizer.apply(this, arguments);
	}

	inherit(AttrRecognizer, Recognizer, {
		/**
		 * @namespace
		 * @memberof AttrRecognizer
		 */
		defaults: {
			/**
			 * @type {Number}
			 * @default 1
			 */
			pointers: 1
		},

		/**
		 * Used to check if it the recognizer receives valid input, like input.distance > 10.
		 * @memberof AttrRecognizer
		 * @param {Object} input
		 * @returns {Boolean} recognized
		 */
		attrTest: function(input) {
			var optionPointers = this.options.pointers;
			return optionPointers === 0 || input.pointers.length === optionPointers;
		},

		/**
		 * Process the input and return the state for the recognizer
		 * @memberof AttrRecognizer
		 * @param {Object} input
		 * @returns {*} State
		 */
		process: function(input) {
			var state = this.state;
			var eventType = input.eventType;

			var isRecognized = state & (STATE_BEGAN | STATE_CHANGED);
			var isValid = this.attrTest(input);

			// on cancel input and we've recognized before, return STATE_CANCELLED
			if (isRecognized && (eventType & INPUT_CANCEL || !isValid)) {
				return state | STATE_CANCELLED;
			} else if (isRecognized || isValid) {
				if (eventType & INPUT_END) {
					return state | STATE_ENDED;
				} else if (!(state & STATE_BEGAN)) {
					return STATE_BEGAN;
				}
				return state | STATE_CHANGED;
			}
			return STATE_FAILED;
		}
	});

	/**
	 * Pan
	 * Recognized when the pointer is down and moved in the allowed direction.
	 * @constructor
	 * @extends AttrRecognizer
	 */
	function PanRecognizer() {
		AttrRecognizer.apply(this, arguments);

		this.pX = null;
		this.pY = null;
	}

	inherit(PanRecognizer, AttrRecognizer, {
		/**
		 * @namespace
		 * @memberof PanRecognizer
		 */
		defaults: {
			event: 'pan',
			threshold: 10,
			pointers: 1,
			direction: DIRECTION_ALL
		},

		getTouchAction: function() {
			var direction = this.options.direction;
			var actions = [];
			if (direction & DIRECTION_HORIZONTAL) {
				actions.push(TOUCH_ACTION_PAN_Y);
			}
			if (direction & DIRECTION_VERTICAL) {
				actions.push(TOUCH_ACTION_PAN_X);
			}
			return actions;
		},

		directionTest: function(input) {
			var options = this.options;
			var hasMoved = true;
			var distance = input.distance;
			var direction = input.direction;
			var x = input.deltaX;
			var y = input.deltaY;

			// lock to axis?
			if (!(direction & options.direction)) {
				if (options.direction & DIRECTION_HORIZONTAL) {
					direction = (x === 0) ? DIRECTION_NONE : (x < 0) ? DIRECTION_LEFT : DIRECTION_RIGHT;
					hasMoved = x != this.pX;
					distance = Math.abs(input.deltaX);
				} else {
					direction = (y === 0) ? DIRECTION_NONE : (y < 0) ? DIRECTION_UP : DIRECTION_DOWN;
					hasMoved = y != this.pY;
					distance = Math.abs(input.deltaY);
				}
			}
			input.direction = direction;
			return hasMoved && distance > options.threshold && direction & options.direction;
		},

		attrTest: function(input) {
			return AttrRecognizer.prototype.attrTest.call(this, input) &&
				(this.state & STATE_BEGAN || (!(this.state & STATE_BEGAN) && this.directionTest(input)));
		},

		emit: function(input) {
			this.pX = input.deltaX;
			this.pY = input.deltaY;

			var direction = directionStr(input.direction);
			if (direction) {
				this.manager.emit(this.options.event + direction, input);
			}

			this._super.emit.call(this, input);
		}
	});

	/**
	 * Pinch
	 * Recognized when two or more pointers are moving toward (zoom-in) or away from each other (zoom-out).
	 * @constructor
	 * @extends AttrRecognizer
	 */
	function PinchRecognizer() {
		AttrRecognizer.apply(this, arguments);
	}

	inherit(PinchRecognizer, AttrRecognizer, {
		/**
		 * @namespace
		 * @memberof PinchRecognizer
		 */
		defaults: {
			event: 'pinch',
			threshold: 0,
			pointers: 2
		},

		getTouchAction: function() {
			return [TOUCH_ACTION_NONE];
		},

		attrTest: function(input) {
			return this._super.attrTest.call(this, input) &&
				(Math.abs(input.scale - 1) > this.options.threshold || this.state & STATE_BEGAN);
		},

		emit: function(input) {
			this._super.emit.call(this, input);
			if (input.scale !== 1) {
				var inOut = input.scale < 1 ? 'in' : 'out';
				this.manager.emit(this.options.event + inOut, input);
			}
		}
	});

	/**
	 * Press
	 * Recognized when the pointer is down for x ms without any movement.
	 * @constructor
	 * @extends Recognizer
	 */
	function PressRecognizer() {
		Recognizer.apply(this, arguments);

		this._timer = null;
		this._input = null;
	}

	inherit(PressRecognizer, Recognizer, {
		/**
		 * @namespace
		 * @memberof PressRecognizer
		 */
		defaults: {
			event: 'press',
			pointers: 1,
			time: 500, // minimal time of the pointer to be pressed
			threshold: 5 // a minimal movement is ok, but keep it low
		},

		getTouchAction: function() {
			return [TOUCH_ACTION_AUTO];
		},

		process: function(input) {
			var options = this.options;
			var validPointers = input.pointers.length === options.pointers;
			var validMovement = input.distance < options.threshold;
			var validTime = input.deltaTime > options.time;

			this._input = input;

			// we only allow little movement
			// and we've reached an end event, so a tap is possible
			if (!validMovement || !validPointers || (input.eventType & (INPUT_END | INPUT_CANCEL) && !validTime)) {
				this.reset();
			} else if (input.eventType & INPUT_START) {
				this.reset();
				this._timer = setTimeoutContext(function() {
					this.state = STATE_RECOGNIZED;
					this.tryEmit();
				}, options.time, this);
			} else if (input.eventType & INPUT_END) {
				return STATE_RECOGNIZED;
			}
			return STATE_FAILED;
		},

		reset: function() {
			clearTimeout(this._timer);
		},

		emit: function(input) {
			if (this.state !== STATE_RECOGNIZED) {
				return;
			}

			if (input && (input.eventType & INPUT_END)) {
				this.manager.emit(this.options.event + 'up', input);
			} else {
				this._input.timeStamp = now();
				this.manager.emit(this.options.event, this._input);
			}
		}
	});

	/**
	 * Rotate
	 * Recognized when two or more pointer are moving in a circular motion.
	 * @constructor
	 * @extends AttrRecognizer
	 */
	function RotateRecognizer() {
		AttrRecognizer.apply(this, arguments);
	}

	inherit(RotateRecognizer, AttrRecognizer, {
		/**
		 * @namespace
		 * @memberof RotateRecognizer
		 */
		defaults: {
			event: 'rotate',
			threshold: 0,
			pointers: 2
		},

		getTouchAction: function() {
			return [TOUCH_ACTION_NONE];
		},

		attrTest: function(input) {
			return this._super.attrTest.call(this, input) &&
				(Math.abs(input.rotation) > this.options.threshold || this.state & STATE_BEGAN);
		}
	});

	/**
	 * Swipe
	 * Recognized when the pointer is moving fast (velocity), with enough distance in the allowed direction.
	 * @constructor
	 * @extends AttrRecognizer
	 */
	function SwipeRecognizer() {
		AttrRecognizer.apply(this, arguments);
	}

	inherit(SwipeRecognizer, AttrRecognizer, {
		/**
		 * @namespace
		 * @memberof SwipeRecognizer
		 */
		defaults: {
			event: 'swipe',
			threshold: 10,
			velocity: 0.65,
			direction: DIRECTION_HORIZONTAL | DIRECTION_VERTICAL,
			pointers: 1
		},

		getTouchAction: function() {
			return PanRecognizer.prototype.getTouchAction.call(this);
		},

		attrTest: function(input) {
			var direction = this.options.direction;
			var velocity;

			if (direction & (DIRECTION_HORIZONTAL | DIRECTION_VERTICAL)) {
				velocity = input.velocity;
			} else if (direction & DIRECTION_HORIZONTAL) {
				velocity = input.velocityX;
			} else if (direction & DIRECTION_VERTICAL) {
				velocity = input.velocityY;
			}

			return this._super.attrTest.call(this, input) &&
				direction & input.direction &&
				input.distance > this.options.threshold &&
				abs(velocity) > this.options.velocity && input.eventType & INPUT_END;
		},

		emit: function(input) {
			var direction = directionStr(input.direction);
			if (direction) {
				this.manager.emit(this.options.event + direction, input);
			}

			this.manager.emit(this.options.event, input);
		}
	});

	/**
	 * A tap is ecognized when the pointer is doing a small tap/click. Multiple taps are recognized if they occur
	 * between the given interval and position. The delay option can be used to recognize multi-taps without firing
	 * a single tap.
	 *
	 * The eventData from the emitted event contains the property `tapCount`, which contains the amount of
	 * multi-taps being recognized.
	 * @constructor
	 * @extends Recognizer
	 */
	function TapRecognizer() {
		Recognizer.apply(this, arguments);

		// previous time and center,
		// used for tap counting
		this.pTime = false;
		this.pCenter = false;

		this._timer = null;
		this._input = null;
		this.count = 0;
	}

	inherit(TapRecognizer, Recognizer, {
		/**
		 * @namespace
		 * @memberof PinchRecognizer
		 */
		defaults: {
			event: 'tap',
			pointers: 1,
			taps: 1,
			interval: 300, // max time between the multi-tap taps
			time: 250, // max time of the pointer to be down (like finger on the screen)
			threshold: 2, // a minimal movement is ok, but keep it low
			posThreshold: 10 // a multi-tap can be a bit off the initial position
		},

		getTouchAction: function() {
			return [TOUCH_ACTION_MANIPULATION];
		},

		process: function(input) {
			var options = this.options;

			var validPointers = input.pointers.length === options.pointers;
			var validMovement = input.distance < options.threshold;
			var validTouchTime = input.deltaTime < options.time;

			this.reset();

			if ((input.eventType & INPUT_START) && (this.count === 0)) {
				return this.failTimeout();
			}

			// we only allow little movement
			// and we've reached an end event, so a tap is possible
			if (validMovement && validTouchTime && validPointers) {
				if (input.eventType != INPUT_END) {
					return this.failTimeout();
				}

				var validInterval = this.pTime ? (input.timeStamp - this.pTime < options.interval) : true;
				var validMultiTap = !this.pCenter || getDistance(this.pCenter, input.center) < options.posThreshold;

				this.pTime = input.timeStamp;
				this.pCenter = input.center;

				if (!validMultiTap || !validInterval) {
					this.count = 1;
				} else {
					this.count += 1;
				}

				this._input = input;

				// if tap count matches we have recognized it,
				// else it has began recognizing...
				var tapCount = this.count % options.taps;
				if (tapCount === 0) {
					// no failing requirements, immediately trigger the tap event
					// or wait as long as the multitap interval to trigger
					if (!this.hasRequireFailures()) {
						return STATE_RECOGNIZED;
					} else {
						this._timer = setTimeoutContext(function() {
							this.state = STATE_RECOGNIZED;
							this.tryEmit();
						}, options.interval, this);
						return STATE_BEGAN;
					}
				}
			}
			return STATE_FAILED;
		},

		failTimeout: function() {
			this._timer = setTimeoutContext(function() {
				this.state = STATE_FAILED;
			}, this.options.interval, this);
			return STATE_FAILED;
		},

		reset: function() {
			clearTimeout(this._timer);
		},

		emit: function() {
			if (this.state == STATE_RECOGNIZED ) {
				this._input.tapCount = this.count;
				this.manager.emit(this.options.event, this._input);
			}
		}
	});

	/**
	 * Simple way to create an manager with a default set of recognizers.
	 * @param {HTMLElement} element
	 * @param {Object} [options]
	 * @constructor
	 */
	function Hammer(element, options) {
		options = options || {};
		options.recognizers = ifUndefined(options.recognizers, Hammer.defaults.preset);
		return new Manager(element, options);
	}

	/**
	 * @const {string}
	 */
	Hammer.VERSION = '2.0.4';

	/**
	 * default settings
	 * @namespace
	 */
	Hammer.defaults = {
		/**
		 * set if DOM events are being triggered.
		 * But this is slower and unused by simple implementations, so disabled by default.
		 * @type {Boolean}
		 * @default false
		 */
		domEvents: false,

		/**
		 * The value for the touchAction property/fallback.
		 * When set to `compute` it will magically set the correct value based on the added recognizers.
		 * @type {String}
		 * @default compute
		 */
		touchAction: TOUCH_ACTION_COMPUTE,

		/**
		 * @type {Boolean}
		 * @default true
		 */
		enable: true,

		/**
		 * EXPERIMENTAL FEATURE -- can be removed/changed
		 * Change the parent input target element.
		 * If Null, then it is being set the to main element.
		 * @type {Null|EventTarget}
		 * @default null
		 */
		inputTarget: null,

		/**
		 * force an input class
		 * @type {Null|Function}
		 * @default null
		 */
		inputClass: null,

		/**
		 * Default recognizer setup when calling `Hammer()`
		 * When creating a new Manager these will be skipped.
		 * @type {Array}
		 */
		preset: [
			// RecognizerClass, options, [recognizeWith, ...], [requireFailure, ...]
			[RotateRecognizer, { enable: false }],
			[PinchRecognizer, { enable: false }, ['rotate']],
			[SwipeRecognizer,{ direction: DIRECTION_HORIZONTAL }],
			[PanRecognizer, { direction: DIRECTION_HORIZONTAL }, ['swipe']],
			[TapRecognizer],
			[TapRecognizer, { event: 'doubletap', taps: 2 }, ['tap']],
			[PressRecognizer]
		],

		/**
		 * Some CSS properties can be used to improve the working of Hammer.
		 * Add them to this method and they will be set when creating a new Manager.
		 * @namespace
		 */
		cssProps: {
			/**
			 * Disables text selection to improve the dragging gesture. Mainly for desktop browsers.
			 * @type {String}
			 * @default 'none'
			 */
			userSelect: 'none',

			/**
			 * Disable the Windows Phone grippers when pressing an element.
			 * @type {String}
			 * @default 'none'
			 */
			touchSelect: 'none',

			/**
			 * Disables the default callout shown when you touch and hold a touch target.
			 * On iOS, when you touch and hold a touch target such as a link, Safari displays
			 * a callout containing information about the link. This property allows you to disable that callout.
			 * @type {String}
			 * @default 'none'
			 */
			touchCallout: 'none',

			/**
			 * Specifies whether zooming is enabled. Used by IE10>
			 * @type {String}
			 * @default 'none'
			 */
			contentZooming: 'none',

			/**
			 * Specifies that an entire element should be draggable instead of its contents. Mainly for desktop browsers.
			 * @type {String}
			 * @default 'none'
			 */
			userDrag: 'none',

			/**
			 * Overrides the highlight color shown when the user taps a link or a JavaScript
			 * clickable element in iOS. This property obeys the alpha value, if specified.
			 * @type {String}
			 * @default 'rgba(0,0,0,0)'
			 */
			tapHighlightColor: 'rgba(0,0,0,0)'
		}
	};

	var STOP = 1;
	var FORCED_STOP = 2;

	/**
	 * Manager
	 * @param {HTMLElement} element
	 * @param {Object} [options]
	 * @constructor
	 */
	function Manager(element, options) {
		options = options || {};

		this.options = merge(options, Hammer.defaults);
		this.options.inputTarget = this.options.inputTarget || element;

		this.handlers = {};
		this.session = {};
		this.recognizers = [];

		this.element = element;
		this.input = createInputInstance(this);
		this.touchAction = new TouchAction(this, this.options.touchAction);

		toggleCssProps(this, true);

		each(options.recognizers, function(item) {
			var recognizer = this.add(new (item[0])(item[1]));
			item[2] && recognizer.recognizeWith(item[2]);
			item[3] && recognizer.requireFailure(item[3]);
		}, this);
	}

	Manager.prototype = {
		/**
		 * set options
		 * @param {Object} options
		 * @returns {Manager}
		 */
		set: function(options) {
			extend(this.options, options);

			// Options that need a little more setup
			if (options.touchAction) {
				this.touchAction.update();
			}
			if (options.inputTarget) {
				// Clean up existing event listeners and reinitialize
				this.input.destroy();
				this.input.target = options.inputTarget;
				this.input.init();
			}
			return this;
		},

		/**
		 * stop recognizing for this session.
		 * This session will be discarded, when a new [input]start event is fired.
		 * When forced, the recognizer cycle is stopped immediately.
		 * @param {Boolean} [force]
		 */
		stop: function(force) {
			this.session.stopped = force ? FORCED_STOP : STOP;
		},

		/**
		 * run the recognizers!
		 * called by the inputHandler function on every movement of the pointers (touches)
		 * it walks through all the recognizers and tries to detect the gesture that is being made
		 * @param {Object} inputData
		 */
		recognize: function(inputData) {
			var session = this.session;
			if (session.stopped) {
				return;
			}

			// run the touch-action polyfill
			this.touchAction.preventDefaults(inputData);

			var recognizer;
			var recognizers = this.recognizers;

			// this holds the recognizer that is being recognized.
			// so the recognizer's state needs to be BEGAN, CHANGED, ENDED or RECOGNIZED
			// if no recognizer is detecting a thing, it is set to `null`
			var curRecognizer = session.curRecognizer;

			// reset when the last recognizer is recognized
			// or when we're in a new session
			if (!curRecognizer || (curRecognizer && curRecognizer.state & STATE_RECOGNIZED)) {
				curRecognizer = session.curRecognizer = null;
			}

			var i = 0;
			while (i < recognizers.length) {
				recognizer = recognizers[i];

				// find out if we are allowed try to recognize the input for this one.
				// 1.   allow if the session is NOT forced stopped (see the .stop() method)
				// 2.   allow if we still haven't recognized a gesture in this session, or the this recognizer is the one
				//      that is being recognized.
				// 3.   allow if the recognizer is allowed to run simultaneous with the current recognized recognizer.
				//      this can be setup with the `recognizeWith()` method on the recognizer.
				if (session.stopped !== FORCED_STOP && ( // 1
					!curRecognizer || recognizer == curRecognizer || // 2
					recognizer.canRecognizeWith(curRecognizer))) { // 3
					recognizer.recognize(inputData);
				} else {
					recognizer.reset();
				}

				// if the recognizer has been recognizing the input as a valid gesture, we want to store this one as the
				// current active recognizer. but only if we don't already have an active recognizer
				if (!curRecognizer && recognizer.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED)) {
					curRecognizer = session.curRecognizer = recognizer;
				}
				i++;
			}
		},

		/**
		 * get a recognizer by its event name.
		 * @param {Recognizer|String} recognizer
		 * @returns {Recognizer|Null}
		 */
		get: function(recognizer) {
			if (recognizer instanceof Recognizer) {
				return recognizer;
			}

			var recognizers = this.recognizers;
			for (var i = 0; i < recognizers.length; i++) {
				if (recognizers[i].options.event == recognizer) {
					return recognizers[i];
				}
			}
			return null;
		},

		/**
		 * add a recognizer to the manager
		 * existing recognizers with the same event name will be removed
		 * @param {Recognizer} recognizer
		 * @returns {Recognizer|Manager}
		 */
		add: function(recognizer) {
			if (invokeArrayArg(recognizer, 'add', this)) {
				return this;
			}

			// remove existing
			var existing = this.get(recognizer.options.event);
			if (existing) {
				this.remove(existing);
			}

			this.recognizers.push(recognizer);
			recognizer.manager = this;

			this.touchAction.update();
			return recognizer;
		},

		/**
		 * remove a recognizer by name or instance
		 * @param {Recognizer|String} recognizer
		 * @returns {Manager}
		 */
		remove: function(recognizer) {
			if (invokeArrayArg(recognizer, 'remove', this)) {
				return this;
			}

			var recognizers = this.recognizers;
			recognizer = this.get(recognizer);
			recognizers.splice(inArray(recognizers, recognizer), 1);

			this.touchAction.update();
			return this;
		},

		/**
		 * bind event
		 * @param {String} events
		 * @param {Function} handler
		 * @returns {EventEmitter} this
		 */
		on: function(events, handler) {
			var handlers = this.handlers;
			each(splitStr(events), function(event) {
				handlers[event] = handlers[event] || [];
				handlers[event].push(handler);
			});
			return this;
		},

		/**
		 * unbind event, leave emit blank to remove all handlers
		 * @param {String} events
		 * @param {Function} [handler]
		 * @returns {EventEmitter} this
		 */
		off: function(events, handler) {
			var handlers = this.handlers;
			each(splitStr(events), function(event) {
				if (!handler) {
					delete handlers[event];
				} else {
					handlers[event].splice(inArray(handlers[event], handler), 1);
				}
			});
			return this;
		},

		/**
		 * emit event to the listeners
		 * @param {String} event
		 * @param {Object} data
		 */
		emit: function(event, data) {
			// we also want to trigger dom events
			if (this.options.domEvents) {
				triggerDomEvent(event, data);
			}

			// no handlers, so skip it all
			var handlers = this.handlers[event] && this.handlers[event].slice();
			if (!handlers || !handlers.length) {
				return;
			}

			data.type = event;
			data.preventDefault = function() {
				data.srcEvent.preventDefault();
			};

			var i = 0;
			while (i < handlers.length) {
				handlers[i](data);
				i++;
			}
		},

		/**
		 * destroy the manager and unbinds all events
		 * it doesn't unbind dom events, that is the user own responsibility
		 */
		destroy: function() {
			this.element && toggleCssProps(this, false);

			this.handlers = {};
			this.session = {};
			this.input.destroy();
			this.element = null;
		}
	};

	/**
	 * add/remove the css properties as defined in manager.options.cssProps
	 * @param {Manager} manager
	 * @param {Boolean} add
	 */
	function toggleCssProps(manager, add) {
		var element = manager.element;
		each(manager.options.cssProps, function(value, name) {
			element.style[prefixed(element.style, name)] = add ? value : '';
		});
	}

	/**
	 * trigger dom event
	 * @param {String} event
	 * @param {Object} data
	 */
	function triggerDomEvent(event, data) {
		var gestureEvent = document.createEvent('Event');
		gestureEvent.initEvent(event, true, true);
		gestureEvent.gesture = data;
		data.target.dispatchEvent(gestureEvent);
	}

	extend(Hammer, {
		INPUT_START: INPUT_START,
		INPUT_MOVE: INPUT_MOVE,
		INPUT_END: INPUT_END,
		INPUT_CANCEL: INPUT_CANCEL,

		STATE_POSSIBLE: STATE_POSSIBLE,
		STATE_BEGAN: STATE_BEGAN,
		STATE_CHANGED: STATE_CHANGED,
		STATE_ENDED: STATE_ENDED,
		STATE_RECOGNIZED: STATE_RECOGNIZED,
		STATE_CANCELLED: STATE_CANCELLED,
		STATE_FAILED: STATE_FAILED,

		DIRECTION_NONE: DIRECTION_NONE,
		DIRECTION_LEFT: DIRECTION_LEFT,
		DIRECTION_RIGHT: DIRECTION_RIGHT,
		DIRECTION_UP: DIRECTION_UP,
		DIRECTION_DOWN: DIRECTION_DOWN,
		DIRECTION_HORIZONTAL: DIRECTION_HORIZONTAL,
		DIRECTION_VERTICAL: DIRECTION_VERTICAL,
		DIRECTION_ALL: DIRECTION_ALL,

		Manager: Manager,
		Input: Input,
		TouchAction: TouchAction,

		TouchInput: TouchInput,
		MouseInput: MouseInput,
		PointerEventInput: PointerEventInput,
		TouchMouseInput: TouchMouseInput,
		SingleTouchInput: SingleTouchInput,

		Recognizer: Recognizer,
		AttrRecognizer: AttrRecognizer,
		Tap: TapRecognizer,
		Pan: PanRecognizer,
		Swipe: SwipeRecognizer,
		Pinch: PinchRecognizer,
		Rotate: RotateRecognizer,
		Press: PressRecognizer,

		on: addEventListeners,
		off: removeEventListeners,
		each: each,
		merge: merge,
		extend: extend,
		inherit: inherit,
		bindFn: bindFn,
		prefixed: prefixed
	});

	if (typeof define == TYPE_FUNCTION && define.amd) {
		define(function() {
			return Hammer;
		});
	} else if (typeof module != 'undefined' && module.exports) {
		module.exports = Hammer;
	} else {
		window[exportName] = Hammer;
	}

})(window, document, 'Hammer');

(function(factory) {
	if (typeof define === 'function' && define.amd) {
		define(['jquery', 'hammerjs'], factory);
	} else if (typeof exports === 'object') {
		factory(require('jquery'), require('hammerjs'));
	} else {
		factory(jQuery, Hammer);
	}
}(function($, Hammer) {
	function hammerify(el, options) {
		var $el = $(el);
		if(!$el.data("hammer")) {
			$el.data("hammer", new Hammer($el[0], options));
		}
	}

	$.fn.hammer = function(options) {
		return this.each(function() {
			hammerify(this, options);
		});
	};

	// extend the emit method to also trigger jQuery events
	Hammer.Manager.prototype.emit = (function(originalEmit) {
		return function(type, data) {
			originalEmit.call(this, type, data);
			$(this.element).trigger({
				type: type,
				gesture: data
			});
		};
	})(Hammer.Manager.prototype.emit);
}));