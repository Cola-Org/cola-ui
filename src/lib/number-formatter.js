function formatNumber(format, n) {

	function formatInt(n, format, dec) {
		if (!format) {
			return (parseInt(n.substring(0, nfs.length), 10) + 1) + '';
		}

		var c, f, r = '', j = 0, prefix = '';
		var fv = format.split('');
		for (var i = 0; i < fv.length; i++) {
			f = fv[i];
			if (f === '#' || f === '0' || f === '`') {
				fv = fv.slice(i);
				break;
			}
			prefix += f;
		}
		fv = fv.reverse();
		var cv = n.split('').reverse();
		for (var i = 0; i < fv.length; i++) {
			f = fv[i];
			if (f === '#') {
				if (j < cv.length) {
					if (n === '0') {
						j = cv.length;
					} else if (n === '-0') {
						if (dec) r += '-';
						j = cv.length;
					} else {
						r += cv[j++];
					}
				}
			} else if (f === '0') {
				if (j < cv.length) {
					r += cv[j++];
				} else {
					r += f;
				}
			} else if (f === '`') {
				var commaCount = 3;
				while (j < cv.length) {
					c = cv[j++];
					if (commaCount === 3 && c !== '-') {
						r += ',';
						commaCount = 0;
					}
					r += c;
					commaCount++;
				}
			} else {
				r += f;
			}
		}

		while (j < cv.length) {
			r += cv[j++];
		}
		return prefix + r.split('').reverse().join('');
	}

	function formatDecimal(n, format) {
		var nfs = (format) ? format.match(/[\#0]/g) : null;
		if (nfs === null) {
			return [format, (n && n.charAt(0) > '4')];
		} else if (n && n.length > nfs.length && n.charAt(nfs.length) > '4') {
			var n = n.substring(0, nfs.length);
			n = (parseInt(n, 10) + 1) + '';
			var overflow = n.length > nfs.length;
			if (overflow) {
				n = n.substring(n.length - nfs.length);
			} else {
				var leadingZero = '';
				for (var i = n.length; i < nfs.length; i++) {
					leadingZero += '0';
				}
				n = leadingZero + n;
			}
		}

		var f, r = '', j = 0;
		for (var i = 0; i < format.length; i++) {
			f = format.charAt(i);
			if (f === '#' || f === '0') {
				if (n && j < n.length) {
					r += n.charAt(j++);
				} else if (f === '0') {
					r += f;
				}
			} else {
				r += f;
			}
		}
		return [r, overflow];
	}

	if (n == null || isNaN(n)) return "";
	n = n + '';
	if (n.indexOf("e-") > 0) {
		return n;
	}
	if (!format) return n;
	var n1, n2, f0 = '', f1, f2, f3 = '', i;
	i = n.indexOf('.');
	if (i > 0) {
		n1 = n.substring(0, i);
		n2 = n.substring(i + 1);
	} else {
		n1 = n;
	}

	i = format.indexOf('.');
	if (i > 0) {
		f1 = format.substring(0, i);
		f2 = format.substring(i + 1);
		for (var j = 0; j < f2.length; j++) {
			var c = f2.charAt(j);
			if (c !== '#' && c !== '0') {
				break;
			}
		}
		if (j > 0) {
			f3 = f2.substring(j);
			f2 = f2.substring(0, j);
		}
	} else {
		f1 = format;
	}

	i = Math.floor(f1.indexOf('#'), f1.indexOf('0'));
	if (i > 0) {
		f0 = f1.substring(0, i);
		f1 = f1.substring(i);
	}

	f1 = f1.replace(/\#,/g, '`');

	var r = formatDecimal(n2, f2);
	var dec = r[0];
	if (r[1]) {
		n1 = (parseInt(n1, 10) + ((n1.charAt(0) === '-') ? -1 : 1)) + '';
	}
	return f0 + formatInt(n1, f1, dec) + ((dec) ? ('.' + dec) : '') + f3;
}
