/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {
	// provide innerText supports to Element for Mozilla
	try {
		if (HTMLElement && !HTMLElement.prototype.innerText) {
		
			HTMLElement.prototype.__defineGetter__("innerText", function() {
				var text = this.textContent;
				if (text) {
					text = text.replace(/<BR>/g, "\n");
				}
				return text;
			});
			
			HTMLElement.prototype.__defineSetter__("innerText", function(text) {
				if (text && text.constructor == String) {
					var sections = text.split("\n");
					if (sections.length > 1) {
						this.innerHTML = "";
						for (var i = 0; i < sections.length; i++) {
							if (i > 0) this.appendChild(document.createElement("BR"));
							this.appendChild(document.createTextNode(sections[i]));
						}
						return;
					}
				}
				this.textContent = text;
			});
		}
	} 
	catch (ex) {
	}
	
	if (!String.prototype.startsWith) {
		String.prototype.startsWith = function(str) {
			return this.slice(0, str.length) == str;
		};
	}
	if (!String.prototype.endsWith) {
		String.prototype.endsWith = function(str) {
			return this.slice(-str.length) == str;
		};
	}
	
	
	/**
	 * @name Array
	 * @class 为系统的数组提供的prototype扩展。
	 * <p>
	 * <b>注意：此处的文档只描述了扩展的部分，并未列出数组对象所支持的所有属性方法。</b>
	 * </p>
	 */
	// ====
	
	// provide push, indexOf, removeAt, remove, insert supports to Array
	if (!Array.prototype.push) {
		/**
		 * 向数组的末尾追加一个元素。
		 * <p>
		 * <b>大部分浏览器中JavaScript引擎已经支持此方法，dorado扩展的目的仅针对那些原本不支持此方法的浏览器。</b>
		 * </p>
		 * @param {Object} element 要追加的元素。
		 */
		Array.prototype.push = function(element) {
			this[this.length] = element;
		};
	}
	
	if (!Array.prototype.indexOf) {
		/**
		 * 返回某元素在数组中第一次出现的下标位置。
		 * <p>
		 * <b>大部分浏览器中JavaScript引擎已经支持此方法，dorado扩展的目的仅针对那些原本不支持此方法的浏览器。</b>
		 * </p>
		 * @param {Object} element 要寻找的元素。
		 * @return {int} 元素的下标位置。
		 */
		Array.prototype.indexOf = function(element) {
			for (var i = 0; i < this.length; i++) {
				if (this[i] == element) {
					return i;
				}
			}
			return -1;
		};
	}
	
	if (!Array.prototype.remove) {
		/**
		 * 从数组删除某元素。
		 * <p>
		 * 如果要删除的元素并不存在于数组中，那么此方法什么都不会做，并且返回值为-1。<br>
		 *  如果要删除的元素在于数组中出现多次，那么此方法只删除元素第一次出现的位置，并返回该位置的下标。
		 * </p>
		 * @param {Object} element 要删除的元素。
		 * @return {int} 被删除元素原先的下标位置。
		 */
		Array.prototype.remove = function(element) {
			var i = this.indexOf(element);
			if (i >= 0) this.splice(i, 1);
			return i;
		};
	}
	
	if (!Array.prototype.removeAt) {
		/**
		 * 从数组删除某下标位置处的元素。
		 * <p>
		 * 此方法删除某下标位置后，后面的元素会自动递补，最终数组的长度会缩小1个单位。
		 * </p>
		 * @param {int} i 要删除的下标位置。
		 */
		Array.prototype.removeAt = function(i) {
			this.splice(i, 1);
		};
	}
	
	if (!Array.prototype.insert) {
		/**
		 * 向数组中的指定位置插入一个元素。
		 * <p>
		 * 插入元素后，原插入位置开始的元素会自动后退，最终数组的长度会增加1个单位。
		 * </p>
		 * @param {Object} element 要插入的元素。
		 * @param {Object} [i=0] 要插入的下标位置。
		 */
		Array.prototype.insert = function(element, i) {
			this.splice(i || 0, 0, element);
		};
	}
	
	if (!Array.prototype.peek) {
	
		/**
		 * 返回数组中的最后一个元素。
		 * @return {Object} 最后一个元素。
		 */
		Array.prototype.peek = function() {
			return this[this.length - 1];
		};
	}
	
	if (!Array.prototype.each) {
	
		/**
		 * 遍历数组。
		 * @param {Function} fn 针对数组中每一个元素的回调函数。此函数支持下列两个参数:
		 * <ul>
		 * <li>item - {Object} 当前遍历到的数据元素。</li>
		 * <li>[i] - {int} 当前遍历到的数据下标。</li>
		 * </ul>
		 * 另外，此函数的返回值可用于通知系统是否要终止整个遍历操作。
		 * 返回true或不返回任何数值表示继续执行遍历操作，返回false表示终止整个遍历操作。<br>
		 * 此回调函数中的this指向正在被遍历的数组。
		 *
		 * @example
		 * var s = '';
		 * ['A', 'B', 'C'].each(function(item) {
		 * 	s += item;
		 * });
		 * // s == "ABC"
		 */
		Array.prototype.each = function(fn) {
			for (var i = 0; i < this.length; i++) {
				if (fn.call(this, this[i], i) === false) break;
			}
		};
	}

	if (!Function.prototype.bind) {
		Function.prototype.bind = function (target) {
			var fn = this;
			return function () {
				return fn.apply(target, arguments);
			};
		};
	}
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @name jQuery
 * @class 针对jQuery的扩展。
 *        <p>
 *        <b>注意：这里给出的并不是jQuery的使用文档，而是dorado7对jQuery所做了一系列扩展方法的文档。</b>
 *        </p>
 * @static
 */
(function($) {

	var matched, browser;

	// Use of jQuery.browser is frowned upon.
	// More details: http://api.jquery.com/jQuery.browser
	// jQuery.uaMatch maintained for back-compat
	jQuery.uaMatch = function(ua) {
		ua = ua.toLowerCase();

		var match = /(chrome)[ \/]([\w.]+)/.exec(ua) ||
			/(webkit)[ \/]([\w.]+)/.exec(ua) ||
			/(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) ||
			/(msie) ([\w.]+)/.exec(ua) ||
			/(trident).*rv\:([\w.]+)/.exec(ua) ||
			ua.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua) ||
			[];

		return {
			browser: match[ 1 ] || "",
			version: match[ 2 ] || "0"
		};
	};

	matched = jQuery.uaMatch(navigator.userAgent);
	browser = {};

	if (matched.browser) {
		browser[ matched.browser ] = true;
		browser.version = matched.version;
	}

	// Chrome is Webkit, but Webkit is also Safari.
	if (browser.chrome) {
		browser.webkit = true;
	}
	else if (browser.webkit) {
		browser.safari = true;
	}
	else if (browser.trident) {
		browser.msie = true;
	}

	jQuery.browser = browser;

	// 在jQuery 1.2.6、jQuery 1.3.2中Safari下的ready事件总是在document.readyState
	// 变为complete之前触发，这导致在此事件中进行渲染的DOM对象无法正确的提取offsetHeight等属性。
	// 1.4.x下此现象似乎又转移到了Chrome中，但只在个别情况下出现，如访问一个已经被缓存的页面时。
	var superReady = $.prototype.ready;
	$.prototype.ready = function(fn) {
		if (jQuery.browser.webkit) {
			var self = this;

			function waitForReady() {
				if (document.readyState !== "complete") {
					setTimeout(waitForReady, 10);
				}
				else {
					superReady.call(self, fn);
				}
			}

			waitForReady();
		}
		else {
			superReady.call(this, fn);
		}
	};

	var flyableElem = $();
	flyableElem.length = 1;
	var flyableArray = $();

	/**
	 * @name $fly
	 * @function
	 * @description 根据传入的DOM元素返回一个jQuery的对象。
	 *              <p>
	 *              注意：与jQuery()或$()不同，$fly()为了提高效率并不总是返回新的jQuery对象的实例。
	 *              因此，保留$fly()返回的实例变量不能保证我们能够一直操作同样的DOM元素。
	 *              </p>
	 * @param {HTMLElement|HTMLElement[]}
	 *            elems 要包装的DOM元素或DOM元素的数组。
	 * @return {jQuery} jQuery对象的实例。
	 *
	 * @example var elem1 = $fly("div1"); elem1.text("Text A"); //
	 *          将div1的内容设置为"Text A"。
	 *
	 * var elem2 = $fly("div2"); // 此处返回的elem2很可能和elem1是同一个jQuery实例。
	 * elem2.text("Text B"); // 将div2的内容设置为"Text B"。
	 *
	 * elem1.text("Text C"); // 很可能改写的不是div1的内容，而是div2的内容。
	 */
	$fly = function(elems) {
		if (elems instanceof Array) {
			if ((dorado.Browser.mozilla && dorado.Browser.version >= 2) || dorado.Browser.msie) {
				for(var i = flyableArray.length - 1; i >= 0; i--) {
					delete flyableArray[i];
				}
			}
			Array.prototype.splice.call(flyableArray, 0, flyableArray.length);
			Array.prototype.push.apply(flyableArray, elems);
			return flyableArray;
		}
		else {
			flyableElem[0] = elems;
			return flyableElem;
		}
	};

})(jQuery);

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @namespace dorado的根命名空间。
 */
var dorado = {
	id: '_' + parseInt(Math.random() * Math.pow(10, 8)),

	_ID_SEED: 0,
	_TIMESTAMP_SEED: 0,

	_GET_ID: function(obj) {
		return obj._id;
	},

	_GET_NAME: function(obj) {
		return obj._name;
	},

	_NULL_FUNCTION: function() {
	},

	_UNSUPPORTED_FUNCTION: function() {
		return function() {
			throw new dorado.ResourceException("dorado.core.OperationNotSupported", dorado.getFunctionDescription(arguments.callee));
		};
	},

	/**
	 * @name dorado.Browser
	 * @class 用于获取当前浏览器信息的静态对象。
	 * @static
	 */
	Browser: (function() {
		var browser = {};
		for(var p in jQuery.browser) {
			if (jQuery.browser.hasOwnProperty(p)) browser[p] = jQuery.browser[p];
		}

		function detect(ua) {
			var os = {}, android = ua.match(/(Android)[\s+,;]([\d.]+)?/), android_40 = ua.match(/(Android)\s+(4.0)/),
				ipad = ua.match(/(iPad).*OS\s([\d_]+)/), iphone = !ipad && ua.match(/(iPhone\sOS)\s([\d_]+)/), miui = ua.match(/(MiuiBrowser)\/([\d.]+)/i);

			if (android) {
				os.android = true;
				os.version = android[2];
			} else if (iphone) {
				os.ios = true;
				os.version = iphone[2].replace(/_/g, '.');
				os.iphone = true;
			} else if (ipad) {
				os.ios = true;
				os.version = ipad[2].replace(/_/g, '.');
				os.ipad = true;
			}
			if (miui) {
				os.miui = true;
			}
			if (android_40) {
				os.android_40 = true;
			}
			return os;
		}

		var ua = navigator.userAgent, os = detect(ua);
		if (os.iphone) {
			browser.isPhone = os.iphone;
		} else if (os.android) {
			var screenSize = window.screen.width;
			if (screenSize > window.screen.height) screenSize = window.screen.height;
			browser.isPhone = (screenSize / window.devicePixelRatio) < 768;
			if (os.miui) {
				browser.miui = true;
			}
		}

		browser.android = os.android;
		browser.android_40 = os.android_40;
		browser.iOS = os.ios;
		browser.osVersion = os.version;

		browser.isTouch = (browser.android || browser.iOS) && !!("ontouchstart" in window || (window["$setting"] && $setting["common.simulateTouch"]));
		browser.version = parseInt(browser.version);
		return browser;
	})(),

	/**
	 * @name dorado.Browser.version
	 * @property
	 * @type Number
	 * @description 返回浏览器的版本号。
	 */
	/**
	 * @name dorado.Browser.safari
	 * @property
	 * @type boolean
	 * @description 返回是否Safari浏览器。
	 */
	/**
	 * @name dorado.Browser.chrome
	 * @property
	 * @type boolean
	 * @description 返回是否Chrome浏览器。
	 */
	/**
	 * @name dorado.Browser.opera
	 * @property
	 * @type boolean
	 * @description 返回是否Opera浏览器。
	 */
	/**
	 * @name dorado.Browser.msie
	 * @property
	 * @type boolean
	 * @description 返回是否IE浏览器。
	 */
	/**
	 * @name dorado.Browser.mozilla
	 * @property
	 * @type boolean
	 * @description 返回是否Mozilla浏览器。
	 */
	/**
	 * @name dorado.Browser.webkit
	 * @property
	 * @type boolean
	 * @description 返回是否Webkit浏览器。
	 */
	/**
	 * @name dorado.Browser.isTouch
	 * @property
	 * @type boolean
	 * @description 返回是否手持设备中的浏览器。
	 */
	// =====

	/**
	 * 注册一个在Dorado将要初始化之前触发的监听器。
	 * @param {Function} listener 监听器。
	 */
	beforeInit: function(listener) {
		if (this.beforeInitFired) {
			throw new dorado.Exception("'beforeInit' already fired.");
		}

		if (!this.beforeInitListeners) {
			this.beforeInitListeners = [];
		}
		this.beforeInitListeners.push(listener);
	},

	fireBeforeInit: function() {
		if (this.beforeInitListeners) {
			this.beforeInitListeners.each(function(listener) {
				return listener.call(dorado);
			});
			delete this.beforeInitListeners;
		}
		this.beforeInitFired = true;
	},

	/**
	 * 注册一个在Dorado初始化之后触发的监听器。
	 * @param {Function} listener 监听器。
	 */
	onInit: function(listener) {
		if (this.onInitFired) {
			throw new dorado.Exception("'onInit' already fired.");
		}

		if (!this.onInitListeners) {
			this.onInitListeners = [];
		}
		this.onInitListeners.push(listener);
	},

	fireOnInit: function() {
		if (this.onInitListeners) {
			this.onInitListeners.each(function(listener) {
				return listener.call(dorado);
			});
			delete this.onInitListeners;
		}
		this.onInitFired = true;
	},

	afterInit: function(listener) {
		if (this.afterInitFired) {
			throw new dorado.Exception("'afterInit' already fired.");
		}

		if (!this.afterInitListeners) {
			this.afterInitListeners = [];
		}
		this.afterInitListeners.push(listener);
	},

	fireAfterInit: function() {
		if (this.afterInitListeners) {
			this.afterInitListeners.each(function(listener) {
				return listener.call(dorado);
			});
			delete this.afterInitListeners;
		}
		this.afterInitFired = true;
	},

	defaultToString: function(obj) {
		var s = obj.constructor.className || "[Object]";
		if (obj.id) s += (" id=" + obj.id);
		if (obj.name) s += (" name=" + obj.name);
	},

	/**
	 * 返回一个方法的描述信息。
	 * @param {Function} fn 要描述的方法。
	 * @return {String} 方法的描述信息。
	 */
	getFunctionDescription: function(fn) {
		var defintion = fn.toString().split('\n')[0], name;
		if (fn.methodName) {
			var className;
			if (fn.declaringClass) className = fn.declaringClass.className;
			name = (className ? (className + '.') : "function ") +
				fn.methodName;
		}
		else {
			var regexpResult = defintion.match(/^function (\w*)/);
			name = "function " + (regexpResult && regexpResult[1] || "anonymous");
		}

		var regexpResult = defintion.match(/\((.*)\)/);
		return name + (regexpResult && regexpResult[0]);
	},

	/**
	 * 返回一个方法名称\参数信息。
	 * @param {Function} fn 要描述的方法。
	 * @return {Object} 方法的名称\参数信息。
	 */
	getFunctionInfo: function(fn) {
		var defintion = fn.toString().substring(8), len = defintion.length, name = "", signature = "";
		var inSignatrue = false;
		for(var i = 0; i < len; i++) {
			var c = defintion.charAt(i);
			if (c === ' ' || c === '\t' || c === '\n' || c === '\r') {
				continue;
			}
			else if (c === '(') {
				inSignatrue = true;
			}
			else if (c === ')') {
				break;
			}
			else if (inSignatrue) {
				signature += c;
			}
			else {
				name += c;
			}
		}
		return {
			name: name,
			signature: signature
		};
	}
};

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class dorado核心类，其中包含了若干最常用的工具方法。
 * @static
 */
dorado.Core = {

	/**
	 * 返回dorado的版本号。
	 * @type String
	 */
	VERSION: "%version%",

	/**
	 * 生成一个新的id。
	 * @return {String} 新生成的id。
	 */
	newId: function() {
		return "_uid_" + (++dorado._ID_SEED);
	},

	/**
	 * 生成新的时间戳。<br>
	 * 此处的时间戳事实上只是一个自动递增的整数，并不代表当前的时间。
	 * @return {int} 新时间戳。
	 */
	getTimestamp: function() {
		return ++dorado._TIMESTAMP_SEED;
	},

	/**
	 * 为一个函数指定其调用时的scope，即指定该函数在调用时this对象的指向。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @return {Function} 代理函数。
	 *
	 * @see $scopify
	 *
	 * @example
	 * var s = "hello!";
	 * dorado.Core.scopify(s, "alert(this)")(); // should say "hello!";
	 *
	 * @example
	 * var s = "hello!";
	 * dorado.Core.scopify(s, function(){
	 *	 alert(this);
	 * })(); // should say "hello"
	 */
	scopify: function(scope, fn) {
		if (typeof fn == "function") {
			return function() {
				return fn.apply(scope, arguments);
			};
		}
		else {
			return function() {
				return eval("(function(){return(" + fn + ")}).call(scope)");
			};
		}
	},

	/**
	 * 设定一个延时任务，同时指定该延时任务在调用时的scope。 该方法的功能类似于window.setTimeout。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @param {int} timeMillis 延时的时长（毫秒数）。
	 * @return {int} 延时任务的id。
	 *
	 * @see dorado.Core.scopify
	 * @see $setInterval
	 *
	 * @example
	 * // should say "hello!" after one second.
	 * var s = "hello!";
	 * dorado.Core.setTimeout(s, function() {
	 *	 alert(this);
	 * }, 1000);
	 */
	setTimeout: function(scope, fn, timeMillis) {
		if (dorado.Browser.mozilla && dorado.Browser.version >= 8) {
			// FF8莫名其妙的向setTimeout、setInterval的闭包函数中传入timerID
			return window.setTimeout(function() {
				(dorado.Core.scopify(scope, fn))();
			}, timeMillis);
		}
		else {
			return setTimeout(dorado.Core.scopify(scope, fn), timeMillis);
		}
	},

	/**
	 * 设定一个定时任务，同时指定该定时任务在调用时的scope。 该方法的功能类似于window.setInterval。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @param {int} timeMillis 定时任务的间隔（毫秒数）。
	 * @return {int} 定时任务的id。
	 *
	 * @see dorado.Core.scopify
	 * @see $setInterval
	 */
	setInterval: function(scope, fn, timeMillis) {
		if (dorado.Browser.mozilla && dorado.Browser.version >= 8) {
			// FF8莫名其妙的向setTimeout、setInterval的闭包函数中传入timerID
			return setInterval(function() {
				(dorado.Core.scopify(scope, fn))();
			}, timeMillis);
		}
		else {
			return setInterval(dorado.Core.scopify(scope, fn), timeMillis);
		}
	},

	/**
	 * 克隆一个对象。
	 * <p>
	 * 如果被克隆的对象本身支持clone()方法，那么此处将直接使用该对象自身的clone()来完成克隆。
	 * 否则会使用默认的规则，按照类似属性反射的方式对对象进行浅克隆。
	 * </p>
	 * @param {Object} obj 将被克隆的对象。
	 * @param {boolean} [deep] 是否执行深度克隆。
	 * @return {Object} 对象的克隆。
	 */
	clone: function(obj, deep) {

		function doClone(obj, deep) {
			if (obj == null || typeof(obj) != "object") return obj;
			if (typeof obj.clone == "function") {
				return obj.clone(deep);
			}
			if (obj instanceof Date) {
				return new Date(obj.getTime());
			}
			else {
				var constr = obj.constructor;
				var cloned = new constr();
				for(var attr in obj) {
					if (cloned[attr] === undefined) {
						var v = obj[attr];
						if (deep) v = doClone(v, deep);
						cloned[attr] = v;
					}
				}
				return cloned;
			}
		}

		return doClone(obj, deep);
	}
};

(function() {

	/**
	 * @name $create
	 * @function
	 * @description document.createElement()方法的快捷方式。
	 * @param {String} tagName 要创建的DOM元素的标签名。
	 * @return {HTMLElement} 新创建的DOM元素。
	 *
	 * @example
	 * var div = $create("DIV"); // 相当于document.createElement("DIV")
	 */
	window.$create = (dorado.Browser.msie && dorado.Browser.version < 9) ? document.createElement : function(arg) {
		return document.createElement(arg);
	};

	/**
	 * @name $scopify
	 * @function
	 * @description dorado.Core.scopify()方法的快捷方式。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @return {Function} 代理函数。
	 *
	 * @see dorado.Core.scopify
	 *
	 * @example
	 * var s = "hello!";
	 * $scopify(s, "alert(this)")(); // should say "hello!"
	 *
	 * @example
	 * var s = "hello!";
	 * $scopify(s, function(){
	 *	 alert(this);
	 * })(); // should say "hello!"
	 */
	window.$scopify = dorado.Core.scopify;

	/**
	 * @name $setTimeout
	 * @function
	 * @description dorado.Core.setTimeout()方法的快捷方式。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @param {int} timeMillis 延时的时长（毫秒数）。
	 * @return {int} 延时任务的id。
	 *
	 * @see dorado.Core.setTimeout
	 *
	 * @example
	 * // should say "hello!" after one second.
	 * var s = "hello!";
	 * $setTimeout(s, function() {
	 *	 alert(this);
	 * }, 1000);
	 */
	window.$setTimeout = dorado.Core.setTimeout;

	/**
	 * @name $setInterval
	 * @function
	 * @description dorado.Core.setInterval()方法的快捷方式。
	 * @param {Object} scope 调用时this对象。
	 * @param {Function|String} fn 要处理的函数或文本形式表示的代码片段。
	 * @param {int} timeMillis 定时任务的间隔（毫秒数）。
	 * @return {int} 定时任务的id。
	 *
	 * @see dorado.Core.setInterval
	 */
	window.$setInterval = dorado.Core.setInterval;

})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function () {

	var CLASS_REPOSITORY = {};
	var UNNAMED_CLASS = "#UnnamedClass";

	function newClassName(prefix) {
		var i = 1;
		while (CLASS_REPOSITORY[prefix + i])
			i++;
		return prefix + i;
	}

	function adapterFunction(fn) {
		var adapter = function () {
			return fn.apply(this, arguments);
		};
		adapter._doradoAdapter = true;
		return adapter;
	}

	function cloneDefintions(defs) {
		var newDefs = {};
		for (var p in defs) {
			if (defs.hasOwnProperty(p)) {
				newDefs[p] = dorado.Object.apply({}, defs[p]);
			}
		}
		return newDefs;
	}

	function overrideDefintions(subClass, defProp, defs, overwrite) {
		if (!defs) return;
		var sdefs = subClass.prototype[defProp];
		if (!sdefs) {
			subClass.prototype[defProp] = cloneDefintions(defs);
		} else {
			for (var p in defs) {
				if (defs.hasOwnProperty(p)) {
					var odef = defs[p];
					if (odef === undefined) return;
					var cdef = sdefs[p];
					if (cdef === undefined) sdefs[p] = cdef = {};
					for (var m in odef) {
						if (odef.hasOwnProperty(m) && (overwrite || cdef[m] === undefined)) {
							var odefv = odef[m];
							if (typeof odefv == "function") {
								// if (odefv.declaringClass) odefv = adapterFunction(odefv);
								if (!odefv.declaringClass) {
									odefv.declaringClass = subClass;
									odefv.methodName = m;
									odefv.definitionType = defProp;
									odefv.definitionName = p;
								}
							}
							cdef[m] = odefv;
						}
					}
				}
			}
		}
	}

	function override(subClass, overrides, overwrite) {
		if (!overrides) return;
		if (overwrite === undefined) overwrite = true;

		var subp = subClass.prototype;
		for (var p in overrides) {
			var override = overrides[p];
			if (p == "ATTRIBUTES" || p == "EVENTS") {
				overrideDefintions(subClass, p, override, overwrite);
				continue;
			}
			/*
			 // for debug
			 if (!overwrite && subp[p] !== undefined && overrides[p] !== undefined && subp[p] != overrides[p]) {
			 window._skipedOverWriting = (window._skipedOverWriting || 0) + 1;
			 if (window._skipedOverWriting < 10) alert(subClass.className + ",  " + p + ",  " + overrides.constructor.className + "\n=============\n" + subp[p] + "\n=============\n" + overrides[p]);
			 }
			 */
			if (subp[p] === undefined || overwrite) {
				if (typeof override == "function") {
					// if (override.declaringClass) override = adapterFunction(override);
					if (!override.declaringClass) {
						override.declaringClass = subClass;
						override.methodName = p;
					}
				}
				subp[p] = override;
			}
		}
	};

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 用于封装一些对象操作的类。
	 * @static
	 */
	dorado.Object = {

		/**
		 * 创建一个命名空间。
		 * @param {String} name 命名空间的名称。例如"dorado.sample"。
		 * @see $namespace
		 *
		 * @example
		 * // 创建新的名为"dorado.sample"的命名空间。
		 * dorado.Object.createNamespace("dorado.sample");
		 *
		 * // 使用新创建的命名空间。
		 * dorado.sample.MyClass = function() {
		 * };
		 */
		createNamespace: function (name) {
			var names = name.split('.');
			var parent = window;
			for (var i = 0; i < names.length; i++) {
				var n = names[i];
				var p = parent[n];
				if (p === undefined) {
					parent[n] = p = {};
				}
				parent = p;
			}
			return parent;
		},

		/**
		 * 创建并返回一个新的类。
		 * @param {Object} p 新类的prototype。 在该参数的子属性中有下列几个需特别注意：
		 * <ul>
		 * <li>constructor - 其中新类的构造方法可利用此属性来定义。</li>
		 * <li>$className - 类的名称。该名称并不会对类的执行逻辑造成影响，但是定义一个有效的名称对于JavaScript的调试将有很重要的意义。 </li>
		 * </ul>
		 * @return {Object} 新的类。
		 * @see $class
		 *
		 * @example
		 * var MyClass = dorado.Object.createClass( {
		 * 	$className : "MyClass",
		 *
		 * 	// 构造方法
		 * 	constructor : function(message) {
		 * 		this.message = message;
		 * 	},
		 * 	getMessage : function() {
		 * 		return this.message;
		 * 	}
		 * });
		 * var foo = new Foo("Hello world!");
		 * alert(foo.getMessage()); // should say "Hello world!"
		 */
		createClass: function (p) {
			var constr = p.constructor;
			if (constr === Object) constr = new Function();
			constr.className = p.$className || newClassName(UNNAMED_CLASS);
			delete p.$className;

			for (var m in p) {
				if (p.hasOwnProperty(m)) {
					var v = p[m];
					if (typeof v == "function") {
						// if (v.declaringClass) p[m] = v = adapterFunction(v);
						if (!v.declaringClass) {
							v.declaringClass = constr;
							v.methodName = m;
						}
					}
				}
			}

			constr.prototype = p;
			CLASS_REPOSITORY[constr.className] = constr;
			return constr;
		},

		/**
		 * 将一个类或对象中的所有属性和方法改写到另一个类中。
		 * @function
		 * @param {Object} subClass 被改写的类。
		 * @param {Object} overrides 包含要改写的属性和方法的类或对象。
		 * @param {boolean} [overwrite=true] 是否允许覆盖subClass中已存在的同名属性或方法。默认为不允许覆盖。
		 */
		override: override,

		/**
		 * 从指定的父类派生出一个新的子类。
		 * <p>
		 * 通过此方法继承出的子类具有以下的扩展属性：
		 * <ul>
		 * <li>superClass - {Prototype} 第一个父类。</li>
		 * <li>superClasses - {Prototype[]} 所有父类的数组。</li>
		 * </ul>
		 * 上述属性的具体用法请参见示例。
		 * </p>
		 * @function
		 * @param {Prototype|Prototype[]} superClass 父类或父类的数组。
		 * 如果此处定义了多个父类，那么dorado将以数组中的第一个父类作为主要的父类，新类的superClass属性将指向第一个父类。
		 * 而其他父类中属性和方法将被继承到新类中，且后面父类中的方法和属性不会覆盖前面的同名方法或属性。
		 * @param {Object} [overrides] 包含一些属性和方法的类或对象，这些属性和方法将被改写进新生成的子类。 在该参数的子属性中有下列几个需特别注意：
		 * <ul>
		 * <li>constructor - 其中新类的构造方法可利用此属性来定义。</li>
		 * <li>$className -
		 * 类的名称。该名称并不会对类的执行逻辑造成影响，但是定义一个有效的名称对于JavaScript的调试将有很重要的意义。 </li>
		 * </ul>
		 * @return {Prototype} 新的子类。
		 *
		 * @see $extend
		 *
		 * @example
		 * // 从SuperClass派生并得到MyClass。
		 * var MyClass = dorado.Object.extend(SuperClass, {
		 * 	$className : "MyClass",
		 * 	//constructor是一个特殊的方法用于声明子类的构造方法。
		 * 	constructor : function() {
		 * 		//调用父类的构造方法。
		 * 		SubClass.superClass.constructor.call(this, arguments);
		 * 		this.children = [];
		 * },
		 *
		 * // 这是一个子类自有的方法。
		 * 	getChildren : function() {
		 * 		return this.children;
		 * 	}
		 * });
		 */
		extend: (function () {
			var oc = Object.prototype.constructor;
			return function (superClass, overrides) {
				var sc, scs;
				if (superClass instanceof Array) {
					scs = superClass;
					sc = superClass[0];
				} else {
					sc = superClass;
				}

				var subClass = (overrides && overrides.constructor != oc) ? overrides.constructor : function () {
					sc.apply(this, arguments);
				};

				var fn = new Function();
				var sp = fn.prototype = sc.prototype;

				// 当某超类不是通过dorado的方法声明的时，确保其能够符合dorado的基本规范。
				if (!sc.className) {
					sp.constructor = sc;
					sc.className = newClassName(UNNAMED_CLASS);
					sc.declaringClass = sp;
					sc.methodName = "constructor";
				}

				var subp = subClass.prototype = new fn();
				subp.constructor = subClass;
				subClass.className = overrides.$className || newClassName((sc.$className || UNNAMED_CLASS) + '$');
				subClass.superClass = sc;
				subClass.declaringClass = subClass;
				subClass.methodName = "constructor";

				delete overrides.$className;
				delete overrides.constructor;

				// process attributes, dirty code
				var attrs = subp["ATTRIBUTES"];
				if (attrs) {
					subp["ATTRIBUTES"] = cloneDefintions(attrs);
				}

				// process avents, dirty code
				var events = subp["EVENTS"];
				if (events) {
					subp["EVENTS"] = cloneDefintions(events);
				}

				var ps = [sc];
				if (scs) {
					for (var i = 1, p; i < scs.length; i++) {
						p = scs[i].prototype;
						override(subClass, p, false);
						ps.push(scs[i]);
					}
				}
				subClass.superClasses = ps;

				override(subClass, overrides, true);

				CLASS_REPOSITORY[subClass.className] = subClass;
				return subClass;
			};
		})(),

		/**
		 * 迭代给定对象的每一个属性。
		 * @param {Object} object 要迭代的对象。
		 * @param {Function} fn 用于监听每一个属性的迭代方法。<br>
		 * 该方法具有下列两个参数：
		 * <ul>
		 * <li>p - {String} 当前迭代的属性名。</li>
		 * <li>v - {Object} 当前迭代的属性值。 </li>
		 * </ul>
		 * 该方法中的this对象即为被迭代的对象。
		 */
		eachProperty: function (object, fn) {
			if (object && fn) {
				for (var p in object)
					fn.call(object, p, object[p]);
			}
		},

		/**
		 * 将源对象中所有的属性复制（覆盖）到目标对象中。
		 * @param {Object} target 目标对象。
		 * @param {Object} source 源对象。
		 * @param {boolean|Function} [options] 选项。
		 * 此参数具有如下两种定义方式：
		 * <ul>
		 * <li>此值的类型是逻辑值时，表示是否覆盖目标对象中原有的属性值。
		 * 如果设置此参数为false，那么只有当目标对象原有的属性值未定义或值为undefined时，才将源对象中的属性值写入目标对象。
		 * 如果不定义此选项则系统默认按照覆盖方式处理。</li>
		 * <li>此值的类型是Function时，表示用于监听每一个属性的赋值动作的拦截方法。</li>
		 * </ul>
		 * @return {Object} 返回目标对象。
		 *
		 * @example
		 * // p, v参数即当前正在处理的属性名和属性值。
		 * function listener(p, v) {
		 * 	if (p == "prop2") {
		 * 		this[p] = v * 2; // this即apply方法的target参数对象。
		 * 		return false; // 返回false表示通知apply方法跳过对此属性的后续处理。
		 * 	}
		 * 	else if (p == "prop3") {
		 * 		return false; // 返回false表示通知apply方法跳过对此属性的后续处理。
		 * 	}
		 * }
		 *
		 * var target = {};
		 * var source = {
		 * 	prop1 : 100,
		 * 	prop2 : 200,
		 * 	prop3 : 300
		 * };
		 * dorado.Object.apply(target, source, listener);
		 * //此时，target应为 { prop1: 100, prop2: 400 }
		 */
		apply: function (target, source, options) {
			if (source) {
				for (var p in source) {
					if (typeof options == "function" && options.call(target, p, source[p]) === false) continue;
					if (options === false && target[p] !== undefined) continue;
					target[p] = source[p];
				}
			}
			return target;
		},

		/**
		 * 判断一个对象实例是否某类或接口的实例。
		 * <p>
		 * 提供此方法的原因是因为dorado的对象集成机制是支持多重继承的，
		 * 而Javascript中原生的instanceof操作符只能支持对多重继承中第一个超类型的判断。
		 * 因此，当我们需要判断多重继承中的后几个超类型时，必须使用此方法。<br>
		 * 需要注意的是instanceof操作符的运行效率远高于此方法。
		 * </p>
		 * @param {Object} object 要判断的对象实例。
		 * @param {Function} type 类或接口。注意：此处传入的超类或接口必须是通过dorado定义的。
		 * @return {boolean} 是否是给定类或接口的实例。
		 */
		isInstanceOf: function (object, type) {
			function hasSuperClass(superClasses) {
				if (!superClasses) return false;
				if (superClasses.indexOf(type) >= 0) return true;
				for (var i = 0; i < superClasses.length; i++) {
					if (hasSuperClass(superClasses[i].superClasses)) return true;
				}
				return false;
			}

			if (!object) return false;
			var b = false;
			if (type.className) b = object instanceof type;
			if (!b) {
				var t = object.constructor;
				if (t) b = hasSuperClass(t.superClasses);
			}
			return b;
		},

		/**
		 * 对一个对象进行浅度克隆。
		 * @param {Object} object 要克隆的对象。
		 * @param {Object} [options] 执行选项。
		 * @param {Function} [options.onCreate] 用于创建克隆对象的回调函数。
		 * @param {Function} [options.onCopyProperty] 用于拦截每一个属性复制的回调函数。
		 * @return {Object} 新的克隆对象。
		 */
		clone: function (object, options) {
			if (typeof object == "object") {
				var objClone, options = options || {};
				if (options.onCreate) objClone = new options.onCreate(object);
				else objClone = new object.constructor();
				for (var p in object) {
					if (!options.onCopyProperty || options.onCopyProperty(p, object, objClone)) {
						objClone[p] = object[p];
					}
				}
				objClone.toString = object.toString;
				objClone.valueOf = object.valueOf;
				return objClone;
			} else {
				return object;
			}
		},

		hashCode: function (object) {
			if (object == null) return 0;

			var strKey = (typeof object) + '|' + dorado.JSON.stringify(object), hash = 0;
			for (i = 0; i < strKey.length; i++) {
				var c = strKey.charCodeAt(i);
				hash = ((hash << 5) - hash) + c;
				hash = hash & hash; // Convert to 32bit integer
			}
			return hash;
		}

	};

	/**
	 * @name $namespace
	 * @function
	 * @description dorado.Object.createNamespace()方法的快捷方式。
	 * 详细用法请参考dorado.Object.createNamespace()的说明。
	 * @see dorado.Object.createNamespace
	 *
	 * @example
	 * // 创建新的名为"dorado.sample"的命名空间。
	 * $namespace("dorado.sample");
	 *
	 * // 使用新创建的命名空间。
	 * dorado.sample.MyClass = function() {
	 * };
	 */
	window.$namespace = dorado.Object.createNamespace;

	/**
	 * @name $class
	 * @function
	 * @description dorado.Object.createClass()方法的快捷方式。
	 * 详细用法请参考dorado.Object.createClass()的说明。
	 * @see dorado.Object.createClass
	 *
	 * @example
	 * var MyClass = $class("MyClass"， {
	 * 		// 构造方法
	 * 		constructor: function(message) {
	 * 			this.message = message;
	 * 		},
	 * 		getMessage: function() {
	 * 			return this.message;
	 * 		}
	 * 	});
	 * var foo = new Foo("Hello world!");
	 * alert(foo.getMessage());    // should say "Hello world!";
	 */
	window.$class = dorado.Object.createClass;

	/**
	 * @name $extend
	 * @function
	 * @description dorado.Object.extend()方法的快捷方式。
	 * 详细用法请参考dorado.Object.extend()的说明。
	 * @see dorado.Object.extend
	 *
	 * @example
	 * // 从SuperClass派生并得到MyClass。
	 * var MyClass = $extend("MyClass", SuperClass, {
	 * 	// constructor是一个特殊的方法用于声明子类的构造方法。
	 * 	constructor : function() {
	 * 		// 调用父类的构造方法。
	 * 		SubClass.superClass.constructor.call(this, arguments);
	 * 		this.children = [];
	 * 	},
	 *
	 * 	// 这是一个子类自有的方法。
	 * 	getChildren : function() {
	 * 		return this.children;
	 * 	}
	 * });
	 */
	window.$extend = dorado.Object.extend;

	/**
	 * @name $getSuperClass
	 * @function
	 * @description 返回当前对象的超类。对于多重继承而言，此方法返回第一个超类。
	 * <p>
	 * 注意：此方法的调用必须放在类方法内部才有效。
	 * </p>
	 * @return {Function} 超类。
	 */
	var getSuperClass = window.$getSuperClass = function () {
		var fn = getSuperClass.caller, superClass;
		if (fn.declaringClass) superClass = fn.declaringClass.superClass;
		return superClass || {};
	};

	/**
	 * @name $getSuperClasses
	 * @function
	 * @description 返回当前对象的超类的数组。
	 * <p>
	 * 注意：此方法的调用必须放在类方法内部才有效。
	 * </p>
	 * @return {Prototype[]} 超类的数组。
	 */
	var getSuperClasses = window.$getSuperClasses = function () {
		var fn = getSuperClasses.caller, superClass;
		if (dorado.Browser.opera && dorado.Browser.version < 10) fn = fn.caller;
		if (fn.caller && fn.caller._doradoAdapter) fn = fn.caller;

		if (fn.declaringClass) superClasses = fn.declaringClass.superClasses;
		return superClasses || [];
	};

	/**
	 * @name $invokeSuper
	 * @function
	 * @description 调用当前方法在超类中的实现逻辑。
	 * <p>
	 * 注意此方法的调用必须放在类方法内部才有效。<br>
	 * 另外，此方法必须通过call语法进行调用，见示例。
	 * </p>
	 * @param {Object} scope 调用超类方法时的宿主对象。一般应直接传入this。
	 * @param {Object[]} [args] 调用超类方法时的参数数组。很多情况下我们可以直接传入arguments。
	 *
	 * @example
	 * $invokeSuper.call(this, arguments); // 较简单的调用方式
	 * $invokeSuper.call(this, [ "Sample Arg", true ]); // 自定义传给超类方法的参数数组
	 */
	var invokeSuper = window.$invokeSuper = function (args) {
		var fn = invokeSuper.caller;
//		if (dorado.Browser.opera && dorado.Browser.version < 10) fn = fn.caller;
		if (fn.caller && fn.caller._doradoAdapter) fn = fn.caller;

		if (fn.declaringClass) {
			var superClasses = fn.declaringClass.superClasses;
			if (!superClasses) return;

			var superClass, superFn;
			for (var i = 0; i < superClasses.length; i++) {
				superClass = superClasses[i].prototype;
				if (fn.definitionType) {
					superFn = superClass[fn.definitionType][fn.definitionName][fn.methodName];
				} else {
					superFn = superClass[fn.methodName];
				}
				if (superFn) {
					return superFn.apply(this, args || []);
				}
			}
		}
	};
	invokeSuper.methodName = "$invokeSuper";

})();
/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @name dorado.Setting
	 * @class dorado的配置对象，用于维护一组dorado运行时所需的参数。
	 * @static
	 * @see $setting
	 *
	 * @example
	 * var debugEnabled = dorado.Setting["common.debugEnabled"]; // 取得一个参数值
	 */
	// =====
	
	var doradoServierURI = ">dorado/view-service";
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @name $setting
	 * @property
	 * @description dorado.Setting的快捷方式。
	 * @type dorado.Setting
	 * @see dorado.Setting
	 *
	 * @example
	 * var debugEnabled = $setting["common.debugEnabled"]; // 相当于dorado.Setting["common.debugEnabled"]
	 */
	dorado.Setting = {
		"common.defaultDateFormat": "Y-m-d",
		"common.defaultTimeFormat": "H:i:s",
		"common.defaultDateTimeFormat": "Y-m-d H:i:s",

		"common.defaultDisplayDateFormat": "Y-m-d",
		"common.defaultDisplayTimeFormat": "H:i:s",
		"common.defaultDisplayDateTimeFormat": "Y-m-d H:i:s",
		
		"ajax.defaultOptions": {
			batchable: true
		},
		"ajax.dataTypeRepositoryOptions": {
			url: doradoServierURI,
			method: "POST",
			batchable: true
		},
		"ajax.dataProviderOptions": {
			url: doradoServierURI,
			method: "POST",
			batchable: true
		},
		"ajax.dataResolverOptions": {
			url: doradoServierURI,
			method: "POST",
			batchable: true
		},
		"ajax.remoteServiceOptions": {
			url: doradoServierURI,
			method: "POST",
			batchable: true
		},
		"longPolling.pollingOptions": {
			url: doradoServierURI,
			method: "GET",
			batchable: false
		},
		"longPolling.sendingOptions": {
			url: doradoServierURI,
			method: "POST",
			batchable: true
		},
		"ajax.loadViewOptions": {
			url: doradoServierURI,
			method: "GET",
			batchable: true
		},
		"dom.useCssShadow": true,
		"widget.skin": "~current",
		"widget.panel.useCssCurveBorder": true,
		"widget.datepicker.defaultYearMonthFormat": "m &nbsp;&nbsp; Y"
	};
	
	if (window.$setting instanceof Object) {
		dorado.Object.apply(dorado.Setting, $setting);
	}
	
	var contextPath = dorado.Setting["common.contextPath"];
	if (contextPath) {
		if (contextPath.charAt(contextPath.length - 1) != '/') contextPath += '/';
	}
	else {
		contextPath = '/';
	}
	dorado.Setting["common.contextPath"] = contextPath;
	
	window.$setting = dorado.Setting;
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 抽象的Dorado异常。
 * @abstract
 */
dorado.AbstractException = $class({
	$className: "dorado.AbstractException",

	constructor: function () {
		dorado.Exception.EXCEPTION_STACK.push(this);

		if (dorado.Browser.msie || dorado.Browser.mozilla) {
			/* 强行接管window.onerror事件，须建议用户不要自行声明此事件 */
			window.onerror = function (message, url, line) {
				var result = false;
				if (dorado.Exception.EXCEPTION_STACK.length > 0) {
					var e;
					while (e = dorado.Exception.EXCEPTION_STACK.peek()) {
						dorado.Exception.processException(e);
					}
					result = true;
				}
				window.onerror = null;
				return result;
			};
		}

		$setTimeout(this, function () {
			if (dorado.Exception.EXCEPTION_STACK.indexOf(this) >= 0) {
				dorado.Exception.processException(this);
			}
		}, 50);
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class dorado异常的基类。
 * <p>
 * 此类可以实例化并抛出。
 * 虽然JavaScript支持抛出任何类型的对象，但是在dorado的框架下抛出dorado.Exception或其派生类的实例可以获得额外的好处。
 * 例如：可以通过dorado.Exception获得错误堆栈信息，以辅助对错误的定位和调试。
 * </p>
 * <p>
 * 需要特别注意的是dorado.Excpeption对象一旦被创建，即便没有抛出(throw)，最终都会激活{@link dorado.Exception.processException}方法，
 * 默认情况下此异常信息一定会弹出错误提示(dorado.AbortException)。<br>
 * 当然，尽管dorado.Excpeption一旦被创建会自动引起错误提示，大部分情况下我们仍需要将其抛出(throw)。
 * 否则当前程序仍会按照正常的情况继续向后执行，并不会被该异常打断。
 * </p>
 * @extends dorado.AbstractException
 * @param {String} [message] 异常信息。
 *
 * @example
 * throw new dorado.Exception("My Message.");
 */
dorado.Exception = $extend(dorado.AbstractException, /** @scope dorado.Exception.prototype */ {
	$className: "dorado.Exception",

	/**
	 * dorado生成的错误堆栈信息。
	 * @name dorado.Exception#stack
	 * @property
	 * @type String[]
	 */
	/**
	 * 系统提供的错误堆栈信息。目前仅在FireFox、Mozilla下可以得到。
	 * @name dorado.Exception#systemStack
	 * @property
	 * @type String[]
	 */
	// =====

	constructor: function (message) {
		this.message = message || this.$className;
		if ($setting["common.debugEnabled"]) this._buildStackTrace();
		$invokeSuper.call(this, arguments);
	},

	_buildStackTrace: function () {
		var stack = [];
		var funcCaller = dorado.Exception.caller, callers = [];
		while (funcCaller && callers.indexOf(funcCaller) < 0) {
			callers.push(funcCaller);
			stack.push(dorado.getFunctionDescription(funcCaller));
			funcCaller = funcCaller.caller;
		}
		this.stack = stack;

		if (dorado.Browser.mozilla || dorado.Browser.chrome) {
			var stack = new Error().stack;
			if (stack) {
				stack = stack.split('\n');
				this.systemStack = stack.slice(2, stack.length - 1);
			}
		}
	},

	/**
	 * 将传入的调用堆栈信息格式化为较便于阅读的文本格式。
	 * @param {String[]} stack 调用堆栈信息。
	 * @return {String} 格式化后的调用堆栈信息。
	 * @see dorado.Exception.formatStack
	 */
	formatStack: function (stack) {
		return dorado.Exception.formatStack(stack);
	},

	toString: function () {
		return this.message;
	}
});

/**
 * 将传入的调用堆栈信息格式化为较便于阅读的文本格式。
 * @param {String[]} stack 调用堆栈信息。
 * @return {String} 格式化后的调用堆栈信息。
 */
dorado.Exception.formatStack = function (stack) {
	var msg = "";
	if (stack) {
		if (typeof stack == "string") {
			msg = stack;
		} else {
			for (var i = 0; i < stack.length; i++) {
				if (i > 0) msg += '\n';
				var trace = jQuery.trim(stack[i]);
				if (trace.indexOf("at ") != 0) {
					trace = "at " + trace;
				}
				msg += " > " + trace;
				if (i > 255) {
					msg += "\n > ... ... ...";
					break;
				}
			}
		}
	}
	return msg;
};

//=====

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 终止异常。
 * <p>
 * 这是一个特殊的异常对象，用于通知系统放弃当前的操作。该异常是哑异常，抛出后不会带来任何默认的异常提示。
 * </p>
 * @extends dorado.Exception
 */
dorado.AbortException = $extend(dorado.Exception, {
	$className: "dorado.AbortException"
});

//=====

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 特殊的用于执行一段JavaScript的异常。
 * @extends dorado.AbstractException
 * @param {String} script 可执行的脚本。
 */
dorado.RunnableException = $extend(dorado.AbstractException, {
	$className: "dorado.RunnableException",

	/**
	 *可执行的脚本。
	 * @name dorado.RunnableException#script
	 * @property
	 * @type String
	 */
	// =====

	constructor: function (script) {
		this.script = script;
		$invokeSuper.call(this, arguments);
	},

	toString: function () {
		return this.script;
	}
});

//=====

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 支持自动从资源库中提取消息的异常。
 * @extends dorado.Exception
 * @param {String} path 由命名空间+资源项名称组成的资源路径。
 * @param {Object...} [args] 一到多个参数。
 * @see $resource
 */
dorado.ResourceException = $extend(dorado.Exception, {
	$className: "dorado.ResourceException",

	constructor: function () {
		$invokeSuper.call(this, [$resource.apply(this, arguments)]);
	}
});

//=====

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 来自外部系统的异常信息。
 * @extends dorado.Exception
 * @param {String} message 异常信息。
 * @param {String} [exceptionType] 外部系统中报出的异常类型。
 * @param {String} [remoteStack] 外部系统中报出的异常堆栈。
 */
dorado.RemoteException = $extend(dorado.Exception, {
	$className: "dorado.RemoteException",

	/**
	 * 异常类型。对于来自Java的异常而言此属性为异常对象的className。
	 * @name dorado.RemoteException#exceptionType
	 * @property
	 * @type String
	 */
	/**
	 * 外部系统中的错误堆栈信息。对于来自Java的异常而言即异常堆栈中的StackTrace信息。
	 * @name dorado.Exception#remoteStack
	 * @property
	 * @type String[]
	 */
	// =====

	constructor: function (message, exceptionType, remoteStack) {
		$invokeSuper.call(this, [message]);
		this.exceptionType = exceptionType;
		this.remoteStack = remoteStack;
	}
});

//=====

dorado.Exception.EXCEPTION_STACK = [];
dorado.Exception.IGNORE_ALL_EXCEPTIONS = false;

dorado.Exception.getExceptionMessage = function (e) {
	if (!e || e instanceof dorado.AbortException) return null;
	var msg;
	if (e instanceof dorado.Exception) msg = e.message;
	else if (e instanceof Error) msg = e.message;
	else msg = e;
	return msg;
};

/**
 * 处理一个异常对象。
 * <p>
 * 注意：此方法需要处理的异常对象包括所有JavaScript所支持抛出的对象。
 * </p>
 * @param {dorado.Exception|Object} e 异常对象。
 */
dorado.Exception.processException = function (e) {
	if (dorado.Exception.IGNORE_ALL_EXCEPTIONS || dorado.windowClosed) return;
	
	if (!e) dorado.Exception.removeException(e);
	if (e instanceof dorado.AbortException) {
		dorado.Exception.removeException(e);
		return;
	}
	
	if (dorado._fireOnException(e) === false) {
		return;
	}

	dorado.Exception.removeException(e);

	if (e instanceof dorado.RunnableException) {
		eval(e.script);
		fn.call(window, e);	// 此处的fn是在e.script中声明的
	} else {
		var delay = e._processDelay || 0;
		setTimeout(function () {
			if (dorado.windowClosed) return;

			var msg = dorado.Exception.getExceptionMessage(e);
			if ($setting["common.showExceptionStackTrace"]) {
				if (e instanceof dorado.Exception) {
					if (e.stack) msg += "\n\nDorado Stack:\n" + dorado.Exception.formatStack(e.stack);
					if (e.remoteStack) msg += "\n\nRemote Stack:\n" + dorado.Exception.formatStack(e.remoteStack);
					if (e.systemStack) msg += "\n\nSystem Stack:\n" + dorado.Exception.formatStack(e.systemStack);
				} else if (e instanceof Error) {
					if (e.stack) msg += "\n\nSystem Stack:\n" + dorado.Exception.formatStack(e.stack);
				}
			}

			if (window.console) {
				if (console.error) console.error(msg);
				else console.log(msg);
			}

			if (!dorado.Exception.alertException || !document.body) {
				dorado.Exception.removeException(e);
				alert(dorado.Exception.getExceptionMessage(e));
			} else {
				try {
					dorado.Exception.alertException(e);
				}
				catch (e2) {
					dorado.Exception.removeException(e2);
					alert(dorado.Exception.getExceptionMessage(e));
				}
			}
		}, delay);
	}
};

/**
 * 从系统的异常堆栈中移除一个异常对象。
 * @param {dorado.Exception|Object} e 异常对象。
 */
dorado.Exception.removeException = function (e) {
	dorado.Exception.EXCEPTION_STACK.remove(e);
};

dorado._exceptionListeners;

/**
 * 当系统中有异常发生时触发的方法。
 * @param {Function} listener 监听器。
 * 此监听器支持一个传入的参数arg，该arg参数具有下列子属性：
 * <ul>
 * <li>exception - 异常对象。</li>
 * <li>processDefault - 是否允许系统继续按照默认的方式来处理该异常。</li>
 * </ul>
 */
dorado.onException = function(listener) {
	if (!dorado._exceptionListeners) {
		dorado._exceptionListeners = [];
	}
	dorado._exceptionListeners.push(listener);
};

dorado._fireOnException = function(e) {
	if (dorado._exceptionListeners && dorado._exceptionListeners.length) {
		var arg = {
			exception: e,
			processDefault: true
		};
		dorado._exceptionListeners.each(function(listener) {
			if (listener.call(window, arg) === false) {
				return false;
			}
		});
		if (!arg.processDefault) {
			dorado.Exception.removeException(e);
			return false;
		}
	}
	return true;
};
/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	dorado.AttributeException = $extend(dorado.ResourceException, {
		$className: "dorado.AttributeException"
	});

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 支持get/set属性的对象的通用接口。
	 *        <p>
	 *        对于实现了此接口的子对象，用户可在其prototype的ATTRIBUTES中定义若干个属性。
	 *        然后，用后可利用此接口提供的get、set方法来读取和设置属性值。
	 *        </p>
	 *        <p>
	 *        此种对象通过一个名为ATTRIBUTES的特殊属性来声明的给类支持的属性。
	 *        声明时，每一个被声明的属性应作为ATTRIBUTES对象的一个子属性，该属性的值为一个用于描述属性的JSON对象。该JSON对象中支持下列子属性：
	 *        <ul>
	 *        <li>getter - {Function} 该属性对应的getter方法。
	 *        该方法具有一个传入参数，为属性名。方法的返回值为外界读取到的属性值。</li>
	 *        <li>setter - {Function} 该属性对应的setter方法。
	 *        该方法具有两个传入参数，依次为要设置的属性值和属性名。</li>
	 *        <li>readOnly - {boolean} 该属性是否只读。</li>
	 *        <li>writeOnly - {boolean} 该属性是否只写。</li>
	 *        <li>writeOnce - {boolean} 该属性是否只允许被写入一次。</li>
	 *        <li>defaultValue - {Object|Function} 该属性的默认值。
	 *        如果默认值是一个Function，那么系统将调用该Function，以其返回值作为属性的默认值。</li>
	 *        见:{@link dorado.AttributeSupport#getAttributeWatcher},
	 *        {@link dorado.AttributeWatcher}</li>
	 *        </ul>
	 *        </p>
	 *
	 * @abstract
	 *
	 * @example
	 * // 读写类属性。
	 * oop.set("visible", true); // 设置一个属性
	 * oop.get("visible"); // 读取一个属性
	 *
	 * @example
	 * // 声明类属性。
	 * var SampleClass = $class({
	 * 	ATTRIBUTES: {
	 * 		visible: {}, // 声明一个简单的属性
	 * 		label: { // 声明一个带有getter方法的属性
	 * 			getter: function(attr) {
	 * 				... ...
	 * 			}
	 * 		},
	 * 		status: { // 声明一个带有setter方法的只读属性
	 * 			readOnly: true,
	 * 			setter: function(value, attr) {
	 * 				... ...
	 * 			}
	 * 		}
	 * 	}
	 * });
	 */
	dorado.AttributeSupport = $class(/** @scope dorado.AttributeSupport.prototype */
		{
			$className: "dorado.AttributeSupport",

			/**
			 * 用于声明该对象中所支持的所有Attribute。<br>
			 * 此属性中的对象一般由dorado系统自动生成，且往往一个类型的所有实例都共享同一个EVENTS对象。
			 * 因此，如无特殊需要，我们不应该在运行时手动的修改此对象中的内容。
			 *
			 * @type Object
			 *
			 * @example
			 * // 获取某对象的caption属性的声明。
			 * var attributeDef = oop.ATTRIBUTES.caption。
			 * // 判断该属性是否只读
			 * if (attributeDef.readOnly) { ... ... }
			 */
			ATTRIBUTES: /** @scope dorado.AttributeSupport.prototype */
			{
				/**
				 * 对象的标签。
				 * <p>
				 * 开发人员可以为一个对象定义一到多个String型的标签，以便于后面快速的查找到一个或一批具有指定标签的对象。
				 * </p>
				 *
				 * @type String|String[]
				 * @attribute
				 * @see dorado.TagManager
				 */
				tags: {
					setter: function(tags) {
						if (typeof tags == "string") {
							tags = tags.split(',');
						}
						if (this._tags) {
							dorado.TagManager.unregister(this);
						}
						this._tags = tags;
						if (tags) {
							dorado.TagManager.register(this);
						}
					}
				}
			},

			EVENTS: /** @scope dorado.AttributeSupport.prototype */
			{

				/**
				 * 当对象中的某属性值被改变时触发的事件。
				 *
				 * @param {Object}
				 *            self 事件的发起者，即对象本身。
				 * @param {Object}
				 *            arg 事件参数。
				 * @param {String}
				 *            arg.attribute 发生改变的属性名。
				 * @param {Object}
				 *            arg.value 新的属性值。
				 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
				 * @event
				 */
				onAttributeChange: {}
			},

			constructor: function() {
				var defs = this.ATTRIBUTES;
				for(var p in defs) {
					var def = defs[p];
					if (def && def.defaultValue != undefined && this['_' + p] == undefined) {
						var dv = def.defaultValue;
						this['_' + p] = (typeof dv == "function" && !def.dontEvalDefaultValue) ? dv() : dv;
					}
				}
			},

			/**
			 * 返回与该对象关联的属性观察者。
			 *
			 * @return {dorado.AttributeWatcher} 属性观察者。
			 */
			getAttributeWatcher: function() {
				if (!this.attributeWatcher) {
					this.attributeWatcher = new dorado.AttributeWatcher(this._watcherData);
				}
				return this.attributeWatcher;
			},

			/**
			 * 读取指定的属性值。
			 * <p>
			 * 此方法还支持迭代式的属性读取，即通过"."来分割一组属性名，交由此方法一层层向下挖掘并返回最终结果。<br>
			 * 当进行迭代式的读取时，系统会自动判断前一个属性返回的对象是dorado.AttributeSupport的实例还是普通JSON对象，并藉此决定如何进一步执行读取操作。
			 * 如果碰到的中间对象dorado.AttributeSupport的实例，系统会自动读取它的Attribute；
			 * 如果碰到的中间对象是普通的JSON对象，系统会直接读取它的属性。
			 * </p>
			 *
			 * @param {String}
			 *            attr 属性名。
			 * @return {Object} 读取到的属性值。
			 *
			 * @example
			 * oop.get("label");
			 *
			 * @example
			 * oop.get("address.postCode"); // 迭代式的属性读取
			 * // 如果address的属性值是一个dorado.AttributeSupport的实例，那么此行命令的效果相当于oop.get("address").get("postCode")。
			 * // 如果address的属性值是一个JSON对象，那么此行命令的效果相当于oop.get("address").postCode
			 */
			get: function(attr) {
				var i = attr.indexOf('.');
				if (i > 0) {
					var result = this.doGet(attr.substring(0, i));
					if (result) {
						var subAttr = attr.substring(i + 1);
						if (typeof result.get == "function") {
							result = result.get(subAttr);
						}
						else {
							var as = subAttr.split('.');
							for(var i = 0; i < as.length; i++) {
								var a = as[i];
								result = (typeof result.get == "function") ? result.get(a) : result[a];
								if (!result) break;
							}
						}
					}
					return result;
				}
				else {
					return this.doGet(attr);
				}
			},

			doGet: function(attr) {
				var def = this.ATTRIBUTES[attr] || (this.PRIVATE_ATTRIBUTES && this.PRIVATE_ATTRIBUTES[attr]);
				if (def) {
					if (def.writeOnly) {
						throw new dorado.AttributeException(
							"dorado.core.AttributeWriteOnly", attr);
					}

					var result;
					if (def.getter) {
						result = def.getter.call(this, attr);
					}
					else if (def.path) {
						var sections = def.path.split('.'), owner = this;
						for(var i = 0; i < sections.length; i++) {
							var section = sections[i];
							if (section.charAt(0) != '_' && typeof owner.get == "function") {
								owner = owner.get(section);
							}
							else {
								owner = owner[section];
							}
							if (owner == null || i == sections.length - 1) {
								result = owner;
								break;
							}
						}
					}
					else {
						result = this['_' + attr];
					}
					return result;
				}
				else {
					throw new dorado.AttributeException("dorado.core.UnknownAttribute", attr);
				}
			},

			/**
			 * 设置属性值。
			 *
			 * @param {String|Object}
			 *            attr 此参数具有下列两种设置方式：
			 *            <ul>
			 *            <li>当attr为String时，系统会将attr的作为要设置属性名处理。属性值为value参数代表的值。</li>
			 *            <li>当attr为Object时，系统会将忽略value参数。此时，可以通过attr参数的JSON对象定义一组要设置的属性值。
			 *            注意：当通过此方式为对象设置一系列属性时，系统只会跳过那些设置出错的属性，并不会给出错误信息，也不会中断正在执行的设置操作。</li>
			 *            </ul>
			 *            <p>
			 *            如同{@link dorado.AttributeSupport#get}方法，set方法也支持对属性进行迭代式的设置。
			 *            即通过"."来分割一组属性名，交由此方法一层层向下挖掘，直到挖掘到倒数第二个子对象时停止并记录下一个子属性名，然后对该子对象的属性进行复制操作，请参考后面的例程。
			 *            </p>
			 *            <p>
			 *            set方法不但可以用于为对象的属性赋值，同时也可以用于为对象中的事件添加事件监听器。
			 *            <ul>
			 *            <li>直接以事件名称作为属性，以事件监听器作为属性值，进行赋值操作。</li>
			 *            <li>为对象listener属性赋值，具体方法请参考{@link dorado.EventSupport#attribute:listener}。</li>
			 *            </ul>
			 *            虽然上述两种方法都可以实现添加事件监听器的功能，并且第一种方法看起来更加方便易用。但第二种方法却较第一种更为灵活。
			 *            例如：当我们需要一次性的为同一个事件绑定多个监听器，第一种方法是不能胜任的；
			 *            或者我们当我们批量的设置一组属性值和事件监听器时，第二种方法总是确保事件监听器首先被绑定然后才处理该操作中剩余的属性值的赋值（在绝大多数的场景的这样的顺序是更加合理的），
			 *            而此时如果使用第一种方法，监听器和属性值的处理顺序是难以预知的。
			 *            </p>
			 * @param {Object}
			 *            [value] 此参数具有多重含义：要设置的属性值。当attr为Object时，此参数将被忽略。
			 *            <ul>
			 *            <li>当attr为String时，此参数代表要设置的属性值。</li>
			 *            <li>当attr为Object时，此参数可代表一组执行选项，见option参数的说明。</li>
			 *            </ul>
			 * @param {Object}
			 *            [options] 执行选项。此参数仅在attr参数为Object时有效。
			 * @param {boolean}
			 *            [options.skipUnknownAttribute=false] 是否忽略未知的属性。
			 * @param {boolean}
			 *            [options.tryNextOnError=false] 是否在发生错误后继续尝试后续的属性设置操作。
			 * @param {boolean}
			 *            [options.preventOverwriting=false] 是否组织本次赋值操作覆盖对象中原有的属性值。
			 *            即对于那些已拥有值(曾经通过set方法写入过值)的属性跳过本次的赋值操作，而只对那些未定义过的属性进行赋值。
			 * @return {dorado.AttributeSupport} 返回对象自身。
			 *
			 * @example
			 * oop.set("label", "Sample Text"); oop.set("visible", true);
			 *
			 * @example
			 * oop.set( { label : "Sample Text", visible : true });
			 *
			 * @example
			 * // 利用属性迭代的特性为子对象中的属性赋值。
			 * oop.set("address.postCode", "7232-00124");
			 * ... ...
			 * oop.set({
			 * 	"name" : "Toad",
			 * 	"address.postCode" : "7232-00124"
			 * });
			 * // 上面的两行命令相当于
			 * oop.get("address").set("postCode", "7232-00124")
			 *
			 * @example
			 * // 使用上文中提及的第一种方法为label属性赋值，同时为onClick事件绑定一个监听器。
			 * oop.set({
			 *  label : "Sample Text",
			 *  onClick : function(self, arg) {
			 *  	... ...
			 *  }
			 * });
			 */
			set: function(attr, value, options) {
				var skipUnknownAttribute, tryNextOnError, preventOverwriting, lockWritingTimes;
				if (attr && typeof attr == "object") options = value;
				if (options && typeof options == "object") {
					skipUnknownAttribute = options.skipUnknownAttribute;
					tryNextOnError = options.tryNextOnError;
					preventOverwriting = options.preventOverwriting;
					lockWritingTimes = options.lockWritingTimes;
				}

				var watcherData = this._watcherData;
				if (attr.constructor !== String) {
					for(var p in attr) {
						if (attr.hasOwnProperty(p)) {
							var v = attr[p];							
							if (p === "DEFINITION") {
								if (v) {
									if (v.ATTRIBUTES) {
										if (!this.PRIVATE_ATTRIBUTES) this.PRIVATE_ATTRIBUTES = {};
										for(var defName in v.ATTRIBUTES) {
											if (v.ATTRIBUTES.hasOwnProperty(defName)) {
												var def = v.ATTRIBUTES[defName];
												overrideDefinition(this.PRIVATE_ATTRIBUTES, def, defName);
												if (def && def.defaultValue != undefined && this['_' + p] == undefined) {
													var dv = def.defaultValue;
													this['_' + p] = (typeof dv == "function" && !def.dontEvalDefaultValue) ? dv() : dv;
												}
											}
										}
									}
									if (v.EVENTS) {
										if (!this.PRIVATE_EVENTS) this.PRIVATE_EVENTS = {};
										for(var defName in v.EVENTS) {
											if (v.EVENTS.hasOwnProperty(defName)) {
												overrideDefinition(this.PRIVATE_EVENTS, v.EVENTS[defName], defName);
											}
										}
									}
								}
							}
							else {
								if (preventOverwriting && watcherData && watcherData[p]) continue;
								try {
									this.doSet(p, v, skipUnknownAttribute, lockWritingTimes);
								}
								catch(e) {
									if (!tryNextOnError) {
										throw e;
									}
									else if (e instanceof dorado.Exception) {
										dorado.Exception.removeException(e);
									}
								}
							}
						}
					}
				}
				else {
					if (preventOverwriting && watcherData && watcherData[attr]) return;
					try {
						this.doSet(attr, value, skipUnknownAttribute, lockWritingTimes);
					}
					catch(e) {
						if (!tryNextOnError) {
							throw e;
						}
						else if (e instanceof dorado.Exception) {
							dorado.Exception.removeException(e);
						}
					}
				}
				return this;
			},

			/**
			 * 用于实现为单个属性赋值的内部方法。
			 *
			 * @param {String}
			 *            attr 要设置的属性名。
			 * @param {Object}
			 *            value 属性值。
			 * @param {boolean}
			 *            [skipUnknownAttribute] 是否忽略未知的属性。
			 * @protected
			 */
			doSet: function(attr, value, skipUnknownAttribute, lockWritingTimes) {
				if (attr.charAt(0) == '$') return;

				var path, def;
				if (attr.indexOf('.') > 0) {
					path = attr;
				}
				else {
					def = this.ATTRIBUTES[attr] || (this.PRIVATE_ATTRIBUTES && this.PRIVATE_ATTRIBUTES[attr]);
					if (def) path = def.path;
				}

				if (path) {
					var sections = path.split('.'), owner = this;
					for(var i = 0, len = sections.length - 1; i < len && owner != null; i++) {
						var section = sections[i];
						if (section.charAt(0) !== '_' && typeof owner.get === "function") {
							owner = owner.get(section);
						}
						else {
							owner = owner[section];
						}
					}
					if (owner != null) {
						var section = sections[sections.length - 1];
						(section.charAt(0) == '_') ? (owner[section] = value)
							: owner.set(section, value);
					}
					else {
						this['_' + attr] = value;
					}
				}
				else {
					if (def) {
						if (def.readOnly) {
							throw new dorado.AttributeException("dorado.core.AttributeReadOnly", attr);
						}

						var watcherData = this._watcherData;
						if (!watcherData) {
							this._watcherData = watcherData = {};
						}
						if (def.writeOnce && watcherData[attr]) {
							throw new dorado.AttributeException(
								"dorado.core.AttributeWriteOnce", attr);
						}
						if (!lockWritingTimes) {
							watcherData[attr] = (watcherData[attr] || 0) + 1;
						}

						if (def.setter) {
							def.setter.call(this, value, attr);
						}
						else {
							this['_' + attr] = value;
						}

						if (this.fireEvent && this.getListenerCount("onAttributeChange")) {
							this.fireEvent("onAttributeChange", this, {
								attribute: attr,
								value: value
							});
						}
					}
					else {
						if (value instanceof Object && this.EVENTS && (this.EVENTS[attr] || (this.PRIVATE_EVENTS && this.PRIVATE_EVENTS[attr]))) {
							if (typeof value === "function") {
								this.bind(attr, value);
							}
							else if (value.listener) this.bind(attr, value.listener, value.options);
						}
						else if (!skipUnknownAttribute) {
							throw new dorado.AttributeException("dorado.core.UnknownAttribute", attr);
						}
					}
				}
			},
			
			/**
			 * 判断对象中是否定义了某个标签值。
			 *
			 * @param {String}
			 *            tag 要判断的标签值。
			 * @return {boolean} 是否具有该标签值。
			 */
			hasTag: function(tag) {
				if (this._tags) {
					return this._tags.indexOf(tag) >= 0;
				}
				else {
					return false;
				}
			}
		});

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 属性的观察者。
	 */
	dorado.AttributeWatcher = $class(/** @scope dorado.AttributeWatcher.prototype */ {
		$className: "dorado.AttributeWatcher",
		
		constructor: function(watcherData) {
			this._watcherData = watcherData;
		},

		/**
		 * 返回某属性的被写入次数。
		 *
		 * @param {String}
		 *            attr 属性名
		 * @return {int} 属性的被写入次数。
		 */
		getWritingTimes: function(attr) {
			return (this._watcherData && this._watcherData[attr]) || 0;
		}
	});

	function overrideDefinition(targetDefs, def, name) {
		if (!def) return;
		var targetDef = targetDefs[name];
		if (targetDef) {
			dorado.Object.apply(targetDef, def);
		}
		else {
			targetDefs[name] = dorado.Object.apply({}, def);
		}
	}

})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @name dorado.Callback
 * @static
 * @class 异步方法的回调参数对象。
 * <p>
 * <font color="red"><b> 注意：这是一个虚拟的对象，在实际的运行状态中并不存在这样一个类型，因此您不能尝试实例化此类型。 </b></font>
 * </p>
 * <p>
 * 在dorado的客户端中，所有的异步执行方法都包含有一个相同类型的callback参数，该参数既可以是一个Function也可以是一个JavaScript对象。
 * <ul>
 * <li>当callback参数是一个Function时，那么该方法的声明应是如下形式：
 * <pre class="symbol-example code">
 * <code class="javascript">
 * function (obj) {
 *	 ... ...
 * }
 * </code>
 * </pre>
 *
 * 其中obj参数即为异步操作获得结果。 </li>
 * <li>当callback参数是一个对象时，该对象的结构应是一个与此处dorado.Callback匹配的JavaScript对象。 </li>
 * </ul>
 * </p>
 *
 * @example
 * // 以Function形式定义回调参数时
 * dataPipe.getAsync(function(obj) {
 *	 alert("获得的数据为：" + obj);
 * });
 *
 * @example
 * // 以JavaScript对象形式定义回调参数，并使用success和failure子方法时
 * dataPipe.getAsync({
 *	 success : function(obj) {
 *		 alert("获得的数据为：" + obj);
 *	 },
 *
 *	 failure : function(e) {
 *		 alert("发生异常：" + e);
 *	 }
 * });
 *
 * @example
 * // 以JavaScript对象形式定义回调参数，并使用callback子方法时
 * dataPipe.getAsync({
 *	 callback : function(success, obj) {
 *		 if (success) {
 *			 alert("执行成功！获得的数据为：" + obj);
 *		 }
 *		 else {
 *			 alert("执行失败！发生异常：" + obj);
 *		 }
 *	 }
 * });
 */
dorado.Callback = {};

/**
 * @name dorado.Callback#callback
 * @function
 * @description 当提取数据操作执行成功时触发的回调函数.
 * @param {boolean} [success] 异步操作被是否成功的执行了。
 * @param {Object} [obj] 异步操作获得返回结果或抛出的异常对象。
 */
/**
 * @name dorado.Callback#success
 * @function
 * @description 当提取数据操作执行成功时触发的回调函数。
 * @param {Object} [obj] 异步操作获得返回结果。
 */
/**
 * @name dorado.Callback#failure
 * @function
 * @description 当提取数据操作执行失败时触发的回调函。
 * @param {Object} [e] 异步操作执行过程中抛出的异常对象。
 */
/**
 * @name dorado.Callback.invokeCallback
 * @function
 * @description 对回调方法或对象进行调用。
 * @param {Object|Function} callback 要调用的回调方法或对象。
 * @param {Object} [success=false] 回调方法或对象监听的过程是否执行成功。
 * @param {Object} [arg] 调用回调方法时传入方法的参数。
 * @param {Object} [options] 监听选项。
 * @param {Object} [options.scope] 事件方法脚本的宿主，即事件脚本中this的含义。如果此参数为空则表示this为触发该事件的对象。
 * @param {int} [options.delay] 延时执行此事件方法的毫秒数。如果不指定此参数表示不对事件进行延时处理。
 * @see $callback
 */
/**
 * @name $callback
 * @function
 * @description {@link dorado.Callback#invokeCallback}的快捷方式。
 * @see dorado.Callback#invokeCallback
 */
window.$callback = dorado.Callback.invokeCallback = function (callback, success, arg, options) {

	function invoke(fn, args) {
		if (delay > 0) {
			setTimeout(function () {
				fn.apply(scope, args);
			}, delay);
		} else {
			fn.apply(scope, args);
		}
	}

	if (!callback) return;
	if (success == null) success = true;

	var scope, delay;
	if (options) {
		scope = options.scope;
		delay = options.delay;
	}

	if (typeof callback == "function") {
		if (!success) return;
		invoke(callback, [arg]);
	} else {
		scope = callback.scope || scope || window;
		delay = callback.delay || delay;

		if (typeof callback.callback == "function") {
			invoke(callback.callback, [success, arg]);
		}

		var name = (success) ? "success" : "failure";
		if (typeof callback[name] == "function") {
			invoke(callback.callback, [arg]);
		}
	}
};

// 用于同时触发一组异步操作，并且等待所有的异步操作全部完成之后再激活所有相应的回调方法。
dorado.Callback.simultaneousCallbacks = function (tasks, callback) {

	function getSimultaneousCallback(task) {
		var fn = function () {
			suspendedTasks.push({
				task: task,
				scope: this,
				args: arguments
			});

			if (taskReg[task.id]) {
				delete taskReg[task.id];
				taskNum--;
				if (taskNum == 0) {
					jQuery.each(suspendedTasks, function (i, suspendedTask) {
						suspendedTask.task.callback.apply(suspendedTask.scope, suspendedTask.args);
					});
					$callback(callback, true);
				}
			}
		};
		return fn;
	}

	var taskReg = {}, taskNum = tasks.length, suspendedTasks = [];
	if (taskNum > 0) {
		jQuery.each(tasks, function (i, task) {
			if (!task.id) task.id = dorado.Core.newId();
			var simCallback = getSimultaneousCallback(task);
			taskReg[task.id] = callback;
			task.run(simCallback);
		});
	} else {
		$callback(callback, true);
	}
};

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 支持事件触发机制的对象的通用接口。
 * <p>
 * 声明时事件时，每一个被声明的事件应作为EVENTS对象的一个子属性，该属性的值为一个用于描述属性的JSON对象。该JSON对象中支持下列子属性：
 * <ul>
 * <li>interceptor - {Function} 对该事件的触发动作（即{@link dorado.EventSupport#fireEvent}方法）的拦截方法。
 * 该方法的第一个传入参数是一个用于完成用默认的事件的触发动作的Function对象，从第二个参数开始与事件监听器的参数一致，方法的返回值即为相应的为外界读取到的{@link dorado.EventSupport#fireEvent}方法的返回值。
 * 再此拦截方法中，可以调用第一个参数所代表的Function来调用默认的事件的触发动作，传递给该方法的参数即最终传递给事件监听器的参数。</li>
 * <li>delay - {int} 延时触发事件的毫秒数。</li>
 * <li>processException - {boolean} 是否要在系统触发事件的过程中处理事件代码中抛出的异常，以避免这些异常进一步的被抛向外界从而干扰系统代码的执行。</li>
 * <li>disallowMultiListeners - {boolean} 是否禁止在该事件中绑定一个以上的监听器。</li>
 * </ul>
 * </p>
 *
 * @abstract
 *
 * @example
 * var SampleClass = $class({
 * 	EVENTS: {
 * 		onReady: {}, // 声明一个简单的事件
 * 		onClick: { // 声明一个带有拦截方法方法的属性
 * 			interceptor: function(superFire, self, arg) {
 * 				var retval = superFire(self, arg);
 * 				... ...
 * 				return retval;
 * 			},
 * 			
 * 			delay: 50 // 延时50毫秒后触发事件
 * 		}
 * 	}
 * });
 */
dorado.EventSupport = $class(/** @scope dorado.EventSupport.prototype */{
	$className: "dorado.EventSupport",

	ATTRIBUTES: /** @scope dorado.EventSupport.prototype */ {
		/**
		 * 用于简化为对象添加监听器操作的虚拟属性，该属性不支持读取操作。
		 * <p>
		 * 此属性的具有多态性：
		 * <ul>
		 * <li>当要赋的值为单个的JSON对象时，我们可以以事件名作为JSON对象的属性名，以事件方法作为属性值。
		 * 在此JSON对象中关联一到多个事件。</li>
		 * <li>当要赋的值为数组时，数组中的每一个JSON对象都用于描述一个事件监听器。
		 * 监听器的描述对象是一个可包含下列3个子属性的JSON对象：
		 * <ul>
		 * <li>name - {String} 要监听的事件名称。</li>
		 * <li>listener - {Function} 事件监听方法。</li>
		 * <li>[options] - {Object} 监听选项。见{@link dorado.EventSupport#bind}中的options参数的说明。</li>
		 * </ul>
		 * 采用此种方式定义的目的一般是为了同时某一个事件关联多个监听器，或者为了指定事件监听器的选项。 </li>
		 * </ul>
		 * </p>
		 * <p>
		 * 注意：此属性只在那些实现了{@link dorado.AttributeSupport}接口的子类中有效。
		 * </p>
		 * @type Object|Object[]
		 * @attribute writeOnly
		 *
		 * @example
		 * // sample 1
		 * oop.set("listener", {
		 *	 onFocus: function(button) {
		 *		 ... ...
		 *	 },
		 *	 onBlur: function(button) {
		 *		 ... ...
		 *	 }
		 * });
		 *
		 * @example
		 * // sample 2
		 * // 利用数组一次性定义两个监听器
		 * oop.set("listener", {
		 * 	onFocus: [
		 * 		{
		 * 			fn: function(button) {
		 * 				... ...
		 * 			},
		 * 			options:{ once: true }
		 * 		},
		 * 		function: (button) {
		 * 			... ...
		 * 		}
		 * });
		 */
		listener: {
			setter: function (v) {
				if (!v) return;
				for (var p in v) {
					if (v.hasOwnProperty(p)) {
						var listener = v[p];
						if (listener) {
							if (listener instanceof Array) {
								for (var i = 0; i < listener.length; i++) {
									var l = listener[i];
									if (typeof l == "function") {
										this.bind(p, l);
									}
									else if (typeof l.fn == "function") {
										this.bind(p, l.fn, l.options);
									}
								}
							} else if (typeof listener == "function") {
								this.bind(p, listener);
							} else if (typeof listener.fn == "function") {
								this.bind(p, listener.fn, listener.options);
							}
						}
					}
				}
			},
			writeOnly: true
		}
	},

	/**
	 * 用于声明该对象中所支持的所有事件。<br>
	 * 此属性中的对象一般由dorado系统自动生成，且往往一个类型的所有实例都共享同一个EVENTS对象。
	 * 因此，如无特殊需要，我们不应该在运行时手动的修改此对象中的内容。
	 * @type Object
	 *
	 * @example
	 * // 获取某对象的onClick事件的声明。
	 * var eventDef = oop.ENENTS.onClick。
	 */
	EVENTS: {},

	_disableListenersCounter: 0,

	/**
	 * 添加一个事件监听器。
	 * @deprecated
	 * @see dorado.EventSupport#bind
	 */
	addListener: function (name, listener, options) {
		return this.bind(name, listener, options);
	},

	/**
	 * 移除一个事件监听器。
	 * @deprecated
	 * @see dorado.EventSupport#unbind
	 */
	removeListener: function (name, listener) {
		return this.unbind(name, listener);
	},

	/**
	 * 添加一个事件监听器。
	 * @param {String} name 事件名称。
	 * <p>此处允许您通过特殊的语法为添加的事件监听器定义别名，以便于在未来可以更加方便的删除该事件监听器。</p>
	 * <p>例如当您使用<pre>"onClick.system"</pre>这样的名称来绑定事件，这相当于为onClick事件定义了一个别名为system的事件监听器。
	 * 当您想要移除该事件监听器时，只要这样调用<pre>button.unbind("onClick.system")</pre>就可以了。</p>
	 * @param {Function} listener 事件监听方法。
	 * @param {Object} [options] 监听选项。
	 * @param {Object} [options.scope] 事件方法脚本的宿主，即事件脚本中this的含义。如果此参数为空则表示this为触发该事件的对象。
	 * @param {boolean} [options.once] 该事件是否只支持执行一次，即当事件第一次触发之后时间监听器将被自动移除。
	 * @param {int} [options.delay] 延时多少毫秒后触发。
	 * @return {Object} 返回宿主对象自身。
	 */
	bind: function (name, listener, options) {
		var i = name.indexOf('.'), alias;
		if (i > 0) {
			alias = name.substring(i + 1);
			name = name.substring(0, i);
		}

		var def = this.EVENTS[name] || (this.PRIVATE_EVENTS && this.PRIVATE_EVENTS[name]);
		if (!def) throw new dorado.ResourceException("dorado.core.UnknownEvent", name);

		var handler = dorado.Object.apply({}, options);
		handler.alias = alias;
		handler.listener = listener;
		handler.options = options;
		if (!this._events) this._events = {};
		var handlers = this._events[name];
		if (handlers) {
			if (def.disallowMultiListeners && handlers.length) {
				new dorado.ResourceException("dorado.core.MultiListenersNotSupport", name);
			}
			if (alias) {
				for (var i = handlers.length - 1; i >= 0; i--) {
					if (handlers[i].alias == alias) {
						handlers.removeAt(i);
					}
				}
			}
			handlers.push(handler);
		} else this._events[name] = [handler];
		return this;
	},

	/**
	 * 移除一个事件监听器。
	 * @param {String} name 事件名称。
	 * <p>此处允许您通过特殊的语法来根据别名删除某个事件监听器。</p>
	 * @param {Function} [listener] 事件监听器。如果不指定此参数则表示移除该事件中的所有监听器。
	 */
	unbind: function (name, listener) {
		var i = name.indexOf('.'), alias;
		if (i > 0) {
			alias = name.substring(i + 1);
			name = name.substring(0, i);
		}

		var def = this.EVENTS[name] || (this.PRIVATE_EVENTS && this.PRIVATE_EVENTS[name]);
		if (!def) throw new dorado.ResourceException("dorado.core.UnknownEvent", name);

		if (!this._events) return;
		if (listener) {
			var handlers = this._events[name];
			if (handlers) {
				for (var i = handlers.length - 1; i >= 0; i--) {
					if (handlers[i].listener == listener && (!alias || handlers[i].alias == alias)) {
						handlers.removeAt(i);
					}
				}
			}
		}
		else if (alias) {
			var handlers = this._events[name];
			if (handlers) {
				for (var i = handlers.length - 1; i >= 0; i--) {
					if (handlers[i].alias == alias) {
						handlers.removeAt(i);
					}
				}
			}
		}
		else {
			delete this._events[name];
		}
	},

	/**
	 * 清除事件中的所有事件监听器。
	 * @param {String} name 事件名称。
	 */
	clearListeners: function (name) {
		if (!this._events) return;
		this._events[name] = null;
	},

	/**
	 * 禁用所有事件的监听器。
	 */
	disableListeners: function () {
		this._disableListenersCounter++;
	},

	/**
	 * 启用所有事件的监听器。
	 */
	enableListeners: function () {
		if (this._disableListenersCounter > 0) this._disableListenersCounter--;
	},

	/**
	 * 触发一个事件。
	 * @param {String} name 事件名称。
	 * @param {Object} [args...] 0到n个事件参数。
	 * @return {boolean} 返回事件队列的触发过程是否正常的执行结束。
	 */
	fireEvent: function (name) {
		var def = this.EVENTS[name] || (this.PRIVATE_EVENTS && this.PRIVATE_EVENTS[name]);
		if (!def) throw new dorado.ResourceException("dorado.core.UnknownEvent", name);

		var handlers = (this._events) ? this._events[name] : null;
		if ((!handlers || !handlers.length) && !def.interceptor) return;

		var self = this;
		var superFire = function () {
			if (handlers) {
				for (var i = 0; i < handlers.length;) {
					var handler = handlers[i];
					if (handler.once) handlers.removeAt(i);
					else i++;
					if (self.notifyListener(handler, arguments) === false) return false;
				}
			}
			return true;
		};

		var interceptor = (typeof def.interceptor == "function") ? def.interceptor : null;
		if (interceptor) {
			arguments[0] = superFire;
			return interceptor.apply(this, arguments);
		} else if (handlers && this._disableListenersCounter == 0) {
			return superFire.apply(this, Array.prototype.slice.call(arguments, 1));
		}
		return true;
	},

	/**
	 * 返回某事件中 已定义的事件监听器的个数。
	 * @param {String} name 事件名称。
	 * @return {int} 已定义的事件监听器的个数。
	 */
	getListenerCount: function (name) {
		if (this._events) {
			var handlers = this._events[name];
			return (handlers) ? handlers.length : 0;
		}
		else {
			return 0;
		}
	},

	notifyListener: function (handler, args) {
		var listener = handler.listener;
		var scope = handler.scope;
		if (!scope && this.getListenerScope) {
			scope = this.getListenerScope();
		}
		scope = scope || this;

		// 自动参数注入
		if (handler.autowire !== false) {
			if (handler.signature === undefined) {
				var info = dorado.getFunctionInfo(handler.listener);
				if (!info.signature || info.signature == "self,arg") {
					handler.signature = null;
				}
				else {
					handler.signature = info.signature.split(',');
				}
			}
			if (handler.signature) {
				var customArgs = [];
				if (dorado.widget && dorado.widget.View && scope instanceof dorado.widget.View) {
					for (var i = 0; i < handler.signature.length; i++) {
						var param = handler.signature[i];
						if (param == "self") {
							customArgs.push(args[0]);
						}
						else if (param == "arg") {
							customArgs.push(args[1]);
						}
						else if (param == "view") {
							customArgs.push(scope);
						}
						else {
							var object = scope.id(param);
							if (object == null) {
								object = scope.getDataType(param);
							}
							if (!object) {
								if (i == 0) object = args[0];
								else if (i == 1) object = args[1];
							}
							customArgs.push(object);
						}
					}
				}
				else{
					for (var i = 0; i < handler.signature.length; i++) {
						var param = handler.signature[i];
						if (param == "self") {
							customArgs.push(args[0]);
						}
						else if (param == "arg") {
							customArgs.push(args[1]);
						}
						else {
							customArgs = null;
							break;
						}
					}
				}
				if (customArgs) args = customArgs;
			}
		}

		var delay = handler.delay;
		if (delay >= 0) {
			/* ignore delayed listener's result */
			setTimeout(function () {
				listener.apply(scope, args);
			}, delay);
		} else {
			return listener.apply(scope, args);
		}
	}
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @name dorado.util
 * @namespace dorado中使用的各种工具类的命名空间。
 */
dorado.util = {};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @class 资源集合对象，主要用于实现国际化等功能。
 * @static
 * @see $resource
 */
dorado.util.Resource = {
	
	strings: {},

	/**
	 * 向dorado资源集合中添加一组资源。
	 * <p>
	 * 需要特别注意的是，此方法的传入参数具有多态性，当我们只为此方法传入一个参数并且这个参数不是String时， 系统会将这个参数识别为items。
	 * </p>
	 * @param {String} namespace 命名空间。传入null代表不指定命名空间。
	 * @param {Object} items 以JSON对象方式定义的一组资源。
	 * 
	 * @example
	 * // 向默认的命名空间中资源集合一次性的添加3项资源
	 * dorado.util.Resource.append( {
	 *	 property1 : "value1",
	 *	 property2 : "value2",
	 *	 property3 : "value3"
	 * });
	 * 
	 * @example
	 * // 向资源集合一次性的想命名空间"xxx.yyy.zzz"中添加3项资源
	 * dorado.util.Resource.append("xxx.yyy.zzz"， {
	 *	 property1 : "value1",
	 *	 property2 : "value2",
	 *	 property3 : "value3"
	 * });
	 */
	append: function(namespace, items) {
		if (arguments.length == 1 && namespace && namespace.constructor != String) {
			items = namespace;
			namespace = null;
		}		
		for (var p in items) {
			if (items.hasOwnProperty(p)) {
				if (namespace) {
					this.strings[namespace + '.' + p] = items[p];
				}
				else {
					this.strings[p] = items[p];
				}
			}
		}
	},

	sprintf: function() {
		var num = arguments.length;
		var s = arguments[0];
		for ( var i = 1; i < num; i++) {
			var pattern = "\\{" + (i - 1) + "\\}";
			var re = new RegExp(pattern, "g");
			s = s.replace(re, arguments[i]);
		}
		return s;
	},

	/**
	 * 根据给定的资源路径和一组参数返回资源字符串。此方法的具体使用方法请参考{@link $resource}的说明。
	 * @param {String} path 由命名空间+资源项名称组成的资源路径。
	 * @param {Object} [args...] 一到多个参数。
	 * @return {String} 资源字符串。
	 * @see $resource
	 */
	get: function(path) {
		var str = this.strings[path];
		if (arguments.length > 1 && str) {
			arguments[0] = str;
			return this.sprintf.apply(this, arguments);
		}
		else {
			return str;
		}
	}
};

/**
 * @name $resource
 * @function
 * @description dorado.util.Resource.get()的快捷方式。根据给定的资源路径和一组参数返回资源字符串。
 * @param {String} path 由命名空间+资源项名称组成的资源路径。
 * @param {Object} [args...] 一到多个参数。
 * @return {String} 资源字符串。
 * @see dorado.util.Resource#get
 * 
 * @example
 * // 提取名默认命名空间中的property1代表的字符串
 * var text = $resource("property1");
 * 
 * @example
 * // 提取名为命名空间xxx.yyy.zzz中的property1代表的字符串
 * var text = $resource("xxx.yyy.zzz.property1");
 * 
 * @example
 * // 假设xxx.yyy.zzz.property1所代表的资源字符串是"My name is {0}, I'm {1} years old."，
 * // 此方法将返回"My name is John, I'm 5 years old."
 * var text = $resource("xxx.yyy.zzz.property1", "John", 5);
 */
window.$resource = function(path, args) {
	return dorado.util.Resource.get.apply(dorado.util.Resource, arguments);
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @name Date
	 * @class 为系统日期对象提供格式化输入输出支持的prototype扩展。
	 * <p>
	 * <b>注意：此处的文档只描述了扩展的部分，并未列出日期对象所支持的所有属性方法。</b>
	 * </p>
	 * <p>
	 * 格式化输入输出日期值时，都需要使用格式化字符串。此处的格式化字符串支持下列具有特殊含义的字符：
	 * <ul>
	 * <li>d - 补足到两位的以数字表示的日期，即年月日中的日。</li>
	 * <li>D - 以文字缩写表示的星期几。</li>
	 * <li>j - 以数字表示日期，即年月日中的日。</li>
	 * <li>l - 以文字表示的星期几。</li>
	 * <li>S - 当前时间对象中天的英文序数后缀，返回值为 'st', 'nd', 'rd' 或 'th'。</li>
	 * <li>w - 以数字表示的星期几。</li>
	 * <li>z - 日期是当年中的第几天。</li>
	 * <li>W - 日期在当年中的第几周。</li>
	 * <li>F - 以文字表示的月份。</li>
	 * <li>m - 补足到两位的以数字表示的月份。</li>
	 * <li>M - 以文字缩写表示的月份。</li>
	 * <li>n - 以数字表示的月份。</li>
	 * <li>t - 日期是当月中的第几天。</li>
	 * <li>L - 以1和0表示是否闰年。</li>
	 * <li>Y - 年份。</li>
	 * <li>y - 年份的缩写。</li>
	 * <li>a - 以am、pm表示的上午、下午。</li>
	 * <li>A - 以AM、PM表示的上午、下午。</li>
	 * <li>g - 以数字表示的12进制小时。</li>
	 * <li>G - 以数字表示的24进制小时。</li>
	 * <li>h - 补足到两位的以数字表示的12进制小时。</li>
	 * <li>H - 补足到两位的以数字表示的24进制小时。</li>
	 * <li>i - 补足到两位的以数字表示的分钟。</li>
	 * <li>s - 补足到两位的以数字表示的秒数。</li>
	 * <li>O - 时区偏移字符串，格式如：'+0800'。</li>
	 * <li>T - 时区名，如 'CST', 'PDT', 'EDT' 等。</li>
	 * <li>Z - 以秒钟表示的与格林威治时间的时差。</li>
	 * </ul>
	 * </p>
	 */
		// ====

	Date.parseFunctions = {
		count: 0
	};
	Date.parseRegexes = [];
	Date.formatFunctions = {
		count: 0
	};

	/**
	 * 格式化输出日期值。
	 * @param {String} format 格式化字符串。
	 * @return {String} 格式化后的日期字符串。
	 *
	 * @example
	 * var date = new Date();
	 * date.formatDate("Y-m-d");    // 返回类似"2000-09-25"的字符串
	 * date.formatDate("H:i:s");    // 返回类似"23:10:30"的字符串
	 * date.formatDate("Y年m月d日 H点i分s秒");    // 返回类似"2000年09月25日 23点10分30秒"的字符串
	 */
	Date.prototype.formatDate = function(format) {
		if (Date.formatFunctions[format] == null) {
			Date.createNewFormat(format);
		}
		var func = Date.formatFunctions[format];
		return this[func]();
	};

	Date.createNewFormat = function(format) {
		var funcName = "format" + Date.formatFunctions.count++;
		Date.formatFunctions[format] = funcName;
		var code = "Date.prototype." + funcName + " = function(){return ";
		var special = false;
		var ch = '';
		for(var i = 0; i < format.length; ++i) {
			ch = format.charAt(i);
			if (!special && ch == "\\") {
				special = true;
			}
			else if (special) {
				special = false;
				code += "'" + String.escape(ch) + "' + ";
			}
			else {
				code += Date.getFormatCode(ch);
			}
		}
		eval(code.substring(0, code.length - 3) + ";}");
	};

	Date.getFormatCode = function(character) {
		switch(character) {
			case "d":
				return "String.leftPad(this.getDate(), 2, '0') + ";
			case "D":
				return "getDayNames()[this.getDay()].substring(0, 3) + ";
			case "j":
				return "this.getDate() + ";
			case "l":
				return "getDayNames()[this.getDay()] + ";
			case "S":
				return "this.getSuffix() + ";
			case "w":
				return "this.getDay() + ";
			case "z":
				return "this.getDayOfYear() + ";
			case "W":
				return "this.getWeekOfYear() + ";
			case "F":
				return "getMonthNames()[this.getMonth()] + ";
			case "m":
				return "String.leftPad(this.getMonth() + 1, 2, '0') + ";
			case "M":
				return "getMonthNames()[this.getMonth()].substring(0, 3) + ";
			case "n":
				return "(this.getMonth() + 1) + ";
			case "t":
				return "this.getDaysInMonth() + ";
			case "L":
				return "(this.isLeapYear() ? 1 : 0) + ";
			case "Y":
				return "this.getFullYear() + ";
			case "y":
				return "('' + this.getFullYear()).substring(2, 4) + ";
			case "a":
				return "(this.getHours() < 12 ? 'am' : 'pm') + ";
			case "A":
				return "(this.getHours() < 12 ? 'AM' : 'PM') + ";
			case "g":
				return "((this.getHours() %12) ? this.getHours() % 12 : 12) + ";
			case "G":
				return "this.getHours() + ";
			case "h":
				return "String.leftPad((this.getHours() %12) ? this.getHours() % 12 : 12, 2, '0') + ";
			case "H":
				return "String.leftPad(this.getHours(), 2, '0') + ";
			case "i":
				return "String.leftPad(this.getMinutes(), 2, '0') + ";
			case "s":
				return "String.leftPad(this.getSeconds(), 2, '0') + ";
			case "O":
				return "this.getGMTOffset() + ";
			case "T":
				return "this.getTimezone() + ";
			case "Z":
				return "(this.getTimezoneOffset() * -60) + ";
			default:
				return "'" + String.escape(character) + "' + ";
		}
	};

	/**
	 * 根据给定的格式尝试将一段日期字符串解析为日期值。
	 * @param {String} input 要解析的日期字符串。
	 * @param {String} format 格式化字符串。
	 * @return {Date} 日期值。
	 *
	 * @example
	 * var date1 = Date.parseDate("2000-09-25", "Y-m-d");
	 * var date2 = Date.parseDate("20000925", "Ymd");
	 * var date3 = Date.parseDate("2000-09-25 23:10:30", "Y-m-d H:i:s");
	 */
	Date.parseDate = function(input, format) {
		if (Date.parseFunctions[format] == null) {
			Date.createParser(format);
		}
		var func = Date.parseFunctions[format];
		return Date[func](input);
	};

	Date.createParser = function(format) {
		var funcName = "parse" + Date.parseFunctions.count++;
		var regexNum = Date.parseRegexes.length;
		var currentGroup = 1;
		Date.parseFunctions[format] = funcName;

		var code = "Date." + funcName + " = function(input){\n" + "var y = -1, m = -1, d = -1, h = -1, i = -1, s = -1;\n" +
			"var results = input.match(Date.parseRegexes[" +
			regexNum +
			"]);\n" +
			"if (results && results.length > 0) {";

		var regex = "";

		var special = false;
		var ch = '';
		for(var i = 0; i < format.length; ++i) {
			ch = format.charAt(i);
			if (!special && ch == "\\") {
				special = true;
			}
			else if (special) {
				special = false;
				regex += String.escape(ch);
			}
			else {
				obj = Date.formatCodeToRegex(ch, currentGroup);
				currentGroup += obj.g;
				regex += obj.s;
				if (obj.g && obj.c) {
					code += obj.c;
				}
			}
		}

		code += "if ((h >= 0 || i >= 0 || s >= 0) && (y < 0 || m < 0 || d < 0)) {" +
			"var now = new Date();\n" +
			"if (y < 0) y = now.getFullYear();\n" +
			"if (m < 0) m = now.getMonth();\n" +
			"if (d < 0) d = now.getDate();\n" + 
			"}" +
			"var retval = null;" +
			"if (y > 0 && m >= 0 && d > 0 && h >= 0 && i >= 0 && s >= 0)\n" + 
			"{retval = new Date(y, m, d, h, i, s);}\n" +
			"else if (y > 0 && m >= 0 && d > 0 && h >= 0 && i >= 0)\n" +
			"{retval = new Date(y, m, d, h, i);}\n" +
			"else if (y > 0 && m >= 0 && d > 0 && h >= 0)\n" +
			"{retval = new Date(y, m, d, h);}\n" +
			"else if (y > 0 && m >= 0 && d > 0)\n" +
			"{retval = new Date(y, m, d);}\n" +
			"else if (y > 0 && m >= 0)\n" +
			"{retval = new Date(y, m);}\n" +
			"else if (y > 0)\n" +
			"{retval = new Date(y);}\n" +
			"}" +
			"if (retval) {" +
			"if (s >= 0 && s != retval.getSeconds() || i >= 0 && i != retval.getMinutes() || h >= 0 && h != retval.getHours() || d >= 0 && d != retval.getDate() || m >= 0 && m != retval.getMonth()) {" +
			"retval = null;" + 
			"}" + 
			"}" + 
			"return retval;}";

		Date.parseRegexes[regexNum] = new RegExp("^" + regex + "$");
		eval(code);
	};

	Date.formatCodeToRegex = function(character, currentGroup) {
		switch(character) {
			case "D":
				return {
					g: 0,
					c: null,
					s: "(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)"
				};
			case "j":
			case "d":
				return {
					g: 1,
					c: "d = parseInt(results[" + currentGroup + "], 10);\n",
					s: "(\\d{1,2})"
				};
			case "l":
				return {
					g: 0,
					c: null,
					s: "(?:" + getDayNames().join("|") + ")"
				};
			case "S":
				return {
					g: 0,
					c: null,
					s: "(?:st|nd|rd|th)"
				};
			case "w":
				return {
					g: 0,
					c: null,
					s: "\\d"
				};
			case "z":
				return {
					g: 0,
					c: null,
					s: "(?:\\d{1,3})"
				};
			case "W":
				return {
					g: 0,
					c: null,
					s: "(?:\\d{2})"
				};
			case "F":
				return {
					g: 1,
					c: "m = parseInt(Date.monthNumbers[results[" + currentGroup + "].substring(0, 3)], 10);\n",
					s: "(" + getMonthNames().join("|") + ")"
				};
			case "M":
				return {
					g: 1,
					c: "m = parseInt(Date.monthNumbers[results[" + currentGroup + "]], 10);\n",
					s: "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
				};
			case "n":
			case "m":
				return {
					g: 1,
					c: "m = parseInt(results[" + currentGroup + "], 10) - 1;\n",
					s: "(\\d{1,2})"
				};
			case "t":
				return {
					g: 0,
					c: null,
					s: "\\d{1,2}"
				};
			case "L":
				return {
					g: 0,
					c: null,
					s: "(?:1|0)"
				};
			case "Y":
				return {
					g: 1,
					c: "y = parseInt(results[" + currentGroup + "], 10);\n",
					s: "(\\d{1,4})"
				};
			case "y":
				return {
					g: 1,
					c: "var ty = parseInt(results[" + currentGroup + "], 10);\n" +
						"y = ty > Date.y2kYear ? 1900 + ty : 2000 + ty;\n",
					s: "(\\d{1,2})"
				};
			case "a":
				return {
					g: 1,
					c: "if (results[" + currentGroup + "] == 'am') {\n" + "if (h == 12) { h = 0; }\n" +
						"} else { if (h < 12) { h += 12; }}",
					s: "(am|pm)"
				};
			case "A":
				return {
					g: 1,
					c: "if (results[" + currentGroup + "] == 'AM') {\n" + "if (h == 12) { h = 0; }\n" +
						"} else { if (h < 12) { h += 12; }}",
					s: "(AM|PM)"
				};
			case "g":
			case "G":
			case "h":
			case "H":
				return {
					g: 1,
					c: "h = parseInt(results[" + currentGroup + "], 10);\n",
					s: "(\\d{1,2})"
				};
			case "i":
				return {
					g: 1,
					c: "i = parseInt(results[" + currentGroup + "], 10);\n",
					s: "(\\d{2})"
				};
			case "s":
				return {
					g: 1,
					c: "s = parseInt(results[" + currentGroup + "], 10);\n",
					s: "(\\d{2})"
				};
			case "O":
				return {
					g: 0,
					c: null,
					s: "[+-]\\d{4}"
				};
			case "T":
				return {
					g: 0,
					c: null,
					s: "[A-Z]{3}"
				};
			case "Z":
				return {
					g: 0,
					c: null,
					s: "[+-]\\d{1,5}"
				};
			default:
				return {
					g: 0,
					c: null,
					s: String.escape(character)
				};
		}
	};

	Date.prototype.getTimezone = function() {
		return this.toString().replace(/^.*? ([A-Z]{3}) [0-9]{4}.*$/, "$1").replace(/^.*? [0-9]{4}.* \(([A-Z]{3})\)$/g, "$1").replace(/^.*?\(([A-Z])[a-z]+ ([A-Z])[a-z]+ ([A-Z])[a-z]+\)$/, "$1$2$3");
	};

	Date.prototype.getGMTOffset = function() {
		return (this.getTimezoneOffset() > 0 ? "-" : "+") +
			String.leftPad(Math.floor(Math.abs(this.getTimezoneOffset() / 60)), 2, "0") +
			String.leftPad(this.getTimezoneOffset() % 60, 2, "0");
	};

	Date.prototype.getDayOfYear = function() {
		var num = 0;
		Date.daysInMonth[1] = this.isLeapYear() ? 29 : 28;
		for(var i = 0; i < this.getMonth(); ++i) {
			num += Date.daysInMonth[i];
		}
		return num + this.getDate() - 1;
	};

	Date.prototype.getWeekOfYear = function() {
		// Skip to Thursday of this week
		var now = this.getDayOfYear() + (4 - this.getDay());
		// Find the first Thursday of the year
		var jan1 = new Date(this.getFullYear(), 0, 1);
		var then = (7 - jan1.getDay() + 4);
		return String.leftPad(((now - then) / 7) + 1, 2, "0");
	};

	Date.prototype.isLeapYear = function() {
		var year = this.getFullYear();
		return ((year & 3) == 0 && (year % 100 || (year % 400 == 0 && year)));
	};

	Date.prototype.getFirstDayOfMonth = function() {
		var day = (this.getDay() - (this.getDate() - 1)) % 7;
		return (day < 0) ? (day + 7) : day;
	};

	Date.prototype.getLastDayOfMonth = function() {
		var day = (this.getDay() + (Date.daysInMonth[this.getMonth()] - this.getDate())) % 7;
		return (day < 0) ? (day + 7) : day;
	};

	Date.prototype.getDaysInMonth = function() {
		Date.daysInMonth[1] = this.isLeapYear() ? 29 : 28;
		return Date.daysInMonth[this.getMonth()];
	};

	Date.prototype.getSuffix = function() {
		switch(this.getDate()) {
			case 1:
			case 21:
			case 31:
				return "st";
			case 2:
			case 22:
				return "nd";
			case 3:
			case 23:
				return "rd";
			default:
				return "th";
		}
	};

	String.escape = function(string) {
		return string.replace(/('|\\)/g, "\\$1");
	};

	String.leftPad = function(val, size, ch) {
		var result = new String(val);
		if (ch == null) {
			ch = " ";
		}
		while(result.length < size) {
			result = ch + result;
		}
		return result;
	};

	Date.daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	Date.y2kYear = 50;
	Date.monthNumbers = {
		Jan: 0,
		Feb: 1,
		Mar: 2,
		Apr: 3,
		May: 4,
		Jun: 5,
		Jul: 6,
		Aug: 7,
		Sep: 8,
		Oct: 9,
		Nov: 10,
		Dec: 11
	};
	Date.patterns = {
		ISO8601LongPattern: "Y-m-d H:i:s",
		ISO8601ShortPattern: "Y-m-d",
		ShortDatePattern: "n/j/Y",
		LongDatePattern: "l, F d, Y",
		FullDateTimePattern: "l, F d, Y g:i:s A",
		MonthDayPattern: "F d",
		ShortTimePattern: "g:i A",
		LongTimePattern: "g:i:s A",
		SortableDateTimePattern: "Y-m-d\\TH:i:s",
		UniversalSortableDateTimePattern: "Y-m-d H:i:sO",
		YearMonthPattern: "F, Y"
	};

	function getMonthNames() {
		if (!Date.monthNames) {
			Date.monthNames = ($resource("dorado.core.AllMonths") || "January,February,March,April,May,June,July,August,September,October,November,December").split(",");
		}
		return Date.monthNames;
	}

	function getDayNames() {
		if (!Date.dayNames) {
			Date.dayNames = ($resource("dorado.core.AllWeeks") || "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday").split(",");
		}
		return Date.dayNames;
	}

})();
/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @name dorado.util.Common
 * @class 一些实现通用功能的工具方法。
 * @static
 */
dorado.util.Common = {

	/**
	 * 用于注册URL预设变量的JSON对象。
	 * @type {Object}
	 * @see dorado.util.Common.translateURL
	 * @see $url
	 */
	URL_VARS: {},

	concatURL: function () {
		var url = "";
		for (var i = 0; i < arguments.length; i++) {
			var section = arguments[i];
			if (typeof section == "string" && section) {
				section = jQuery.trim(section);
				var e = (url.charAt(url.length - 1) == '/');
				var s = (section.charAt(0) == '/');
				if (s == e) {
					if (s) {
						url += section.substring(1);
					}
					else {
						url += '/' + section;
					}
				}
				else {
					url += section;
				}
			}
		}
		return url;
	},

	/**
	 * 将一段给定URL转换为最终的可以使用的URL。
	 * <p>
	 * 此方法允许用户在定义一个URL时利用">"在URL中植入特定的内容。<br>
	 * 例如：">images/loading.gif"表示应用的根路径下的"images/loading.gif"。
	 * 如果此时应用的根路径是"/sampleApp"，那么此方法最终返回的URL将是"/sampleApp/images/loading.gif"。（应用的根路径通过{@link $setting}中的"common.contextPath"项设定）
	 * </p>
	 * <p>
	 * 另外，此方法还支持在URL中植入预设变量。<br>
	 * 例如："skin>button.css"表示系统当前皮肤根路径中的button.css。其中的"skin>"就代表一个名为skin的预设变量。此方法会将预设变量的值替换的URL中。<br>
	 * 假设skin变量的值为"/sampleApp/skins/nature/"，那么上述URL的最终转换结果为"/sampleApp/skins/nature/button.css"。
	 * </p>
	 * <p>
	 * 此方法中使用的预设变量都需要注册在{@link dorado.Toolkits.URL_VARS}中，系统默认情况下只提供一个名为skin的预设变量。开发人员可以根据自己的需要向URL_VARS中注册自己的预设变量。
	 * </p>
	 * @param {String} url 要转换的URL。
	 * @return {String} 转换后得到的URL。
	 * @see $url
	 * @see dorado.Toolkits.URL_VARS
	 */
	translateURL: function (url) {
		if (!url) return url;

		var reg = /^.+\>/, m = url.match(reg);
		if (m) {
			m = m[0];
			var varName = m.substring(0, m.length - 1);
			if (varName.charAt(0) == '>') varName = varName.substring(1);
			var s1 = this.URL_VARS[varName] || "", s2 = url.substring(m.length);
			url = this.concatURL(s1, s2);
		}
		else if (url.charAt(0) == '>') {
			url = this.concatURL($setting["common.contextPath"], url.substring(1));
		}
		return url;
	},

	parseExponential: function(n) {
		n = n + '';
		var cv = n.split("e-");
		var leadingZero = "";
		var fl = parseInt(cv[1]);
		for(var i = 0; fl > 1 && i < fl-1; i++){
			leadingZero +="0";
		}
		
		var es = cv[0];
		var pi = es.indexOf(".");
		if (pi > 0){
			es = es.substring(0, pi) + es.substring(pi+1);
		}
		n = "0."+leadingZero + es;
		return n;
	},
	
	/**
	 * 格式化输出数字的方法。
	 * <p>
	 * 此方法的format参数是一个格式化字符串，用于指定数字的格式化方式。 其语法中包含下面的几种具有特定含义的字符或组合:
	 * <ul>
	 * <li># - 用于表示一个非强制输出的数字字符。即如果在此位置有可用的数字则输出该数字，否则不输出任何内容。</li>
	 * <li>0 - 用于表示一个强制输出的数字字符。即如果在此位置有可用的数字则输出该数字，否则将输出0来占位。</li>
	 * <li>#, - 用于表示以123,456,这样的方式向左输出所有的剩余数字。</li>
	 * </ul>
	 * </p>
	 * @param {float} n 要转换的浮点数。
	 * @param {String} format 格式化字符串。
	 * @return {String} 格式化后得到的字符串。
	 *
	 * @example
	 * var $formatFloat = dorado.util.Common.formatFloat;
	 * $formatFloat(123456789.789, "#,##0.00"); // 123,456,789.79
	 * $formatFloat(123456789.789, "#"); // 123456790
	 * $formatFloat(123456789.789, "0"); // 123456790
	 * $formatFloat(123, "#.##"); // 123
	 * $formatFloat(123, "0.00"); // 123.00
	 * $formatFloat(0.123, "0.##"); // 0.12
	 * $formatFloat(0.123, "#.##"); // .12
	 * $formatFloat(-0.123, "0.##"); // -0.12
	 * $formatFloat(-0.123, "#.##"); // -.12
	 * $formatFloat(1234.567, "$#,##0.00/DAY"); // $1,234.57/DAY
	 * $formatFloat(02145375683, "(###)########"); // (021)45375683
	 */
	formatFloat: function(n, format) {
	
		function formatInt(n, format, dec) {
			if (!format) {
				return (parseInt(n.substring(0, nfs.length), 10) + 1) + '';
			}
			
			var c, f, r = '', j = 0, prefix = '';
			var fv = format.split('');
			for (var i = 0; i < fv.length; i++) {
				f = fv[i];
				if (f == '#' || f == '0' || f == '`') {
					fv = fv.slice(i);
					break;
				}
				prefix += f;
			}
			fv = fv.reverse();
			var cv = n.split('').reverse();
			for (var i = 0; i < fv.length; i++) {
				f = fv[i];
				if (f == '#') {
					if (j < cv.length) {
						if (n == '0') {
							j = cv.length;
						} else if (n == '-0') {
							if (dec) r += '-';
							j = cv.length;
						} else {
							r += cv[j++];
						}
					}
				} else if (f == '0') {
					if (j < cv.length) {
						r += cv[j++];
					} else {
						r += f;
					}
				} else if (f == '`') {
					var commaCount = 3;
					while (j < cv.length) {
						var c = cv[j++];
						if (commaCount == 3 && c != '-') {
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
				if (f == '#' || f == '0') {
					if (n && j < n.length) {
						r += n.charAt(j++);
					} else if (f == '0') {
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
		if (n.indexOf("e-") > 0){
			n = dorado.util.Common.parseExponential(n);
		}
		if (!format) return n;
		var n1, n2, f1, f2, f3 = '', i;
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
			var j = 0;
			for (j = 0; j < f2.length; j++) {
				var c = f2.charAt(j);
				if (c != '#' && c != '0') {
					break;
				} 
			}
			if (j > 0){
				f3 = f2.substring(j);
				f2 = f2.substring(0, j);
			}
		} else {
			f1 = format;
		}
		f1 = f1.replace(/\#,/g, '`');
		
		var r = formatDecimal(n2, f2);
		var dec = r[0];
		if (r[1]) {
			n1 = (parseInt(n1, 10) + ((n1.charAt(0) == '-') ? -1 : 1)) + '';
		}
		return formatInt(n1, f1, dec) + ((dec) ? ('.' + dec) : '') + f3;
	},	
	
	/**
	 * 尝试将一段字符串中包含的数字转换成一个浮点数。 如果转换失败将返回Number.NaN。
	 * @param {String} s 要转换的字符串。
	 * @return {float} 转换后得到的浮点数。
	 */
	parseFloat: function(s) {
		if (s === 0) return 0;
		if (!s) return Number.NaN;		
		s = s + '';
		if (s.indexOf("e-") > 0){
			s = dorado.util.Common.parseExponential(s);
		}
		var ns = s.match(/[-\d\.]/g);
		if (!ns) return Number.NaN;
		var n = parseFloat(ns.join(''));
		if (n > 9007199254740991) {
			throw new dorado.ResourceException("dorado.data.ErrorNumberOutOfRangeG");
		}
		else if (n < -9007199254740991) {
			throw new dorado.ResourceException("dorado.data.ErrorNumberOutOfRangeL");
		}
		return n;
	},

	_classTypeCache: {},
	
	/**
	 * 根据给定的Class类型的名称返回具体的Class的构造器。
	 * @param {String} type Class类型的名称。
	 * @param {boolean} [silence] 是否已安静的方式执行。即当此方法的执行过程中发生异常时，是否要抛出异常。
	 * @return {Function} 具体的Class的构造器。
	 */
	getClassType: function(type, silence) {
		var classType = null;
		try {
			classType = this._classTypeCache[type];
			if (classType === undefined) {
				var path = type.split('.'), obj = window, i = 0, len = path.length;
				for (; i < len && obj; i++) {
					obj = obj[path[i]];
				}
				if (i == len) classType = obj;
				this._classTypeCache[type] = (classType || null);
			}
		}
		catch (e) {
			if (!silence) throw new dorado.ResourceException("dorado.core.UnknownType", type);
		}
		return classType;
	},
	
	singletonInstance: {},
	
	/**
	 * 返回一个单例对象。
	 * @param {String|Function} factory 单例对象的类型名或创建工厂。
	 * @return {Object} 单例对象的实例。
	 *
	 * @see $singleton
	 *
	 * @example
	 * // 利用类型名
	 * var renderer = dorado.util.Common.getSingletonInstance("dorado.widget.grid.DefaultCellRenderer");
	 *
	 * @example
	 * // 利用创建工厂
	 * var renderer = dorado.util.Common.getSingletonInstance(function() {
	 * 	return dorado.widget.grid.DefaultCellRenderer();
	 * });
	 */
	getSingletonInstance: function(factory) {
		var typeName;
		if (typeof factory == "string") typeName = factory;
		else {
			typeName = factory._singletonId;
			if (!typeName) {
				factory._singletonId = typeName = dorado.Core.newId();
			}
		}
		
		var instance = this.singletonInstance[typeName];
		if (!instance) {
			if (typeof factory == "string") {
				var classType = dorado.util.Common.getClassType(typeName);
				instance = new classType();
			}
			else {
				instance = new factory();
			}
			this.singletonInstance[typeName] = instance;
		}
		return instance;
	}
};

/**
 * @name $url
 * @function
 * @description dorado.Toolkits.translateURL()方法的快捷方式。
 * 详细用法请参考dorado.Toolkits.translateURL()的说明。
 * @see dorado.Toolkits.translateURL
 */
window.$url = function (url) {
	return dorado.util.Common.translateURL(url);
};

dorado.util.Common.URL_VARS.skin = $url($setting["widget.skinRoot"] + ($setting["widget.skin"] ? ($setting["widget.skin"] + '/') : ''));

/**
 * @name $singleton
 * @function
 * @description dorado.util.Common.getSingletonInstance()方法的快捷方式。
 * @param {String|Object} factory 单例对象的类型名或创建工厂。
 * @return {Object} 单例对象的实例。
 * @see dorado.util.Common.getSingletonInstance
 */
window.$singleton = function(factory) {
	return dorado.util.Common.getSingletonInstance(factory);
};


/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 迭代器的通用接口。
	 * @abstract
	 */
	dorado.util.Iterator = $class(/** @scope dorado.util.Iterator.prototype */{
		$className: "dorado.util.Iterator",
		
		/**
		 * 将迭代器迭代位置设置到起始位置。
		 * @function
		 */
		first: dorado._NULL_FUNCTION,
		
		/**
		 * 将迭代器迭代位置设置到结束位置。
		 * @function
		 */
		last: dorado._NULL_FUNCTION,
		
		/**
		 * 返回迭代器中是否还存在上一个元素。
		 * @function
		 * @return {boolean} 是否还存在上一个元素。
		 */
		hasPrevious: dorado._NULL_FUNCTION,
		
		/**
		 * 返回迭代器中是否还存在下一个元素。
		 * @function
		 * @return {boolean} 是否还存在下一个元素。
		 */
		hasNext: dorado._NULL_FUNCTION,
		
		/**
		 * 返回迭代器中的上一个元素。
		 * @function
		 * @return {Object} 上一个元素。
		 */
		previous: dorado._NULL_FUNCTION,
		
		/**
		 * 返回迭代器中的下一个元素。
		 * @function
		 * @return {Object} 下一个元素。
		 */
		next: dorado._NULL_FUNCTION,
		
		/**
		 * 返回之前最后一次利用next()或previous()返回的元素。
		 * @function
		 * @return {Object} 当前元素。
		 */
		current: dorado._NULL_FUNCTION,
		
		/**
		 * 创建并返回一个书签对象。
		 * @function
		 * @return {Object} 书签对象。
		 */
		createBookmark: dorado._UNSUPPORTED_FUNCTION(),
		
		/**
		 * 根据传入的书签对象将迭代器的当前位置还原到书签对象所指示的位置。
		 * @function
		 * @param {Object} bookmark 书签对象。
		 */
		restoreBookmark: dorado._UNSUPPORTED_FUNCTION()
	});
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 用于迭代JavaScript数组的迭代器。
	 * @extends dorado.util.Iterator
	 * @param {Array} v 将被迭代的数组。
	 * @param {int} [nextIndex] 下一个返回元素的下标。
	 */
	dorado.util.ArrayIterator = $extend(dorado.util.Iterator, /** @scope dorado.util.ArrayIterator.prototype */ {
		$className: "dorado.util.ArrayIterator",
		
		constructor: function(v, nextIndex) {
			this._v = v;
			this._current = (nextIndex || 0) - 1;
		},
		
		first: function() {
			this._current = -1;
		},
		
		last: function() {
			this._current = this._v.length;
		},
		
		hasPrevious: function() {
			return this._current > 0;
		},
		
		hasNext: function() {
			return this._current < (this._v.length - 1);
		},
		
		previous: function() {
			return (this._current < 0) ? null : this._v[--this._current];
		},
		
		next: function() {
			return (this._current >= this._v.length) ? null : this._v[++this._current];
		},
		
		current: function() {
			return this._v[this._current];
		},
		
		/**
		 * 设置迭代器的起始位置，即下一次调用next()时所返回的元素的下标。
		 * @param nextIndex {int} 下一个返回元素的下标。
		 */
		setNextIndex: function(nextIndex) {
			this._current = nextIndex - 1;
		},
		
		createBookmark: function() {
			return this._current;
		},
		
		restoreBookmark: function(bookmark) {
			this._current = bookmark;
		}
	});
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 键值对数组，即支持通过键值对元素进行快速定位的数组。
 * @param {Function} [getKeyFunction] 用于从元素中提取元素键值的函数，此函数应该返回一个String作为键值。
 *
 * @example
 * var keyedArray = new dorado.util.KeyedArray();
 *
 * @example
 * var keyedArray = new dorado.util.KeyedArray( function(obj) {
 * 	// 此处的参数obj为数组中的某个元素，返回值为与该元素匹配的键值。
 * 		return obj.id;
 * 	});
 */
dorado.util.KeyedArray = $class(/** @scope dorado.util.KeyedArray.prototype */{
	$className: "dorado.util.KeyedArray",
	
	// TODO: DOC for beforeInsert\afterInsert\beforeRemove\afterRemove
	// =====
	
	constructor: function(getKeyFunction) {
		/**
		 * @name dorado.util.KeyedArray#items
		 * @property
		 * @description 键值对数组中的所有元素。
		 * @type Array
		 */
		this.items = [];
		
		this._keyMap = {};
		this._getKeyFunction = getKeyFunction;
	},
	
	/**
	 * 键值对数组的大小，即数组中的元素个数。
	 * @type int
	 */
	size: 0,
	
	_getKey: function(data) {
		var key = this._getKeyFunction ? this._getKeyFunction(data) : data.id;
		return (typeof key == "string") ? key : (key + '');
	},
	
	/**
	 * 向键值对数组中添加一个对象。
	 * @param {Object} data 要添加的对象。
	 * @param {int|String} [insertMode] 对象的插入位置或插入模式。如果不定义此参数表示将对象添加到集合的末尾。
	 * 此参数具有两种可能的含义:
	 * <ul>
	 * <li>当此参数是一个数字时，表示新对象在集合中的最终位置。</li>
	 * <li>当此参数是一个字符串时，表示新对象的插入模式。
	 * 插入方式，包含下列四种取值：
	 * <ul>
	 * <li>begin - 在链表的起始位置插入。</li>
	 * <li>before - 在refData参数指定的参照对象之前插入。</li>
	 * <li>after - 在refData参数指定的参照对象之后插入。</li>
	 * <li>end - 在链表的末尾插入。</li>
	 * </ul>
	 * </li>
	 * </ul>
	 * @param {Object} [refData] 插入位置的参照对象。此参数仅在insertMode参数为字符串时有意义。
	 */
	insert: function(data, insertMode, refData) {
		var ctx;
		if (this.beforeInsert) ctx = this.beforeInsert(data); 
		if (!isFinite(insertMode) && insertMode) {
			switch (insertMode) {
				case "begin":{
					insertMode = 0;
					break;
				}
				case "before":{
					insertMode = this.items.indexOf(refData);
					if (insertMode < 0) insertMode = 0;
					break;
				}
				case "after":{
					insertMode = this.items.indexOf(refData) + 1;
					if (insertMode >= this.items.length) insertMode = null;
					break;
				}
				default:
					insertMode = null;
					break;
			}
		}
		
		if (insertMode != null && isFinite(insertMode) && insertMode >= 0) {
			this.items.insert(data, insertMode);
		} else {
			this.items.push(data);
		}
		
		this.size++;
		var key = this._getKey(data);
		if (key) this._keyMap[key] = data;
		if (this.afterInsert) this.afterInsert(data, ctx); 
	},
	
	/**
	 * 向键值对数组中追加一个对象。
	 * @param {Object} data 要追加的对象。
	 */
	append: function(data) {
		this.insert(data);
	},
	
	/**
	 * 从键值对数组中移除一个对象。
	 * @param {Object} data 要移除的对象。
	 * @return {int} 被移除元素的下标位置。
	 */
	remove: function(data) {
		var ctx;
		if (this.beforeRemove) ctx = this.beforeRemove(data); 
		var i = this.items.remove(data);
		if (i >= 0) {
			this.size--;
			var key = this._getKey(data);
			if (key) delete this._keyMap[key];
		}
		if (this.afterRemove) this.afterRemove(data, ctx); 
		return i;
	},
	
	/**
	 * 从键值对数组中移除指定位置的元素。
	 * @param {int} i 要移除元素的下标位置。
	 * @return {Object} 返回从数组中移除移除的对象.
	 */
	removeAt: function(i) {
		if (i >= 0 && i < this.size) {
			var data = this.items[i], ctx;
			if (data) {
				if (this.beforeRemove) ctx = this.beforeRemove(data); 
				var key = this._getKey(data);
				if (key) delete this._keyMap[key];
			}
			this.items.removeAt(i);
			this.size--;
			if (data && this.afterRemove) this.afterRemove(data, ctx); 
			return data;
		}
		return null;
	},
	
	/**
	 * 从键值对数组中移除指定键值。
	 * @param {String} key 要移除元素的键值。
	 * @return {Object} 返回从数组中移除移除的对象.
	 */
	removeKey: function(key) {
		var ctx, data = this._keyMap[key];
		if (this.beforeRemove) ctx = this.beforeRemove(data); 
		var i = this.items.remove(data);
		if (i >= 0) {
			this.size--;
			if (key) delete this._keyMap[key];
		}
		if (this.afterRemove) this.afterRemove(data, ctx); 
		return data;
	},
	
	/**
	 * 根据对象返回其在键值对数组中的下标位置。如果指定的对象不在键值对数组中将返回-1。
	 * @param {Object} data 查找的对象。
	 * @return {int} 下标位置。
	 */
	indexOf: function(data) {
		return this.items.indexOf(data);
	},
	
	/**
	 * 替换键值对数组的某一项。
	 * @param {Object} oldData 将被替换的对象。
	 * @param {Object} newData 新的对象。
	 * @return {int} 发生替换动作下标位置。如果返回-1则表示被替换的对象并不存在于该数组中。
	 */
	replace: function(oldData, newData) {
		var i = this.indexOf(oldData);
		if (i >= 0) {
			this.removeAt(i);
			this.insert(newData, i);
		}
		return i;
	},
	
	/**
	 * 根据传入的下标位置或键值返回匹配的对象。
	 * @param {int|String} k 下标位置或键值。
	 * @return {Object} 匹配的对象。
	 */
	get: function(k) {
		return (typeof k == "number") ? this.items[k] : this._keyMap[k];
	},
	
	/**
	 * 清除集合中的所有对象。
	 */
	clear: function() {
		for (var i = this.size - 1; i >= 0; i--) this.removeAt(i);
	},
	
	/**
	 * 返回数组的迭代器。
	 * @param {Object} [from] 从哪一个元素所在的位置开始迭代。
	 * @return {dorado.util.Iterator} 数组迭代器。
	 */
	iterator: function(from) {
		var start = this.items.indexOf(from);
		if (start < 0) start = 0;
		return new dorado.util.ArrayIterator(this.items, start);
	},
	
	/**
	 * 针对键值对数组中的每一个元素执行指定的函数。此方法可用于替代对数组的遍历代码。
	 * @param {Function} fn 针对每一个元素执行的函数。
	 * @param {Object} [scope] 函数脚本的宿主，即函数脚本中this的含义。如果此参数为空则表示this为数组中的某个对象。
	 *
	 * @example
	 * // 将每一个数组元素的name属性连接成为一个字符串。
	 * var names = "";
	 * var keyedArray = new dorado.util.KeyedArray();
	 * ... ... ...
	 * keyedArray.each(function(obj){
	 * 	names += obj.name;
	 * });
	 */
	each: function(fn, scope) {
		var array = this.items;
		for (var i = 0; i < array.length; i++) {
			if (fn.call(scope || array[i], array[i], i) === false) {
				return i;
			}
		}
	},
	
	/**
	 * 将集成从所有的对象导出至一个数组中。
	 * @return {Array} 包含所有集合元素的数组。
	 */
	toArray: function() {
		return this.items.slice(0);
	},
	
	/**
	 * 浅度克隆本键值对数组。
	 * @return {dorado.util.KeyedArray} 克隆的数组。
	 */
	clone: function() {
		var cloned = dorado.Core.clone(this);
		cloned.items = dorado.Core.clone(this.items);
		cloned._keyMap = dorado.Core.clone(this._keyMap);
		return cloned;
	},
	
	/**
	 * 深度克隆本键值对数组。
	 * @return {dorado.util.KeyedArray} 克隆的数组。
	 */
	deepClone: function() {
		var cloned = new dorado.util.KeyedArray(this._getKeyFunction);
		for (var i = 0; i < this.items.length; i++) {
			cloned.append(dorado.Core.clone(this.items[i]));
		}
		return cloned;
	}
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 键值对集合，即支持通过键值对元素进行快速定位的集合。
 * 该集合的本质是一个双向链表，集合中的元素都被封装在一个个的链表元素中，链表元素对象包含下列子属性：
 * <ul>
 * <li>data - 该链表元素中封装的对象。</li>
 * <li>previous - 该链表元素的前一个链表元素。</li>
 * <li>next - 该链表元素的下一个链表元素。</li>
 * </ul>
 * @param {Function} [getKeyFunction] 用于从元素中提取元素键值的函数，此函数应该返回一个String作为键值。
 * 
 * @example
 * var keyedList = new dorado.util.KeyedList();
 *
 * @example
 * var keyedList = new dorado.util.KeyedList( function(obj) {
 *	 	// 此处的参数obj为数组中的某个元素，返回值为与该元素匹配的键值。
 *		return obj.id;
 *	 });
 */
dorado.util.KeyedList = $class(/** @scope dorado.util.KeyedList.prototype */{
	$className: "dorado.util.KeyedList",
	
	constructor: function(getKeyFunction) {
		this._keyMap = {};
		this._getKeyFunction = getKeyFunction;
	},
	
	/**
	 * @name dorado.util.KeyedList#first
	 * @property
	 * @description 链表中的第一个元素。
	 * @type Object
	 */
	/**
	 * @name dorado.util.KeyedList#last
	 * @property
	 * @description 链表中的最后一个元素。
	 * @type Object
	 */
	// =====
	/**
	 * 集合的大小，即集合中的元素个数。
	 * @type int
	 */
	size: 0,
	
	_getKey: function(data) {
		var key = this._getKeyFunction ? this._getKeyFunction(data) : data.id;
		return (typeof key == "string") ? key : (key + '');
	},
	
	_registerEntry: function(entry) {
		var key = this._getKey(entry.data);
		if (key != null) this._keyMap[key] = entry;
	},
	
	_unregisterEntry: function(entry) {
		var key = this._getKey(entry.data);
		if (key != null) delete this._keyMap[key];
	},
	
	_unregisterAllEntries: function() {
		this._keyMap = {};
	},
	
	insertEntry: function(entry, insertMode, refEntry) {
		var e1, e2;
		switch (insertMode) {
			case "begin":
				e1 = null;
				e2 = this.first;
				break;
			case "before":
				e1 = (refEntry) ? refEntry.previous : null;
				e2 = refEntry;
				break;
			case "after":
				e1 = refEntry;
				e2 = (refEntry) ? refEntry.next : null;
				break;
			default:
				e1 = this.last;
				e2 = null;
				break;
		}
		
		entry.previous = e1;
		entry.next = e2;
		if (e1) e1.next = entry;
		else this.first = entry;
		if (e2) e2.previous = entry;
		else this.last = entry;
		
		this._registerEntry(entry);
		this.size++;
	},
	
	removeEntry: function(entry) {
		var e1, e2;
		e1 = entry.previous;
		e2 = entry.next;
		if (e1) e1.next = e2;
		else this.first = e2;
		if (e2) e2.previous = e1;
		else this.last = e1;
		
		this._unregisterEntry(entry);
		this.size--;
	},
	
	findEntry: function(data) {
		if (data == null) return null;
		
		var key = this._getKey(data);
		if (key != null) {
			return this._keyMap[key];
		} else {
			var entry = this.first;
			while (entry) {
				if (entry.data === data) {
					return entry;
				}
				entry = entry.next;
			}
		}
		return null;
	},
	
	findEntryByKey: function(key) {
		return this._keyMap[key];
	},
	
	/**
	 * 向集合中插入一个对象。
	 * @param {Object} data 要插入的对象。
	 * @param {String} [insertMode] 插入方式，包含下列四种取值：
	 * <ul>
	 * <li>begin - 在链表的起始位置插入。</li>
	 * <li>before - 在refData参数指定的参照对象之前插入。</li>
	 * <li>after - 在refData参数指定的参照对象之后插入。</li>
	 * <li>end - 在链表的末尾插入。</li>
	 * </ul>
	 * @param {Object} [refData] 插入位置的参照对象。
	 */
	insert: function(data, insertMode, refData) {
		var refEntry = null;
		if (refData != null) {
			refEntry = this.findEntry(refData);
		}
		var entry = {
			data: data
		};
		this.insertEntry(entry, insertMode, refEntry);
	},
	
	/**
	 * 向集合中追加一个对象。
	 * @param {Object} data 要集合的对象。
	 */
	append: function(data) {
		this.insert(data);
	},
	
	/**
	 * 从集合中移除一个对象。
	 * @param {Object} data 要移除的对象。
	 * @return {boolean} 是否成功的移除了对象。
	 */
	remove: function(data) {
		var entry = this.findEntry(data);
		if (entry != null) this.removeEntry(entry);
		return (entry != null);
	},
	
	/**
	 * 根据传入的键值从集合中移除匹配的对象。
	 * @param {String} key 键值。
	 * @return {Object} 被移除的匹配的对象。
	 */
	removeKey: function(key) {
		var entry = this._keyMap[key];
		if (entry) {
			this.removeEntry(entry);
			return entry.data;
		}
		return null;
	},
	
	/**
	 * 根据传入的键值返回匹配的对象。
	 * @param {String} key 键值。
	 * @return {Object} 匹配的对象。
	 */
	get: function(key) {
		var entry = this._keyMap[key];
		if (entry) {
			return entry.data;
		}
		return null;
	},
	
	/**
	 * 清除集合中的所有对象。
	 */
	clear: function() {
		var entry = this.first;
		while (entry) {
			if (entry.data) delete entry.data;
			entry = entry.next;
		}
		
		this._unregisterAllEntries();
		this.first = null;
		this.last = null;
		this.size = 0;
	},
	
	/**
	 * 返回键值对集合的迭代器。
	 * @param {Object} [from] 从哪一个元素所在的位置开始迭代。迭代时不包含传入的元素，而是从该元素的上一个或下一个开始。
	 * @return {dorado.util.KeyedListIterator} 键值对集合的迭代器。
	 */
	iterator: function(from) {
		return new dorado.util.KeyedListIterator(this, from);
	},
	
	/**
	 * 针对集合的每一个元素执行指定的函数。此方法可用于替代对集合的遍历代码，示例如下：
	 * @param {Function} fn 针对每一个元素执行的函数
	 * @param {Object} [scope] 函数脚本的宿主，即函数脚本中this的含义。如果此参数为空则表示this为集合中的某个对象。
	 * 
	 * @example
	 * // 将每一个集合元素的name属性连接成为一个字符串。
	 * var names = "";
	 * var keyedList = new dorado.util.KeyedList();
	 * ... ... ...
	 * keyedList.each(function(obj){
	 *	 names += obj.name;
	 * });
	 */
	each: function(fn, scope) {
		var entry = this.first, i = 0;
		while (entry != null) {
			if (fn.call(scope || entry.data, entry.data, i++) === false) {
				break;
			}
			entry = entry.next;
		}
	},
	
	/**
	 * 将集成从所有的对象导出至一个数组中。
	 * @return {Array} 包含所有集合元素的数组。
	 */
	toArray: function() {
		var v = [], entry = this.first;
		while (entry != null) {
			v.push(entry.data);
			entry = entry.next;
		}
		return v;
	},
	
	/**
	 * 返回集合中的第一个对象。
	 * @return {Object} 集合中的第一个对象。
	 */
	getFirst: function() {
		return this.first ? this.first.data : null;
	},
	
	/**
	 * 返回集合中的最后一个对象。
	 * @return {Object} 集合中的最后一个对象。
	 */
	getLast: function() {
		return this.last ? this.last.data : null;
	},
	
	/**
	 * 浅度克隆本键值对集合。
	 * @return {dorado.util.KeyedList} 克隆的集合。
	 */
	clone: function() {
		var cloned = new dorado.util.KeyedList(this._getKeyFunction);
		var entry = this.first;
		while (entry != null) {
			cloned.append(entry.data);
			entry = entry.next;
		}
		return cloned;
	},
	
	/**
	 * 深度克隆本键值对集合。
	 * @return {dorado.util.KeyedArray} 克隆的集合。
	 */
	deepClone: function() {
		var cloned = new dorado.util.KeyedList(this._getKeyFunction);
		var entry = this.first;
		while (entry != null) {
			cloned.append(dorado.Core.clone(entry.data));
			entry = entry.next;
		}
		return cloned;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 键值对集合的迭代器。
 * @extends dorado.util.Iterator
 * @param {dorado.util.KeyedList} list 要迭代的键值对集合。
 */
dorado.util.KeyedListIterator = $extend(dorado.util.Iterator, /** @scope dorado.util.KeyedListIterator.prototype */ {
	$className: "dorado.util.KeyedListIterator",
	
	constructor: function(list, from) {
		this._list = list;
		this.current = null;
		if (from) this.current = list.findEntry(from);
		
		this.isFirst = (this.current == null);
		this.isLast = false;
	},
	
	first: function() {
		this.isFirst = true;
		this.isLast = false;
		this.current = null;
	},
	
	last: function() {
		this.isFirst = false;
		this.isLast = true;
		this.current = null;
	},
	
	hasNext: function() {
		if (this.isFirst) {
			return (this._list.first != null);
		} else if (this.current != null) {
			return (this.current.next != null);
		} else {
			return false;
		}
	},
	
	hasPrevious: function() {
		if (this.isLast) {
			return (this._list.last != null);
		} else if (this.current != null) {
			return (this.current.previous != null);
		} else {
			return false;
		}
	},
	
	next: function() {
		var current = this.current;
		if (this.isFirst) {
			current = this._list.first;
		} else if (current != null) {
			current = current.next;
		} else {
			current = null;
		}
		this.current = current;
		
		this.isFirst = false;
		if (current != null) {
			this.isLast = false;
			return current.data;
		} else {
			this.isLast = true;
			return null;
		}
	},
	
	previous: function() {
		var current = this.current;
		if (this.isLast) {
			current = this._list.last;
		} else if (current != null) {
			current = current.previous;
		} else {
			current = null;
		}
		this.current = current;
		
		this.isLast = false;
		if (current != null) {
			this.isFirst = false;
			return current.data;
		} else {
			this.isFirst = true;
			return null;
		}
	},
	
	current: function() {
		return (this.current) ? this.current.data : null;
	},
	
	createBookmark: function() {
		return {
			isFirst: this.isFirst,
			isLast: this.isLast,
			current: this.current
		};
	},
	
	restoreBookmark: function(bookmark) {
		this.isFirst = bookmark.isFirst;
		this.isLast = bookmark.isLast;
		this.current = bookmark.current;
	}
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @class 对象缓存池。用于对对象进行缓存、池化管理的容器。
 * @description 构造器。
 * @param {Object} factory 可池化对象的工厂。
 * @param {Function} factory.makeObject (<b>必须指定</b>) 创建一个新的对象，该方法的返回值即为新创建的对象。
 * @param {Function} factory.destroyObject 销毁一个对象。
 * @param {Function} factory.activateObject 当一个对象被激活（被租借）时触发的方法。
 * @param {Function} factory.passivateObject 当一个对象被钝化（被归还）时触发的方法。
 *
 * @example
 * // 结合XMLHttpRequest创建过程的简陋示例：
 * // 声明XMLHttpRequest的创建工厂
 * var factory = {
 * 	makeObject: function() {
 * 		// 创建XMLHttpRequset对象
 * 		// 注：这里的创建方法不够健壮，勿学！
 * 		if (window.ActiveXObject){
 * 			return new ActiveXObject("Microsoft.XMLHTTP");
 * 		}
 * 		else {
 * 			return new XMLHttpRequest();
 * 		}
 * 	},	passivateObject: function(xhr) {
 * 		// 重置XMLHttpRequset对象
 * 		xhr.onreadystatechange = {};
 * 		xhr.abort();
 * 	}
 * };
 * var pool = new ObjectPool(factory); // 创建对象池
 * ......
 * var xhr = pool.borrowObject(); // 获得一个XMLHttpRequest对象
 * xhr.onreadystatechange = function() {
 * 	if (xhr.readyState == 4) {
 * 		......
 * 		pool.returnObject(xhr); // 归还XMLHttpRequest对象
 * 	}
 * };
 * xhr.open(method, url, true);
 * ......
 */
dorado.util.ObjectPool = $class(/** @scope dorado.util.ObjectPool.prototype */
{
	$className : "dorado.util.ObjectPool",

	constructor : function(factory) {
		dorado.util.ObjectPool.OBJECT_POOLS.push(this);

		this._factory = factory;
		this._idlePool = [];
		this._activePool = [];
	},
	/**
	 * 从对象池中租借一个对象。
	 * @return {Object} 返回租借到的对象实例。
	 */
	borrowObject : function() {
		var object = null;
		var factory = this._factory;
		if(this._idlePool.length > 0) {
			object = this._idlePool.pop();
		} else {
			object = factory.makeObject();
		}
		if(object != null) {
			this._activePool.push(object);
			if(factory.activateObject) {
				factory.activateObject(object);
			}
		}
		return object;
	},
	/**
	 * 向对象池归还一个先前租借的对象。
	 * @param {Object} object 要归还的对象。
	 */
	returnObject : function(object) {
		if(object != null) {
			var factory = this._factory;
			var i = this._activePool.indexOf(object);
			if(i < 0)
				return;
			if(factory.passivateObject) {
				factory.passivateObject(object);
			}
			this._activePool.removeAt(i);
			this._idlePool.push(object);
		}
	},
	/**
	 * 返回对象池中的激活对象的个数。
	 * @return {int} 激活对象的个数。
	 */
	getNumActive : function() {
		return this._activePool.length;
	},
	/**
	 * 返回对象池中的空闲对象的个数。
	 * @return {int} 空闲对象的个数。
	 */
	getNumIdle : function() {
		return this._idlePool.length;
	},
	/**
	 * 销毁对象池及其中管理的所有对象。
	 */
	destroy : function() {
		if(!!this._destroyed) return;

		var factory = this._factory;

		function returnObject(object) {
			if(factory.passivateObject) {
				factory.passivateObject(object);
			}
		}

		function destroyObject(object) {
			if(factory.destroyObject) {
				factory.destroyObject(object);
			}
		}

		var activePool = this._activePool;
		for(var i = 0; i < activePool.length; i++) {
			var object = activePool[i];
			returnObject(object);
			destroyObject(object);
		}

		var idlePool = this._idlePool;
		for(var i = 0; i < idlePool.length; i++) {
			var object = idlePool[i];
			destroyObject(object);
		}

		this._factory = null;
		this._destroyed = true;
	}
});

dorado.util.ObjectPool.OBJECT_POOLS = [];

// jQuery(window).unload(function() {
// var pools = dorado.util.ObjectPool.OBJECT_POOLS;
// for ( var i = 0; i < pools.length; i++)
// pools[i].destroy();
// });

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	function f(n) {
		return n < 10 ? '0' + n : n;
	}
	
	Date.prototype.toJSON = function(key) {
		return this.getFullYear() + '-' + f(this.getMonth() + 1) + '-' + f(this.getDate()) + 'T' +
			f(this.getHours()) + ':' + f(this.getMinutes()) + ':' + f(this.getSeconds()) + 'Z';
	};
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 用于实现一些与JSON相关功能的对象。
	 * @static
	 */
	dorado.JSON = {
	
		/**
		 * 将一段JSON字符串解析成JSON对象。
		 * @param {Object} text 要解析的JSON字符串。
		 * @param {boolean} [untrusty] 服务器返回的Response信息是否是不可信的。默认为false，即Response信息是可信的。<br>
		 * 此参数将决定dorado通过何种方式来解析服务端返回的JSON字符串，为了防止某些嵌入在JSON字符串中的黑客代码对应用造成伤害，
		 * dorado可以使用安全的方式来解析JSON字符串，但是这种安全检查会带来额外的性能损失。
		 * 因此，如果您能够确定访问的服务器是安全的，其返回的JSON字符串不会嵌入黑客代码，那么就不必开启此选项。
		 * @return {Object} 得到的JSON对象。
		 */
		parse: function(text, untrusty) {
			return text ? ((untrusty) ? JSON.parse(text) : eval('(' + text + ')')) : null;
		},
		
		/**
		 * 将给定的JSON对象、实体对象({@link dorado.Entity})或实体集合({@link dorado.EntityList})转换成JSON字符串。
		 * @param {Object} value 要转换的数据。
		 * @param {Object} [options] 转换选项。
		 * @param {String[]} [options.properties] 属性名数组，表示只转换该数组中列举过的属性。如果不指定此属性表示转换实体对象中的所有属性。
		 * @param {boolean} [options.includeReferenceProperties] 是否转换实体对象中{@link dorado.Reference}类型的属性。默认按false进行处理。
		 * @param {boolean} [options.includeLookupProperties] 是否转换实体对象中{@link dorado.Lookup}类型的属性。默认按false进行处理。
		 * @param {boolean} [options.includeUnloadPage] 是否转换{@link dorado.EntityList}中尚未装载的页中的数据。默认按false进行处理。
		 * @return {String} 得到的JSON字符串。
		 */
		stringify: function(value, options) {
			if (value != null) {
				if (value instanceof dorado.Entity || value instanceof dorado.EntityList) {
					value = value.toJSON(options);
				}
			}
			return JSON.stringify(value, (options != null) ? options.replacer : null);
		},
		
		/**
		 * 对JSON数据模板进行求值。
		 * <p>
		 * JSON数据模板事实上指包含function型值的JSON对象。 对JSON数据模板进行求值，就是执行这些function并且得到最终的返回值。
		 * </p>
		 * @param {Object} template JSON数据模板。
		 * @return 求值后得到的最终JSON数据。
		 *
		 * @example
		 * // 这是一个JSON数据模板，如下：
		 * {
		 * 	property1: "value1",
		 * 	property2: function() {
		 * 		return 100 + 200;
		 * 	}
		 * }
		 *
		 * // 经过求值，我们将得到一个新的JSON对象，如下：
		 * {
		 * 	property1: "value1",
		 * 	property2: 300
		 * }
		 */
		evaluate: function(template) {
		
			function toJSON(obj) {
				if (typeof obj == "function") {
					obj = obj.call(dorado.$this || this);
				} else if (obj instanceof dorado.util.Map) {
					obj = obj.toJSON();
				}
				
				var json;
				if (obj instanceof dorado.Entity || obj instanceof dorado.EntityList) {
					json = obj.toJSON({
						generateDataType: true
					});
				} else if (obj instanceof Array) {
					json = [];
					for (var i = 0; i < obj.length; i++) {
						json.push(toJSON(obj[i]));
					}
				} else if (obj instanceof Object && !(obj instanceof Date)) {
					if (typeof obj.toJSON == "function") {
						json = obj.toJSON();
					} else {
						json = {};
						for (var p in obj) {
							if (obj.hasOwnProperty(p)) {
								v = obj[p];
								if (v === undefined) continue;
								if (v != null) v = toJSON.call(obj, v);
								json[p] = v;
							}
						}
					}
				} else {
					json = obj;
				}
				return json;
			}
			
			return toJSON(template);
		}
	};
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

dorado.util.AjaxConnectionPool = new dorado.util.ObjectPool({
	activeX: ["MSXML2.XMLHTTP.6.0", "MSXML2.XMLHTTP.5.0", "MSXML2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0", "MSXML2.XMLHTTP", "Microsoft.XMLHTTP"],

	_createXMLHttpRequest: function() {
		try {
			return new XMLHttpRequest();
		}
		catch(e) {
			for(var i = 0; i < this.activeX.length; ++i) {
				try {
					return new ActiveXObject(this.activeX[i]);
				}
				catch(e) {
				}
			}
		}
	},
	makeObject: function() {
		return {
			conn: this._createXMLHttpRequest()
		};
	},
	passivateObject: function(connObj) {
		delete connObj.url;
		delete connObj.method;
		delete connObj.options;

		var conn = connObj.conn;
		conn.onreadystatechange = dorado._NULL_FUNCTION;
		conn.abort();
	}
});

/**
 *
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class Ajax引擎的客户端。
 * <p>
 * dorado中的Ajax引擎具备如下两个与众不同的特性：
 * <ul>
 * <li> <b>支持XMLHttpRequest对象池</b> -
 * AjaxEngine引擎并不会为每一次的请求创建全新的XMLHttpRequest对象，而是会为XMLHttpRequest建立一个对象池。
 * 每当AjaxEngine将要发出一个Ajax请求(包括利用AjaxEngine发出的同步请求)时，AjaxEngine会首先尝试到对象池租借一个空闲的XMLHttpRequest，
 * 只有当无法得到一个空闲XMLHttpRequest时，dorado才会创建一个新的XMLHttpRequest。 <br>
 * 同样，当一次请求的处理完成后，dorado也不会立刻销毁相应的XMLHttpRequest，而将他放入到对象池中备用。 <br>
 * 通过上述实现方式，可以有效的降低带有大量Ajax操作的页面的系统消耗，提高页面的响应速度。 </li>
 * <li> <b>支持自动批量请求的功能</b> -
 * 远程过程访问常常被认为是Ajax应用的运行过程中较为消耗时间的一个环节，因此如果能够尽可能减少远程过程访问(即向Server发出请求)的次数，
 * 应当可以使页面的效率得到提高。 <br>
 * AjaxEngine支持自动收集极短时间内连续向Server发出的请求，并且把它们打包成一次批量操作的请求发往服务器。 <br>
 * 此功能的生效须满足一些前提条件，例如这些批量请求的URL必须是一样的，不能带有Parameter，而且此功能需要服务器上的执行逻辑提供适当的支持。 </li>
 * </ul>
 * </p>
 * @extends dorado.EventSupport
 * @see $ajax
 */
dorado.util.AjaxEngine = $extend([dorado.AttributeSupport, dorado.EventSupport], /** @scope dorado.util.AjaxEngine.prototype */
	{
		$className: "dorado.util.AjaxEngine",

		constructor: function(options) {
			this._requests = [];
			this._connectionPool = dorado.util.AjaxConnectionPool;
			$invokeSuper.call(this);
			if (options) this.set(options);
		},

		ATTRIBUTES: /** @scope dorado.util.AjaxEngine.prototype */
		{
			/**
			 * 默认的执行选项。 执行选项中可包含下列一些属性：
			 * <ul>
			 * <li>url - {String} 请求的URL。</li>
			 * <li>method - {String} 请求时的HttpMethod，可选的值包括GET、POST、PUT、DELETE。默认将按照GET来处理。</li>
			 * <li>header - {Object} 请求时包含在HttpRequest中的头信息 所有的头信息以属性的方式存放在json对象中。
			 * 最终在请求发出时所包含的头信息是此处的头信息和方法的options参数中的头信息的合集，如二者之间的属性定义有冲突，则以方法的options参数中头信息的为准。</li>
			 * <li>xmlData - {String} 请求时以POST方法发往服务器的XML信息。</li>
			 * <li>jsonData - {Object|Object[]} 请求时以POST方法发往服务器的JSON信息。</li>
			 * <li>message - {String} 当请求尚未结束时希望系统显示给用户的提示信息。此属性目前仅在以异步模式执行时有效，如果设置此属性为none或null则表示不显示提示信息。</li>
			 * </ul>
			 * 上述属性中xmlData和jsonData在定义时只可选择其一。如果同时定义了这两个属性将只有xmlData会生效。
			 * @type Object
			 * @attribute writeOnce
			 *
			 * @example
			 * ajaxEngine.set("defaultOptions", {
		 *		 url: "/xxx.do"
		 *		 method: "POST",
		 *		 headers: {
		 *			 "content-type": "test/xml",
		 *			 "sample-header": "xxxxx"
		 *		 }
		 *	 });
			 */
			defaultOptions: {
				writeOnce: true
			},

			/**
			 * 是否启用自动批量请求的功能。默认值为false。
			 * <p>
			 * 此功能一般须配合minConnectInterval、maxBatchSize、defaultOptions等属性一同使用。
			 * 如果autoBatchEnabled属性为true，当AjaxEngine开始侦测到某一次发往服务器的请求时，
			 * 会暂时搁置该请求及之后发生的请求并开始计时，直到minConnectInterval属性指定时间耗尽或被搁置的请求的数量达到maxBatchSize属性设定的上限。
			 * 然后AjaxEngine会将这些请求进行打包合并，最后一次批量请求的方式发往服务器。
			 * </p>
			 * @type boolean
			 * @attribute
			 * @see dorado.util.AjaxEngine#setAutoBatchEnabled
			 */
			autoBatchEnabled: {
				setter: function(value) {
					if (value && !(this._defaultOptions && this._defaultOptions.url)) {
						throw new dorado.ResourceException("dorado.core.BatchUrlUndefined");
					}
					this._autoBatchEnabled = value;
				}
			},

			/**
			 * 最小的与服务器建立的连接的时间间隔(毫秒数)。此属性仅在autoBatchEnabled属性为true时生效。
			 * @type int
			 * @attribute
			 * @default 10
			 */
			minConnectInterval: {
				defaultValue: 20
			},

			/**
			 * 每一次批量请求中允许的最大子请求数量。此属性仅在autoBatchEnabled属性为true时生效。
			 * @type int
			 * @attribute
			 * @default 20
			 */
			maxBatchSize: {
				defaultValue: 20
			}
		},

		EVENTS: /** @scope dorado.util.AjaxEngine.prototype */
		{
			/**
			 * 当AjaxEngine将要发出以个请求时触发的事件。
			 * @param {Object} self 事件的发起者，即AjaxEngine本身。
			 * @param {Object} arg 事件参数。
			 * @param {boolean} arg.async 是否异步操作。
			 * @param {Object} arg.options 执行选项，见{@link dorado.util.AjaxEngine#request}中的options参数。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 * @event
			 */
			beforeRequest: {},

			/**
			 * 当AjaxEngine某个请求执行结束后(包含因失败而结束的情况)触发的事件。
			 * @param {Object} self 事件的发起者，即AjaxEngine本身。
			 * @param {Object} arg 事件参数。
			 * @param {boolean} arg.async 是否异步操作。
			 * @param {Object} arg.options 本次请求得到的返回结果。，见{@link dorado.util.AjaxResult}。
			 * @return {boolean} result  是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onResponse: {},

			/**
			 * 当AjaxEngine将要与服务器建立连接时触发的事件。
			 * @param {Object} self 事件的发起者，即AjaxEngine本身。
			 * @param {Object} arg 事件参数。
			 * @param {boolean} arg.async 是否异步操作。
			 * @param {Object} arg.options 执行选项，见{@link dorado.util.AjaxEngine#request}中的options参数。
			 * @return {boolean} result  是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			beforeConnect: {},

			/**
			 * 当AjaxEngine断开与服务器建立连接时触发的事件。
			 * @param {Object} self 事件的发起者，即AjaxEngine本身。
			 * @param {Object} arg 事件参数。
			 * @param {boolean} arg.async 是否异步操作。
			 * @param {Object} arg.options 本次请求得到的返回结果。，见{@link dorado.util.AjaxResult}。
			 * @return {boolean} result  是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDisconnect: {}
		},

		/**
		 * 发起一个异步的请求。
		 * @param {String|Object} [options] 执行选项。
		 * <p>
		 * 此参数有两种定义方式:
		 * <ul>
		 * <li>当此参数的类型是String时，系统直接将此参数作为请求的URL。</li>
		 * <li>当此参数的类型是JSON对象时，系统将此参数执行选项，并处理其中的子属性。</li>
		 * </ul>
		 * </p>
		 * <p>
		 * 需要注意的是，下面的xmlData和jsonData子参数在定义时只可选择其一。如果同时定义了这两个属性将只有xmlData会生效。
		 * </p>
		 * @param {String} [options.url] 请求的URL，如果此属性未指定则使用defaultOptions.url的定义。
		 * @param {String} [options.method="GET"] 请求时的HttpMethod，可选值包括GET、POST、PUT、DELETE。如果此属性未指定则使用defaultOptions.method的定义。
		 * @param {String} [options.parameter] 请求是附带的参数。
		 * 这些参数以子属性值的方式保存在此JSON对象中。
		 * <b>对于POST方法的请求而言，如果在定义了parameter的同时又定义了xmlData或jsonData，那么parameter将被添加到url中以类似GET请求的方式发送。、
		 * 真正通过POST方法发送的数据将是xmlData或jsonData。</b>
		 * @param {int} [options.timeout] 以毫秒为单位的超时时长。此特性在同步模式下不生效。
		 * @param {boolean} [options.batchable] 是否支持自动批量请求模式。此特性在同步模式下不生效。
		 * @param {String} [options.header] 请求时包含在HttpRequest中的头信息。
		 * 这些头信息以子属性值的方式保存在此JSON对象中。
		 * 最终在请求发出时所包含的头信息是defaultOptions.header和此处header属性的合集，如二者之间的属性定义有冲突，则以此处header属性中的为准。
		 * @param {String} [options.xmlData] 请求时以POST方法发往服务器的XML信息。
		 * @param {Object} [options.jsonData] 请求时以POST方法发往服务器的JSON信息。
		 * @param {String} [options.message] 当请求尚未结束时希望系统显示给用户的提示信息。此属性目前仅以异步模式执行时有效。
		 * @param {Function|dorado.Callback} [callback] 回调对象。传入回调对象的结果参数是{@link dorado.util.AjaxResult}对象。
		 * @throws {dorado.util.AjaxException}
		 * @throws {Error}
		 *
		 * @example
		 * // 发起一个Ajax异步请求，使用Function作为回调对象。
		 * var ajax = new AjaxEngine();
		 * ajax.request({
		 * 	url: "/delete-employee.do",
		 * 	method: "POST",
		 * 	jsonData: ["0001", "0002", "0005"]
		 * 	// 定义要提交给服务器的信息。
		 * }, function(result) {
		 * 	alert(result.responseText);
		 * });
		 *
		 * @example
		 * <pre>
		 * // 发起一个Ajax异步请求，并声明一个回调对象。
		 * var ajax = new AjaxEngine();
		 * ajax.request({
		 * 	timeout: parseInt("30000"), // 设置Ajax操作的超时时间为30秒
		 * 	url: "/delete-employee.do",
		 * 	method: "POST",
		 * 	xmlData: "&lt;xml&gt;&lt;id&gt;0001&lt;/id&gt;&lt;id&gt;0002&lt;/id&gt;&lt;id&gt;0005&lt;/id&gt;&lt;/xml&gt;"
		 * }, {
		 * 	success: function(result) {
		 * 		alert("操作成功：" + result.responseText);
		 * 	},
		 * 	failure: function(e) {
		 * 		alert("操作失败：" + e);
		 * 	}
		 * });
		 * </pre>
		 *
		 * @example
		 * // 使用自动批量请求功能。
		 * // 以上的三个请求最终将被AjaxEngine打包成一个批量请求，并发往服务器。
		 * var ajax = new AjaxEngine();
		 * ajax.set("options", {
		 * 	// 每一个支持批量操作的请求的url都必须是一致的。
		 * 	url: "/delete-employee.do",
		 *
		 * 	// 每一个支持批量操作的请求的method都必须是一致的。
		 * 	method: "POST"
		 * });
		 *
		 * // 启用自动批量请求功能。
		 * ajax.setAutoBatchEnabled(true);
		 *
		 * ajax.request({
		 * 	jsonData: "0001"
		 * }, function(result) {
		 * 	alert(result.responseText);
		 * });
		 *
		 * ajax.request({
		 * 	jsonData: "0002"
		 * }, function(result) {
		 * 	alert(result.responseText);
		 * });
		 *
		 * ajax.request({
		 * 	jsonData: "0005"
		 * }, function(result) {
		 * 	alert(result.responseText);
		 * });
		 */
		request: function(options, callback) {
			if (typeof options == "string") {
				options = {
					url: options
				};
			}

			var id = dorado.Core.newId();
			dorado.util.AjaxEngine.ASYNC_REQUESTS[id] = true;
			
			var callbackWrapper = {
					callback: function(success, result) {
						var timerId = dorado.util.AjaxEngine.ASYNC_REQUESTS[id];
						if (timerId) {
							if (typeof timerId == "number") clearTimeout(timerId);
							delete dorado.util.AjaxEngine.ASYNC_REQUESTS[id];
							$callback(callback, success, result);
						}
					}
				};
			
			var useBatch = this._autoBatchEnabled && (options.batchable === true);
			if (useBatch) {
				if (options) {
					if (options.url && options.url != this._defaultOptions.url || options.method && options.method != "POST" || options.timeout) {
						useBatch = false;
					}
					if (useBatch && options.headers) {
						for(var prop in options.headers) {
							if (options.headers.hasOwnProperty(prop)) {
								useBatch = false;
								break;
							}
						}
					}
				}

				var requests = this._requests;
				if (requests.length == 0) {
					this._batchTimerId = $setTimeout(this, function() {
						this._requestBatch(true);
					}, this._minConnectInterval);
					this._oldestPendingRequestTime = new Date();					
					dorado.util.AjaxEngine.INSTANCES_PENDING_REQUESTS.push(this);
				}

				this.fireEvent("beforeRequest", this, {
					async: true,
					options: options
				});

				var message = options.message, taskId;
				if (message && message != "none") {
					taskId = dorado.util.TaskIndicator.showTaskIndicator(message, options.modal ? "main" : "daemon");
				}
				
				if (callback && options && options.timeout) {
					dorado.util.AjaxEngine.ASYNC_REQUESTS[id] = $setTimeout(this, function() {
						var result = new dorado.util.AjaxResult(options);
						result._setException(new dorado.util.AjaxTimeoutException($resource("dorado.core.AsyncRequestTimeout", options.timeout)));
						$callback(callbackWrapper, false, result, {
							scope: this
						});
					}, options.timeout);
				}

				requests.push({
					options: options,
					callback: callbackWrapper,
					taskId: taskId
				});

				if (requests.length >= this._maxBatchSize) {
					this._requestBatch(true);
				}
			}
			else {
				this.requestAsync(options, callbackWrapper);
			}
		},

		_requestBatch: function(force) {
			if (!force) {
				if (this._oldestPendingRequestTime && (new Date() - this._oldestPendingRequestTime) < this._minConnectInterval) {
					return;
				}
			}

			if (this._batchTimerId) {
				clearTimeout(this._batchTimerId);
				this._batchTimerId = 0;
			}

			var requests = this._requests;
			if (requests.length == 0) return;
			this._requests = [];
			this._oldestPendingRequestTime = 0;
			dorado.util.AjaxEngine.INSTANCES_PENDING_REQUESTS.remove(this);

			var batchCallback = {
				scope: this,
				callback: function(success, batchResult) {
					function createAjaxResult(options) {
						var result = new dorado.util.AjaxResult(options);
						result._init(batchResult._connObj);
						return result;
					}

					if (success) {
						var xmlDoc = jQuery(batchResult.getXmlDocument());

						var i = 0;
						xmlDoc.find("result>request").each($scopify(this, function(index, elem) {
							var request = requests[i];
							if (request.taskId) {
								dorado.util.TaskIndicator.hideTaskIndicator(request.taskId);
							}

							var result = createAjaxResult(request.options);

							var el = jQuery(elem);
							var exceptionEl = el.children("exception");
							var success = (exceptionEl.size() == 0);
							if (success) {
								var responseEl = el.children("response");
								result.text = responseEl.text();
							}
							else {
								result.text = exceptionEl.text();
								if (exceptionEl.attr("type") == "runnable") {
									result._parseRunnableException(result.text);
								}
								else {
									result._setException(result._parseException(result.text, batchResult._connObj));
								}
							}
							$callback(request.callback, success, result);

							this.fireEvent("onResponse", this, {
								async: true,
								result: result
							});
							i++;
						}));
					}
					else {
						for(var i = 0; i < requests.length; i++) {
							var request = requests[i];
							if (request.taskId) {
								dorado.util.TaskIndicator.hideTaskIndicator(request.taskId);
							}

							var result = createAjaxResult(request.options);
							result._setException(batchResult.exception);
							$callback(request.callback, false, result);

							this.fireEvent("onResponse", this, {
								async: true,
								result: result
							});
						}
					}
				}
			};

			var sendData = ["<batch>\n"];
			for(var i = 0; i < requests.length; i++) {
				var request = requests[i];
				var options = request.options;
				var type = "";
				if (options) {
					if (options.xmlData) {
						type = "xml";
					}
					else if (options.jsonData) {
						type = "json";
					}
				}

				sendData.push("<request type=\"" + type + "\"><![CDATA[");

				var data = this._getSendData(options);
				if (data) data = data.replace(/]]>/g, "]]]]><![CDATA[>");
				sendData.push(data);

				sendData.push("]]></request>\n");
			}
			sendData.push("</batch>");

			var batchOptions = {
				isBatch: true,
				xmlData: sendData.join('')
			};
			this.requestAsync(batchOptions, batchCallback);
		},
		
		/**
		 * 发起一个异步的请求。
		 * <p>
		 * 此方法看起来与request()完成的功能是很像的，不同点在于此方法会忽略掉autoBatchEnabled的设置。
		 * 即利用此方法发出的请求不会被自动批量请求功能搁置，而总是会立刻发往服务器。<br>
		 * <b>在通常情况下，我们不建议您直接使用此方法，而应该用request()方法替代。</b>
		 * </p>
		 * @protected
		 * @param {Object} [options] 执行选项，请参考本类中request()方法的options参数的描述。
		 * @param {Function|dorado.Callback} [callback] 回调对象。
		 * @throws {dorado.util.AjaxException}
		 * @throws {Error}
		 * @see dorado.util.AjaxEngine#request
		 */
		requestAsync: function(options, callback) {
			var connObj = this._connectionPool.borrowObject();
			this._init(connObj, options, true);

			var eventArg = {
				async: true,
				options: options
			};
			if (options == null || !options.isBatch) {
				this.fireEvent("beforeRequest", this, eventArg);
			}
			this.fireEvent("beforeConnect", this, eventArg);

			var conn = connObj.conn;

			var message = options.message, taskId;
			if (message && message != "none") {
				taskId = dorado.util.TaskIndicator.showTaskIndicator(message, options.modal ? "main" : "daemon");
			}
			
			if (callback && options && options.timeout) {
				connObj.timeoutTimerId = $setTimeout(this, function() {
					try {
						if (taskId) {
							dorado.util.TaskIndicator.hideTaskIndicator(taskId);
						}

						var result = new dorado.util.AjaxResult(options);
						try {
							result._init(connObj);
						}
						catch(e) {
							// do nothing
						}
						result._setException(new dorado.util.AjaxTimeoutException($resource("dorado.core.AsyncRequestTimeout", options.timeout), null, connObj));
						$callback(callback, false, result, {
							scope: this
						});

						var eventArg = {
							async: true,
							result: result
						};

						this.fireEvent("onDisconnect", this, eventArg);
						if (options == null || !options.isBatch) {
							this.fireEvent("onResponse", this, eventArg);
						}
					}
					finally {
						this._connectionPool.returnObject(connObj);
					}
				}, options.timeout);
			}

			conn.onreadystatechange = $scopify(this, function() {
				if (conn.readyState == 4) {
					try {
						if (taskId) dorado.util.TaskIndicator.hideTaskIndicator(taskId);
						if (callback && options && options.timeout) {
							clearTimeout(connObj.timeoutTimerId);
						}
						var result = new dorado.util.AjaxResult(options, connObj);

						var eventArg = {
							async: true,
							result: result
						};
						this.fireEvent("onDisconnect", this, eventArg);

						$callback(callback, result.success, result, {
							scope: this
						});

						if (options == null || !options.isBatch) {
							this.fireEvent("onResponse", this, eventArg);
						}
					}
					finally {
						this._connectionPool.returnObject(connObj);
					}
				}
			});
			conn.send(this._getSendData(options));
		},

		_setHeader: function(connObj, options) {

			function setHeaders(conn, headers) {
				if (!headers) return;
				for(var prop in headers) {
					if (headers.hasOwnProperty(prop)) {
						var value = headers[prop];
						if (value != null) {
							conn.setRequestHeader(prop, value);
						}
					}
				}
			}

			if (this._defaultOptions) {
				setHeaders(connObj.conn, this._defaultOptions.headers);
			}
			if (options) {
				setHeaders(connObj.conn, options.headers);
			}
		},

		_init: function(connObj, options, async) {

			function urlAppend(url, p, s) {
				if (s) {
					return url + (url.indexOf('?') === -1 ? '?' : '&') + p + '=' + encodeURI(s);
				}
				return url;
			}

			var url, method;
			if (options) {
				url = options.url;
				method = options.method;

				if (!options.headers) {
					options.headers = {};
				}
				if (options.xmlData) {
					options.headers["content-type"] = "text/xml";
					method = "POST";
				}
				else if (options.jsonData) {
					options.headers["content-type"] = "text/javascript";
					method = "POST";
				}
			}

			var defaultOptions = (this._defaultOptions) ? this._defaultOptions : {};
			url = url || defaultOptions.url;
			method = method || defaultOptions.method || "GET";

			var parameter = options.parameter;
			if (parameter && (method == "GET" || options.xmlData || options.jsonData)) {
				if (typeof parameter == "string") {
					url += (url.indexOf('?') === -1 ? '?' : '&') + encodeURI(parameter);
				}
				else {
					for(var p in parameter) {
						if (parameter.hasOwnProperty(p)) {
							url = urlAppend(url, p, parameter[p]);
						}
					}
				}
			}

			connObj.url = url = $url(url);
			connObj.method = method;
			connObj.options = options;

			connObj.conn.open(method, url, async);
			this._setHeader(connObj, options);
		},

		_getSendData: function(options) {
			if (!options) {
				return null;
			}
			var data = null;
			if (options.xmlData) {
				data = options.xmlData;
			}
			else if (options.jsonData) {
				data = dorado.JSON.stringify(options.jsonData, {
					replacer: function(key, value) {
						return (typeof value == "function") ? value.call(this) : value;
					}
				});
			}
			else if (options.parameter) {
				var parameter = options.parameter;
				data = '';
				var i = 0;
				for(var p in parameter) {
					if (parameter.hasOwnProperty(p)) {
						data += (i > 0 ? '&' : '') + p + '=' + encodeURI(parameter[p]);
						i++;
					}
				}
			}
			return data;
		},
		/**
		 * 发起一个同步的请求。
		 * @param {String|Object} [options] 执行选项，请参考本类中request()方法的options参数的描述。
		 * @param {boolean} [alwaysReturn] 即使发生错误也返回一个包含异常信息的{@link dorado.util.AjaxResult}，而不是抛出异常信息。默认值为false，即允许抛出异常。
		 * @return {dorado.util.AjaxResult} 执行结果。
		 * @throws {dorado.util.AjaxException}
		 * @throws {Error}
		 *
		 * @example
		 * var ajax = new AjaxEngine();
		 * var result = ajax.requestSync({
		 * 	url: "/delete-employee.do",
		 * 	method: "POST",
		 * 	jsonData: ["0001", "0002", "0005"]
		 * 	// 定义要提交给服务器的信息
		 * });
		 * alert(result.responseText);
		 */
		requestSync: function(options, alwaysReturn) {
			if (typeof options == "string") {
				options = {
					url: options
				};
			}

			var connObj = this._connectionPool.borrowObject();
			try {
				var eventArg = {
					async: false,
					options: options
				};
				this.fireEvent("beforeRequest", this, eventArg);
				this.fireEvent("beforeConnect", this, eventArg);

				var exception = null;
				try {
					this._init(connObj, options, false);
					connObj.conn.send(this._getSendData(options));
				}
				catch(e) {
					exception = e;
				}

				var result = new dorado.util.AjaxResult(options);
				if (exception != null) {
					result._init(connObj);
					result._setException(exception);
				}
				else {
					result._init(connObj, true);
				}
				eventArg = {
					async: true,
					result: result
				};
				this.fireEvent("onDisconnect", this, eventArg);
				this.fireEvent("onResponse", this, eventArg);

				if (!alwaysReturn && exception != null) {
					throw exception;
				}
				return result;
			}
			finally {
				this._connectionPool.returnObject(connObj);
			}
		}
	});

dorado.util.AjaxEngine._parseXml = function(xml) {
	var xmlDoc = null;
	try {
		if (dorado.Browser.msie) {
			var activeX = ["MSXML2.DOMDocument", "MSXML.DOMDocument"];
			for(var i = 0; i < activeX.length; ++i) {
				try {
					xmlDoc = new ActiveXObject(activeX[i]);
					break;
				}
				catch(e) {
					// do nothing
				}
			}
			xmlDoc.loadXML(xml);
		}
		else {
			var parser = new DOMParser();
			xmlDoc = parser.parseFromString(xml, "text/xml");
		}
	}
	finally {
		return xmlDoc;
	}
};

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 用于描述Ajax操作(包含同步请求)过程中发生的异常信息的对象。
 * @extends dorado.Exception
 * @param {String} [message] 异常消息。
 * @param {String} [description] 异常的描述信息。
 * @param {XMLHttpRequest} [connObj] 用于实现远程访问的XMLHttpRequest对象。
 */
dorado.util.AjaxException = $extend(dorado.Exception, /** @scope dorado.util.AjaxException.prototype */ {
	$className: "dorado.util.AjaxException",

	constructor: function(message, description, connObj) {
		/**
		 * 异常消息。
		 * @type String
		 */
		this.message = message || "Unknown Exception.";

		/**
		 * 异常的描述信息。
		 * @type String
		 */
		this.description = description;

		if (connObj != null) {
			/**
			 * 请求的URL。
			 * @type String
			 */
			this.url = connObj.url;
	
			/**
			 * 发起请求时使用的HttpMethod。
			 * @type String
			 * @default "GET"
			 */
			this.method = connObj.method;
	
			/**
			 * 服务器返回的Http状态码。<br>
			 * 如：200表示正常返回、404表示请求的资源不存在等，详情请参考Http协议说明。
			 * @type int
			 */
			this.status = connObj.conn.status;
	
			/**
			 * 服务器返回的Http状态描述。<br>
			 * 如：OK表示正常返回、NOT_MODIFIED表示资源未发生任何改变等，详情请参考Http协议说明。
			 * @type String
			 */
			this.statusText = connObj.conn.statusText;
	
			// IE - #1450: sometimes returns 1223 when it should be 204
			if (this.status === 1223) {
				this.status = 204;
			}
		}

		$invokeSuper.call(this, arguments);
	},

	toString: function() {
		var text = this.message;
		if (this.url) {
			text += "\nURL: " + this.url;
		}
		if (this.status) {
			text += "\nStatus: " + this.statusText + '(' + this.status + ')';
		}
		if (this.description) {
			text += '\n' + this.description;
		}
		return text;
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class Ajax操作的超时异常。
 * @extends dorado.util.AjaxException
 * @param {String} [message] 异常消息。
 * @param {String} [description] 异常的描述信息。
 * @param {XMLHttpRequest} [connObj] 用于实现远程访问的XMLHttpRequest对象。
 */
dorado.util.AjaxTimeoutException = $extend(dorado.util.AjaxException, /** @scope dorado.util.AjaxTimeoutException.prototype */ {
	$className: "dorado.util.AjaxTimeoutException"
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 用于封装Ajax请求(包含同步请求)返回结果的对象。
 * @description 构造器。
 * @param {Object} options 发起请求时使用的请求选项。
 * @param {XMLHttpRequest} [connObj] 用于实现远程访问的XMLHttpRequest对象。
 */
dorado.util.AjaxResult = $class(/** @scope dorado.util.AjaxResult.prototype */
	{
		$className: "dorado.util.AjaxResult",

		constructor: function(options, connObj) {
			/**
			 * @name dorado.util.AjaxResult#options
			 * @property
			 * @description 发起请求时使用的请求选项。
			 * @type Object
			 */
			this.options = options;

			if (connObj != null) {
				this._init(connObj, true);
			}
		},
		/**
		 * Ajax请求是否执行成功。
		 * @type boolean
		 * @default true
		 */
		success: true,

		_init: function(connObj, parseResponse) {
			this._connObj = connObj;

			/**
			 * 请求的URL。
			 * @type String
			 */
			this.url = connObj.url;

			/**
			 * 发起请求时使用的HttpMethod。
			 * @type String
			 */
			this.method = connObj.method;

			var conn = connObj.conn;

			/**
			 * 服务器返回的Http状态码。<br>
			 * 如：200表示正常返回、404表示请求的资源不存在等，详情请参考Http协议说明。
			 * @type int
			 */
			this.status = conn.status;

			/**
			 * 服务器返回的Http状态描述。<br>
			 * 如：OK表示正常返回、NOT_MODIFIED表示资源未发生任何改变等，详情请参考Http协议说明。
			 * @type String
			 */
			this.statusText = conn.statusText;

			/**
			 * 包含所有的Response头信息的字符串。<br>
			 * 其格式为：header1=value1;header2=value2;...
			 * @type String
			 */
			this.allResponseHeaders = conn.getAllResponseHeaders();

			if (parseResponse) {
				/**
				 * 服务器返回的原始文本信息。
				 * @type String
				 */
				this.text = conn.responseText;

				var exception, contentType = this.getResponseHeaders()["content-type"];
				if (contentType && contentType.indexOf("text/dorado-exception") >= 0) {
					exception = this._parseException(conn.responseText, connObj);
				}
				else if (contentType && contentType.indexOf("text/runnable") >= 0) {
					exception = this._parseRunnableException(conn.responseText, connObj);
				}
				else if (conn.status < 200 || conn.status >= 400) {
					if (dorado.windowClosed && conn.status == 0) {
						exception = new dorado.AbortException();
					}
					else {
						exception = new dorado.util.AjaxException("HTTP " + conn.status + " " + conn.statusText, null, connObj);
						if (conn.status == 0) {
							exception._processDelay = 1000;
						}
					}
				}
				if (exception) this._setException(exception);
			}
		},

		_setException: function(exception) {
			this.success = false;

			/**
			 * 请求过程中发生的异常。
			 * @type Error
			 */
			this.exception = exception;
		},

		_parseException: function(text) {
			var json = dorado.JSON.parse(text);
			if (json.exceptionType == "com.bstek.dorado.view.resolver.AbortException") {
				return new dorado.AbortException(json.message);
			}
			else {
				return new dorado.RemoteException(json.message, json.exceptionType, json.stackTrace);
			}
		},

		_parseRunnableException: function(text) {
			return new dorado.RunnableException(text);
		},

		/**
		 * 返回一个包含所有的Response头信息的对象。<br>
		 * 所有的Response头信息以属性的形式存放在该对象中，其形式如下：<br>
		 * <pre class="symbol-example code">
		 * <code class="javascript">
		 * {
		 *	 "content-type": "text/xml",
		 *	 "header1": "value1",
		 *	 "header2": "value2",
		 *	 ... ... ...
		 * }
		 * </code>
		 * </pre>
		 * @return {Object} 包含所有的Response头信息的对象。
		 */
		getResponseHeaders: function() {
			var responseHeaders = this._responseHeaders;
			if (responseHeaders === undefined) {
				responseHeaders = {};
				this._responseHeaders = responseHeaders;
				try {
					var headerStr = this.allResponseHeaders;
					var headers = headerStr.split('\n');
					for(var i = 0; i < headers.length; i++) {
						var header = headers[i];
						var delimitPos = header.indexOf(':');
						if (delimitPos != -1) {
							responseHeaders[header.substring(0, delimitPos).toLowerCase()] = header.substring(delimitPos + 2);
						}
					}
				}
				catch(e) {
					// do nothing
				}
			}
			return responseHeaders;
		},

		/**
		 * 以XmlDocument的形式获得服务器返回的Response信息。
		 * @return {XMLDocument} XmlDocument。
		 */
		getXmlDocument: function() {
			var responseXML = this._responseXML;
			if (responseXML === undefined) {
				responseXML = dorado.util.AjaxEngine._parseXml(this.text);
				this._responseXML = responseXML;
			}
			return responseXML;
		},

		/**
		 * 以JSON数据的形式获得服务器返回的Response信息。
		 * @param {boolean} [untrusty] 服务器返回的Response信息是否是不可信的。默认为false，即Response信息是可信的。<br>
		 * 此参数将决定dorado通过何种方式来解析服务端返回的JSON字符串，为了防止某些嵌入在JSON字符串中的黑客代码对应用造成伤害，
		 * dorado可以使用安全的方式来解析JSON字符串，但是这种安全检查会带来额外的性能损失。
		 * 因此，如果您能够确定访问的服务器是安全的，其返回的JSON字符串不会嵌入黑客代码，那么就不必开启此选项。
		 * @return {Object} JSON数据。
		 */
		getJsonData: function(untrusty) {
			var jsonData = this._jsonData;
			if (jsonData === undefined) {
				this._jsonData = jsonData = dorado.JSON.parse(this.text, untrusty);
			}
			return jsonData;
		}
	});

dorado.util.AjaxEngine.INSTANCES_PENDING_REQUESTS = [];
dorado.util.AjaxEngine.SHARED_INSTANCES = {};
dorado.util.AjaxEngine.ASYNC_REQUESTS = {};

dorado.util.AjaxEngine.getInstance = function(options) {
	var defaultOptions = $setting["ajax.defaultOptions"];
	if (defaultOptions) {
		defaultOptions = dorado.Object.apply({}, defaultOptions);
		options = dorado.Object.apply(defaultOptions, options);
	}
	var key = (options.url || "#EMPTY") + '|' + (options.batchable || false) + '|' + (options.method);
	var ajax = dorado.util.AjaxEngine.SHARED_INSTANCES[key];
	if (ajax === undefined) {
		ajax = new dorado.util.AjaxEngine({
			defaultOptions: options,
			autoBatchEnabled: options.autoBatchEnabled || options.batchable
		});
		dorado.util.AjaxEngine.SHARED_INSTANCES[key] = ajax;
	}
	return ajax;
}

dorado.util.AjaxEngine.processAllPendingRequests = function(force) {
	var engines = dorado.util.AjaxEngine.INSTANCES_PENDING_REQUESTS;
	if (!engines.length) return;
	for (var i = 0, len = engines.length; i < len; i++) {
		engines[i]._requestBatch(force);
	}
},

/**
 * @name $ajax
 * @property
 * @description 默认的dorado.util.AjaxEngine实例。
 * <p>
 * 很多情况下，我们建议您直接利用$ajax来完成Ajax操作，这样就不必频繁的创建dorado.util.AjaxEngine的对象实例了。
 * </p>
 * @see dorado.util.AjaxEngine
 *
 * @example
 * // 发起一个Ajax异步请求，使用Function作为回调对象。
 * $ajax.request( {
 * 	url : "/delete-employee.do",
 * 	method : "POST",
 * 	jsonData : [ "0001", "0002", "0005" ] // 定义要提交给服务器的信息
 * }, function(result) {
 * 	alert(result.responseText);
 * });
 */
window.$ajax = new dorado.util.AjaxEngine();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 仿Map对象。用于维护若干组键值对。
 * <p>
 * 此对象最经常被使用的场景是在DataSet、Action、Reference等对象的parameter属性中。
 * 因为很多时候我们会希望将这写地方的parameter参数设置成类似Map的形式，以便于利用Map的特性在parameter中维护若干个子参数，每一个自参数保存在Map的一个键值下。
 * 这样就可以比较方便的在逻辑代码中根据实际需要增删Map中的子参数。<br>
 * 当然，这一功能通过标准的JSON对象完全可以实现，这里的Map对象只是可以让这种使用方法变得更加简单而已。
 * </p>
 * <p>
 * 假设您通过Dorado的IDE将某Action的parameter属性定义成一个Entity，且其中包含了两个属性值a和b作为两个子参数。
 * 当该属性被Dorado引擎自动生成到客户端时，Dorado会自动将其创建为一个Map对象。
 * 如果在实际的运行过程中您又有两个额外的子参数c和d需要添加到这个Map对象中时，你只需要调用如下的方法：
 * <pre class="symbol-example code">
 * <code class="javascript">
 * action.set("parameter", $map({ c: "xxx", d: true }));
 * </code>
 * </pre>
 * Dorado就会自动将c和d合并到parameter属性原有的Map中，而不是直接用这个只包含c和d的Map替换之。<br>\
 * 之所以这样是因为，对于上述提及的这些parameter属性Dorado都已内置了针对Map的特殊处理逻辑。
 * 只要某属性原先的值类型是一个Map，当通过set方法为其设置一个新的Map时，Dorado会自动将新的Map中的键值对合并到原Map中。<br>
 * 当某属性原有的值和将要写入的值中有任何一个不是Map类型时，Dorado将只会使用最简单的属性写入逻辑。即将原有的值完整的替换掉。
 * </p>
 * @param {Object|dorado.util.Map} [config] 用于初始化Map键值对的参数。
 * 此参数应是一个JSON对象，其中定义的所有属性会自动的被添加到Map中。
 * @see $map
 */
dorado.util.Map = $class(/** @scope dorado.util.Map.prototype */{
	$className: "dorado.util.Map",
	
	constructor: function(config) {
		this._map = {};
		if (config && config instanceof Object) this.put(config);
	},
	
	/**
	 * 向Map中添加一到多个键值对。
	 * <p>
	 * 此方法有如下两种使用方式：
	 * <ul>
	 * 	<li>添加一组键值对，以String的形式定义key参数，同时定义value参数。</li>
	 * 	<li>一次性的添加多组键值对，以JSON/dorado.util.Map的形式定义key参数。此时不需要定义value参数。</li>
	 * </ul>
	 * </p>
	 * @param {String|Object|dorado.util.Map} key 要设置的键或者以JSON/dorado.util.Map方式定义的若干组键值对。
	 * @param {Object} [value] 键值。
	 */
	put: function(k, v) {
		if (!k) return;
		if (v === undefined && k instanceof Object) {
			var obj = k;
			if (obj instanceof dorado.util.Map) {
				obj = obj._map;
			}
			if (obj) {
				var map = this._map;
				for (var p in obj) {
					if (obj.hasOwnProperty(p)) map[p] = obj[p];
				}
			}
		} else {
			this._map[k] = v;
		}
	},
	
	/**
	 * 此方法与{@link dorado.util.Map#put}的作用和用法完全相同，
	 * 提供该方法目的主要是为了使之与Dorado中的其他对象的使用方法形成统一。
	 * @see dorado.util.Map#put
	 */
	set: function() {
		this.put.apply(this, arguments);
	},
	
	/**
	 * 根据给定的键返回相应的值。
	 * @param {String} key 要读取的键。
	 * @return {Object} 相应的值。
	 */
	get: function(k) {
		return this._map[k];
	},
	
	/**
	 * 返回是否为空。
	 * @return {boolean} 是否为空。
	 */
	isEmpty: function() {
		var map = this._map;
		for (var k in map) {
			if (map.hasOwnProperty(k)) return false;
		}
		return true;
	},
	
	/**
	 * 删除Map中的某个键值对。
	 * @param {String} key 要删除的键。
	 */
	remove: function(k) {
		delete this._map[k];
	},
	
	/**
	 * 清空Map中所有的键值对。
	 */
	clear: function() {
		this._map = {};
	},
	
	/**
	 * 将此Map对象转换为标准的JSON对象并返回。
	 * @return {Object} 包含Map中所有键值对的JSON对象。
	 */
	toJSON: function() {
		return this._map;
	},
	
	/**
	 * 返回包含Map中所有键值的数组。
	 * @return {String[]} 键值数组。
	 */
	keys: function() {
		var map = this._map, keys = [];
		for (var k in map) {
			if (map.hasOwnProperty(k)) keys.push(k);
		}
		return keys;
	},
	
	/**
	 * 遍历所有键值对。
	 * @param {Function} fn 针对数组中每一个元素的回调函数。此函数支持下列两个参数:
	 * <ul>
	 * <li>key - {String} 当前遍历到的键。</li>
	 * <li>value - {Object} 当前遍历到的键值。</li>
	 * </ul>
	 * 另外，此函数的返回值可用于通知系统是否要终止整个遍历操作。
	 * 返回true或不返回任何数值表示继续执行遍历操作，返回false表示终止整个遍历操作。<br>
	 * 此回调函数中的this指向正在被遍历的数组。
	 * 
	 * @example
	 * map.each(function(key, value) {
	 * 	// your code
	 * });
	 */
	eachKey: function(fn) {
		if (!fn) return;
		var map = this._map;
		for (var k in map) {
			if (map.hasOwnProperty(k)) fn.call(this, k, map[k]);
		}
	},
	
	toString: function() {
		return "dorado.util.Map";
	}
});

/**
 * @name $map
 * @function
 * @param {Object} 用于初始化Map键值对的参数。
 * 此参数应是一个JSON对象，其中定义的所有属性会自动的被添加到Map中。
 * @return {dorado.util.Map} 仿Map对象。
 * @description 用于将一个JSON对象包装成dorado的仿Map对象。
 * @see dorado.util.Map
 */
window.$map = function(obj) {
	return new dorado.util.Map(obj);
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	var maxZIndex = 9999;
	
	/**
	 * @name $DomUtils
	 * @property
	 * @description dorado.util.Dom的快捷方式。
	 * @see dorado.util.Dom
	 */
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @author Frank Zhang (mailto:frank.zhang@bstek.com)
	 * @name dorado.util.Dom
	 * @class 提供DOM相关操作的工具类。
	 * @static
	 */
	window.$DomUtils = dorado.util.Dom = {
	
		/**
		 * 返回一个不可见的DIV节点。
		 * <p>
		 * 此处的不可见并非是指利用style.display或style.visibility设置成为不可见的DIV。
		 * 而一个本质可见却位于屏幕之外而无法被看到的DIV。
		 * </p>
		 * <p>
		 * 本方法最多只会创建一个不可见的DIV节点，因此每一次调用此方法我们都会得到相同的返回结果。
		 * </p>
		 * @return {HTMLElement} DIV节点。
		 */
		getInvisibleContainer: function() {
			var id = "_dorado_invisible_div";
			var div = document.getElementById(id);
			if (!div) {
				div = this.xCreate({
					tagName: "DIV",
					id: id,
					style: {
						position: "absolute",
						width: 100,
						height: 100,
						left: -200,
						top: -200,
						overflow: "hidden"
					}
				});
				document.body.appendChild(div);
			}
			return div;
		},
		
		getUndisplayContainer: function() {
			var id = "_dorado_undisplay_div";
			var div = document.getElementById(id);
			if (!div) {
				div = this.xCreate({
					tagName: "DIV",
					id: id,
					style: {
						visibility: "hidden",
						display: "none"
					}
				});
				document.body.appendChild(div);
			}
			return div;
		},
		
		/**
		 * 根据传入的节点返回节点所属的window对象。
		 * @param {HTMLElement} node HTML元素或节点。
		 * @return {Window} window对象。
		 */
		getOwnerWindow: function(node) {
			return dorado.Browser.msie ? node.ownerDocument.parentWindow : node.ownerDocument.defaultView;
		},
		
		/**
		 * 判断owner参数代表的节点是否是node参数代表的节点的上级节点。
		 * @param {HTMLElement} node 要判断的节点。
		 * @param {HTMLElement} owner 上级节点。
		 * @return {boolean} 是否上级节点。
		 */
		isOwnerOf: function(node, owner) {
			while (true) {
				node = node.parentNode;
				if (node == null) return false;
				if (node == owner) return true;
			}
		},
		
		/**
		 * 根据fn函数所代表的匹配规则，查找第一个匹配的父节点。
		 * @param {HTMLElement} node 子节点。
		 * @param {Function} fn 用于描述匹配规则的函数。
		 * @param {boolean} [includeSelf=true] 查找范围中是否包含node参数指定的子节点自身，默认为true。
		 * @return {HTMLElement} 找到的父节点。
		 *
		 * @example
		 * // 查找并返回node节点的&lt;DIV&gt;类型的父节点
		 * var parentDiv = dorado.util.Dom.findParent(node, function(parentNode) {
		 * 	return parentNode.tagName.toLowerCase() == "div";
		 * });
		 */
		findParent: function(node, fn, includeSelf) {
			if (includeSelf !== false) {
				if (fn(node)) return node;
			}
			while (true) {
				node = node.parentNode;
				if (!node) break;
				if (fn(node)) return node;
			}
			return null;
		},
		
		/**
		 * 根据以JSON形式定义的组件的模板信息快速的创建DOM元素。
		 * @param {Object|Object[]} template JSON形式定义的组件的模板信息。
		 * @param {Object} [arg] JSON形式定义的模板参数。
		 * @param {Object} [context] 用于在创建过程中搜集子元素引用的上下文对象。
		 * 对于那些模板信息中带有contextKey属性的子元素，本方法会自动将相应的子元素的引用添加到context的属性中。
		 * @return {HTMLElement|HTMLElement[]} 新创建的HTML元素或HTML元素的数组。
		 *
		 * @example
		 * // 创建一个按钮
		 * $DomUtils.xCreate({
		 * 	tagName: "button",
		 * 	content: "Click Me",	// 定义按钮的标题
		 * 	style: {	// 定义按钮的style
		 * 		border: "1px black solid",
		 * 		backgroundColor: "white"
		 * 	},
		 * 	onclick: function() {	// 定义onclick事件
		 * 		alert("Button clicked.");
		 * 	}
		 * });
		 * 
		 * @example
		 * // 创建一个按钮
		 * $DomUtils.xCreate({
		 * 	tagName: "DIV",
		 * 	contentText: "<Input>"	// contentText属性类似于content，但contentText中的文本内容不会被识别成为HTML
		 * });
		 *
		 * @example
		 * // 创建两个DIV, 同时将两个DIV注册到上下文中
		 * var context = {};
		 * $DomUtils.xCreate([
		 * 	{
		 * 		tagName: "div",
		 * 		content: "Content of DIV1",
		 * 		contextKey: "div1"
		 * 	},
		 * 	{
		 * 		tagName: "div",
		 * 		content: "Content of DIV2",
		 * 		contextKey: "div2"
		 * 	}
		 * ], null, context);
		 * var div1 = context.div1;
		 * var div2 = context.div2;
		 *
		 * @example
		 * // 一个表格
		 * $DomUtils.xCreate(
		 * 	{
		 * 		tagName: "table",
		 * 		content: [
		 * 			{
		 * 				tagName: "tr",
		 * 				content: [
		 * 					{
		 * 						tagName: "td"
		 * 						content: "1.1"
		 * 					},
		 * 					{
		 * 						tagName: "td"
		 * 						content: "1.2"
		 * 					}
		 * 				]
		 * 			},
		 * 			{
		 * 				tagName: "tr",
		 * 				content: [
		 * 					{
		 * 						tagName: "td"
		 * 						content: "2.1"
		 * 					},
		 * 					{
		 * 						tagName: "td"
		 * 						content: "2.2"
		 * 					}
		 * 				]
		 * 			}
		 * 		]
		 * 	}
		 * );
		 *
		 * @example
		 * // 使用带参数的模板
		 * var template = function(arg) {
		 * 	return [ {
		 * 		tagName : "button",
		 * 		content : arg.buttonText1
		 * 	}, {
		 * 		tagName : "button",
		 * 		content : arg.buttonText2
		 * 	} ]
		 * };
		 * var arg = {
		 * 	buttonText1 : "Button 1",
		 * 	buttonText2 : "Button 2"
		 * };
		 * $DomUtils.xCreate(template, arg);
		 */
		xCreate: function(template, arg, context) {
		
			function setAttrs(el, attrs, jqEl) {
				//attrName is not global. modified by frank
				var $el = jQuery(el);
				for (var attrName in attrs) {
					var attrValue = attrs[attrName];
					switch (attrName) {
						case "style":
							if (attrValue.constructor == String) {
								$el.attr("style", attrValue);
							} else {
								for (var styleName in attrValue) {
									var v = attrValue[styleName];
									if (styleName.match(/^width$|^height$|^top$|^left$|^right$|^bottom$/)) {
										if (isFinite(v)) v += "px";
									}
									el.style[styleName] = v;
								}
							}
							break;
							
						case "outerWidth":
							jqEl.outerWidth(attrValue);
							break;
							
						case "outerHeight":
							jqEl.outerHeight(attrValue);
							break;
							
						case "tagName":
						case "content":
						case "contentText":
							continue;
							
						case "contextKey":
							if (context instanceof Object && attrValue && typeof attrValue == "string") {
								context[attrValue] = el;
							}
							continue;
						
						case "data":
							$el.data(attrValue);
							break;
							
						default:
							if (attrName.substr(0, 2) == "on") { // event?
								var event = attrName.substr(2);
								if (typeof attrValue != "function") attrValue = new Function(attrValue);
								jqEl.bind(event, attrValue);
							} else {
								el[attrName] = attrValue;
							}
					}
				}
				return el;
			}
			
			function setText(el, content, jqEl, isText) {
				var isHtml = /(<\S[^><]*>)|(&.+;)/g;
				if (isText !== true && content.match(isHtml) != null && el.tagName.toUpperCase() != "TEXTAREA") {
					el.innerHTML = content;
				} else {
					if (dorado.Browser.mozilla) {
						el.innerHTML = content.replace(/&/g, '&amp;').replace(/>/g, '&gt;').replace(/</g, '&lt;').replace(/\n/g, "<br />\n");
					}
					else {
						el.innerText = content;
					}
				}
				return el;
			}
			
			function appendChild(parentEl, el) {
				if (/* dorado.Core.msie && */parentEl.nodeName.toUpperCase() == "TABLE" &&
				el.nodeName.toUpperCase() == "TR") {
					var tbody;
					if (parentEl && parentEl.tBodies[0]) {
						tbody = parentEl.tBodies[0];
						
					} else {
						tbody = parentEl.appendChild(document.createElement("tbody"));
					}
					parentEl = tbody;
				}
				parentEl.appendChild(el);
			}
			
			if (typeof template == "function") {
				template = template(arg || window);
			}
			
			if (template instanceof Array) {
				var elements = [];
				for (var i = 0; i < template.length; i++) {
					elements.push(this.xCreate(template[i], arg, context));
				}
				return elements;
			}
			
			var tagName = template.tagName || "DIV";
			tagName = tagName.toUpperCase();
			var content = template.content;
			
			var el;
			if (dorado.Core.msie && tagName == "INPUT" && template.type) {
				el = document.createElement("<" + tagName + " type=\"" + template.type + "\"/>");
				
			} else {
				el = document.createElement(tagName);
			}
			var jqEl = jQuery(el);
			el = setAttrs(el, template, jqEl);
			
			if (content != null) {
				if (content.constructor == String) {
					if (content.charAt(0) == '^') {
						appendChild(el, document.createElement(content.substring(1)));
					} else {
						el = setText(el, content, jqEl);
					}
				} else {
					if (content instanceof Array) {
						for (var i = 0; i < content.length; i++) {
							var c = content[i];
							if (c.constructor == String) {
								if (c.charAt(0) == '^') {
									appendChild(el, document.createElement(c.substring(1)));
								} else {
									appendChild(el, document.createTextNode(c));
								}
							} else {
								appendChild(el, this.xCreate(c, arg, context));
							}
						}
					} else if (content.nodeType) {
						appendChild(el, content);
					} else {
						appendChild(el, this.xCreate(content, arg, context));
					}
				}
			}
			else {
				var contentText = template.contentText;
				if (contentText != null && contentText.constructor == String) {
					el = setText(el, contentText, jqEl, true);
				}
			}
			return el;
		},
		
		BLANK_IMG: dorado.Setting["common.contextPath"] + "dorado/client/resources/blank.gif",
		
		setImgSrc: function(img, src) {
			src = $url(src) || BLANK_IMG;
			if (img.src != src) img.src = src;
		},
		
		setBackgroundImage: function(el, url) {
			if (url) {
				var reg = /url\(.*\)/i, m = url.match(reg);
				if (m) {
					m = m[0];
					var realUrl = jQuery.trim(m.substring(4, m.length - 1));
					realUrl = $url(realUrl);
					el.style.background = url.replace(reg, "url(" + realUrl + ")");
					return;
				}
				url = $url(url);
				url = "url(" + url + ")";
			} else {
				url = "";
			}
			if (el.style.backgroundImage != url) {
				el.style.backgroundImage = url;
				el.style.backgroundPosition = "center";
			}
		},
		
		placeCenterElement: function(element, container) {
			var offset = $fly(container).offset();
			element.style.left = (offset.left + (container.offsetWidth - element.offsetWidth) / 2) + "px";
			element.style.top = (offset.top + (container.offsetHeight - element.offsetHeight) / 2) + "px";
		},
		
		getOrCreateChild: function(parentNode, index, tagName, fn) {
			var child, refChild;
			if (index < parentNode.childNodes.length) {
				child = refChild = parentNode.childNodes[index];
				if (fn && fn(child) === false) child = null;
			}
			if (!child) {
				child = (typeof tagName == "function") ? tagName(index) : ((tagName.constructor == String) ? document.createElement(tagName) : this.xCreate(tagName));
				(refChild) ? parentNode.insertBefore(child, refChild) : parentNode.appendChild(child);
			}
			return child;
		},
		
		removeChildrenFrom: function(parentNode, from, fn) {
			var toRemove = [];
			for (var i = parentNode.childNodes.length - 1; i >= from; i--) {
				var child = parentNode.childNodes[i];
				if (fn && fn(child) === false) continue;
				toRemove.push(child);
			}
			if (toRemove.length > 0) $fly(toRemove).remove();
		},
		
		isDragging: function() {
			var currentDraggable = jQuery.ui.ddmanager.current;
			return (currentDraggable && currentDraggable._mouseStarted);
		},
		
		/**
		 * 取得触发事件的表格单元格。
		 * @param {Event} event 浏览器的event对象。
		 * @return {Object} 触发事件的表格单元格，包含row、column、element属性。
		 */
		getCellPosition: function(event) {
			var element = event.srcElement || event.target, row = -1, column = -1;
			while (element && element != element.ownerDocument.body) {
				var tagName = element.tagName.toLowerCase();
				if (tagName == "td") {
					row = element.parentNode.rowIndex;
					column = element.cellIndex;
					break;
				}
				element = element.parentNode;
			}
			if (element != element.ownerDocument.body) {
				return {
					"row": row,
					"column": column,
					"element": element
				};
			}
			return null;
		},
		
		/**
		 * 将一个DOM对象一环绕的方式停靠在另一个固定位置DOM对象的周围。
		 * <p>
		 * 该方法把固定位置的DOM对象的横向和纵向进行了区域划分。<br />
		 * 横向可以分为五个区域，分别是left、innerleft、center、innerright、top。<br />
		 * 纵向也可以分为5个区域，分别是top、innertop、center、innerbottom、bottom。<br />
		 * 如下图所示（橙色方块代表fixedElement，从fixedElement的左上角作为原点坐标，可以为水平和垂直方向分别划分5个区域，该图主要展示水平和垂直区域的划分）：
		 * </p>
		 * <img class="clip-image" src="images/dock-around-1.jpg">
		 * <p>
		 * 根据水平方向五个区域，垂直方向五个区域，那么对水平方向和垂直方向进行组合，则可以得出25中组合，如下图所示：
		 * </p>
		 * <img class="clip-image" src="images/dock-around-2.jpg">
		 * <p>
		 * 这些组合基本上可以满足用户的大部分需求，如果计算出来的位置需要微调，可以使用offsetLeft、offsetTop进行微调。
		 * </p>
		 *
		 * <p>
		 * 另外，此方法在设定停靠位置的同时会尽可能使DOM对象位于屏幕的可见区域内。
		 * 该方法会先判断出该组件是横向超出，还是纵向超出，然后根据要停靠的DOM对象的align和vAlign设置，进行一个合理的方向的调整。
		 * 如果该方向可以显示在屏幕范围内，则使用该位置。<br />
		 * 如果仍然不能显示在屏幕范围内，我们就认为该组件的超出触发，会调用该组件的overflowHandler来处理组件的超出。
		 * </p>
		 * @param {HTMLElement} element 要停靠的DOM对象。
		 *     此DOM对象是绝对定位的(style.position=absolute)并且其DOM树处于顶层位置(即其父节点是document.body)。
		 * @param {HTMLElement|window} fixedElement 固定位置的DOM对象，如果是window，则表示该要停靠的DOM元素相对于当前可视范围进行停靠。
		 * @param {Object} options 以JSON方式定义的选项。
		 * @param {String} [options.align=innerleft] 在水平方向上，停靠的DOM对象停靠在固定位置的DOM对象的位置。可选值为left、innerleft、center、innerright、top。
		 * @param {String} [options.vAlign=innertop] 在垂直方向上，停靠的DOM对象停靠在固定位置的DOM对象的位置。可选值为top、innertop、center、innerbottom、bottom。
		 * @param {int} [options.gapX=0] 在水平方向上，停靠的DOM对象与固定位置的DOM对象之间的间隙大小，可以为正，可以为负。
		 * @param {int} [options.gapY=0] 在垂直方向上，停靠的DOM对象与固定位置的DOM对象之间的间隙大小，可以为正，可以为负。
		 * @param {int} [options.offsetLeft=0] 使用align计算出组件的位置的水平偏移量，可以为正，可以为负。
		 * @param {int} [options.offsetTop=0] 使用vAlign计算出组件的位置的垂直偏移量，可以为正，可以为负。
		 * @param {boolean} [options.autoAdjustPosition=true] 当使用默认的align、vAlign计算的位置超出屏幕可见范围以后，是否要对停靠DOM对象的位置进行调整，默认为true，即进行调整。
		 * @param {boolean} [options.handleOverflow=true] 当组件无法显示在屏幕范围以内以后，就认为停靠的DOM对象的超出触发了，该属性用来标示是否对这种情况进行处理，默认会对这种情况进行处理。
		 * @param {Function} [options.overflowHandler] 当停靠的DOM的超出触发以后，要调用的函数。
		 *
		 * @return {Object} 计算出来的位置。
		 */
		dockAround: function(element, fixedElement, options) {
			options = options || {};
			var align = options.align || "innerleft", vAlign = options.vAlign || "innertop",
				offsetLeft = options.offsetLeft || 0, offsetTop = options.offsetTop || 0,
				autoAdjustPosition = options.autoAdjustPosition, handleOverflow = options.handleOverflow,
				offsetParentEl = $fly(element.offsetParent), offsetParentWidth = offsetParentEl.width(),
				offsetParentHeight = offsetParentEl.height(), offsetParentBottom, offsetParentRight, overflowTrigger = false,
				offsetParentOffset = offsetParentEl.offset() || { left: 0, top: 0 }, maxWidth, maxHeight, adjustLeft, adjustTop;

			offsetParentRight = Math.floor(offsetParentWidth + offsetParentOffset.left);
			offsetParentBottom = Math.floor(offsetParentHeight + offsetParentOffset.top);

			if (fixedElement == window || !fixedElement) fixedElement = document.body;
			
			var position = jQuery(fixedElement).offset(),
				left = Math.floor(position.left), top = Math.floor(position.top), rect, newAlign, vAlignPrefix, overflowRect;

			if (fixedElement) {
				rect = getRect(fixedElement);
				if (options.gapX) {
					rect.left -= options.gapX;
					rect.right += options.gapX;
				}
				if (options.gapY) {
					rect.top -= options.gapY;
					rect.bottom += options.gapY;
				}

				if (align) {
					left = getLeft(rect, element, align);

					if ((left + element.offsetWidth > offsetParentRight) || (left < 0)) {
						if (!(autoAdjustPosition === false)) {
							if (align != "center") {
								if (align.indexOf("left") != -1) {
									newAlign = align.replace("left", "right");
								} else if (align.indexOf("right") != -1) {
									newAlign = align.replace("right", "left");
								}
								adjustLeft = getLeft(rect, element, newAlign);
								if ((adjustLeft + element.offsetWidth > offsetParentRight) || (adjustLeft < 0)) {
									left = 0;
									overflowTrigger = true;
									maxWidth = offsetParentWidth;
								} else {
									left = adjustLeft;
									align = newAlign;
								}
							} else if (align == "center") {
								if (left < 0) {
									left = 0;
									overflowTrigger = true;
									maxWidth = offsetParentWidth;
								}
							}
						} else {
							overflowTrigger = true;
						}
					}
				}

				if (vAlign) {
					top = getTop(rect, element, vAlign);

					if ((top + element.offsetHeight > offsetParentBottom) || (top < 0)) {
						if (!(autoAdjustPosition === false)) {
							if (vAlign != "center") {
								if (vAlign.indexOf("top") != -1) {
									vAlign = vAlign.replace("top", "bottom");
									vAlignPrefix = vAlign.replace("top", "");
								} else if (vAlign.indexOf("bottom") != -1) {
									vAlign = vAlign.replace("bottom", "top");
									vAlignPrefix = vAlign.replace("bottom", "");
								}

								adjustTop = getTop(rect, element, vAlign);

								if (adjustTop + element.offsetHeight > offsetParentBottom) {//超出的情况下才会触发这个
									//overflow trigger
									overflowTrigger = true;
									if (adjustTop < (offsetParentHeight / 2)) {
										top = adjustTop;
										maxHeight = offsetParentHeight - top;
										vAlign = vAlignPrefix + "bottom";
									} else {
										maxHeight = element.offsetHeight + top;
										vAlign = vAlignPrefix + "top";
									}
								} else if (adjustTop < 0) {//top < 0的情形下才会触发这个
									//overflow trigger
									overflowTrigger = true;
									if (top > (offsetParentHeight / 2)) {
										top = 0;
										maxHeight = element.offsetHeight + adjustTop;
										vAlign = vAlignPrefix + "top";
									} else {
										maxHeight = offsetParentHeight - top;
										vAlign = vAlignPrefix + "bottom";
									}
								} else {
									top = adjustTop;
								}
							} else if (vAlign == "center") {
								if (top < 0) {
									overflowTrigger = true;
									top = 0;
									maxHeight = offsetParentHeight;
								}
							}
						} else {
							overflowTrigger = true;
						}
					}
				}
			}

			//console.log("overflowTrigger:" + overflowTrigger);
			options.align = align;
			options.vAlign = vAlign;

			var finalLeft = left + offsetLeft /**+ $fly(element.offsetParent).scrollLeft()*/,
				finalTop = top + offsetTop /**+ $fly(element.offsetParent).scrollTop() */;

			$fly(element).offset({ left: finalLeft, top: finalTop });

			finalLeft = parseInt($fly(element).css("left"), 10);
			finalTop = parseInt($fly(element).css("top"), 10);

			if (!(handleOverflow === false) && overflowTrigger) {
				if (typeof options.overflowHandler == "function") {
					overflowRect = {
						left: finalLeft,
						top: finalTop,
						align: align,
						vAlign: vAlign,
						maxHeight: maxHeight,
						maxWidth: maxWidth
					};
					options.overflowHandler.call(null, overflowRect);
				}
			}

			return {
				left: finalLeft,
				top: finalTop,
				0: finalLeft,
				1: finalTop
			};
		},

		/**
		 * 将一个绝对定位(style.position=absolute)的DOM对象放置在屏幕或另一个DOM对象的可见区域内。
		 *
		 * @param {HTMLElement} element 要放置的DOM对象。
		 *     此DOM对象是绝对定位的(style.position=absolute)并且其DOM树处于顶层位置(即其父节点是document.body)。
		 * @param {Object} options 以JSON方式定义的选项。
		 * @param {HTMLElement} options.parent 作为容器的DOM对象（并不是指DOM结构上的父节点，仅指视觉上的关系）。如果不指定此属性则表示放置在屏幕可见区域内。
		 * @param {int} options.offsetLeft 水平偏移量，可以为正，可以为负。
		 * @param {int} options.offsetTop 垂直偏移量，可以为正，可以为负。
		 * @param {boolean} options.autoAdjustPosition 当使用指定的position计算的位置超出屏幕可见范围以后，是否要对停靠DOM对象的位置进行调整，默认为true，即进行调整。
		 * @param {boolean} options.handleOverflow 当组件无法显示在屏幕范围以内以后，认为停靠的DOM的超出触发了，该属性用来标示是否对这种情况进行处理，默认会对这种情况进行处理。
		 * @param {Function} options.overflowHandler 当停靠的DOM的超出触发以后，要调用的函数。
		 *
		 * @return {Object} 计算出来的位置。
		 */
		locateIn: function(element, options) {
			options = options || {};
			var offsetLeft = options.offsetLeft || 0, offsetTop = options.offsetTop || 0, handleOverflow = options.handleOverflow,
				parent = options.parent, offsetParentEl = $fly(element.offsetParent), offsetParentWidth = offsetParentEl.width(),
				offsetParentHeight = offsetParentEl.height(), adjustLeft, adjustTop, overflowTrigger = false, maxWidth, maxHeight,
				position = options.position, left = position ? position.left : 0, top = position ? position.top : 0,
				autoAdjustPosition = options.autoAdjustPosition;

			if (parent) {
				var parentPos = $fly(parent).offset();
				left += parentPos.left;
				top += parentPos.top;
			}

			if (!(autoAdjustPosition === false)) {
				if (top < 0) {
					top = 0;
				}
				if (left < 0) {
					left = 0;
				}
				if (left + element.offsetWidth > offsetParentWidth) {
					if (!(handleOverflow === false)) {
						adjustLeft = left - element.offsetWidth;
						if (adjustLeft > 0) {
							left = adjustLeft;
						} else {
							left = 0;
							overflowTrigger = true;
							maxWidth = offsetParentWidth;
						}
					} else {
						overflowTrigger = true;
					}
				}
				if (top + element.offsetHeight >= offsetParentHeight) {
					if (!(handleOverflow === false)) {
						adjustTop = top - element.offsetHeight;
						if (adjustTop < 0) {
							top = 0;
							overflowTrigger = true;
							maxHeight = offsetParentHeight;
						} else {
							top = adjustTop;
						}
					} else {
						overflowTrigger = true;
					}
				}
			}

			var finalLeft = left + offsetLeft, finalTop = top + offsetTop;
			$fly(element).left(finalLeft).top(finalTop);

			if (handleOverflow !== false && overflowTrigger) {
				if (typeof options.overflowHandler == "function") {
					var overflowRect = {
						left: finalLeft,
						top: finalTop,
						maxHeight: maxHeight,
						maxWidth: maxWidth
					};
					options.overflowHandler.call(null, overflowRect);
				}
			}

			return {
				left: finalLeft,
				top: finalTop,
				0: finalLeft,
				1: finalTop
			};
		},
		
		/**
		 * 禁止某DOM对象（包含其中的子元素）被鼠标选中。
		 * @param {HTMLElement} element DOM对象。
		 */
		disableUserSelection: function(element) {
			if (dorado.Browser.msie) {
				$fly(element).bind("selectstart.disableUserSelection", onSelectStart);
			} else {
				element.style.MozUserSelect = "none";
				element.style.KhtmlUserSelect = "none";
				element.style.webkitUserSelect = "none";
				element.style.OUserSelect = "none";
				element.unselectable = "on";
			}
		},
		
		/**
		 * 允许某DOM对象（包含其中的子元素）被鼠标选中。
		 * @param {HTMLElement} element DOM对象。
		 */
		enableUserSelection: function(element) {
			if (dorado.Browser.msie) {
				$fly(element).unbind("selectstart.disableUserSelection");
			} else {
				element.style.MozUserSelect = "";
				element.style.KhtmlUserSelect = "";
				element.style.webkitUserSelect = "";
				element.style.OUserSelect = "";
				element.unselectable = "";
			}
		},
		
		/**
		 * 将相应元素提到最前面，即为相应元素设置合适的style.zIndex使其不至于被其他元素阻挡。
		 * @param {HTMLElement} element DOM对象。
		 * @param {int} [radius] zIndex偏移量，默认为0。
		 * @return {int} 该DOM对象获得的新的zIndex的值。
		 */
		bringToFront: function(dom, radius) {
			if (dorado.Browser.msie) maxZIndex += 2;
			else maxZIndex += 1;
			var zIndex = maxZIndex + (radius || 0);
			if (dom) dom.style.zIndex = zIndex;
			return zIndex;
		}
	};
	
	function onSelectStart() {
		return false;
	}
	
	function getRect(element) {
		if (element) {
			var width, height;
			if (element == window) {
				var $win = $fly(window), left = $win.scrollLeft(), top = $win.scrollTop();
				
				width = $win.width();
				height = $win.height();
				
				return {
					left: Math.floor(left),
					top: Math.floor(top),
					right: Math.floor(left) + width,
					bottom: Math.floor(top) + height
				};
			}
			
			var offset = $fly(element).offset();
			if (element == document.body) {
				width = $fly(window).width();
				height = $fly(window).height();
			} else {
				width = $fly(element).outerWidth();
				height = $fly(element).outerHeight();
			}
			return {
				left: Math.floor(offset.left),
				top: Math.floor(offset.top),
				right: Math.floor(offset.left + width),
				bottom: Math.floor(offset.top + height)
			};
		}
		return null;
	}
	
	//获取相对触发元素的left
	function getLeft(rect, dom, align) {
		switch (align.toLowerCase()) {
			case "left":
				return rect.left - dom.offsetWidth;
			case "innerleft":
				return rect.left;
			case "center":
				return (rect.left + rect.right - dom.offsetWidth) / 2;
			case "innerright":
				return rect.right - dom.offsetWidth;
			case "right":
			default:
				return rect.right;
		}
	}
	
	//获取相对触发元素的top
	function getTop(rect, dom, vAlign) {
		switch (vAlign.toLowerCase()) {
			case "top":
				return rect.top - dom.offsetHeight;
			case "innertop":
				return rect.top;
			case "center":
				return (rect.top + rect.bottom - dom.offsetHeight) / 2;
			case "innerbottom":
				return rect.bottom - dom.offsetHeight;
			case "bottom":
			default:
				return rect.bottom;
		}
	}
	
	function findValidContent(container) {
		//performance issue modified by frank
		var childNodes = container.childNodes;
		for (var i = 0, j = childNodes.length; i < j; i++) {
			var child = childNodes[i];
			with (child.style) {
				if (display != "none" && (position == '' || position == "static")) {
					return child;
				}
			}
		}
		return null;
	}
	
})();
/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @name jQuery#shadow
 * @function
 * @description 为HTML元素添加阴影效果。
 * <p>
 * 注意：此功能不支持低版本IE（即IE6、7、8）。
 * </p>
 * @param {Object} [options] 选项。
 * @param {String} [options.mode="drop"] 阴影类型，目前有drop、sides、frame这三种类型供选择。
 * @return {jQuery} 调用此方法的jQuery对象自身。
 * @see jQuery#unshadow
 */
jQuery.fn.shadow = function(options) {	
	if (dorado.Browser.msie && dorado.Browser.version < 9) return this;
	
	options = options || {};
	var mode = options.mode || "drop";
	switch (mode.toLowerCase()) {
		case "drop":
			this.addClass("d-shadow-drop");
			break;
		case "sides":
			this.addClass("d-shadow-sides");
			break;
		case "frame":
			this.addClass("d-shadow-frame");
			break;
	}
	return this;
};

/**
 * @name jQuery#unshadow
 * @function
 * @description 移除HTML元素上的阴影效果。
 * @return {jQuery} 调用此方法的jQuery对象自身。
 * @see jQuery#shadow
 */
jQuery.fn.unshadow = function(options) {
	if (dorado.Browser.msie && dorado.Browser.version < 9) return this;
	
	options = options || {};
	var mode = options.mode || "drop";
	switch (mode.toLowerCase()) {
		case "drop":
			this.removeClass("d-shadow-drop");
			break;
		case "sides":
			this.removeClass("d-shadow-sides");
			break;
		case "frame":
			this.removeClass("d-shadow-frame");
			break;
	}
	return this;
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function($) {

	function num(el, prop) {
		return parseInt(jQuery.css(el.jquery ? el[0] : el, prop, true)) || 0;
	};
	
	/**
	 * @name jQuery#left
	 * @function
	 * @param {String|int} [val] style.left值。
	 * @return {int|jQuery} style.left值;或者当此方法用于设置对象的style.left时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的style.left值。
	 */
	/**
	 * @name jQuery#top
	 * @function
	 * @param {String|int} [val] style.top。
	 * @return {int|jQuery} style.top值;或者当此方法用于设置对象的style.top时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的style.top值。
	 */
	/**
	 * @name jQuery#right
	 * @function
	 * @param {String|int} [val] style.right。
	 * @return {int|jQuery} style.right值;或者当此方法用于设置对象的style.right时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的style.right值。
	 */
	/**
	 * @name jQuery#bottom
	 * @function
	 * @param {String|int} [val] style.bottom。
	 * @return {int|jQuery} style.bottom值;或者当此方法用于设置对象的style.bottom时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的style.bottom值。
	 */
	/**
	 * @name jQuery#position
	 * @function
	 * @param {String|int} [left] style.left。
	 * @param {String|int} [top] style.top。
	 * @return {Object|jQuery} 对象坐标;或者当此方法用于设置对象的坐标时返回调用此方法的jQuery对象自身。
	 * 此处返回的对象坐标是一个的JSON对象，其中包含下列子属性：
	 * <ul>
	 * <li>left - style.left的值。</li>
	 * <li>top - style.top的值。</li>
	 * </ul>
	 * @description 返回或设置对象的坐标，即返回或设置对象的style.left和style.top。
	 */
	/**
	 * @name jQuery#outerWidth
	 * @function
	 * @param {String|int} [width] 将要设置的宽度。
	 * 当此处指定的宽度为百分比时，此方法将直接简单的把此参数赋给对象的style.width属性。
	 * @return {int|jQuery} 对象的实际宽度（包含对象的padding、border）;或者当此方法用于设置对象的宽度时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的实际宽度。
	 * <p>
	 * 当我们不定义此方法的width参数时，表示我们需要此方法返回对象的实际宽度； 如果定义了此方法的width参数，表示我们要设置此对象的实际宽度。
	 * </p>
	 */
	/**
	 * @name jQuery#outerHeight
	 * @function
	 * @param {String|int} [height] 将要设置的高度。
	 * 当此处指定的高度为百分比时，此方法将直接简单的把此参数赋给对象的style.height属性。
	 * @return {int|jQuery} 对象的实际高度（包含对象的padding、border）;或者当此方法用于设置对象的高度时返回调用此方法的jQuery对象自身。
	 * @description 返回或设置对象的实际高度。
	 * <p>
	 * 当我们不定义此方法的height参数时，表示我们需要此方法返回对象的实际高度；
	 * 如果定义了此方法的height参数，表示我们要设置此对象的实际高度。
	 * </p>
	 */
	// =====
	
	/**
	 * @name jQuery#bringToFront
	 * @function
	 * @description 将相应元素提到最前面，即为相应元素设置合适的style.zIndex使其不至于被其他元素阻挡。
	 * @param {int} [radius] zIndex偏移量，默认为0。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.bringToFront = function(radius) {
		return this.css("zIndex", $DomUtils.bringToFront(null, radius));
	};
	
	// Extend left, top, right, bottom methods
	$.each(["left", "top", "right", "bottom"], function(i, name) {
		$.fn[name] = function(val) {
			return this.css(name, val);
		};
	});
	
	// Extend position method
	var oldPosition = $.fn.position;
	$.fn.position = function(left, top) {
		if (arguments.length) {
			this.css("left", left).css("top", top);
			return this;
		} else {
			return oldPosition.call(this);
		}
	};
	
	// Extend outerHeight and outerWidth methods
	$.each(["Height", "Width"], function(i, name) {
		var tl = i ? "Left" : "Top"; // top or left
		var br = i ? "Right" : "Bottom"; // bottom or right
		var fn = $.fn["outer" + name];

		$.fn["outer" + name] = function(arg) {
			if (arg != null && (arg.constructor != Boolean || arguments.length > 1)) {
				if (arg.constructor == String) {
					if (arg == "auto" || arg.match('%')) {
						return this[name.toLowerCase()](arg);
					} else if (arg == "none") {
						return this.css(name.toLowerCase(), "");
					}
				} else {
					var n = parseInt(arg);
					if (arguments[1] === true) {
						n = n - num(this, "padding" + tl) - num(this, "padding" + br) -
						    num(this, "border" + tl + "Width") - num(this, "border" + br + "Width") -
							num(this, "margin" + tl) - num(this, "margin" + br);
					} else {
						n = n - num(this, "padding" + tl) - num(this, "padding" + br) -
						    num(this, "border" + tl + "Width") - num(this, "border" + br + "Width");
					}
					return this[name.toLowerCase()](n);
				}
				return this;
			}
			return fn.apply(this, arguments);
		};
	});
	
	// Extend edgeLeft edgeTop edgeRight and edgeBottom methods
	$.each(["Left", "Top", "Right", "Bottom"], function(i, name) {
		$.fn["edge" + name] = function(includeMargin) {
			var n = num(this, "padding" + name) +
				num(this, "border" + name + "Width");
			if (includeMargin) {
				n += num(this, "margin" + name);
			}
			return n;
		};
	});
	
	// Extend edgeWidth
	$.fn.edgeWidth = function(includeMargin) {
		return this.edgeLeft(includeMargin) + this.edgeRight(includeMargin);
	}
	
	// Extend edgeHeight
	$.fn.edgeHeight = function(includeMargin) {
		return this.edgeTop(includeMargin) + this.edgeBottom(includeMargin);
	}
	
	/**
	 * @name jQuery#addClassOnHover
	 * @function
	 * @description 当鼠标经过该对象时为该对象添加一个CSS Class，并在鼠标离开后移除该CSS Class。
	 * <p>
	 * 注意：此方法不适用于$fly()方法返回的对象。应使用$()或jQuery()来封装DOM对象。
	 * </p>
	 * @param {String} cls 要设置的CSS Class。
	 * @param {jQuery} [clsOwner] 要将CSS Class设置给哪个对象，如果不指定此参数则将设置给调用此方法的jQuery对象。
	 * @param {Function} [fn] 一个用于判断是否要启用鼠标悬停效果的函数，其返回值的true/false决定是否要启用悬停效果。 该fn的scope即为jQuery对象自身。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.addClassOnHover = function(cls, clsOwner, fn) {
		var clsOwner = clsOwner || this;
		this.hover(function() {
			if ($DomUtils.isDragging()) return;
			if (typeof fn == "function" && !fn.call(this)) return;
			clsOwner.addClass(cls);
		}, function() {
			clsOwner.removeClass(cls);
		});
		return this;
	};
	
	/**
	 * @name jQuery#addClassOnFocus
	 * @function
	 * @description 当该对象获得焦点时为该对象添加一个CSS Class，并在对象失去焦点后移除该CSS Class。
	 * <p>
	 * 注意：此方法不适用于$fly()方法返回的对象。应使用$()或jQuery()来封装DOM对象。
	 * </p>
	 * @param {String} cls 要设置的CSS Class。
	 * @param {jQuery} [clsOwner] 要将CSS Class设置给哪个对象，如果不指定此参数则将设置给调用此方法的jQuery对象。
	 * @param {Function} [fn] 一个用于判断是否要启用焦点效果的函数，其返回值的true/false决定是否要启用焦点效果。 该fn的scope即为jQuery对象自身。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.addClassOnFocus = function(cls, clsOwner, fn) {
		var clsOwner = clsOwner || this;
		this.focus(function() {
			if (typeof fn == "function" && !fn.call(this)) return;
			clsOwner.addClass(cls);
		});
		this.blur(function() {
			clsOwner.removeClass(cls);
		});
		return this;
	};
	
	/**
	 * @name jQuery#addClassOnClick
	 * @function
	 * @description 当鼠标在该对象上按下时为该对象添加一个CSS Class，并在鼠标抬起后移除该CSS Class。
	 * <p>
	 * 注意：此方法不适用于$fly()方法返回的对象。应使用$()或jQuery()来封装DOM对象。
	 * </p>
	 * @param {String} cls 要设置的CSS Class。
	 * @param {jQuery} [clsOwner] 要将CSS Class设置给哪个对象，如果不指定此参数则将设置给调用此方法的jQuery对象。
	 * @param {Function} [fn] 一个用于判断是否要启用单击效果的函数，其返回值的true/false决定是否要启用单击效果。 该fn的scope即为jQuery对象自身。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.addClassOnClick = function(cls, clsOwner, fn) {
		var clsOwner = clsOwner || this;
		this.mousedown(function() {
			if (typeof fn == "function" && !fn.call(this)) return;
			clsOwner.addClass(cls);
			$(document).one("mouseup", function() {
				clsOwner.removeClass(cls);
			});
		});
		return this;
	};
	
	/**
	 * @name jQuery#repeatOnClick
	 * @function
	 * @description 当鼠标在该对象上按下的时候重复执行一个函数，当鼠标抬起以后，则取消执行这段函数。
	 * @param {Function} fn 要执行的函数。
	 * @param {int} interval=100 重复执行的间隔。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.repeatOnClick = function(fn, interval) {
		this.mousedown(function() {
			var timer;
			if (typeof fn == "function") {
				fn.apply(null, []);
				timer = setInterval(fn, interval || 100);
			}
			$(document).one("mouseup", function() {
				if (timer) {
					clearInterval(timer);
					timer = null;
				}
			});
		});
		return this;
	};
	
	var disableMouseWheel = function(event) {
		event.preventDefault();
	};	
	
	/**
	 * @name jQuery#fullWindow
	 * @function
	 * @description 调用对象应为display为block的元素。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.fullWindow = function(options) {
		var self = this;
		if (self.length == 1) {
			var dom = self[0], containBlock = dom.parentNode, parentsOverflow = [], parentsPositioned = false, parentsPosition = [];

			function doFilter() {
				if (this == document.body || (/(auto|scroll|hidden)/).test(jQuery.css(this, 'overflow') + jQuery.css(this, 'overflow-y'))) {
					parentsOverflow.push({
						parent: this,
						overflow: jQuery.css(this, "overflow"),
						overflowY: jQuery.css(this, "overflow-y"),
						scrollTop: this.scrollTop
					});
					var overflowValue = this == document.body ? "hidden" : "visible";
					
					var $this = jQuery(this);
					$this.prop("scrollTop", 0).css({
						overflow: overflowValue,
						overflowY: overflowValue
					});
					
					if ($this.mousewheel) {
						$this.mousewheel(disableMouseWheel);
					}
				}

				if (!parentsPositioned  && dorado.Browser.msie && dorado.Browser.version <= 7) {
					if (this == document.body || (/(relative|absolute)/).test(jQuery.css(this, 'position'))) {
						if (jQuery.css(this, "z-index") == "") {
							parentsPosition.push(this);
							parentsPositioned = true;
							jQuery(this).css("z-index", 100);
						}
					}
				}
			}
			
			while (containBlock != document.body) {
				if (jQuery(containBlock).css("position") != "static") {
					break;
				}
				containBlock = containBlock.parentNode;
			}

			options = options || {};
			
			var docWidth = jQuery(window).width(), docHeight = jQuery(window).height();
			
			var isAbs = (self.css("position") == "absolute");
			
			var backupStyle = {
				position: dom.style.position,
				left: dom.style.left,
				top: dom.style.top
				//,zIndex: dom.style.zIndex
			};
			
			var poffset = jQuery(containBlock).offset() || {
				left: 0,
				top: 0
			}, position, left, top;
			
			self.css({
				position: "absolute",
				left: 0,
				top: 0
			});
			
			position = self.position();
			
			left = -1 * (poffset.left + position.left);
			top = -1 * (poffset.top + position.top);

			self.parents().filter(doFilter);

			var targetStyle = {
				position: "absolute",
				left: left,
				top: top
			};
			if (options.modifySize !== false) {
				backupStyle.width = dom.style.width;
				backupStyle.height = dom.style.height;
				targetStyle.width = docWidth;
				targetStyle.height = docHeight;
			}
			
			jQuery.data(dom, "fullWindow.backupStyle", backupStyle);
			jQuery.data(dom, "fullWindow.parentsOverflow", parentsOverflow);
			jQuery.data(dom, "fullWindow.parentsPosition", parentsPosition);
			jQuery.data(dom, "fullWindow.backupSize", {
				width: self.outerWidth(),
				height: self.outerHeight()
			});
			self.css(targetStyle).bringToFront();

			if (dorado.Browser.msie && dorado.Browser.msie <= 7) {
				jQuery(".d-dialog .button-panel").css("visibility", "hidden");
				jQuery(".d-dialog .dialog-footer").css("visibility", "hidden");
			}

			var callback = options.callback;
			if (callback) {
				callback({
					width: docWidth,
					height: docHeight
				});
			}
		}
		return this;
	};
	
	/**
	 * @name jQuery#unfullWindow
	 * @function
	 * @description 调用对象应为display为block的元素。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.unfullWindow = function(options) {
		var self = this;
		if (self.length == 1) {
			options = options || {};
			var dom = self[0], callback = options.callback;
			var backupStyle = jQuery.data(dom, "fullWindow.backupStyle"), backupSize = jQuery.data(dom, "fullWindow.backupSize"),
				parentsOverflow = jQuery.data(dom, "fullWindow.parentsOverflow"), parentsPosition = jQuery.data(dom, "fullWindow.parentsPosition");
			
			if (backupStyle) {
				self.css(backupStyle);
			}
			
			if (callback) {
				callback(backupSize);
			}
			
			if (parentsOverflow) {
				for (var i = 0, j = parentsOverflow.length; i < j; i++) {
					var parentOverflow = parentsOverflow[i];
					var $parent = jQuery(parentOverflow.parent);
					$parent.css({
						overflow: parentOverflow.overflow,
						overflowY: parentOverflow.overflowY
					}).prop("scrollTop", parentOverflow.scrollTop);
					if ($parent.unmousewhee) {
						$parent.unmousewheel(disableMouseWheel);
					}
				}
			}

			if (parentsPosition) {
				for (var i = 0, j = parentsPosition.length; i < j; i++) {
					var parentPosition = parentsPosition[i];
					jQuery(parentPosition).css("z-index", "");
				}
			}

			if (dorado.Browser.msie && dorado.Browser.msie <= 7) {
				jQuery(".d-dialog .button-panel").css("visibility", "");
				jQuery(".d-dialog .dialog-footer").css("visibility", "");
			}

			jQuery.data(dom, "fullWindow.backupStyle", null);
			jQuery.data(dom, "fullWindow.backupSize", null);
			jQuery.data(dom, "fullWindow.parentsOverflow", null);
		}
		return this;
	};

	var hashTimerInited = false, storedHash;
	
	/**
	 * @name jQuery#hashchange
	 * @description 监听window的onHashChange事件。
	 * @param {Function} 事件方法。
	 * @function
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	$.fn.hashchange = function(fn) {
		this.bind("hashchange", fn);
		
		if (!hashTimerInited && jQuery.browser.msie && jQuery.browser.version < 8) {
			hashTimerInited = true;
			
			var storedHash = window.location.hash;
			window.setInterval(function() {
				if (window.location.hash != storedHash) {
					storedHash = window.location.hash;
					$(window).trigger("hashchange");
				}
			}, 100);
		}
	}
	
})(jQuery);

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @name jQuery#xCreate
 * @function
 * @param {Object|Array} template JSON形式定义的组件的模板信息。
 * @param {Object} [arg] JSON形式定义的模板参数。
 * @param {Object} [options] 执行选项。
 * @param {boolean} [options.insertBefore] 是否已插入而不是追加的方式将新创建的元素添加到父对象中。xCreate默认是以appendChild的模式添加新元素的。
 * @param {HTMLElement} [options.refNode] 当使用insertBefore方式添加新元素时，应将新元素插入到哪一个原有的子元素之前。如果不定义此参数，则将插入所有子元素之前。
 * @param {boolean} [options.returnNewElements] 指定此方法是否返回新创建的元素，否则方法返回的是调用者自身。
 * @param {Object} [options.context] 上下文对象，见{@link dorado.util.Dom.xCreate}中的context参数。
 * @return {jQuery} jQuery对象或新创建的元素。
 * @description 根据以JSON形式定义的组件的模板信息快速的插入批量元素。<br>
 * 更多的例子请参考{@link dorado.Dom.xCreate}的文档。
 * @see dorado.util.Dom.xCreate
 *
 * @example
 * // 创建并插入一个按钮
 * jQuery("body").xCreate({
 * 	tagName: "button",
 * 	content: "Click Me",	// 定义按钮的标题
 * 	style: {	// 定义按钮的style
 * 		border: "1px black solid",
 * 		backgroundColor: "white"
 * 	}
 * 	onclick: function() {	// 定义onclick事件
 * 		alert("Button clicked.");
 * 	}
 * });
 */
jQuery.fn.xCreate = function(template, arg, options) {
	var parentEl = this[0];
	var element = $DomUtils.xCreate(template, arg, (options ? options.context : null));
	if (element) {
		var insertBef = false, returnNewElements = false, refNode = null;
		if (options instanceof Object) {
			insertBef = options.insertBefore;
			refNode = (options.refNode) ? options.refNode : parentEl.firstChild;
			returnNewElements = options.returnNewElements;
		}
		
		var elements = (element instanceof Array) ? element : [element];
		for (var i = 0; i < elements.length; i++) {
			if (insertBef && refNode) {
				parentEl.insertBefore(elements[i], refNode);
			} else {
				parentEl.appendChild(elements[i]);
			}
		}
	}
	return returnNewElements ? jQuery(elements) : this;
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {
	// Commented by Benny
	// 下面这段扩展在jQuery 1.7.1下似乎导致动画不能播放

	//fix jquery bug.jQuery不能保证动画队列中的前一个complete一定会在下一个动画的step之前执行。
	/*
	 jQuery.extend({
	 speed: function( speed, easing, fn ) {
	 var opt = speed && typeof speed === "object" ? speed : {
	 complete: fn || !fn && easing ||
	 jQuery.isFunction( speed ) && speed,
	 duration: speed,
	 easing: fn && easing || easing && !jQuery.isFunction(easing) && easing
	 };

	 opt.duration = jQuery.fx.off ? 0 : typeof opt.duration === "number" ? opt.duration :
	 jQuery.fx.speeds[opt.duration] || jQuery.fx.speeds._default;

	 // Queueing
	 opt.old = opt.complete;
	 opt.complete = function() {
	 if ( jQuery.isFunction( opt.old ) ) {
	 opt.old.call( this );
	 }
	 if ( opt.queue !== false ) {
	 jQuery(this).dequeue();
	 }
	 };

	 return opt;
	 }
	 });
	 */

	if (jQuery.Tween) {
		var oldFn = jQuery.Tween.prototype.run;
		jQuery.Tween.prototype.run = function(percent) {
			this.state = percent;

			return oldFn.apply(this, arguments)
		};
	}

	jQuery.fn.region = function(){
		var self = this, element = self[0];
		if(self.length == 1){
			var position = self.offset(), width = element.offsetWidth, height = element.offsetHeight;
			return {
				top: position.top,
				right: position.left + width,
				left: position.left,
				bottom: position.top + height,
				height: height,
				width: width
			};
		}
	};

	jQuery.fn.innerRegion = function(){
		var el = this, element = el[0];
		if(el.length == 1){
			var position = el.offset(), width = el.width(), height = el.height(),
				borderTop = parseInt(el.css("border-left-width"), 10) || 0,
				borderLeft = parseInt(el.css("border-top-width"), 10) || 0,
				paddingLeft = parseInt(el.css("padding-left"), 10) || 0,
				paddingTop = parseInt(el.css("padding-top"), 10) || 0;

			//log.debug("paddingWidth:" + paddingLeft + "\tpaddingHeight:" + paddingTop
			//	+ "\tborderWidth:" + borderTop + "\tborderHeight:" + borderLeft);

			return {
				top: position.top + borderLeft + paddingTop,
				right: position.left + borderTop + paddingLeft + width,
				left: position.left + borderTop + paddingLeft,
				bottom: position.top + borderLeft + paddingTop + height,
				height: height,
				width: width
			};
		}
	};

	var propertyMap = {
		normal: ["position", "visibility", "left", "right", "top", "bottom", "width", "height", "zIndex"],
		safe: ["overflow", "position", "width", "height"],
		child: ["position", "left", "right", "top", "bottom", "width", "height"]
	}, DOCKABLE_STYLE_RESTORE = "dockStyleRestore", DOCK_DATA = "dockData";

	var backupStyle = function(element, type) {
		var props = propertyMap[type || "normal"], object = {};
		if (props) {
			for (var i = 0, j = props.length; i < j; i++) {
				var prop = props[i];
				object[prop] = element.style[prop];
			}
		}
		jQuery.data(element, DOCKABLE_STYLE_RESTORE, object);
	};

	var ratioMap = {top: 1, bottom: -1, left: 1, right: -1}, dockStyleMap = {
		top: { horizontal: "left", vertical: "top", style: {left: 0, top: 0, right: "auto", bottom: "auto"}},
		bottom: { horizontal: "left", vertical: "bottom", style: {left: 0, top: "auto", right: "auto", bottom: 0} },
		left: { horizontal: "left", vertical: "top", style: {left: 0, top: 0, right: "auto", bottom: "auto"} },
		right: { horizontal: "right", vertical: "top", style: {left: "auto", top: 0, right: 0, bottom: "auto"} }
	};

	jQuery.fn.dockable = function(direction, safe, showMask){
		var self = this;
		if (self.length == 1) {
			direction = direction || "bottom";

			var element = self[0], absolute = (self.css("position") == "absolute"),
				leftStart = absolute ? parseInt(self.css("left"), 10) || 0 : 0,
				topStart = absolute ? parseInt(self.css("top"), 10) || 0 : 0;

			backupStyle(element, safe ? "safe" : "normal");
			self.css({ visibility: "hidden", display: "block" });

			var dockConfig = dockStyleMap[direction], hori = dockConfig.horizontal, vert = dockConfig.vertical,
				rect = { width: self.outerWidth(), height: self.outerHeight() }, wrap, mask;

			if (safe) {
				var horiRatio = ratioMap[hori], vertRatio = ratioMap[vert], parentRegion = self.innerRegion(),
					child = element.firstChild, region, childStyle = {}, childEl;

				while (child) {
					childEl = jQuery(child);
					backupStyle(child, "child");
					region = childEl.region();

					childStyle[hori] = horiRatio * (region[hori] - parentRegion[hori]);
					childStyle[vert] = vertRatio * (region[vert] - parentRegion[vert]);
					childEl.css(childStyle).outerWidth(child.offsetWidth).outerHeight(child.offsetHeight);

					child = child.nextSibling;
				}

				if (absolute) {
					self.outerWidth(rect.width).outerHeight(rect.height).css({ overflow: "hidden", visibility: ""}).find("> *").css("position", "absolute");
				} else {
					self.css({ overflow: "hidden", position: "relative", visibility: "" }).find("> *").css("position", "absolute");
				}
			} else {
				wrap = document.createElement("div");
				var wrapEl = jQuery(wrap);
				if (absolute) {
					wrap.style.position = "absolute";
					wrap.style.left = self.css("left");
					wrap.style.top = self.css("top");
					wrapEl.bringToFront();
				} else {
					wrap.style.position = "relative";
					element.style.position = "absolute";
				}

				wrap.style.overflow = "hidden";
				wrapEl.insertBefore(element);
				wrap.appendChild(element);

				var style = dockConfig.style;
				style.visibility = "";
				self.css(style).outerWidth(rect.width).outerHeight(rect.height);
			}
			if (showMask !== false) {
				mask = document.createElement("div");
				var maskEl = jQuery(mask);
				//ie7下必须有背景色，否则无法盖住
				maskEl.css({ position: "absolute", left: 0, top: 0, background: "white", opacity: 0 })
					.bringToFront().outerWidth(rect.width).outerHeight(rect.height);

				if (safe) {
					element.appendChild(mask);
				} else {
					wrap.appendChild(mask);
				}
			}
			jQuery.data(element, DOCK_DATA, {
				rect: rect,
				mask: mask,
				wrap: wrap,
				leftStart: leftStart,
				topStart: topStart
			});
		}
		return this;
	};

	jQuery.fn.undockable = function(safe){
		var self = this;
		if (self.length == 1) {
			var element = self[0], dockData = jQuery.data(element, DOCK_DATA);
			//TODO 已知bug：在某些情况下，dockData为null，但是不清楚如何重现这个问题
			if (dockData == null) {
				return;
			}
			if (safe) {
				self.css(jQuery.data(element, DOCKABLE_STYLE_RESTORE)).find("> *").each(function(index, child){
					var style = jQuery.data(child, DOCKABLE_STYLE_RESTORE);
					if (style != null) {
						jQuery(child).css(style);
					}
					jQuery.data(child, DOCKABLE_STYLE_RESTORE, null);
				});
				jQuery(dockData.mask).remove();
			} else {
				var wrap = dockData.wrap;
				if (wrap) {
					self.css(jQuery.data(element, DOCKABLE_STYLE_RESTORE)).insertAfter(wrap);
					jQuery(wrap).remove();
				}
			}
			jQuery.data(element, DOCK_DATA, null);
			jQuery.data(element, DOCKABLE_STYLE_RESTORE, null);
		}

		return this;
	};

	var slideInDockDirMap = { l2r: "right", r2l: "left", t2b: "bottom", b2t: "top" },
		slideOutDockDirMap = { l2r: "left", r2l: "right", t2b: "top", b2t: "bottom" },
		slideSizeMap = { l2r: "height", r2l: "height", t2b: "width", b2t: "width" };

	var getAnimateConfig = function(type, direction, element, safe) {
		var dockData = jQuery.data(element, DOCK_DATA), rect = dockData.rect,
			leftStart = dockData.leftStart, topStart = dockData.topStart;

		if (safe) {
			if (type == "out") {
				switch (direction) {
					case "t2b":
						return { top: [topStart, topStart + rect.height], height: [rect.height, 0] };
					case "r2l":
						return { width: [rect.width, 0] };
					case "b2t":
						return { height: [rect.height, 0] };
					case "l2r":
						return { left: [leftStart, leftStart + rect.width], width: [rect.width, 0] };
				}
			} else {
				switch (direction) {
					case "t2b":
						return { height: [0, rect.height] };
					case "l2r":
						return { width: [0, rect.width] };
					case "b2t":
						return { top: [topStart + rect.height, topStart], height: [0, rect.height] };
					case "r2l":
						return { left: [leftStart + rect.width, leftStart], width: [0, rect.width] };
				}
			}
		} else {
			var property = slideSizeMap[direction];
			jQuery(dockData.wrap).css(property, dockData.rect[property]);
			if (type == "in") {
				switch (direction) {
					case "t2b":
						return { height: [0, rect.height] };
					case "l2r":
						return { width: [0, rect.width] };
					case "b2t":
						return { top: [topStart + rect.height, topStart], height: [0, rect.height] };
					case "r2l":
						return { left: [leftStart + rect.width, leftStart], width: [0, rect.width] };
				}
			} else if (type == "out") {
				switch (direction) {
					case "t2b":
						return { top: [topStart, topStart + rect.height], height: [rect.height, 0] };
					case "r2l":
						return { width: [rect.width, 0] };
					case "b2t":
						return { height: [rect.height, 0] };
					case "l2r":
						return { left: [leftStart, leftStart + rect.width], width: [rect.width, 0] };
				}
			}
		}
	};

	var slide = function(type, element, options, safe) {
		options = typeof options == "string" ? { direction: options } : options || {};
		var direction = options.direction || "t2b", callback = options.complete, step = options.step,
			start = options.start, animConfig, animElement = element, animEl, delayFunc, inited = false;

		delayFunc = function(direction) {
			if (start) {
				if (type == "in") $fly(element).css("display", "");
				start.call(element);
			}

			$fly(element).dockable(type == "in" ? slideInDockDirMap[direction] : slideOutDockDirMap[direction], safe);

			animConfig = getAnimateConfig(type, direction, element, safe);
			animEl = jQuery(safe ? animElement : jQuery.data(element, DOCK_DATA).wrap);
			for (var prop in animConfig) {
				var value = animConfig[prop];
				animEl.css(prop, value[0]);
			}

			inited = true;
		};

		options.step = function(now, animate) {
			if (!inited) {
				delayFunc(direction);
			}

			var defaultEasing = animate.options.easing || (jQuery.easing.swing ? "swing" : "linear"),
				pos = jQuery.easing[defaultEasing](animate.state, animate.options.duration * animate.state, 0, 1, animate.options.duration);

			var nowStyle = {};

			for(var prop in animConfig){
				var range = animConfig[prop];
				nowStyle[prop] = Math.round(range[0] + (range[1] - range[0]) * pos);
			}

			animEl.css(nowStyle);

			if (step) {
				step.call(animate.elem, nowStyle, animate);
			}
		};

		options.complete = function() {
			$fly(element).undockable(safe);
			$fly(element).css("display", type == "out" ? "none" : "");
			if (typeof callback == "function") {
				callback.apply(null, []);
			}
		};
		options.duration =  options.duration ? options.duration : 300;

		$fly(element).animate({
			dummy: 1
		}, options);
	};

	/**
	 * @name jQuery#slideIn
	 * @function
	 * @description 类似slideDown与slideUp，区别在于这个动画不会真正的去改变动画元素的width和height属性，页面效果看起来更美观。
	 * <p>
	 * 目前FloatControl及其子组件均使用了此动画。
	 * 如果参数为字符串，则表示为direction，不能传入其他参数。如果为json，则根据options中的规则获取配置信息。
	 * </p>
	 * @param {Object} options Json类型的参数。
	 * @param {String} options.direction 要滑动的方向，可选的是t2b、b2t、l2r、r2l。意义分别是从上到下、从下到上、从左到右、从右到左。默认值为t2b。
	 * @param {Function} options.complete 完成后要调用的回调函数。
	 * @param {int} options.duration 动画执行的时间，单位为毫秒。
	 * @param {String} options.easing 是用哪个easing function.
	 * @param {Function} options.step 每步动画完成以后调用的回调函数。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	jQuery.fn.slideIn = function(options) {
		var self = this;
		if (self.length == 1) {
			slide("in", self[0], options, false);
		}
		return this;
	};

	/**
	 * @name jQuery#slideOut
	 * @function
	 * @description 类似slideDown与slideUp，区别在于这个动画不会真正的去改变动画元素的width和height属性，页面效果看起来更美观。
	 * <p>
	 * 目前FloatControl以及其子组件使用了此动画。
	 * 如果参数为字符串，则表示为direction，不能传入其他参数。如果为json，则根据options中的规则获取配置信息。
	 * </p>
	 *  @param {Object} options Json类型的参数。
	 * @param {String} options.direction 要滑动的方向，可选的是t2b、b2t、l2r、r2l。意义分别是从上到下、从下到上、从左到右、从右到左。默认值为t2b。
	 * @param {Function} options.complete 完成后要调用的回调函数。
	 * @param {int} options.duration 动画执行的时间，单位为毫秒。
	 * @param {String} options.easing 是用哪个easing function.
	 * @param {Function} options.step 每步动画完成以后调用的回调函数。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	jQuery.fn.slideOut = function(options) {
		var self = this;
		if (self.length == 1) {
			slide("out", self[0], options, false);
		}
		return this;
	};

	/**
	 * @name jQuery#safeSlideIn
	 * @function
	 * @param options
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 * @description 安全滑入动画效果。
	 * 与slideIn的区别在于该动画不会挪动dom元素的位置，可以避免iframe的刷新(非IE浏览器)、滚动条的复位等问题。
	 */
	jQuery.fn.safeSlideIn = function(options){
		var self = this;
		if (self.length == 1) {
			slide("in", self[0], options, true);
		}
		return this;
	};


	/**
	 * @name jQuery#safeSlideOut
	 * @function
	 * @param options
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 * @description 安全滑出动画。
	 * 与slideOut的区别在于该动画不会挪动dom元素的位置，可以避免iframe的刷新(非IE浏览器)、滚动条的复位等问题。
	 */
	jQuery.fn.safeSlideOut = function(options){
		var self = this;
		if (self.length == 1) {
			slide("out", self[0], options, true);
		}
		return this;
	};

	var zoomCoverPool = new dorado.util.ObjectPool({
		makeObject: function() {
			var cover = document.createElement("div");
			cover.className = "i-animate-zoom-proxy d-animate-zoom-proxy";
			jQuery(document.body).append(cover);

			return cover;
		}
	});

	var zoom = function(type, element, options) {
		var position = options.position, animTarget = options.animateTarget,
			startLeft, startTop, endLeft, endTop, offset, isTypeIn = (type != "out"), elWidth, elHeight;

		if (position) {
			var oldLeft = element.style.left, oldTop = element.style.top;
			position = $fly(element).css(position).offset();
			$fly(element).css({ "left": oldLeft || "", "top": oldTop || "" });
		}

		if (typeof animTarget == "string") {
			animTarget = jQuery(animTarget)[0];
		} else if(animTarget instanceof dorado.widget.Control){
			animTarget = animTarget._dom;
		}
		var elementEl = jQuery(element), animTargetEl = jQuery(animTarget);
		if (type == "in") {
			if (animTarget) {
				offset = animTargetEl.offset();

				startTop = offset.top;
				startLeft = offset.left;
				endTop = position.top;
				endLeft = position.left;
			} else {
				offset = elementEl.offset();
				elWidth = elementEl.outerWidth();
				elHeight = elementEl.outerHeight();

				startTop = offset.top + elHeight / 2;
				startLeft = offset.left + elWidth / 2;
				endTop = position.top;
				endLeft = position.left;
			}
		} else {
			if (animTarget) {
				offset = animTargetEl.offset();
				if (!position) {
					position = elementEl.offset();
				}
				startTop = position.top;
				startLeft = position.left;
				endTop = offset.top;
				endLeft = offset.left;
			} else {
				offset = elementEl.offset();
				elWidth = elementEl.outerWidth();
				elHeight = elementEl.outerHeight();

				startTop = offset.top;
				startLeft = offset.left;
				endTop = offset.top + elHeight / 2;
				endLeft = offset.left + elWidth / 2;
			}
		}

		var cover = zoomCoverPool.borrowObject();

		jQuery(cover).css({
			display: "",
			top: startTop,
			left: startLeft,
			width: isTypeIn ? 0 : elementEl.width(),
			height: isTypeIn ? 0 : elementEl.height()
		}).bringToFront().animate({
			top: endTop,
			left: endLeft,
			width: isTypeIn ? elementEl.width() : 0,
			height: isTypeIn ? elementEl.height() : 0
		}, {
			duration: options.animateDuration || 300,
			easing: options.animateEasing,
			complete: function() {
				cover.style.display = "none";
				zoomCoverPool.returnObject(cover);
				options.complete.apply(null, []);
			}
		});
	};

	jQuery.fn.zoomIn = function(options) {
		var self = this;
		if (self.length == 1) {
			zoom("in", self[0], options);
		}
		return this;
	};

	jQuery.fn.zoomOut = function(options) {
		var self = this;
		if (self.length == 1) {
			zoom("out", self[0], options);
		}
		return this;
	};

	var isFunction = function (value) {
		return ({}).toString.call(value) == "[object Function]";
	};

	var vendor = (/webkit/i).test(navigator.appVersion) ? 'webkit' :
			(/firefox/i).test(navigator.userAgent) ? 'moz' :
				(/trident/i).test(navigator.userAgent) ? 'ms' :
					'opera' in window ? 'o' : '', cssVendor = "-" + vendor + "-",
		TRANSITION = cssVendor + "transition", TRANSFORM = cssVendor + "transform",
		TRANSFORMORIGIN = cssVendor + "transform-origin", BACKFACEVISIBILITY = cssVendor + "backface-visibility";

	var transitionEnd = "transitionEnd";
	if (jQuery.browser.webkit) {
		transitionEnd = "webkitTransitionEnd";
	} else if (jQuery.browser.msie) {
		transitionEnd = "msTransitionEnd";
	} else if (jQuery.browser.mozilla) {
		transitionEnd = "transitionend";
	} else if (jQuery.browser.opera) {
		transitionEnd = "oTransitionEnd";
	}

	jQuery.fn.anim = function(properties, duration, ease, callback){
		var transforms = [], opacity, key, callbackCalled = false;
		for (key in properties)
			if (key === 'opacity') opacity = properties[key];
			else transforms.push(key + '(' + properties[key] + ')');

		var invokeCallback = function() {
			if (!callbackCalled) {
				callback();
				callbackCalled = true;
			}
		};

		if (parseFloat(duration) !== 0 && isFunction(callback)) {
			this.one(transitionEnd, invokeCallback);
			setTimeout(invokeCallback, duration * 1000 + 50);
		} else {
			setTimeout(callback, 0);
		}

		return this.css({ opacity: opacity }).css(TRANSITION, 'all ' + (duration !== undefined ? duration : 0.5) + 's ' + (ease || '')).css(TRANSFORM, transforms.join(' '));
	};

	var modernZoom = function(type, el, options) {
		if (!el) return;
		options = options || {};

		var position = options.position, animTarget = options.animateTarget,
			startLeft, startTop, endLeft, endTop, offset;

		if (typeof animTarget == "string") {
			animTarget = jQuery(animTarget)[0];
		} else if(animTarget instanceof dorado.widget.Control){
			animTarget = animTarget._dom;
		}
		var elementEl = jQuery(el), animTargetEl = jQuery(animTarget);
		if (type == "in") {
			if (animTarget) {
				offset = animTargetEl.offset();

				startTop = offset.top;
				startLeft = offset.left;
				endTop = position.top;
				endLeft = position.left;
			}
		} else {
			if (animTarget) {
				offset = animTargetEl.offset();
				if (!position) {
					position = elementEl.offset();
				}
				startTop = position.top;
				startLeft = position.left;
				endTop = offset.top;
				endLeft = offset.left;
			}
		}

		var fromScale = 1,
			toScale = 1;

		if (type == "out") {
			toScale = 0.01;
		} else {
			fromScale = 0.01;
		}

		if (animTarget) {
			$(el).css({
				left: startLeft,
				top: startTop
			}).css(TRANSFORM, 'scale(' + fromScale + ')').css(TRANSFORMORIGIN, '0 0');
		} else {
			$(el).css(TRANSFORM, 'scale(' + fromScale + ')').css(TRANSFORMORIGIN, '50% 50%');
		}

		var callback = function() {
			if (options.complete) {
				options.complete.apply(null, []);
			}
			$(el).css(TRANSITION, "").css(TRANSFORMORIGIN, "").css(TRANSFORM, "");
		};
		if (animTarget) {
			setTimeout(function() {
				$(el).anim({}, options.animateDuration ? options.animateDuration / 1000 : .3, "ease-in-out", callback).css({
					left: endLeft,
					top: endTop
				}).css(TRANSFORM, 'scale(' + toScale + ')').css(TRANSFORMORIGIN, '0 0');
			}, 5);
		} else {
			setTimeout(function() {
				$(el).anim({}, options.animateDuration ? options.animateDuration / 1000 : .3, "ease-in-out", callback)
					.css(TRANSFORM, 'scale(' + toScale + ')').css(TRANSFORMORIGIN, '50% 50%');
			}, 5);
		}
	};

	var flip = function(type, el, options) {
		if (!el) return;
		options = options || {};
		var callback = function() {
			if (options.complete) {
				options.complete.apply(null, []);
			}
			$(el).css(TRANSITION, "").css(TRANSFORMORIGIN, "").css(TRANSFORM, "").css(BACKFACEVISIBILITY, "");
		};

		var rotateProp = 'Y',
			fromScale = 1,
			toScale = 1,
			fromRotate = 0,
			toRotate = 0;

		if (type == "out") {
			toRotate = -180;
			toScale = 0.8;
		} else {
			fromRotate = 180;
			fromScale = 0.8;
		}

		if (options.direction == 'up' || options.direction == 'down') {
			rotateProp = 'X';
		}

		if (options.direction == 'right' || options.direction == 'left') {
			toRotate *= -1;
			fromRotate *= -1;
		}

		$(el).css(TRANSFORM, 'rotate' + rotateProp + '(' + fromRotate + 'deg) scale(' + fromScale + ')').css(BACKFACEVISIBILITY, 'hidden');

		setTimeout(function() {
			$(el).anim({}, options.animateDuration ? options.animateDuration / 1000 : .3, "linear", callback).
				css(TRANSFORM, 'rotate' + rotateProp + '(' + toRotate + 'deg) scale(' + toScale + ')').css(BACKFACEVISIBILITY, 'hidden');
		}, 5);
	};

	jQuery.fn.modernZoomIn = function(options) {
		var self = this;
		if (self.length == 1) {
			modernZoom("in", self[0], options);
		}
		return this;
	};

	jQuery.fn.modernZoomOut = function(options) {
		var self = this;
		if (self.length == 1) {
			modernZoom("out", self[0], options);
		}
		return this;
	};

	jQuery.fn.flipIn = function(options) {
		var self = this;
		if (self.length == 1) {
			options.direction = "left";
			flip("in", self[0], options);
		}
		return this;
	};

	jQuery.fn.flipOut = function(options) {
		var self = this;
		if (self.length == 1) {
			options.direction = "right";
			flip("out", self[0], options);
		}
		return this;
	};

	var getWin = function(elem) {
		return (elem && ('scrollTo' in elem) && elem['document']) ?
			elem :
			elem && elem.nodeType === 9 ?
				elem.defaultView || elem.parentWindow :
				elem === undefined ?
					window : false;
	}, SCROLL_TO = "scrollTo", DOCUMENT = "document";

	jQuery.fn.scrollIntoView = function(container, top, hscroll) {
		var self = this, elem;
		if (self.length == 1) {
			elem = self[0];
		}

		container = typeof container == "string" ? jQuery(container)[0] : container;
		hscroll = hscroll === undefined ? true : !!hscroll;
		top = top === undefined ? true : !!top;

		// default current window, use native for scrollIntoView(elem, top)
		if (!container || container === window) {
			// 注意：
			// 1. Opera 不支持 top 参数
			// 2. 当 container 已经在视窗中时，也会重新定位
			return elem.scrollIntoView(top);
		}

		// document 归一化到 window
		if (container && container.nodeType == 9) {
			container = getWin(container);
		}

		var isWin = container && (SCROLL_TO in container) && container[DOCUMENT],
			elemOffset = self.offset(),
			containerOffset = isWin ? {
				left: jQuery(container).scrollLeft(),
				top: jQuery(container).scrollTop() }
				: jQuery(container).offset(),

		// elem 相对 container 视窗的坐标
			diff = {
				left: elemOffset["left"] - containerOffset["left"],
				top: elemOffset["top"] - containerOffset["top"]
			},

		// container 视窗的高宽
			ch = isWin ? jQuery(window).height() : container.clientHeight,
			cw = isWin ? jQuery(window).width() : container.clientWidth,

		// container 视窗相对 container 元素的坐标
			cl = jQuery(container).scrollLeft(),
			ct = jQuery(container).scrollTop(),
			cr = cl + cw,
			cb = ct + ch,

		// elem 的高宽
			eh = elem.offsetHeight,
			ew = elem.offsetWidth,

		// elem 相对 container 元素的坐标
		// 注：diff.left 含 border, cl 也含 border, 因此要减去一个
			l = diff.left + cl - (parseInt(jQuery(container).css('borderLeftWidth')) || 0),
			t = diff.top + ct - (parseInt(jQuery(container).css('borderTopWidth')) || 0),
			r = l + ew,
			b = t + eh,

			t2, l2;

		// 根据情况将 elem 定位到 container 视窗中
		// 1. 当 eh > ch 时，优先显示 elem 的顶部，对用户来说，这样更合理
		// 2. 当 t < ct 时，elem 在 container 视窗上方，优先顶部对齐
		// 3. 当 b > cb 时，elem 在 container 视窗下方，优先底部对齐
		// 4. 其它情况下，elem 已经在 container 视窗中，无需任何操作
		if (eh > ch || t < ct || top) {
			t2 = t;
		} else if (b > cb) {
			t2 = b - ch;
		}

		// 水平方向与上面同理
		if (hscroll) {
			if (ew > cw || l < cl || top) {
				l2 = l;
			} else if (r > cr) {
				l2 = r - cw;
			}
		}

		// go
		if (isWin) {
			if (t2 !== undefined || l2 !== undefined) {
				container[SCROLL_TO](l2, t2);
			}
		} else {
			if (t2 !== undefined) {
				container["scrollTop"] = t2;
			}
			if (l2 !== undefined) {
				container["scrollLeft"] = l2;
			}
		}
	};
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function($) {

	/**
	 * @name jQuery#draggable
	 * @function
	 * @description 此方法是对jQuery UI中draggable方法的增强，请首先参考jQuery UI中draggable方法的使用方法。
	 * @param {Object} options 选项。以下只列出dorado增加额外子参数。
	 * @param {Function|dorado.DraggingInfo} [options.draggingInfo] 拖拽信息或用于获取拖拽信息的Function。<br>
	 * 要使一个可拖拽对象可以被dorado的控件感知和接受，只需要定义了此参数即可。
	 * @param {dorado.Draggable} [options.doradoDraggable] 与此可拖拽元素对应的dorado可拖拽对象。
	 * 如果定义了此参数，那么我们就可以通过{@link dorado.Draggable}支持的各种方法和事件对拖拽操作进行监听和控制。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	var oldDraggable = $.fn.draggable;
	$.fn.draggable = function(options) {
		var draggingInfo, doradoDraggable;
		if (options) {
			draggingInfo = options.draggingInfo;
			doradoDraggable = options.doradoDraggable;
		}
		
		if (draggingInfo || doradoDraggable) {
			var originOptions = options;
			options = dorado.Object.apply({}, originOptions);
			
			options.createDraggingInfo = function(evt) {
				var draggingInfo = originOptions.draggingInfo;
				if (typeof draggingInfo == "function") draggingInfo = draggingInfo.call(this, this, options);
				if (!draggingInfo) {
					if (doradoDraggable) draggingInfo = doradoDraggable.createDraggingInfo(this, options);
					if (!draggingInfo) draggingInfo = new dorado.DraggingInfo();
				}
				if (draggingInfo) draggingInfo.set("element", this);
				return draggingInfo;
			};
			
			if (typeof originOptions.revert != "string") {
				options.revert = function(dropped) {
					var revert = originOptions.revert;
					if (revert == null) {
						revert = !dropped;
					} else if (typeof revert == "function") {
						revert = revert.call(this, dropped);
					}
					return revert;
				};
			}
			
			if (typeof originOptions.helper != "string") {
				options.helper = function(evt) {
					var helper;
					if (typeof originOptions.helper == "function") {
						helper = originOptions.helper.apply(this, arguments);
					}
					if (doradoDraggable) helper = doradoDraggable.onGetDraggingIndicator(helper, evt, this);
					
					var draggingInfo = options.createDraggingInfo.call(this, evt);
					$fly(this).data("ui-draggable").draggingInfo = draggingInfo;
					
					if (helper instanceof dorado.DraggingIndicator) {
						draggingInfo.set("indicator", helper);
						helper = helper.getDom();
					}
					return helper;
				};
			}
			
			options.start = function(evt, ui) {
				var b = true;
				if (originOptions.start) b = originOptions.start.apply(this, arguments);
				
				if (b !== false) {
					var draggingInfo = dorado.DraggingInfo.getFromElement(this);
					if (draggingInfo) {
						draggingInfo._targetDroppables = [];
						if (doradoDraggable) {
							b = doradoDraggable.onDragStart(draggingInfo, evt);
							if (b !== false) {
								doradoDraggable.initDraggingInfo(draggingInfo, evt);
								var indicator = draggingInfo.get("indicator");
								if (indicator) doradoDraggable.initDraggingIndicator(indicator, draggingInfo, evt);
							}
						}
					}
				}
				return b;
			};
			
			options.stop = function(evt, ui) {
				var b = true;
				if (originOptions.stop) b = originOptions.stop.apply(this, arguments);
				if (b !== false) {
					var draggingInfo = dorado.DraggingInfo.getFromElement(this);
					if (draggingInfo) {
						if (doradoDraggable) b = doradoDraggable.onDragStop(draggingInfo, evt);
						if (b !== false) {
							setTimeout(function() {
								var targetDroppable = draggingInfo._targetDroppables.peek();
								if (targetDroppable) targetDroppable.onDraggingSourceOut(draggingInfo, evt);
							}, 20);
						}
					}
				}
				return b;
			};
			
			options.drag = function(evt, ui) {
				if (originOptions.drag) originOptions.drag.apply(this, arguments);
				var draggingInfo = dorado.DraggingInfo.getFromElement(this);
				if (draggingInfo) {
					if (doradoDraggable) doradoDraggable.onDragMove(draggingInfo, evt);
					var targetDroppable = draggingInfo._targetDroppables.peek();
					if (targetDroppable) targetDroppable.onDraggingSourceMove(draggingInfo, evt);
				}
			};
		}
		
		/*
		if (!options) {
			options = { iframeFix: true };
		} else {
			options.iframeFix = true;
		}
		*/
		return oldDraggable.apply(this, arguments);
	};

	/**
	 * @name jQuery#droppable
	 * @function
	 * @description 此方法是对jQuery UI中droppable方法的增强，请首先参考jQuery UI中droppable方法的使用方法。
	 * @param {Object} options 选项。以下只列出dorado增加额外子参数。
	 * @param {dorado.Droppable} [options.doradoDroppable] 与此可拖拽元素对应的dorado可接受拖拽对象。
	 * 如果定义了此参数，那么我们就可以通过{@link dorado.Droppable}支持的各种方法和事件对拖拽操作进行监听和控制。
	 * @return {jQuery} 调用此方法的jQuery对象自身。
	 */
	var oldDroppable = $.fn.droppable;
	$.fn.droppable = function(options) {
		var doradoDroppable = options ? options.doradoDroppable : null;
		if (doradoDroppable) {
			var originOptions = options;
			options = dorado.Object.apply({}, originOptions);
			
			options.over = function(evt, ui) {
				if (originOptions.over) originOptions.over.apply(this, arguments);
				if (doradoDroppable) {
					var draggingInfo = dorado.DraggingInfo.getFromJQueryUI(ui);
					if (draggingInfo) {
						if (draggingInfo._targetDroppables.peek() != doradoDroppable) {
							draggingInfo._targetDroppables.push(doradoDroppable);
						}
						doradoDroppable.onDraggingSourceOver(draggingInfo, evt);
					}
				}
			};
			
			options.out = function(evt, ui) {
				if (originOptions.out) originOptions.out.apply(this, arguments);
				if (doradoDroppable) {
					var draggingInfo = dorado.DraggingInfo.getFromJQueryUI(ui);
					if (draggingInfo) {
						doradoDroppable.onDraggingSourceOut(draggingInfo, evt);
						if (draggingInfo._targetDroppables.peek() == doradoDroppable) {
							draggingInfo._targetDroppables.pop();
						}
					}
				}
			};
			
			options.drop = function(evt, ui) {
				var draggable = jQuery(ui.draggable).data("ui-draggable");
				if (!jQuery.ui.ddmanager.accept) {
					if (draggable && draggable.options.revert == "invalid") {
						draggable.options.revert = true;
						draggable.options.forceRevert = true;
					}
					return false;
				} else {
					if (draggable && draggable.options.forceRevert) {
						draggable.options.revert = "invalid";
						draggable.options.forceRevert = false;
					}
					var dropped = false;
					if (originOptions.drop) dropped = originOptions.drop.apply(this, arguments);
					if (!dropped && doradoDroppable) {
						var draggingInfo = dorado.DraggingInfo.getFromJQueryUI(ui);
						if (draggingInfo) {
							setTimeout(function() {
								if (doradoDroppable.beforeDraggingSourceDrop(draggingInfo, evt)) {
									doradoDroppable.onDraggingSourceDrop(draggingInfo, evt);
								}
							}, 20);
						}
					}
					return true;
				}
			};
			
			options.accept = function(draggable) {
				var accept = originOptions.accept;
				if (accept) {
					if (typeof accept == "function") {
						accept = accept.apply(this, arguments);
					} else {
						accept = draggable.is(accept);
					}
				}
				return !!accept;
			};
		}
		return oldDroppable.call(this, options);
	};
	
	if (dorado.Browser.chrome || dorado.Browser.safari) {
		jQuery.ui.draggable.prototype.options.userSelectFix = true;
		$.ui.plugin.add("draggable", "userSelectFix", {
			start: function(evt, ui) {
				$DomUtils.disableUserSelection(document.body);
			},
			stop: function(evt, ui) {
				$DomUtils.enableUserSelection(document.body);
			}
		});
	}

//	var useShimDiv;
//
//	jQuery.ui.plugin.add("draggable", "useShim", {
//		start: function(event, ui) {
//			var options = $(this).data("ui-draggable").options;
//			if (options.useShim !== false) {
//				if (!useShimDiv) {
//					useShimDiv = document.createElement("div");
//					useShimDiv.className = "ui-draggable-useShim";
//					useShimDiv.style.background = "#fff";
//					document.body.appendChild(useShimDiv);
//				}
//				$(useShimDiv).css({
//					display: "",
//					position: "absolute",
//					opacity: "0.001",
//					zIndex: 999,
//					left: 0,
//					top: 0
//				});
//
//				var doc = useShimDiv.ownerDocument, bodyHeight = $fly(doc).height(), bodyWidth;
//				if (dorado.Browser.msie) {
//					if (dorado.Browser.version == 6) {
//						bodyWidth = $fly(doc).width() - (parseInt($fly(doc.body).css("margin-left"), 10) || 0)-
//									(parseInt($fly(doc.body).css("margin-right"), 10) || 0);
//						$fly(useShimDiv).width(bodyWidth - 2).height(bodyHeight - 4);
//					} else if (dorado.Browser.version == 7) {
//						$fly(useShimDiv).width("100%").height(bodyHeight);
//					} else if (dorado.Browser.version == 8) {
//						$fly(useShimDiv).width("100%").height(bodyHeight - 4);
//					}
//				} else {
//					$fly(useShimDiv).width("100%").height(bodyHeight - 4);
//				}
//			}
//		},
//		stop: function(event, ui) {
//			jQuery(useShimDiv).css("display", "none");
//		}
//	});
//
//	jQuery.ui.draggable.prototype.options.useShim = false;
	
	jQuery.ui.draggable.prototype.options.iframeFix = true;

	jQuery.ui.draggable.prototype._mouseCapture = function(event) {

		var o = this.options;

		// among others, prevent a drag on a resizable-handle
		if (this.helper || o.disabled || $(event.target).closest(".ui-resizable-handle").length > 0) {
			return false;
		}

		//Quit if we're not on a valid handle
		this.handle = this._getHandle(event);
		if (!this.handle) {
			return false;
		}

		$(o.iframeFix === true ? "iframe" : o.iframeFix).each(function() {
			$("<div class='ui-draggable-iframeFix' style='background: #fff;'></div>")
				.css({
					width: this.offsetWidth+"px", height: this.offsetHeight+"px",
					position: "absolute", opacity: "0.001", zIndex: 9999
				})
				.css($(this).offset())
				.appendTo("body");
		});

		return true;

	};

	//修复this.options.axis不能设置为空的问题。
	//	$.ui.draggable.prototype._mouseDrag = function(event, noPropagation) {
	//
	//		//Compute the helpers position
	//		this.position = this._generatePosition(event);
	//		this.positionAbs = this._convertPositionTo("absolute");
	//
	//		//Call plugins and callbacks and use the resulting position if something is returned
	//		if (!noPropagation) {
	//			var ui = this._uiHash();
	//			if(this._trigger('drag', event, ui) === false) {
	//				this._mouseUp({});
	//				return false;
	//			}
	//			this.position = ui.position;
	//		}
	//
	//		if(!this.options.axis || this.options.axis == "x") this.helper[0].style.left = this.position.left+'px';
	//		if(!this.options.axis || this.options.axis == "y") this.helper[0].style.top = this.position.top+'px';
	//		if($.ui.ddmanager) $.ui.ddmanager.drag(this, event);
	//
	//		return false;
	//	};

})(jQuery);

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 渲染器的通用接口。
 * @abstract
 */
dorado.Renderer = $class(/** @scope dorado.Renderer.prototype */{
	$className: "dorado.Renderer",
	
	/**
	 * 渲染指定的DOM对象。
	 * @param {HTMLElement} dom 要渲染的DOM对象。
	 * @param {Object} arg 渲染参数。
	 */
	render: function(dom, arg) {
	}
});

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 空的渲染器。该渲染器不完成任何实际的渲染操作。
 * @static
 */
dorado.Renderer.NONE_RENDERER = new dorado.Renderer();

dorado.Renderer.render = function(renderer, dom, arg) {
	if (renderer instanceof dorado.Renderer) {
		renderer.render(dom, arg);
	} else if (typeof renderer == "function") {
		renderer(dom, arg);
	}
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 可渲染对象的通用接口。
 * @abstract
 * @extends dorado.AttributeSupport
 */
dorado.RenderableElement = $extend(dorado.AttributeSupport, /** @scope dorado.RenderableElement.prototype */ {
	$className: "dorado.RenderableElement",

	_ignoreRefresh: 0,

	ATTRIBUTES: /** @scope dorado.RenderableElement.prototype */ {

		/**
		 * CSS类名。
		 * @type String
		 * @attribute writeBeforeReady
		 */
		className: {
			writeBeforeReady: true
		},

		/**
		 * 扩展CSS类名。
		 * @type String
		 * @attribute
		 */
		exClassName: {
			skipRefresh: true,
			setter: function(v) {
				if (this._rendered && this._exClassName) {
					$fly(this.getDom()).removeClass(this._exClassName);
				}
				this._exClassName = v;
				if (this._rendered && v) {
					$fly(this.getDom()).addClass(v);
				}
			}
		},

		/**
		 * 宽度。
		 * @type int
		 * @attribute
		 */
		width: {
			setter: function(v) {
				this._width = isFinite(v) ? parseInt(v) : v;
			}
		},

		/**
		 * 高度。
		 * @type int
		 * @attribute
		 */
		height: {
			setter: function(v) {
				this._height = isFinite(v) ? parseInt(v) : v;
			}
		},

		/**
		 * 用于简化DOM元素style属性设置过程的虚拟属性。
		 * 此处用于赋值给style属性的对象是一个结构与HTMLElement的style相似的JavaScript对象。
		 * @type Object|String
		 * @attribute
		 *
		 * @example
		 * // 当我们需要为DOM元素指定背景色和字体颜色时可以使用这样的style
		 * renderable.set("style", {
		 * 	color : "yellow",
		 * 	backgroundColor : "blue"
		 * });
		 *
		 * @example
		 * renderable.set("style", "color: yellow; background-color: blue");
		 */
		style: {
			setter: function(v) {
				if (typeof v == "string" || !this._style) {
					this._style = v;
				}
				else if (v) {
					dorado.Object.apply(this._style, v);
				}
			}
		},

		/**
		 * 指示此对象是否已经渲染过。
		 * @type boolean
		 * @attribute readOnly
		 */
		rendered: {
			readOnly: true
		}
	},

	destroy: function() {
		var dom = this._dom;
		if (dom) {
			delete this._dom;
			if (dorado.windowClosed) {
				$fly(dom).unbind();
			}
			else {
				$fly(dom).remove();
			}
		}
		$invokeSuper.call(this);
	},

	doSet: function(attr, value) {
		var errorMessage = $invokeSuper.call(this, [attr, value]);

		var def = this.ATTRIBUTES[attr];
		if (this._rendered && this._ignoreRefresh < 1 && def && !def.skipRefresh) {
			dorado.Toolkits.setDelayedAction(this, "$refreshDelayTimerId", this.refresh, 50);
		}
		
		return errorMessage;
	},

	/**
	 * 创建对象对应的DOM元素。
	 * <p>
	 * 此方法只会在对象第一次渲染时执行一次。 所以一般而言，不应该在此放置初始化DOM元素的代码。例如那些设置DOM元素的颜色、字体、尺寸的代码。
	 * 而那些而DOM元素绑定事件监听器的代码则适合放置在此方法中。
	 * </p>
	 * @return {HTMLElement} 新创建的DOM元素。
	 */
	createDom: function() {
		return document.createElement("DIV");
	},

	/**
	 * 根据对象自身的属性设定来刷新DOM元素。
	 * <p>
	 * 此方法会在对象每一次被刷新时调用，因此那些设置DOM元素的颜色、字体、尺寸的代码适合放置在此方法中。
	 * </p>
	 * @param {HTMLElement} dom 对应的DOM元素。
	 */
	refreshDom: function(dom) {
		if (dom.nodeType != 3) {
			this.applyStyle(dom);
			this.resetDimension();
		}
	},

	/**
	 * 重设对象的尺寸。
	 * @protected
	 * @param {boolean} [forced] 是否强制重设对象的尺寸，忽略对于宽高值是否发生过改变的判断。
	 * @return {boolean} 本次操作是否改变了对象的尺寸设置。
	 */
	resetDimension: function(forced) {
		var dom = this.getDom(), $dom = $fly(dom), changed = false;
		var width = this.getRealWidth();
		var height = this.getRealHeight();
		if (forced || width && this._currentWidth != width) {
			if (width < 0) {
				this._currentWidth = null;
				dom.style.width = "";
			}
			else {
				this._currentWidth = width;
				if (this._useInnerWidth) {
					$dom.width(width);
				}
				else {
					$dom.outerWidth(width);
				}
			}
			changed = true;
		}
		if (forced || height && this._currentHeight != height) {
			if (height < 0) {
				this._currentHeight = null;
				dom.style.height = "";
			}
			else {
				this._currentHeight = height;
				if (this._useInnerHeight) {
					$dom.height(height);
				}
				else {
					$dom.outerHeight(height);
				}
			}
			changed = true;
		}
		return changed;
	},

	/**
	 * 获得渲染时实际应该采用的宽度值。
	 * <p>
	 * 通过width属性设置的宽度值并不总是该对象实际渲染时所使用的值，实际的宽度常常会受布局管理器或其他类似的功能控制。
	 * 此方法的作用就是返回渲染时实际应该采用的宽度值。
	 * </p>
	 * @return {int|String} 宽度。
	 */
	getRealWidth: function() {
		return (this._realWidth == null) ? this._width : this._realWidth;
	},

	/**
	 * 获得渲染时实际应该采用的高度值。
	 * <p>
	 * 通过width属性设置的高度值并不总是该对象实际渲染时所使用的值，实际的高度常常会受布局管理器或其他类似的功能控制。
	 * 此方法的作用就是返回渲染时实际应该采用的高度值。
	 * </p>
	 * @return {int|String} 宽度。
	 */
	getRealHeight: function() {
		return (this._realHeight == null) ? this._height : this._realHeight;
	},

	applyStyle: function(dom) {
		if (this._style) {
			var style = this._style;
			if (typeof this._style == "string") {
				// 此段处理不能用jQuery.attr("style", style)替代，原因是该方法会覆盖DOM原有的inliine style设置。
				var map = {};
				jQuery.each(style.split(';'), function(i, section) {
					var i = section.indexOf(':');
					if (i > 0) {
						var attr = jQuery.trim(section.substring(0, i));
						var value = jQuery.trim(section.substring(i + 1));
						if (dorado.Browser.msie && attr.toLowerCase() == "filter") {
							dom.style.filter = value;
						}
						else {
							map[attr] = value;
						}
					}
				});
				style = map;
			}
			$fly(dom).css(style);
			delete this._style;
		}
	},

	/**
	 * 返回对象对应的DOM元素。
	 * @return {HTMLElement} 控件对应的DOM元素。
	 */
	getDom: function() {
		if (!this._dom) {
			this._dom = this.createDom();
			var $dom = $fly(this._dom);

			var className = (this._inherentClassName) ? this._inherentClassName : "";
			if (this._className) className += (" " + this._className);
			if (this._exClassName) className += (" " + this._exClassName);
			if (className) $dom.addClass(className);

			this.applyStyle(this._dom);
		}
		return this._dom;
	},

	doRenderToOrReplace: function(replace, element, nextChildElement) {
		var dom = this.getDom();
		if (!dom) return;

		if (replace) {
			if (!element.parentNode) return;
			element.parentNode.replaceChild(dom, element);
		}
		else {
			if (!element) element = document.body;
			if (dom.parentNode != element || (nextChildElement && dom.nextSibling != nextChildElement)) {
				if (nextChildElement) {
					element.insertBefore(dom, nextChildElement);
				}
				else {
					element.appendChild(dom);
				}
			}
		}

		this.refreshDom(dom);
		this._rendered = true;
	},

	/**
	 * 将本对象渲染到指定的DOM容器中。
	 * @param {HTMLElement} containerElement 作为容器的DOM元素。如果此参数为空，将以document.body作为容器。
	 * @param {HTMLElement} [nextChildElement] 指定新的DOM元素要在那个子元素之前插入，即通过此参数可以指定新的DOM元素的插入位置。
	 */
	render: function(containerElement, nextChildElement) {
		this.doRenderToOrReplace(false, containerElement, nextChildElement);
	},

	/**
	 * 本对象并替换指定的DOM对象。
	 * @param {HTMLElement} elmenent 要替换的DOM对象。
	 */
	replace: function(elmenent) {
		this.doRenderToOrReplace(true, elmenent);
	},

	/**
	 * 将对象的DOM节点从其父节点中移除。
	 */
	unrender: function() {
		var dom = this.getDom();
		if (dom && dom.parentNode) dom.parentNode.removeChild(dom);
	},

	/**
	 * 刷新此对象的显示。
	 * @param {boolean} delay 是否允许此次refresh动作延时执行。设置成true有利于系统对refresh动作进行优化处理。
	 */
	refresh: function(delay) {
		if (!this._rendered) return;
		if (delay) {
			dorado.Toolkits.setDelayedAction(this, "$refreshDelayTimerId", function() {
				dorado.Toolkits.cancelDelayedAction(this, "$refreshDelayTimerId");
				this.refreshDom(this.getDom());
			}, 50);
		}
		else {
			dorado.Toolkits.cancelDelayedAction(this, "$refreshDelayTimerId");
			this.refreshDom(this.getDom());
		}
	}
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 标签管理器。
 * <p>
 * 通过此对象可以方便的管理所以支持标签的对象，提取拥有某一标签的所以对象实例。
 * </p>
 * @static
 *
 * @see dorado.AttributeSupport
 * @see dorado.AttributeSupport@attribute:tags
 */
dorado.TagManager = {

	_map: {},
	
	_register: function(tag, object) {
		if (!object._id) object._id = dorado.Core.newId();
		var info = this._map[tag];
		if (info) {
			if (!info.idMap[object._id]) {
				info.list.push(object);
				info.idMap[object._id] = object;
			}
		} else {
			this._map[tag] = info = {
				list: [object],
				idMap: {}
			};
			info.idMap[object._id] = object;
		}
	},
	
	_unregister: function(tag, object) {
		var info = this._map[tag];
		if (info) {
			if (info.idMap[object._id]) {
				delete info.idMap[object._id];
				info.list.remove(object);
			}
		}
	},
	
	_regOrUnreg: function(object, remove) {
		var tags = object._tags;
		if (tags) {
			if (typeof tags == "string") tags = tags.split(',');
			if (tags instanceof Array) {
				for (var i = 0; i < tags.length; i++) {
					var tag = tags[i];
					if (typeof tag == "string" && tag.length > 0) {
						remove ? this._unregister(tag, object) : this._register(tag, object);
					}
				}
			}
		}
	},
	
	/**
	 * 向标签管理器中注册一个对象。
	 * <p>此方法一般由系统内部自动调用，如无特殊需要不必自行调用此方法。</p>
	 * @param {dorado.AttributeSupport} object
	 */
	register: function(object) {
		this._regOrUnreg(object);
	},
	
	/**
	 * 从标签管理器中注销一个对象。
	 * <p>此方法一般由系统内部自动调用，如无特殊需要不必自行调用此方法。</p>
	 * @param {dorado.AttributeSupport} object
	 */
	unregister: function(object) {
		this._regOrUnreg(object, true);
	},
	
	/**
	 * 返回所有具有某一指定标签的对象的对象组。
	 * @param {String} tags 标签值。
	 * @return {dorado.ObjectGroup} 对象组。
	 *
	 * @see dorado.ObjectGroup
	 * @see $tags
	 *
	 * @example
	 * // 寻找所有具有limited标签的对象，并统一设置他们的readOnly属性。
	 * dorado.TagManager.find("limited").set("readOnly", true);
	 */
	find: function(tags) {
		var info = this._map[tags];
		if (info) {
			var objects = info.list, object;
			for (var i = 0, len = objects.length; i < len; i++) {
				object = objects[i];
				if (object._lazyInit) object._lazyInit();
			}
			return new dorado.ObjectGroup(objects);
		}
		else {
			return new dorado.ObjectGroup(null);
		}
	}
};

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 对象组。
 * <p>用于将一批对象组合在一起，以便于方便的进行统一处理，例如统一的设置属性或调用方法。</p>
 * @param {Object[]} objects 要进行的组合的对象的数组。
 */
dorado.ObjectGroup = $class(/** @scope dorado.ObjectGroup.prototype */{
	/**
	 * @name dorado.AttributeSupport#objects
	 * @property
	 * @type dorado.AttributeSupport[]
	 * @description 对象数组。
	 */
	// =====
	
	constructor: function(objects) {
		if (objects && !(objects instanceof Array)) {
			objects = [objects];
		}
		this.objects = objects || [];
	},
	
	/**
	 * 对组中的所有对象进行属性赋值操作。
	 * <p>如果对象组中的某个对象不支持此处将设置属性，该方法会跳过该对象这一个操作并继续后续处理。
	 * 此方法的使用方法与(@link dorado.AttributeSupport#set)方法非常类似，具体使用说明请参考(@link dorado.AttributeSupport#set)方法的说明。</p>
	 * @param {String|Object} attr 属性名或包含多个属性值对的JSON对象。
	 * @param {Object} [value] 属性值。
	 * @return {dorado.AttributeSupport} 返回对象组自身。
	 *
	 * @see dorado.AttributeSupport#set
	 */
	set: function(attr, value) {
		if (!this.objects) return;
		for (var i = 0, len = this.objects.length; i < len; i++) {
			var object = this.objects[i];
			if (object) object.set(attr, value, true);
		}
		return this;
	},
	
	/**
	 * 读取组中每一个对象的属性，并将所有结果集合成一个新组返回。
	 * @param {String} attr 属性名。
	 * @return {dorado.ObjectGroup} 由读取到的结果组成的对象组。
	 */
	get: function(attr) {
		var attrs = attr.split('.'), objects = this.objects;
		for (var i = 0, len = attrs.length; i < len; i++) {
			var a = attrs[i], results = [];
			for (var j = 0; j < objects.length; j++) {
				var object = objects[j], result;
				if (!object) continue;
				if (typeof object.get == "function") {
					result = object.get(a);
				}
				else {
					result = object[a];
				}
				if (result != null) results.push(result);
			}
			objects = results;
		}
		return new dorado.ObjectGroup(objects);
	},

	/**
	 * 添加一个事件监听器。
	 * @deprecated
	 * @see dorado.EventSupport#bind
	 */
	addListener: function (name, listener, options) {
		return this.bind(name, listener, options);
	},

	/**
	 * 移除一个事件监听器。
	 * @deprecated
	 * @see dorado.EventSupport#unbind
	 */
	removeListener: function (name, listener) {
		return this.unbind(name, listener);
	},
	
	/**
	 * 为组中的所有对象绑定事件。
	 * <p>如果对象组中的某个对象不支持事件，该方法会跳过该对象这一个操作并继续后续处理。
	 * 此方法的使用方法与(@link dorado.EventSupport#bind)方法非常类似，具体使用说明请参考(@link dorado.EventSupport#bind)方法的说明。</p>
	 * @param {String} name 事件名称，可支持别名。
	 * @param {Function} listener 事件监听方法。
	 * @param {Object} [options] 监听选项。
	 * @return {dorado.AttributeSupport} 返回对象组自身。
	 *
	 * @see dorado.EventSupport#bind
	 */
	bind: function(name, listener, options) {
		if (!this.objects) return;
		for (var i = 0, len = this.objects.length; i < len; i++) {
			var object = this.objects[i];
			if (object && typeof object.bind == "function") {
				object.bind(name, listener, options);
			}
		}
	},
	
	/**
	 * 从组中的所有对象中移除一个事件。
	 * <p>如果对象组中的某个对象不支持事件，该方法会跳过该对象这一个操作并继续后续处理。
	 * 此方法的使用方法与(@link dorado.EventSupport#unbind)方法非常类似，具体使用说明请参考(@link dorado.EventSupport#unbind)方法的说明。</p>
	 * @param {String} name 事件名称，可支持别名。
	 * @param {Function} [listener] 事件监听器。如果不指定此参数则表示移除该事件中的所有监听器
	 * @return {dorado.AttributeSupport} 返回对象组自身。
	 *
	 * @see dorado.EventSupport#unbind
	 */
	unbind: function(name, listener) {
		if (!this.objects) return;
		for (var i = 0, len = this.objects.length; i < len; i++) {
			var object = this.objects[i];
			if (object && object.unbind) {
				object.unbind(name, listener);
			}
		}
	},
	
	/**
	 * 调用组中的所有对象的某个方法。
	 * @param {String} methodName 要调用的方法名。
	 * @param {Object...} [arg] 调用方法时传入的参数。
	 *
	 * @example
	 * // 同时调用3个按钮的set方法，将他们的disabled属性设置为true。
	 * var group = new dorado.ObjectGroup([button1, button2, button3]);
	 * group.invoke("set", "disabled", true);
	 */
	invoke: function(methodName) {
		if (!this.objects) return;
		for (var i = 0, len = this.objects.length; i < len; i++) {
			var object = this.objects[i];
			if (object) {
				var method = object[methodName];
				if (typeof method == "function") method.apply(object, Array.prototype.slice.call(arguments, 1));
			}
		}
	},
	
	/**
	 * 遍历对象。
	 * @param {Function} fn 针对组中每一个对象的回调函数。此函数支持下列两个参数:
	 * <ul>
	 * <li>object - {dorado.AttributeSupport} 当前遍历到的对象。</li>
	 * <li>[i] - {int} 当前遍历到的对象的下标。</li>
	 * </ul>
	 * 另外，此函数的返回值可用于通知系统是否要终止整个遍历操作。
	 * 返回true或不返回任何数值表示继续执行遍历操作，返回false表示终止整个遍历操作。<br>
	 * 此回调函数中的this指向正在被遍历的对象数组。
	 */
	each: function(callback) {
		if (!this.objects) return;
		this.objects.each(callback);
	}
});

/**
 * @name $group
 * @function
 * @description 创建一个对象组。new dorado.ObjectGroup()操作的快捷方式。
 * @param {Object..} objects 要进行的组合的对象的数组。
 * @return {dorado.ObjectGroup} 新创建的对象组。
 *
 * @see dorado.ObjectGroup
 */
window.$group = function() {
	return new dorado.ObjectGroup(Array.prototype.slice.call(arguments));
};

/**
 * @name $tag
 * @function
 * @description 返回所有具有某一指定标签的对象的对象组。dorado.TagManager.find()方法的快捷方式。
 * @param {String} tags 标签值。
 * @return {dorado.ObjectGroup} 对象组。
 *
 * @see dorado.TagManager.find
 *
 * @example
 * // 寻找所有具有limited标签的对象，并统一设置他们的readOnly属性。
 * $tag("limited").set("readOnly", true);
 */
window.$tag = function(tags) {
	return dorado.TagManager.find(tags);
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 工具方法集。
 * @static
 */
dorado.Toolkits = {
	typesRegistry: {},
	typeTranslators: {},

	/**
	 * 向系统中注册一个类型的简写名。
	 * <p>
	 * 此注册的目的是为了将一种对象类型跟一个简写名关联起来，简化创建对象的操作。<br>
	 * 例如用户可以直接通过JSON对象中的$type属性指定该JSON对象最终应被实例化成哪种类型的实例。
	 * 见{@link dorado.Toolkits.createInstance}。
	 * </p>
	 * <p>
	 * dorado并不要求所有支持此种简化创建过程的类型都必须通过此方法注册到系统中。
	 * 事实上，对于大多数的类而言系统都支持根据一定的规则自动确定其类型简写名。
	 * 具体的缩写规则由各处的处理代码自行决定，例如{@link dorado.widget.Container#attribute:children}。
	 * </p>
	 * @param {String} namespace 命名空间。
	 * @param {String|Object} name 类型名简写。此参数支持下列两种定义方式：
	 * <ul>
	 * <li>传入一个String代表类型名简写。</li>
	 * <li>传入一个JSON对象表示要一次性的注册一组类型。
	 * 此时系统将忽略type参数，并将此JSON对象中的属性名认作类型名简写，属性值认作要注册的对象类型。</li>
	 * </ul>
	 * @param {Prototype} constr 对象的构造函数。
	 * @see dorado.Toolkits.createInstance
	 */
	registerPrototype: function(namespace, name, constr) {
		if (typeof name == "object") {
			for(var p in name) {
				if (name.hasOwnProperty(p)) {
					this.typesRegistry[namespace + '.' + p] = name[p];
				}
			}
		}
		else {
			this.typesRegistry[namespace + '.' + name] = constr;
		}
	},

	registerTypeTranslator: function(namespace, typeTranslator) {
		this.typeTranslators[namespace] = typeTranslator;
	},

	/**
	 * 根据传入的类型简写名返回匹配的对象的构造函数。
	 * @param {String} namespace 命名空间。
	 * 此处可以定义多个命名空间，以","隔开，表示依次在这些命名空间寻找注册的类型。
	 * @param {String|Object} name 类型名简写。
	 * @return {Prototype} 对象的构造函数。
	 */
	getPrototype: function(namespace, name) {
		var ns = namespace.split(",");
		for(var i = 0; i < ns.length; i++) {
			var n = ns[i], constr = this.typesRegistry[n + '.' + (name || "Default")];
			if (!constr) {
				var typeTranslator = this.typeTranslators[n];
				if (typeTranslator && typeof typeTranslator == "function") {
					constr = typeTranslator(name);
				}
			}
			if (constr) return constr;
		}
	},

	/**
	 * 此方法用于根据JSON配置对象中的$type属性指定的对象类型来实例化一个新的对象。
	 * <p>
	 * 在具体的执行过程中首先根据{$link dorado.Toolkits.registerPrototype}注册的简写名来识别$type。<br>
	 * 如果上面的步骤未能找到匹配项，则开始根据typeTranslator中定义的规则继续尝试识别$type。<br>
	 * 如果通过typeTranslator中定义的规则仍未能找到匹配项，那么此方法会将$type当作对象类型的全名进行识别。
	 * </p>
	 * @param {String} namespace 命名空间。
	 * 此处可以定义多个命名空间，以","隔开，表示依次在这些命名空间寻找注册的类型。
	 * @param {Object|String} config JSON配置对象。
	 * <ul>
	 * <li>当参数类型为Object时表示JSON配置对象。</li>
	 * <li>当参数类型为String时表示$type的值。</li>
	 * <li></li>
	 * </ul>
	 * @param {Function|String} [typeTranslator] 此参数有两种定义形式：
	 * <ul>
	 * <li>当参数类型为Function时表示用于将$type的值转换为具体对象类型的回调函数。</li>
	 * <li>当参数类型为String时表示对象类型名的前缀。在运行时附加到$type属性之前形成完整的对象名称。</li>
	 * <li></li>
	 * </ul>
	 * 对象类型名的前缀。在运行时附加到$type属性之前形成完整的对象名称。
	 * @return {Object} 创建得到的新对象。
	 * @see dorado.Toolkits.registerPrototype
	 *
	 * @example
	 * // 根据JSON配置创建一个Button对象。
	 * var button = dorado.Toolkits.createInstance("widget", {
	 * 	$type: "dorado.widget.Button",
	 * 	id: "button1",
	 * 	caption: "TestButton"
	 * });
	 *
	 * @example
	 * // 利用typeTranslator参数，简化$type属性中的定义。
	 * var button = dorado.Toolkits.createInstance("widget", {
	 * 	$type: "Button",
	 * 	id: "button1",
	 * 	caption: "TestButton"
	 * }, function(type) {
	 * 	switch (type) {
	 * 		case "Panel": return dorado.widget.Panel;
	 * 		case "Button": return dorado.widget.Button;
	 * 		case "Input": return dorado.widget.TextEditor;
	 * 		default: return dorado.widget.Control;
	 * 	}
	 * });
	 *
	 * @example
	 * // 利用typeTranslator参数，简化$type属性中的定义。
	 * var button = dorado.Toolkits.createInstance("widget", {
	 * 	$type: "Button",
	 * 	id: "button1",
	 * 	caption: "TestButton"
	 * }, "dorado.widget.");
	 *
	 * @example
	 * // 直接传入一个String作为$type的值。
	 * var button = dorado.Toolkits.createInstance("widget", "Button");
	 */
	createInstance: function(namespace, config, typeTranslator) {
		var type;
		if (typeof config == "string") {
			type = config;
			config = null;
		}
		else {
			type = config ? config.$type : undefined;
		}

		var constr = this.getPrototype(namespace, type);
		if (!constr) {
			if (typeTranslator && typeTranslator.constructor == String) {
				type = typeTranslator;
			}
			if (!constr) {
				if (typeTranslator && typeof typeTranslator == "function") {
					constr = typeTranslator(type);
				}
				if (!constr) {
					if (type) {
						constr = dorado.util.Common.getClassType(type);
					}
					else {
						throw new dorado.ResourceException("dorado.core.TypeUndefined");
					}
				}
			}

			if (constr && type) {
				this.registerPrototype(namespace, type, constr);
			}
		}
		if (!constr) {
			throw new dorado.ResourceException("dorado.core.UnknownType", type);
		}
		return new constr(config);
	},

	setDelayedAction: function(owner, actionId, fn, timeMillis) {
		actionId = actionId || dorado.Core.newId();
		this.cancelDelayedAction(owner, actionId);
		owner[actionId] = $setTimeout(owner, fn, timeMillis);
	},

	cancelDelayedAction: function(owner, actionId) {
		if (owner[actionId]) {
			clearTimeout(owner[actionId]);
			owner[actionId] = undefined;
			return true;
		}
		return false;
	},

	STATE_CODE: {
		info: 0,
		ok: 1,
		warn: 2,
		error: 3,
		validating: 99
	},

	getTopMessage: function(messages) {
		if (!messages) return null;
		var topMessage = null, topStateCode = -1;
		for(var i = 0; i < messages.length; i++) {
			var message = messages[i];
			var code = this.STATE_CODE[message.state];
			if (code > topStateCode) {
				topStateCode = code;
				topMessage = message;
			}
		}
		return topMessage;
	},

	getTopMessageState: function(messages) {
		if (!messages) return null;
		var topMessage = this.getTopMessage(messages);
		return topMessage ? topMessage.state : null;
	},

	trimSingleMessage: function(message, defaultState) {
		if (!message) return null;
		if (typeof message == "string") {
			message = {
				state: defaultState,
				text: message
			};
		}
		else {
			message.state = message.state || defaultState;
		}
		return message;
	},

	trimMessages: function(message, defaultState) {
		if (!message) return null;
		var result;
		if (message instanceof Array) {
			var array = [];
			for(var i = 0; i < message.length; i++) {
				var m = this.trimSingleMessage(message[i], defaultState);
				if (!m) continue;
				array.push(m);
			}
			result = (array.length) ? array : null;
		}
		else {
			result = [this.trimSingleMessage(message, defaultState)];
		}
		return result;
	}
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @author Benny Bao (mailto:benny.bao@bstek.com)
 * @class 拖拽指示光标。
 * @extends dorado.RenderableElement
 */
dorado.DraggingIndicator = $extend(dorado.RenderableElement, /** @scope dorado.DraggingIndicator.prototype */ {
	$className: "dorado.DraggingIndicator",
	
	ATTRIBUTES: /** @scope dorado.DraggingIndicator.prototype */ {
	
		className: {
			defaultValue: "d-dragging-indicator"
		},
		
		/**
		 * 当前正被拖拽的对象是否可被放置在当前悬停的位置。
		 * @type boolean
		 * @attribute
		 */
		accept: {
			skipRefresh: true,
			setter: function(v) {
				if (this._accept != v) {
					this._accept = v;
					this.refresh();
				}
			}
		},
		
		/**
		 * 用于指示可放置状态的图标。
		 * @type String
		 * @attribute
		 */
		icon: {},
		
		/**
		 * 用于指示可放置状态的图标的CSS Class。
		 * @type String
		 * @attribute
		 */
		iconClass: {},
		
		/**
		 * 拖拽光标中拖拽内容区域的水平显示偏移值。
		 * @type int
		 * @attribute
		 */
		contentOffsetLeft: {
			defaultValue: 20
		},
		
		/**
		 * 拖拽光标中拖拽内容区域的垂直显示偏移值。
		 * @type int
		 * @attribute
		 */
		contentOffsetTop: {
			defaultValue: 20
		},
		
		/**
		 * 拖拽光标中拖拽内容区域的内容。
		 * @type HTMLElement|jQuery
		 * @attribute writeOnly
		 */
		content: {
			writeOnly: true,
			setter: function(content) {
				if (content instanceof jQuery) {
					content = content[0];
				}
				if (content) {
					content.style.position = "";
					content.style.left = 0;
					content.style.top = 0;
					content.style.right = 0;
					content.style.bottom = 0;
				}
				this._content = content;
			}
		}
	},
	
	constructor: function(config) {
		$invokeSuper.call(this, arguments);
		if (config) this.set(config);
	},
	
	createDom: function() {
		var dom = $DomUtils.xCreate({
			tagName: "div",
			content: [{
				tagName: "div",
				className: "content-container"
			}, {
				tagName: "div"
			}]
		});
		this._contentContainer = dom.firstChild;
		this._iconDom = dom.lastChild;
		return dom;
	},
	
	refreshDom: function(dom) {
		$invokeSuper.call(this, arguments);
		var contentContainer = this._contentContainer, $contentContainer = $fly(this._contentContainer), content = this._content;
		$contentContainer.toggleClass("default-content", (content == null)).left(this._contentOffsetLeft || 0).top(this._contentOffsetTop || 0);
		if (content) {
			if (content.parentNode != contentContainer) $contentContainer.empty().append(content);
		} else {
			$contentContainer.empty();
		}
		
		var w = contentContainer.offsetWidth + (this._contentOffsetLeft || 0);
		var h = contentContainer.offsetHeight + (this._contentOffsetTop || 0);
		$fly(dom).width(w).height(h);
		
		var iconDom = this._iconDom;
		$fly(iconDom).attr("class", "icon");
		var icon = this._icon, iconClass = this._iconClass;
		if (!icon && !iconClass) {
			iconClass = this._accept ? "accept-icon" : "denied-icon";
		}
		if (icon) {
			$DomUtils.setBackgroundImage(iconDom, icon);
		} else if (iconClass) {
			$fly(iconDom).addClass(iconClass);
		}
	}
});

dorado.DraggingIndicator.create = function() {
	return new dorado.DraggingIndicator();
};

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function() {

	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 拖拽信息。
	 * @extends dorado.AttributeSupport
	 * @param {Object} options 配置信息。
	 * <p>
	 * 系统会自动将该JSON对象中的属性设置到组件中。
	 * </p>
	 */
	dorado.DraggingInfo = $extend(dorado.AttributeSupport, /** @scope dorado.DraggingInfo.prototype */ {
		$className: "dorado.DraggingInfo",
		
		ATTRIBUTES: /** @scope dorado.DraggingInfo.prototype */ {
		
			/**
			 * 被拖拽的对象。
			 * @attribute
			 * @type Object
			 */
			object: {
				setter: function(object) {
					this._object = object;
					this._insertMode = null;
					this._refObject = null;
				}
			},
			
			/**
			 * 被拖拽的对象对应的HTMLElement。
			 * @attribute
			 * @type HTMLElement
			 */
			element: {},
			
			/**
			 * 被拖拽对象的拖拽标签数组。
			 * @attribute
			 * @type String[]
			 */
			tags: {},
			
			/**
			 * 拖拽操作始于哪个控件。
			 * @attribute
			 * @type dorado.widget.Control
			 */
			sourceControl: {},
			
			
			/**
			 * 对象被拖放到了哪个对象中。
			 * @attribute
			 * @type Object
			 */
			targetObject: {},
			
			/**
			 * 对象被拖放到了哪个控件中。
			 * @attribute
			 * @type dorado.widget.Control
			 */
			targetControl: {},
			
			/**
			 * 插入模式。
			 * @attribute
			 * @type String
			 */
			insertMode: {},
			
			/**
			 * 插入参考对象。
			 * @attribute
			 * @type Object
			 */
			refObject: {},
			
			/**
			 * 当前拖放位置是否可接受的正在拖拽的对象。
			 * @attribute
			 * @type boolean
			 */
			accept: {
				getter: function() {
					return jQuery.ui.ddmanager.accept;
				},
				setter: function(accept) {
					if (this._indicator) this._indicator.set("accept", accept);
					jQuery.ui.ddmanager.accept = accept;
				}
			},
			
			/**
			 * 拖拽指示器。
			 * @attribute
			 * @type dorado.DraggingIndicator
			 */
			indicator: {},
			
			/**
			 * 实际传递给jQuery.draggable方法的options参数。
			 * @attribute
			 * @type Object
			 */
			options: {}
		},
		
		constructor: function(options) {
			if (options) this.set(options);
			if (!this._tags) this._tags = [];
		},
		
		/**
		 * 根据给定的拖放标签数组判断对于当前正拖拽的对象是否可被接受。
		 * @param {String[]} droppableTags 拖放标签数组
		 * @return {boolean} 是否可接受。
		 */
		isDropAcceptable: function(droppableTags) {
			if (droppableTags && droppableTags.length && this._tags.length) {
				for (var i = 0; i < droppableTags.length; i++) {
					if (this._tags.indexOf(droppableTags[i]) >= 0) return true;
				}
			}
			return false;
		}
	});
	
	dorado.DraggingInfo.getFromJQueryUI = function(ui) {
		return $fly(ui.draggable[0]).data("ui-draggable").draggingInfo;
	};
	
	dorado.DraggingInfo.getFromElement = function(element) {
		element = (element instanceof jQuery) ? element : $fly(element);
		return element.data("ui-draggable").draggingInfo;
	};
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class 可拖拽对象的通用接口。
	 * @see dorado.Droppable
	 */
	dorado.Draggable = $class( /** @scope dorado.Draggable.prototype */{
		$className: "dorado.Draggable",
		
		defaultDraggableOptions: {
			distance: 5,
			revert: "invalid",
			cursorAt: {
				left: 8,
				top: 8
			}
		},
		
		ATTRIBUTES: /** @scope dorado.Draggable.prototype */ {
		
			/**
			 * 是否可拖拽。
			 * @type boolean
			 * @attribute
			 */
			draggable: {},
			
			/**
			 * 拖拽标签。
			 * <p>
			 * 声明拖拽标签可用用标签数组或是以','分隔的标签字符串。
			 * </p>
			 * <p>
			 * 当系统发现被拖拽对象的标签数组与鼠标移经的可接受拖拽对象的标签数组之间的交集不为空时，
			 * 系统将认为被拖拽对象可以被放置到该可接受拖拽对象中。（这只是一个大致的判断，具体的运行结果还可能受相关对象的事件定义所影响。）
			 * </p>
			 * @type String|String[]
			 * @attribute skipRefresh
			 * @see dorado.Droppable#attribute:droppableTags
			 */
			dragTags: {
				skipRefresh: true,
				setter: function(v) {
					if (typeof v == "string") v = v.split(',');
					this._dragTags = v || [];
				}
			}
		},
		
		EVENTS: /** @scope dorado.Draggable.prototype */ {
		
			/**
			 * 当此对象开始进入拖拽状态之初，系统尝试相应的拖拽指示光标时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingIndicator|HTMLElement} #arg.indicator 系统将要使用的默认拖拽指示光标。
			 * <p>
			 * 您可以直接修改此光标对象，也可以用新的实例替换掉此光标。甚至可以返回一个自己创建好的HTMLElement作用拖拽光标。
			 * </p>
			 * @param {Event} arg.event 系统Event对象。
			 * @param {HTMLElement} arg.draggableElement 被拖拽对象对应的HTMLElement。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onGetDraggingIndicator: {},
			
			/**
			 * 当此对象将要进入拖拽状态时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @param {boolean} #arg.processDefault=true 用于通知系统是否要继续完成后续动作。
			 * 即返回true表示允许此对象开始被拖拽，返回false则禁止此对象被拖拽。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDragStart: {},
			
			/**
			 * 当此对象的拖拽操作结束时触发的事件。
			 * 拖拽对象被成功的放置或拖拽操作被取消时都会触发此事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDragStop: {},
			
			/**
			 * 当此对象被拖动时触发的事件。
			 * 即当此对象处于被拖拽状态时伴随着鼠标的移动系统会不停的触发此事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDragMove: {}
		},
		
		/**
		 * 返回当系统将此对象初始化为可拖拽对象时将要传递给{@link jQuery.draggable}方法的options参数。
		 * @param {HTMLElement} dom 将要初始化的HTMLElement。
		 * @protected
		 * return {Object} options参数。
		 */
		getDraggableOptions: function(dom) {
			var options = dorado.Object.apply({
				doradoDraggable: this
			}, this.defaultDraggableOptions);
			return options;
		},
		
		applyDraggable: function(dom, options) {
			if (dom._currentDraggable !== this._draggable) {
				if (this._draggable) {
					options = options || this.getDraggableOptions(dom);
					$fly(dom).draggable(options);
				} else if ($fly(dom).data("ui-draggable")) {
					$fly(dom).draggable("destroy");
				}
				dom._currentDraggable = this._draggable;
			}
		},
		
		/**
		 * 创建当此对象进入被拖拽状态后与之相关联的拖拽信息对象。
		 * @protected
		 * @param {HTMLElement} dom 将要拖拽的HTMLElement。
		 * @param {Object} dom 传递给{@link jQuery.draggable}方法的options参数。
		 * return {dorado.DraggingInfo} 拖拽信息对象。
		 */
		createDraggingInfo: function(dom, options) {
			var info = new dorado.DraggingInfo({
				sourceControl: this,
				options: options,
				tags: this._dragTags
			});
			return info;
		},
		
		/**
		 * 初始化给定的拖拽信息对象。
		 * @protected
		 * @param {dorado.DraggingInfo} draggingInfo 拖拽信息对象。
		 * @param {Event} evt 系统Event对象。
		 */
		initDraggingInfo: function(draggingInfo, evt) {
		},
		
		/**
		 * 初始化给定的拖拽光标对象。
		 * @protected
		 * @param {dorado.DraggingIndicator|HTMLElement} indicator 拖拽光标对象。
		 * @param {dorado.DraggingInfo} draggingInfo 拖拽信息对象。
		 * @param {Event} evt 系统Event对象。
		 */
		initDraggingIndicator: function(indicator, draggingInfo, evt) {
		},
		
		onGetDraggingIndicator: function(indicator, evt, draggableElement) {
			if (!indicator) indicator = dorado.DraggingIndicator.create();
			var eventArg = {
				indicator: indicator,
				event: evt,
				draggableElement: draggableElement
			};
			this.fireEvent("onGetDraggingIndicator", this, eventArg);
			indicator = eventArg.indicator;
			
			if (indicator instanceof dorado.DraggingIndicator) {
				if (!indicator.get("rendered")) indicator.render();
				var dom = indicator.getDom();
				$fly(dom).bringToFront();
			}
			return indicator;
		},
		
		onDragStart: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt,
				processDefault: true
			};
			this.fireEvent("onDragStart", this, eventArg);
			return eventArg.processDefault;
		},
		
		onDragStop: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt,
				processDefault: true
			};
			this.fireEvent("onDragStop", this, eventArg);
			return eventArg.processDefault;
		},
		
		onDragMove: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt
			};
			this.fireEvent("onDragMove", this, eventArg);
		}
		
	});
	
	/**
	 * @author Benny Bao (mailto:benny.bao@bstek.com)
	 * @class  可接受拖放对象的通用接口。
	 * @see dorado.Draggable
	 */
	dorado.Droppable = $class(/** @scope dorado.Droppable.prototype */{
		$className: "dorado.Droppable",
		
		defaultDroppableOptions: {
			accept: "*",
			greedy: true,
			tolerance: "pointer"
		},
		
		ATTRIBUTES: /** @scope dorado.Droppable.prototype */ {
		
			/**
			 * 是否可接受拖放。
			 * @type boolean
			 * @attribute
			 */
			droppable: {},
			
			/**
			 * 可接受的拖拽标签。
			 * <p>
			 * 声明拖拽标签可用用标签数组或是以','分隔的标签字符串。
			 * </p>
			 * @type String|String[]
			 * @attribute skipRefresh
			 * @see dorado.Draggable#attribute:dragTags
			 */
			droppableTags: {
				skipRefresh: true,
				setter: function(v) {
					if (typeof v == "string") v = v.split(',');
					this._droppableTags = v || [];
				}
			}
		},
		
		EVENTS: /** @scope dorado.Droppable.prototype */ {
		
			/**
			 * 当有某被拖拽对象进入此对象的区域时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @param {boolean} #arg.accept 是否可接受此拖拽对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDraggingSourceOver: {},
			
			/**
			 * 当有某被拖拽对象离开此对象的区域时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDraggingSourceOut: {},
			
			/**
			 * 当有某被拖拽对象在此对象的区域内移动时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDraggingSourceMove: {},
			
			/**
			 * 当有某被拖拽对象在此对象的区域内被释放之前触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @param {boolean} #arg.processDefault=true 是否要继续系统默认的操作。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			beforeDraggingSourceDrop: {},
			
			/**
			 * 当有某被拖拽对象在此对象的区域内被释放时触发的事件。
			 * @param {Object} self 事件的发起者，即对象本身。
			 * @param {Object} arg 事件参数。
			 * @param {dorado.DraggingInfo} arg.draggingInfo 拖拽信息对象。
			 * @param {Event} arg.event 系统Event对象。
			 * @return {boolean} 是否要继续后续事件的触发操作，不提供返回值时系统将按照返回值为true进行处理。
			 * @event
			 */
			onDraggingSourceDrop: {}
		},
		
		/**
		 * 返回当系统将此对象初始化为可接受拖拽对象时将要传递给{@link jQuery.droppable}方法的options参数。
		 * @param {HTMLElement} dom 将要初始化的HTMLElement。
		 * @protected
		 * return {Object} options参数。
		 */
		getDroppableOptions: function(dom) {
			var options = dorado.Object.apply({
				doradoDroppable: this
			}, this.defaultDroppableOptions);
			return options;
		},
		
		applyDroppable: function(dom, options) {
			if (dom._currentDroppable !== this._droppable) {
				if (this._droppable) {
					options = options || this.getDroppableOptions(dom);
					$fly(dom).droppable(options);
				} else if ($fly(dom).data("ui-droppable")) {
					$fly(dom).droppable("destroy");
				}
				dom._currentDroppable = this._droppable;
			}
		},
		
		onDraggingSourceOver: function(draggingInfo, evt) {
			var accept = draggingInfo.isDropAcceptable(this._droppableTags);
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt,
				accept: accept
			};
			this.fireEvent("onDraggingSourceOver", this, eventArg);
			draggingInfo.set("accept", eventArg.accept);
			return eventArg.accept;
		},
		
		onDraggingSourceOut: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt
			};
			this.fireEvent("onDraggingSourceOut", this, eventArg);
			draggingInfo.set({
				targetObject: null,
				insertMode: null,
				refObject: null,
				accept: false
			});
		},
		
		onDraggingSourceMove: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt
			};
			this.fireEvent("onDraggingSourceMove", this, eventArg);
		},
		
		beforeDraggingSourceDrop: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt,
				processDefault: true
			};
			this.fireEvent("beforeDraggingSourceDrop", this, eventArg);
			return eventArg.processDefault;
		},
		
		onDraggingSourceDrop: function(draggingInfo, evt) {
			var eventArg = {
				draggingInfo: draggingInfo,
				event: evt
			};
			this.fireEvent("onDraggingSourceDrop", this, eventArg);
		},
		
		getMousePosition: function(evt) {
			var offset = $fly(this.getDom()).offset();
			return {
				x: evt.pageX - offset.left,
				y: evt.pageY - offset.top
			};
		}
		
	});
	
})();

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @class dorado浮动组件模态管理器。
 * <p>
 * 当需要为绝对定位元素显示模态背景的时候，可以调用该类的show和hide方法。
 * </p>
 * <p>
 * 该类有一个堆栈来保存调用模态背景的顺序，这样可以支持已经模态的组件弹出另外一个模态的组件这种复杂的情况。
 * </p>
 * @static
 */
dorado.ModalManager = {
	_controlStack : [],
	/**
	 * @private
	 */
	getMask : function() {
		var manager = dorado.ModalManager, maskDom = manager._dom;
		if (!maskDom) {
			maskDom = manager._dom = document.createElement("div");
			$fly(maskDom).mousedown(function(evt) {
				var repeat = function(fn, times, delay) {
					var first = true;
					return function() {
						if (times-- >= 0) {
							if (first) {
								first = false;
							} else {
								fn.apply(null, arguments);
							}
							var args = Array.prototype.slice.call(arguments);
							var self = arguments.callee;
							setTimeout(function() {
								self.apply(null, args)
							}, delay);
						}
					};
				};
				if (!dorado.Browser.msie && evt.target == maskDom) {
					var stack = manager._controlStack, stackEl = stack[stack.length - 1], dom;
					if (stackEl)
						dom = stackEl.dom;
					if (dom) {
						var control = dorado.widget.Control.findParentControl(dom);
						if (control) {
							var count = 1, fn = repeat(function() {
								dorado.widget.setFocusedControl(count++ % 2 == 1 ? control : null);
							}, 3, 100);
							fn();
						}
					}
				}
			}).mouseenter(function(evt) {
				evt.stopPropagation();
				evt.preventDefault();
				evt.returnValue = false;
				return false;
			}).mouseleave(function(evt) {
				evt.stopPropagation();
				evt.preventDefault();
				evt.returnValue = false;
				return false;
			});
			$fly(document.body).append(maskDom);
		}
		manager.resizeMask();

		return maskDom;
	},

	resizeMask : function() {
		var manager = dorado.ModalManager, maskDom = manager._dom;
		if (maskDom) {
			var doc = maskDom.ownerDocument, bodyHeight = $fly(doc).height(), bodyWidth;
			if (dorado.Browser.msie) {
				if (dorado.Browser.version == 6) {
					bodyWidth = $fly(doc).width()
						- (parseInt($fly(doc.body).css("margin-left"), 10) || 0)
						- (parseInt($fly(doc.body).css("margin-right"), 10) || 0);
					$fly(maskDom).width(bodyWidth - 2).height(bodyHeight - 4);
				} else if (dorado.Browser.version == 7) {
					$fly(maskDom).height(bodyHeight);
				} else {
					$fly(maskDom).height(bodyHeight - 4);
				}
			} else {
				$fly(maskDom).height(bodyHeight - 4);
			}
		}
	},

	/**
	 * 为一个html element显示模态背景。<br />
	 * 当一个html element需要显示模态背景的时候，就需要调用该方法，即使目前已经显示了模态背景。
	 *
	 * @param {HtmlElement} dom 要显示模态背景的元素
	 * @param {String}  [maskClass="d-modal-mask"] 显示的模态背景使用的className
	 */
	show: function(dom, maskClass) {
		var manager = dorado.ModalManager, stack = manager._controlStack, maskDom = manager.getMask();
		if (dom) {
			maskClass = maskClass || "d-modal-mask";
			$fly(maskDom).css({
				display : ""
			}).bringToFront();

			stack.push({
				dom: dom,
				maskClass: maskClass,
				zIndex : maskDom.style.zIndex
			});

			$fly(dom).bringToFront();
			setTimeout(function() {
				$fly(maskDom).prop("class", maskClass);
			}, 0);
		}
	},

	/**
	 * 隐藏一个html element的模态背景。<br />
	 * 在一个显示了模态背景的html element隐藏后，需要调用该方法，该方法会根据是否还有其他显示模态背景的html
	 * element显示，自动决定是否隐藏模态背景。
	 *
	 * @param {HtmlElement} dom 要隐藏模态背景的元素
	 */
	hide: function(dom) {
		var manager = dorado.ModalManager, stack = manager._controlStack, maskDom = manager.getMask();
		if (dom) {
			if (stack.length > 0) {
				var target = stack[stack.length - 1];
				if (target && target.dom == dom) {
					stack.pop();
				} else {
					for (var i = 0, j = stack.length; i < j; i++) {
						if (dom == (stack[i] || {}).dom) {
							stack.removeAt(i);
							break;
						}
					}
				}

				if (stack.length == 0) {
					$fly(maskDom).prop("class", "").css("display", "none");
				} else {
					target = stack[stack.length - 1];
					$fly(maskDom).css({
						zIndex : target.zIndex
					}).prop("class", target.maskClass);
				}
			}
		}
	}
};

$fly(window).bind("resize", function() {
	if (dorado.ModalManager.onResizeTimerId) {
		clearTimeout(dorado.ModalManager.onResizeTimerId);
		delete dorado.ModalManager.onResizeTimerId;
	}

	dorado.ModalManager.onResizeTimerId = setTimeout(function() {
		delete dorado.ModalManager.onResizeTimerId;
		dorado.ModalManager.resizeMask();
	}, 20);
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 * 
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 * 
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html) 
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 * 
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

/**
 * @class 任务指示器。
 * <p>
 * 任务提示器要正确执行就要先定义任务组，任务组的目的是为了将相似任务的信息合并到同一个任务提示框中。
 * </p>
 * <p>
 * 任务提示器已经预先定义好下列两个任务组:
 * 1. daemon:取义幽灵线程，用于显示大部分的Ajax后台操作。
 * 2. main:取义主线程，用于显示数据保存等操作，此类操作大都在执行时需要屏蔽用户的操作。
 * </p>
 * @static
 */
dorado.util.TaskIndicator = {
		
	type: null,

	idseed: 0,
	
	_taskGroups: {},
	
	init: function() {
		if (this.inited) return;
		this.inited = true;
		
		var mainType = $setting["common.taskIndicator.main.type"] || "panel";
		var daemonType = $setting["common.taskIndicator.daemon.type"] || "panel";
		
		// Main
		var taskGroupConfig =  {
			type: mainType,
			modal: true
		}
		if (mainType == "icon") {
			taskGroupConfig.showOptions = {
				align: "center",
				vAlign: "center"
			};
			taskGroupConfig.className = "d-main-task-indicator";
		}
		else if (mainType == "panel") {
			taskGroupConfig.showOptions = {
				align: "center",
				vAlign: "center"
			};
			taskGroupConfig.className = "d-main-task-indicator";
		}
		this.registerTaskGroup("main", taskGroupConfig);

		// Daemon
		taskGroupConfig =  {
			type: daemonType
		}
		if (daemonType == "icon") {
			taskGroupConfig.showOptions = {
				align: "innerright",
				vAlign: "innertop",
				offsetLeft: -15,
				offsetTop: 15
			};
			taskGroupConfig.className = "d-daemon-task-indicator";
		}
		else if (mainType == "panel") {
			taskGroupConfig.showOptions = {
				align: "innerright",
				vAlign: "innertop",
				offsetLeft: -15,
				offsetTop: 15
			};
			taskGroupConfig.className = "d-daemon-task-indicator";
		}
		this.registerTaskGroup("daemon", taskGroupConfig);
	},
	
	/**
	 * 注册一个任务提示组。
	 * @param {String} groupName 任务组的名称。
	 * @param {Object} [options] 任务组显示选项。
	 */
	registerTaskGroup: function(groupName, options) {
		var indicator = this, taskGroups = indicator._taskGroups;
		if (taskGroups[groupName]) {
			//task has registered already.
		} else {
			options = options || {};
			taskGroups[groupName] = options;
		}
	},
	
	/**
	 * 显示任务提示框。
	 * @example
	 * var taskId = dorado.util.TaskIndicator.showTaskIndicator("保存所有数据");
	 *  command.execute(function() {
	 * 	dorado.util.TaskIndicator.hideTaskIndicator(taskId);
	 * });
	 * @param {String} [taskInfo] 任务描述信息。如果不定义则显示一个默认的任务名称。
	 * @param {String} [groupName] 任务组的名称。如果不定义此参数，默认值为daemon。
	 * @param {Date} [startTime] 任务的开始时间
	 * @return {String} taskId 任务id。
	 */
	showTaskIndicator: function(taskInfo, groupName, startTime) {
		this.init();
		
		var indicator = this, taskGroups = indicator._taskGroups, taskGroupConfig;
		groupName = groupName || "daemon";
		taskGroupConfig = taskGroups[groupName];
		
		if (taskGroupConfig) {
			var groupPanel = taskGroupConfig.groupPanel;
			
			if (!groupPanel) {
				groupPanel = taskGroupConfig.groupPanel = new dorado.util.TaskGroupPanel(taskGroupConfig);
			}
			
			var taskId = groupName + "@" + ++indicator.idseed;
			groupPanel.show();
			groupPanel.addTask(taskId, taskInfo, startTime);
			
			return taskId;
		} else {
			//no register.
			return null;
		}
	},

	/**
	 * 更新某任务的提示信息。
	 * @param {String} taskId 任务id。
	 * @param {String} taskInfo 任务描述信息。
	 * @param {Date} [startTime] 任务的开始时间。
	 */
	updateTaskIndicator: function(taskId, taskInfo, startTime) {
		var indicator = this, taskGroups = indicator._taskGroups, taskGroupName, taskGroupConfig;

		taskGroupName = taskId.substring(0, taskId.indexOf("@"));
		taskGroupConfig = taskGroups[taskGroupName];

		if (taskGroupConfig) {
			var groupPanel = taskGroupConfig.groupPanel;
			if (groupPanel) {
				groupPanel.updateTask(taskId, taskInfo, startTime);
			}
		}
	},
	
	/**
	 * 隐藏任务提示框。
	 * @param {String} taskId 任务id。
	 */
	hideTaskIndicator: function(taskId) {
		var indicator = this, taskGroups = indicator._taskGroups, taskGroupName, taskGroupConfig;
		
		taskGroupName = taskId.substring(0, taskId.indexOf("@"));
		taskGroupConfig = taskGroups[taskGroupName];
		
		if (taskGroupConfig) {
			var groupPanel = taskGroupConfig.groupPanel;
			if (groupPanel) {
				groupPanel.removeTask(taskId);
			}
		}
	}
	
};

/**
 * @class TaskGroupPanel
 * <p>
 * 一般情况下，不需要单独使用该类。该类被TaskIndicator中的每个Group使用，每个Group对应一个TaskGroupPanel.
 * </p>
 */
dorado.util.TaskGroupPanel = $extend(dorado.RenderableElement, { /** @scope dorado.util.TaskGroupPanel.prototype */
	$className: "dorado.util.TaskGroupPanel",
	tasks: null,
	taskGroupConfig: null,
	_intervalId: null,
	
	ATTRIBUTES: /** @scope dorado.util.TaskGroupPanel.prototype */ {
		className: {
			defaultValue: "d-task-group"
		}
	},
	
	constructor: function(taskGroupConfig) {
		$invokeSuper.call(this);
		var panel = this;
		if (!taskGroupConfig) {
			throw new dorado.Exception("taskGroupRequired");
		}
		panel.taskGroupConfig = taskGroupConfig;
		
		panel.tasks = new dorado.util.KeyedArray(function(object) {
			return object.taskId;
		});
	},
	
	createDom: function() {
		var panel = this, dom, doms = {}, taskGroupConfig = panel.taskGroupConfig;
		if (taskGroupConfig.type == "bar") {
			dom = null;
		}
		else if (taskGroupConfig.type == "icon") {
			dom = $DomUtils.xCreate({
				tagName: "div",
				className: panel._className + " " + panel._className + "-" + taskGroupConfig.type + " " + taskGroupConfig.className,
				content: {
					tagName: "div",
					className: "icon",
					content: {
						tagName: "div",
						className: "spinner"
					}
				}
			});
		}
		else {
			dom = $DomUtils.xCreate({
				tagName: "div",
				className: panel._className + " " + panel._className + "-" + taskGroupConfig.type + " " + taskGroupConfig.className,
				content: [{
					tagName: "div",
					className: "icon",
					content: {
						tagName: "div",
						className: "spinner"
					}
				},{
					tagName: "div",
					className: "count-info",
					contextKey: "countInfo"
				}, {
					tagName: "ul",
					className: "task-list",
					contextKey: "taskList",
					content: {
						tagName: "li",
						className: "more",
						content: "... ... ...",
						contextKey: "more",
						style: "display: none"
					}
				}]
			}, null, doms);
			panel._doms = doms;
			
			taskGroupConfig.caption = taskGroupConfig.caption ? taskGroupConfig.caption : $resource("dorado.core.DefaultTaskCountInfo");
			taskGroupConfig.executeTimeCaption = taskGroupConfig.executeTimeCaption ? taskGroupConfig.executeTimeCaption : $resource("dorado.core.DefaultTaskExecuteTime");
		}
		
		return dom;
	},
	
	/**
	 * 添加任务
	 * @param {int} taskId 任务Id。
	 * @param {String} taskInfo 任务的提示信息
	 * @param {Date} [startTime] 任务的开始时间
	 */
	addTask: function (taskId, taskInfo, startTime) {
		startTime = (startTime || new Date()).getTime();
		var time = (new Date()).getTime();
		var panel = this, taskGroupConfig = panel.taskGroupConfig;
		
		if (taskGroupConfig.type == "panel") {
			var listDom = panel._doms.taskList, li = $DomUtils.xCreate({
				tagName: "li",
				className: "task-item",
				content: [{
					tagName: "span",
					className: "interval-span",
					content: taskGroupConfig.executeTimeCaption.replace("${taskExecuteTime}", parseInt((time - startTime) / 1000, 10))
				}, {
					tagName: "span",
					className: "caption-span",
					content: taskInfo
				}]
			});
			
			if (panel.tasks.size >= (panel.taskGroupConfig.showOptions.maxLines || 3)) {
				li.style.display = "none";
				panel._doms.more.style.display = "";
			}
			listDom.insertBefore(li, panel._doms.more);

			if (panel.tasks.size == 0) {
				panel._intervalId = setInterval(function() {
					panel.refreshInterval();
				}, 500);
			}
		}
		
		panel.tasks.append({
			taskId: taskId,
			dom: li,
			startTime: startTime
		});
		
		if (taskGroupConfig.type == "panel") {
			$fly(panel._doms.countInfo).text(taskGroupConfig.caption.replace("${taskNum}", panel.tasks.size));
		}
	},

	/**
	 * 更新某任务的提示信息
	 * @param {String} taskInfo 任务的提示信息
	 * @param {int} taskId 任务Id
	 * @param {Date} [startTime] 任务的开始时间
	 */
	updateTask: function(taskId, taskInfo, startTime) {
		var panel = this, target = panel.tasks.get(taskId), taskGroupConfig = panel.taskGroupConfig;
		if (target){
			if (startTime) target.startTime = startTime;

			if (taskGroupConfig.type == "panel") {
				if (target.dom) {
					$fly(target.dom).find(">.caption-span")[0].innerText = taskInfo;
				}
			}
		}
	},
	
	/**
	 * 移除任务。
	 * @param {int} taskId 分配给该任务的id。
	 */
	removeTask: function(taskId) {
		var panel = this, target = panel.tasks.get(taskId), taskGroupConfig = panel.taskGroupConfig;
		if (target) {
			if (taskGroupConfig.type == "bar" || taskGroupConfig.type == "icon") {
				panel.tasks.remove(target);
				if (panel.tasks.size == 0) {
					panel.hide();
				}
			}
			else if (taskGroupConfig.type == "panel") {
				setTimeout(function() {
					$fly(target.dom).remove();
					panel.tasks.remove(target);
					
					var maxLines = panel.taskGroupConfig.showOptions.maxLines || 3;
					if (panel.tasks.size > maxLines) {
						var i = 0;
						panel.tasks.each(function(task) {
							task.dom.style.display = "";
							if (++i == maxLines) return false;
						});
					}
					else {
						panel._doms.more.style.display = "none";
						if (panel.tasks.size == 0) {
							clearInterval(panel._intervalId);
							panel._intervalId = null;
							panel.hide();
						}
						else {
							panel.tasks.each(function(task) {
								task.dom.style.display = "";
							});
						}
					}
					$fly(panel._doms.countInfo).text(taskGroupConfig.caption.replace("${taskNum}", panel.tasks.size));
				}, 50);
			}
		}
	},
	
	/**
	 * 刷新所有正在执行任务的执行时间。
	 * @protected
	 */
	refreshInterval: function() {
		var panel = this, time = new Date().getTime();
		panel.tasks.each(function(task) {
			var el = task.dom, startTime = task.startTime;
			if (el && startTime) {
				var interval = parseInt((time - startTime) / 1000, 10);
				$fly(el).find(".interval-span").text(panel.taskGroupConfig.executeTimeCaption.replace("${taskExecuteTime}", interval));
			}
		});
	},
	
	/**
	 * 显示任务面板
	 * @param {Object} options 注册任务组的时候的配置信息中的showOptions选项。
	 */
	show: function(options) {
		var panel = this, taskGroupConfig = panel.taskGroupConfig;
		options = options || taskGroupConfig.showOptions;
		if (panel._hideTimer) {
			clearTimeout(panel._hideTimer);
			panel._hideTimer = null;
			return;
		}
		
		if (taskGroupConfig.type == "bar") {
			if (!panel._rendered) {
				panel._rendered = true;
				NProgress.configure({
					positionUsing: (dorado.Browser.isTouch && dorado.Browser.version < "535.0") ? "margin" : ""
				});
				panel._dom = NProgress.render(true);
			}
			NProgress.start();
		}
		else {
			if (!panel._rendered) {
				panel.render(document.body);
			} else {
				$fly(panel._dom).css("display", "").css("visibility", "");
			}
		}
		
		if (panel.tasks.size == 0 && taskGroupConfig.modal) {
			dorado.ModalManager.show(panel._dom);
		}
		$fly(panel._dom).bringToFront();
		
		if (options) {
			try {
				$DomUtils.dockAround(panel._dom, document.body, options);
			}
			catch(e) {
				// do nothing
			}
		}
	},
	
	/**
	 * 隐藏任务面板
	 */
	hide: function() {
		var panel = this;
		var taskGroupConfig = panel.taskGroupConfig;
		
		if (taskGroupConfig.type == "bar") {
			NProgress.done();
		}
		else {
			if (panel._rendered) {
				jQuery(panel._dom).css("display", "none").css("visibility", "hidden");
			}
		}
		
		if (taskGroupConfig.modal) {
			dorado.ModalManager.hide(panel._dom);
		}
	}
});

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 *
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 *
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html)
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 *
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */
(function($) {

	var SCROLLER_SIZE, SCROLLER_EXPANDED_SIZE;
	var SCROLLER_PADDING = 0, MIN_SLIDER_SIZE = SCROLLER_EXPANDED_SIZE, MIN_SPILLAGE = 2;

	function insertAfter(element, refElement) {
		var parent = refElement.parentNode;
		if (parent.lastChild == refElement) {
			parent.appendChild(element);
		}
		else {
			parent.insertBefore(element, refElement.nextSibling);
		}
	}

	dorado.util.Dom.ThinScroller = $class({
		// dom, doms, container, direction

		constructor: function(container, direction, options) {
			this.container = container;
			this.direction = direction;
			if (options) dorado.Object.apply(this, options);
		},

		destroy: function() {
			delete this.dom;
			delete this.doms;
			delete this.container;
		},

		createDom: function() {
			var scroller = this, doms = scroller.doms = {}, dom = scroller.dom = $DomUtils.xCreate({
				tagName: "DIV",
				className: "d-modern-scroller",
				style: "position: absolute",
				content: [
					{
						tagName: "DIV",
						contextKey: "track",
						className: "track",
						style: {
							width: "100%",
							height: "100%"
						}
					},
					{
						tagName: "DIV",
						contextKey: "slider",
						className: "slider",
						style: "position: absolute"
					}
				]
			}, null, doms);

			var $dom = $(dom), slider = doms.slider, $slider = $(slider), track = doms.track, $track = $(track);

			var draggableOptions = {
				containment: "parent",
				start: function() {
					scroller.dragging = true;
				},
				stop: function() {
					(scroller.hover) ? scroller.doMouseEnter() : scroller.doMouseLeave();
					scroller.dragging = false;
				},
				drag: function() {
					var container = scroller.container;
					if (scroller.direction == "h") {
						container.scrollLeft = Math.round(slider.offsetLeft * scroller.positionRatio);
					}
					else {
						container.scrollTop = Math.round(slider.offsetTop * scroller.positionRatio);
					}
				}
			}

			if (scroller.direction == "h") {
				dom.style.height = SCROLLER_SIZE + "px";

				slider.style.height = "100%";
				slider.style.top = "0px";

				draggableOptions.axis = "x";
			}
			else {
				dom.style.width = SCROLLER_SIZE + "px";

				slider.style.width = "100%";
				slider.style.left = "0px";

				draggableOptions.axis = "y";
			}
			$slider.draggable(draggableOptions);

			$dom.hover(function() {
				scroller.update();
				scroller.doMouseEnter();
			}, function() {
				scroller.doMouseLeave();
			});

			$track.click(function(evt) {
				var container = scroller.container;
				if (scroller.direction == "h") {
					if (evt.offsetX > slider.offsetLeft) {
						container.scrollLeft += container.clientWidth;
					}
					else {
						container.scrollLeft -= container.clientWidth;
					}
				}
				else {
					if (evt.offsetY > slider.offsetTop) {
						container.scrollTop += container.clientHeight;
					}
					else {
						container.scrollTop -= container.clientHeight;
					}
				}
			});

			$DomUtils.disableUserSelection(dom);
			$DomUtils.disableUserSelection(doms.track);
			return dom;
		},

		doMouseEnter: function() {
			var scroller = this;
			scroller.hover = true;
			if (scroller.dragging) return;

			$fly(scroller.dom).addClass("d-modern-scroller-hover");
			scroller.expand();
		},

		doMouseLeave: function() {
			var scroller = this;
			scroller.hover = false;
			if (scroller.dragging) return;

			$fly(scroller.dom).removeClass("d-modern-scroller-hover");
			scroller.unexpand();
		},

		expand: function() {
			var scroller = this;
			dorado.Toolkits.cancelDelayedAction(scroller, "$expandTimerId");
			if (scroller.expanded) return;

			var animOptions;
			if (scroller.direction == "h") {
				animOptions = {
					height: SCROLLER_EXPANDED_SIZE
				};
			}
			else {
				animOptions = {
					width: SCROLLER_EXPANDED_SIZE
				};
			}

			scroller.expanded = true;

			var $dom = $(scroller.dom);
			$dom.addClass("d-modern-scroller-expand");
			if (dorado.Browser.msie && dorado.Browser.version < 7) {
				$dom.css(animOptions);
			}
			else {
				scroller.duringAnimation = true;
				$dom.animate(animOptions, 0, function() {
					scroller.duringAnimation = false;
				});
			}
		},

		unexpand: function() {
			var scroller = this;
			dorado.Toolkits.setDelayedAction(scroller, "$expandTimerId", function() {
				var animOptions, container = scroller.container;
				if (scroller.direction == "h") {
					animOptions = {
						height: SCROLLER_SIZE
					};
				}
				else {
					animOptions = {
						width: SCROLLER_SIZE
					};
				}

				var $dom = $(scroller.dom);
				if (dorado.Browser.msie && dorado.Browser.version < 7) {
					$dom.css(animOptions);
					scroller.expanded = false;
				}
				else {
					scroller.duringAnimation = true;
					$dom.animate(animOptions, 300, function() {
						scroller.expanded = false;
						scroller.duringAnimation = false;
						$dom.removeClass("d-modern-scroller-expand");
					});
				}
			}, 700);
		},

		update: function() {
			var scroller = this, container = scroller.container;
			if (!container) return;

			var dom = scroller.dom, $container = $(container), scrollerSize = scroller.expanded ? SCROLLER_EXPANDED_SIZE : SCROLLER_SIZE;

			if (scroller.direction == "h") {
				if (container.scrollWidth > (container.clientWidth + MIN_SPILLAGE) && container.clientWidth > 0) {
					if (!dom) {
						dom = scroller.createDom();
						dom.style.zIndex = 9999;
						dom.style.bottom = 0;
						dom.style.left = 0;
						if (!dorado.Browser.msie || dorado.Browser.version != 6) {
							dom.style.width = "100%";
						}
						container.parentNode.appendChild(dom);
					}
					else {
						dom.style.display = "";
					}

					if (dorado.Browser.msie && dorado.Browser.version == 6) {
						dom.style.width = container.offsetWidth + "px";
					}

					var trackSize = container.offsetWidth - SCROLLER_PADDING * 2;
					var slider = scroller.doms.slider;
					var sliderSize = (trackSize * container.clientWidth / container.scrollWidth);
					if (sliderSize < MIN_SLIDER_SIZE) {
						trackSize -= (MIN_SLIDER_SIZE - sliderSize);
						sliderSize = MIN_SLIDER_SIZE;
					}

					scroller.positionRatio = container.scrollWidth / trackSize;
					slider.style.left = Math.round(container.scrollLeft / scroller.positionRatio) + "px";
					slider.style.width = Math.round(sliderSize) + "px";
				}
				else {
					if (dorado.Browser.msie && dorado.Browser.version == 9 && container.offsetWidth > 0) {
						// IE9下有时无法在初始化时取到正确的clientWidth
						setTimeout(function() {
							scroller.update();
						}, 0);
					}
					if (dom) {
						dom.style.display = "none";
					}
				}
			}
			else {
				if (container.scrollHeight > (container.clientHeight + MIN_SPILLAGE) && container.clientHeight > 0) {
					if (!dom) {
						dom = scroller.createDom();
						dom.style.zIndex = 9999;
						dom.style.top = 0;
						dom.style.right = 0;
						if (!dorado.Browser.msie || dorado.Browser.version != 6) {
							dom.style.height = "100%";
						}
						container.parentNode.appendChild(dom);
					}
					else {
						dom.style.display = "";
					}

					if (dorado.Browser.msie && dorado.Browser.version == 6) {
						dom.style.height = container.offsetHeight + "px";
					}

					var trackSize = container.offsetHeight - SCROLLER_PADDING * 2;
					var slider = scroller.doms.slider;
					var sliderSize = (trackSize * container.clientHeight / container.scrollHeight);
					if (sliderSize < MIN_SLIDER_SIZE) {
						trackSize -= (MIN_SLIDER_SIZE - sliderSize);
						sliderSize = MIN_SLIDER_SIZE;
					}

					scroller.positionRatio = container.scrollHeight / trackSize;
					slider.style.top = Math.round(container.scrollTop / scroller.positionRatio) + "px";
					slider.style.height = Math.round(sliderSize) + "px";
				}
				else {
					if (dorado.Browser.msie && dorado.Browser.version == 9 && container.offsetHeight > 0) {
						// IE9下有时无法在初始化时取到正确的clientWidth
						setTimeout(function() {
							scroller.update();
						}, 0);
					}
					if (dom) {
						dom.style.display = "none";
					}
				}
			}

			if (scroller.dragging) {
				if (scroller._updateTimerId) {
					clearTimeout(scroller._updateTimerId);
					delete scroller._updateTimerId;
				}
				scroller._updateTimerId = setTimeout(function() {
					if (scroller.dragging) {
						var draggable = $fly(scroller.doms.slider).data("ui-draggable");
						draggable._cacheHelperProportions();
						draggable._setContainment();
					}
				}, 200);
			}
		}
	});

	var ModernScroller = dorado.util.Dom.ModernScroller = $class({
		constructor: function(container, options) {
			this.id = dorado.Core.newId();
			this.container = container;
			this.options = options || {};
			var $container = $(container), options = this.options;

			if (options.listenSize || options.listenContainerSize || options.listenContentSize) {
				addListenModernScroller(this);
			}
		},

		destroy: function() {
			this.destroyed = true;
			var options = this.options;
			if (options.listenSize || options.listenContainerSize || options.listenContentSize) {
				removeListenModernScroller(this);
			}
			delete this.container;
		},

		setScrollLeft: dorado._NULL_FUNCTION,
		setScrollTop: dorado._NULL_FUNCTION,
		scrollToElement: dorado._NULL_FUNCTION
	});

	dorado.util.Dom.DesktopModernScroller = $extend(ModernScroller, {
		// container, xScroller, yScroller

		constructor: function(container, options) {
			$invokeSuper.call(this, arguments);

			var options = this.options;
			$container = $(container),
				parentDom = container.parentNode, $parentDom = $(parentDom);

			var overflowX = $container.css("overflowX"), overflowY = $container.css("overflowY");
			var width = $container.css("width"), height = $container.css("height");
			var xScroller, yScroller;

			if (!(overflowX == "hidden" || !dorado.Browser.isTouch && overflowX != "scroll" && (width == "" || width == "auto"))) {
				$container.css("overflowX", "hidden");
				xScroller = new dorado.util.Dom.ThinScroller(container, "h", options);
			}
			if (!(overflowY == "hidden" || !dorado.Browser.isTouch && overflowY != "scroll" && (height == "" || height == "auto"))) {
				$container.css("overflowY", "hidden");
				yScroller = new dorado.util.Dom.ThinScroller(container, "v", options);
			}

			if (!xScroller && !yScroller) throw new dorado.AbortException();

			this.xScroller = xScroller;
			this.yScroller = yScroller;

			var position = $parentDom.css("position");
			if (position != "relative" && position != "absolute") {
				$parentDom.css("position", "relative");
			}

			position = $container.css("position");
			if (position != "relative" && position != "absolute") {
				$container.css("position", "relative");
			}

			this.update();

			var modernScroller = this;
			if ($container.mousewheel) {
				$container.mousewheel(function(evt, delta) {
					if (container.scrollHeight > container.clientHeight) {
						var scrollTop = container.scrollTop - delta * 25;
						if (scrollTop <= 0) {
							scrollTop = 0;
						}
						else if (scrollTop + container.clientHeight > container.scrollHeight) {
							scrollTop = container.scrollHeight - container.clientHeight;
						}
						var gap = container.scrollTop - scrollTop
						if (gap) {
							container.scrollTop = scrollTop;
							if (Math.abs(gap) > MIN_SPILLAGE) {
								return false;
							}
						}
					}
					/*
					 if (container.scrollWidth > container.clientWidth) {
					 var scrollLeft = container.scrollLeft - delta * 25;
					 if (scrollLeft <= 0) {
					 scrollLeft = 0;
					 } else if (scrollLeft + container.clientWidth > container.scrollWidth) {
					 scrollLeft = container.scrollWidth - container.clientWidth;
					 }
					 var gap = container.scrollLeft - scrollLeft
					 if (gap) {
					 container.scrollLeft = scrollLeft;
					 if (Math.abs(gap) > MIN_SPILLAGE) return false;
					 }
					 }
					 */
				});
			}
			$container.bind("scroll",function(evt) {
				if (!(xScroller && xScroller.dragging || yScroller && yScroller.dragging)) {
					modernScroller.update();
				}

				var arg = {
					scrollLeft: container.scrollLeft, scrollTop: container.scrollTop,
					scrollWidth: container.scrollWidth, scrollHeight: container.scrollHeight,
					clientWidth: container.clientWidth, clientHeight: container.clientHeight
				};
				$(container).trigger("modernScrolling", arg).trigger("modernScrolled", arg);
			}).resize(function(evt) {
				modernScroller.update();
			});
		},

		update: function() {
			if (this.destroyed) return;			
			if (this.xScroller && this.xScroller.dragging) return; 
			if (this.yScroller && this.yScroller.dragging) return; 

			if (this.xScroller) this.xScroller.update();
			if (this.yScroller) this.yScroller.update();

			var container = this.container;
			this.currentClientWidth = container.clientWidth;
			this.currentClientHeight = container.clientHeight;
			this.currentScrollWidth = container.scrollWidth;
			this.currentScrollHeight = container.scrollHeight;
		},

		setScrollLeft: function(pos) {
			this.container.scrollLeft = pos;
		},

		setScrollTop: function(pos) {
			this.container.scrollTop = pos;
		},

		scrollToElement: function(dom) {
			var container = this.container, offsetElement = $fly(dom).offset(), offsetContainer = $fly(container).offset();
			var offsetLeft = offsetElement.left - offsetContainer.left, offsetTop = offsetElement.top - offsetContainer.top;
			var offsetRight = offsetLeft + dom.offsetWidth, offsetBottom = offsetTop + dom.offsetHeight;
			var scrollLeft = container.scrollLeft, scrollTop = container.scrollTop;
			var scrollRight = scrollLeft + container.clientWidth, scrollBottom = scrollTop + container.clientHeight;

			if (offsetLeft < scrollLeft) {
				if (offsetRight <= scrollRight) {
					this.setScrollLeft(offsetLeft);
				}
			}
			else if (offsetRight > scrollRight) {
				this.setScrollLeft(offsetRight + dom.offsetWidth);
			}

			if (offsetTop < scrollTop) {
				if (offsetBottom <= scrollBottom) {
					this.setScrollTop(offsetTop);
				}
			}
			else if (offsetBottom > scrollBottom) {
				this.setScrollTop(offsetBottom + dom.offsetHeight);
			}
		},

		destroy: function() {
			$invokeSuper.call(this, arguments);
			if (this.xScroller) this.xScroller.destroy();
			if (this.yScroller) this.yScroller.destroy();
		}
	});

	dorado.util.Dom.IScrollerWrapper = $extend(ModernScroller, {
		// iscroll

		constructor: function(container, options) {
			var $container = $(container);
			var overflowX = $container.css("overflowX"), overflowY = $container.css("overflowY");
			var width = $container.css("width"), height = $container.css("height");

			options = options || {};
			if (options.autoDisable === undefined) options.autoDisable = true;

			/*
			 if ((overflowX == "hidden" || overflowX != "scroll" && (width == "" || width == "auto")) &&
			 (overflowY == "hidden" || overflowY != "scroll" && (height == "" || height == "auto"))) {
			 throw new dorado.AbortException();
			 }
			 */

			var onScrolling = function() {
				var arg = {
					scrollLeft: this.x * -1, scrollTop: this.y * -1,
					scrollWidth: container.scrollWidth, scrollHeight: container.scrollHeight,
					clientWidth: container.clientWidth, clientHeight: container.clientHeight
				};
				$container.trigger("modernScrolling", arg);
			};

			var modernScroller = this, options = modernScroller.options = dorado.Object.apply({
				scrollbarClass: "iscroll",
				hideScrollbar: true,
				fadeScrollbar: true,
				onScrolling: onScrolling,
				onScrollMove: onScrolling,
				onScrollEnd: function() {
					var arg = {
						scrollLeft: this.x * -1, scrollTop: this.y * -1,
						scrollWidth: container.scrollWidth, scrollHeight: container.scrollHeight,
						clientWidth: container.clientWidth, clientHeight: container.clientHeight
					};
					$container.trigger("modernScrolled", arg);
				}
			}, options, false);

			$container.css("overflowX", "hidden").css("overflowY", "hidden");
			setTimeout(function() {
				modernScroller.iscroll = new iScroll(container, modernScroller.options);
				if (options.autoDisable && container.scrollHeight <= (container.clientHeight + 2) && (container.scrollWidth <= container.clientWidth + 2)) {
					modernScroller.iscroll.disable();
				}
			}, 0);

			$invokeSuper.call(modernScroller, [container, modernScroller.options]);

			var $container = $(container);
			$container.bind("scroll",function(evt) {
				modernScroller.update();
			}).resize(function(evt) {
					modernScroller.update();
				});
		},

		update: function() {
			if (!this.iscroll || this.destroyed || this.dragging) return;

			var iscroll = this.iscroll;
			if (this.options.autoDisable) {
				var container = this.container;
				if (container.scrollHeight - (iscroll.y || 0) > (container.clientHeight + 2) ||
					container.scrollWidth - (iscroll.x || 0) > (container.clientWidth + 2)) {
					this.iscroll.enable();
					this.iscroll.refresh();
				}
				else {
					this.iscroll.disable();
					this.iscroll.refresh();
				}
			}
			else {
				this.iscroll.refresh();
			}
		},

		scrollToElement: function(dom) {
			if (this.iscroll) this.iscroll.scrollToElement(dom);
		}
	});

	var listenModernScrollers = new dorado.util.KeyedList(dorado._GET_ID), listenTimerId;

	function addListenModernScroller(modernScroller) {
		listenModernScrollers.insert(modernScroller);
		if (listenModernScrollers.size == 1) {
			listenTimerId = setInterval(function() {
				listenModernScrollers.each(function(modernScroller) {
					var container = modernScroller.container, shouldUpdate = false;
					if (!container) return;
					if (modernScroller.options.listenSize || modernScroller.options.listenContainerSize) {
						if (modernScroller.currentClientWidth != container.clientWidth ||
							modernScroller.currentClientHeight != container.clientHeight) {
							shouldUpdate = true;
						}
					}
					if (modernScroller.options.listenSize || modernScroller.options.listenContentSize) {
						if (modernScroller.currentScrollWidth != container.scrollWidth ||
							modernScroller.currentScrollHeight != container.scrollHeight) {
							shouldUpdate = true;
						}
					}
					if (shouldUpdate) {
						modernScroller.update();
					}
				});
			}, 300);
		}
	}

	function removeListenModernScroller(modernScroller) {
		listenModernScrollers.remove(modernScroller);
		if (listenModernScrollers.size == 0 && listenTimerId) {
			clearInterval(listenTimerId);
			listenTimerId = 0;
		}
	}

	/**
	 * @param {Object} container
	 * @param {Object} [options]
	 * @param {boolean} [options.listenSize]
	 * @param {boolean} [options.listenContainerSize]
	 * @param {boolean} [options.listenContentSize]
	 */
	dorado.util.Dom.modernScroll = function(container, options) {
		if (SCROLLER_SIZE === undefined) SCROLLER_SIZE = $setting["widget.scrollerSize"] || 4;
		if (SCROLLER_EXPANDED_SIZE === undefined) SCROLLER_EXPANDED_SIZE = $setting["widget.scrollerExpandedSize"] || 16;
		
		var $container = $(container);
		if ($container.data("modernScroller")) return;

		try {
			var modernScroller;
			var parentDom = container.parentNode;
			if (parentDom) {
				if (options && options.scrollerType) {
					modernScroller = new options.scrollerType(container, options);
				}
				else if (dorado.Browser.isTouch || $setting["common.simulateTouch"]) {
					modernScroller = new dorado.util.Dom.IScrollerWrapper(container, options);
				}
				else {
					modernScroller = new dorado.util.Dom.DesktopModernScroller(container, options);
				}
			}

			if (modernScroller) $container.data("modernScroller", modernScroller);
		}
		catch(e) {
			dorado.Exception.processException(e);
		}
		return modernScroller;
	}

	dorado.util.Dom.destroyModernScroll = function(container, options) {
		var modernScroller = $(container).data("modernScroller");
		if (modernScroller) modernScroller.destroy();
	}

})(jQuery);

/*
 * This file is part of Dorado 7.x (http://dorado7.bsdn.org).
 *
 * Copyright (c) 2002-2012 BSTEK Corp. All rights reserved.
 *
 * This file is dual-licensed under the AGPLv3 (http://www.gnu.org/licenses/agpl-3.0.html)
 * and BSDN commercial (http://www.bsdn.org/licenses) licenses.
 *
 * If you are unsure which license is appropriate for your use, please contact the sales department
 * at http://www.bstek.com/contact.
 */

(function () {

	dorado.SocketProtocol = $class(/** @scope dorado.SocketProtocol.prototype */ {
		$className: "dorado.SocketProtocol"
	});

	dorado.LongPollingProtocol = $extend(dorado.SocketProtocol, /** @scope dorado.LongPollingProtocol.prototype */  {
		$className: "dorado.LongPollingProtocol",
		serviceAction: "long-polling",

		constructor: function () {
			this._sockets = new dorado.util.KeyedArray(function (socket) {
				return socket._socketId;
			});
			this._socketIds = [];
			this._pollingOptions = $setting["longPolling.pollingOptions"];
			this._sendingOptions = $setting["longPolling.sendingOptions"];
		},

		connect: function (socket, callback) {
			var self = this;
			if (!self._pollingAjaxEngine || !self._sendingAjaxEngine) {
				self._pollingAjaxEngine = dorado.util.AjaxEngine.getInstance(self._pollingOptions);
				self._sendingAjaxEngine = dorado.util.AjaxEngine.getInstance(self._sendingOptions);
			}

			socket._setState("connecting");
			if (self._connecting && !self._groupId) {
				if (!self._pendingConnects) {
					self._pendingConnects = [];
				}
				self._pendingConnects.push({
					socket: socket,
					callback: callback
				});
			}
			else {
				self.doConnection(socket, callback);
			}
		},

		doConnection: function(socket, callback) {
			var self = this;
			
			self._sendingAjaxEngine.bind("beforeConnect", function() {
				self._connecting = true;
			}, {
				once: true
			}).bind("onDisconnect", function() {
				self._connecting = false;
				
				if (self._polling) {
					self.stopPoll();
				}
				
				if (self._pendingConnects) {
					var pendingConnects = self._pendingConnects;
					delete self._pendingConnects;
					pendingConnects.each(function(c) {
						self.doConnection(c.socket, c.callback);
					});
				}
			}, {
				once: true
			});
			
			self._sendingAjaxEngine.request({
				jsonData: {
					action: self.serviceAction,
					subAction: "hand-shake",
					groupId: self._groupId,
					service: socket._service,
					parameter: socket._parameter,
					responseDelay: ((socket._responseDelay >= 0) ? socket._responseDelay : -1)
				}
			}, {
				callback: function (success, result) {
					if (success) {
						var data = result.getJsonData();
						self._groupId = data.groupId;

						socket._connected(data.socketId);
						self._sockets.append(socket);
						self._socketIds.push(socket._socketId);

						if (!self._polling) {
							self._pollingErrorTimes = 0;
							self.poll();
						}
						
						$callback(callback, success, data.returnValue);
					}
					else {
						$callback(callback, success, result.exception);
					}
				}
			});
		},

		disconnect: function (socket, callback) {
			var self = this;

			socket._setState("disconnecting");
			self._sockets.remove(socket);
			self._socketIds.remove(socket._socketId);

			self._sendingAjaxEngine.request({
				jsonData: {
					action: self.serviceAction,
					subAction: "disconnect",
					socketId: socket._socketId
				}
			}, {
				callback: function (success, result) {
					if (success) {
						socket._disconnected();
					}
					$callback(callback, success, result);
				}
			});
		},

		destroy: function() {
			this._sockets.each(function(socket) {
				socket._disconnected();
			});
		},

		poll: function (callback) {
			var self = this;
			if (!self._groupId) {
				throw new dorado.Exception("Polling groupId undefined.");
			}

			self._polling = true;
			self._pollingAjaxEngine.request({
				jsonData: {
					action: self.serviceAction,
					subAction: "poll",
					groupId: self._groupId,
					socketIds: self._socketIds
				}
			}, {
				callback: function (success, result) {
					if (!success) self._pollingErrorTimes++;
					if (self._pollingErrorTimes < 5 && self._sockets.size) {
						self.poll(callback);
					}
					else {
						self._polling = false;
					}
					
					if (!success && result.exception instanceof dorado.util.AjaxException && result.status == 0) {
						dorado.Exception.removeException(result.exception);
					}

					if (success && result) {
						var messages = result.getJsonData();
						messages.each(function (wrapper) {
							var socket = self._sockets.get(wrapper.socketId);
							if (socket && socket._state == "connected") {
								try {
									var message = wrapper.message;
									if (message.type == "$terminate") {
										socket._disconnected();
										return;
									}
									socket._received(message.type, message.data);
								}
								catch (e) {
									dorado.Exception.processException(e);
								}
							}
						});
					}
					$callback(callback, success, result);
				}
			});
		},
		
		stopPoll: function (callback) {
			var self = this;
			if (!self._groupId) {
				throw new dorado.Exception("Polling groupId undefined.");
			}

			self._sendingAjaxEngine.request({
				jsonData: {
					action: self.serviceAction,
					subAction: "stop-poll",
					groupId: self._groupId
				}
			}, {
				callback: function (success, result) {
					if (success) {
						$callback(callback, success, result.getJsonData());
					}
					else {
						$callback(callback, success, result.exception);
					}
				}
			});
		},

		send: function (socket, type, data, callback) {
			var self = this;
			self._sendingAjaxEngine.request({
				jsonData: {
					action: self.serviceAction,
					subAction: "send",
					socketId: socket._socketId,
					type: type,
					data: data
				}
			}, {
				callback: function (success, result) {
					if (success) {
						$callback(callback, success, result.getJsonData());
					}
					else {
						$callback(callback, success, result.exception);
					}
				}
			});
		}
	});


	dorado.Socket = $extend([dorado.AttributeSupport, dorado.EventSupport], /** @scope dorado.Socket.prototype */ {
		$className: "dorado.Socket",

		ATTRIBUTES: /** @scope dorado.Socket.prototype */ {
			service: {
			},

			parameter: {
			},

			protocol: {
				readOnly: true
			},

			/**
			 * disconnected, connecting, connected, disconnecting
			 */
			state: {
				readOnly: true,
				defaultValue: "disconnected"
			},

			connected: {
				readOnly: true,
				getter: function () {
					return this._state == "connected";
				}
			}
		},

		EVENTS: /** @scope dorado.Socket.prototype */ {
			onConnect: {},
			onDisconnect: {},
			onStateChange: {},
			onReceive: {},
			onSend: {}
		},

		constructor: function (options) {
			this._protocol = this.getSocketProtocol();
			$invokeSuper.call(this, [options]);
			if (options) this.set(options);
		},

		_setState: function (state) {
			if (this._state != state) {
				var oldState = this._state;
				this._state = state;
				this.fireEvent("onStateChange", this, {
					oldState: oldState,
					state: state
				});
			}
		},

		_received: function (type, data) {
			var socket = this;
			socket.fireEvent("onReceive", socket, {
				type: type,
				data: data
			});
		},

		connect: function (callback) {
			var socket = this;
			if (socket._state != "disconnected") {
				throw new dorado.Exception("Illegal socket state.");
			}
			socket._protocol.connect(socket, callback);
		},

		_connected: function (socketId) {
			var socket = this;
			socket._socketId = socketId;
			socket._setState("connected");
			socket.fireEvent("onConnect", socket);
		},

		disconnect: function (callback) {
			var socket = this;
			if (socket._state != "connected") {
				throw new dorado.Exception("Not connected yet.");
			}
			socket._protocol.disconnect(socket, callback);
		},

		_disconnected: function () {
			var socket = this;
			socket._setState("disconnected");
			socket.fireEvent("onDisconnect", socket);
			delete socket._socketId;
		},

		send: function (type, data, callback) {
			var socket = this;
			if (socket._state != "connected") {
				throw new dorado.Exception("Not connected yet.");
			}

			socket._protocol.send(socket, type, data, {
				callback: function (success, packet) {
					if (success) {
						socket.fireEvent("onSend", socket, {
							type: type,
							data: data
						});
					}
					$callback(callback, success, packet);
				}
			});
		}
	});

	var defaultSocketProtocol;

	dorado.LongPollingSocket = $extend(dorado.Socket, {
		ATTRIBUTES: /** @scope dorado.LongPollingSocket.prototype */ {
			responseDelay: {
				defaultValue: -1
			}
		},

		getSocketProtocol: function () {
			if (!defaultSocketProtocol) {
				defaultSocketProtocol = new dorado.LongPollingProtocol();
			}
			return defaultSocketProtocol;
		}
	});

	dorado.Socket.connect = function (options, callback) {
		var socket = new dorado.LongPollingSocket(options);
		socket.connect(callback);
		return socket;
	};

	jQuery(window).unload(function(){
		if (defaultSocketProtocol) {
			defaultSocketProtocol.destroy();
		}
	});

})();

