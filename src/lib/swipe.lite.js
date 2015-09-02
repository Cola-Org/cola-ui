function Swipe(container, options) {
	options = options || {};

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
			var props = ['transformProperty', 'WebkitTransform', 'MozTransform', 'OTransform', 'msTransform'];
			for (var i in props) if (temp.style[props[i]] !== undefined) return true;
			return false;
		})(document.createElement('swipe'))
	};

	// quit if no root element
	if (!container) return;
	var element = $fly(container).find("> .items-wrap")[0], slides, slidePos, width, height, vertical = options.vertical,
		index = parseInt(options.startSlide, 10) || 0, speed = options.speed || 300;

	function setup() {
		// cache slides
		slides = element.children;
		// create an array to store current positions of each slide
		slidePos = new Array(slides.length);
		if (vertical) {
			// determine width of each slide
			height = container.getBoundingClientRect().height || container.offsetHeight;
			element.style.height = (slides.length * height) + 'px';
		} else {
			// determine width of each slide
			width = container.getBoundingClientRect().width || container.offsetWidth;
			element.style.width = (slides.length * width) + 'px';
		}

		// stack elements
		var pos = slides.length;
		while (pos--) {
			var slide = slides[pos];
			if (vertical) {
				slide.style.height = height + 'px';
				if (browser.transitions) {
					slide.style.top = (pos * -height) + 'px';
					moveY(pos, index > pos ? -height : (index < pos ? height : 0), 0);
				}
			} else {
				slide.style.width = width + 'px';
				if (browser.transitions) {
					slide.style.left = (pos * -width) + 'px';
					move(pos, index > pos ? -width : (index < pos ? width : 0), 0);
				}
			}

			slide.setAttribute('data-index', pos);
		}

		if (!browser.transitions)
			if (vertical)
				element.style.top = (index * -height) + 'px';
			else
				element.style.left = (index * -width) + 'px';

		container.style.visibility = 'visible';
	}

	function prev() {
		if (index)
			slide(index - 1);
		else if (options.continuous)
			slide(slides.length - 1);
	}

	function next() {
		if (index < slides.length - 1)
			slide(index + 1);
		else if (options.continuous)
			slide(0);
	}

	function slide(to, slideSpeed) {
		// do nothing if already on requested slide
		if (index == to) return;

		if (browser.transitions) {
			var diff = Math.abs(index - to) - 1;
			var direction = Math.abs(index - to) / (index - to); // 1:right -1:left

			while (diff--) move((to > index ? to : index) - diff - 1, width * direction, 0);

			move(index, width * direction, slideSpeed || speed);
			move(to, 0, slideSpeed || speed);
		} else {
			animate(index * -width, to * -width, slideSpeed || speed);
		}

		index = to;

		offloadFn(options.callback && options.callback(index, slides[index]));
	}

	function move(index, dist, speed) {
		translate(index, dist, speed);
		slidePos[index] = dist;
	}

	function translate(index, dist, speed) {
		var slide = slides[index], style = slide && slide.style;

		if (!style) return;

		style.webkitTransitionDuration = style.MozTransitionDuration = style.msTransitionDuration = style.transitionDuration = speed + 'ms';

		style.webkitTransform = 'translate(' + dist + 'px,0)' + 'translateZ(0)';
		style.msTransform = style.MozTransform = 'translateX(' + dist + 'px)';
	}

	function moveY(index, dist, speed) {
		translateY(index, dist, speed);
		slidePos[index] = dist;
	}

	function translateY(index, dist, speed) {
		var slide = slides[index], style = slide && slide.style;

		if (!style) return;

		style.webkitTransitionDuration = style.MozTransitionDuration = style.msTransitionDuration = style.transitionDuration = speed + 'ms';

		style.webkitTransform = 'translate(0,' + dist + 'px)' + 'translateZ(0)';
		style.msTransform = style.MozTransform = 'translateY(' + dist + 'px)';
	}

	// setup initial vars
	var start = {}, delta = {}, isScrolling;

	// setup event capturing
	var events = {
		handleEvent: function (event) {
			switch (event.type) {
				case 'touchstart':
				case 'mousedown':
					this.start(event);
					break;
				case 'touchmove':
				case 'mousemove':
					this.move(event);
					break;
				case 'touchend':
				case 'mouseup':
					offloadFn(this.end(event));
					cola.util.DISABLE_SCROLLER_DRAG = false;
					break;
				case 'webkitTransitionEnd':
				case 'msTransitionEnd':
				case 'oTransitionEnd':
				case 'otransitionend':
				case 'transitionend':
					offloadFn(this.transitionEnd(event));
					break;
				case 'resize':
					offloadFn(setup.call());
					break;
			}
			if (options.stopPropagation) event.stopPropagation();
		},
		start: function (event) {
			var touches = browser.touch ? event.touches[0] : event;

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
			if (browser.touch) {
				element.addEventListener('touchmove', this, false);
				element.addEventListener('touchend', this, false);
			} else {
				document.addEventListener('mousemove', this, false);
				document.addEventListener('mouseup', this, false);
			}
		},
		move: function (event) {
			// ensure swiping with one touch and not pinching
			if (browser.touch && ((event.touches.length > 1) || (event.scale && event.scale !== 1))) return;

			if (options.disableScroll) event.preventDefault();

			var touches = browser.touch ? event.touches[0] : event;
			// measure change in x and y
			delta = {
				x: touches.pageX - start.x,
				y: touches.pageY - start.y
			};

			// determine if scrolling test has run - one time test
			if (typeof isScrolling == 'undefined') {
				if (vertical)
					isScrolling = !!( isScrolling || Math.abs(delta.x) > Math.abs(delta.y) );
				else
					isScrolling = !!( isScrolling || Math.abs(delta.x) < Math.abs(delta.y) );
			}

			// if user is not trying to scroll vertically
			if (!isScrolling) {
				// prevent native scrolling
				event.preventDefault();
				if (!vertical) {
					// increase resistance if first or last slide
					delta.x =
						delta.x /
						( (!index && delta.x > 0               // if first slide and sliding left
							|| index == slides.length - 1        // or if last slide and sliding right
							&& delta.x < 0                       // and if sliding at all
						) ?
							( Math.abs(delta.x) / width + 1 )      // determine resistance level
							: 1 );                                 // no resistance if false

					if (Math.abs(delta.x) > 5) {
						cola.util.DISABLE_SCROLLER_DRAG = true;
					}

					// translate 1:1
					translate(index - 1, delta.x + slidePos[index - 1], 0);
					translate(index, delta.x + slidePos[index], 0);
					translate(index + 1, delta.x + slidePos[index + 1], 0);
				} else {
					// increase resistance if first or last slide
					delta.y =
						delta.y /
						( (!index && delta.y > 0               // if first slide and sliding left
							|| index == slides.length - 1        // or if last slide and sliding right
							&& delta.y < 0                       // and if sliding at all
						) ?
							( Math.abs(delta.y) / height + 1 )      // determine resistance level
							: 1 );                                 // no resistance if false

					if (Math.abs(delta.y) > 5) {
						cola.util.DISABLE_SCROLLER_DRAG = true;
					}

					// translate 1:1
					translateY(index - 1, delta.y + slidePos[index - 1], 0);
					translateY(index, delta.y + slidePos[index], 0);
					translateY(index + 1, delta.y + slidePos[index + 1], 0);
				}
			}
		},
		end: function (event) {
			// measure duration
			var duration = +new Date - start.time, isValidSlide, isPastBounds, direction;
			if (!vertical) {
				// determine if slide attempt triggers next/prev slide
				isValidSlide =
					Number(duration) < 250               // if slide duration is less than 250ms
					&& Math.abs(delta.x) > 20            // and if slide amt is greater than 20px
					|| Math.abs(delta.x) > width / 2;      // or if slide amt is greater than half the width

				// determine if slide attempt is past start and end
				isPastBounds =
					!index && delta.x > 0                            // if first slide and slide amt is greater than 0
					|| index == slides.length - 1 && delta.x < 0;    // or if last slide and slide amt is less than 0

				// determine direction of swipe (true:right, false:left)
				direction = delta.x < 0;

				// if not scrolling vertically
				if (!isScrolling) {
					if (isValidSlide && !isPastBounds) {
						if (direction) {
							move(index - 1, -width, 0);
							move(index, slidePos[index] - width, speed);
							move(index + 1, slidePos[index + 1] - width, speed);
							index += 1;
						} else {
							move(index + 1, width, 0);
							move(index, slidePos[index] + width, speed);
							move(index - 1, slidePos[index - 1] + width, speed);
							index += -1;
						}

						options.callback && options.callback(index, slides[index]);
					} else {
						if (index == (slides.length - 1)) {
							slide(0);
						} else if (index == 0) {
							slide(slides.length - 1);
						} else {
							move(index - 1, -width, speed);
							move(index, 0, speed);
							move(index + 1, width, speed);
						}
					}
				}
			} else {
				// determine if slide attempt triggers next/prev slide
				isValidSlide =
					Number(duration) < 250               // if slide duration is less than 250ms
					&& Math.abs(delta.y) > 20            // and if slide amt is greater than 20px
					|| Math.abs(delta.y) > height / 2;      // or if slide amt is greater than half the width

				// determine if slide attempt is past start and end
				isPastBounds =
					!index && delta.y > 0                            // if first slide and slide amt is greater than 0
					|| index == slides.length - 1 && delta.y < 0;    // or if last slide and slide amt is less than 0

				// determine direction of swipe (true:bottom, false:top)
				direction = delta.y < 0;

				// if not scrolling vertically
				if (!isScrolling) {
					if (isValidSlide && !isPastBounds) {
						if (direction) {
							moveY(index - 1, -height, 0);
							moveY(index, slidePos[index] - height, speed);
							moveY(index + 1, slidePos[index + 1] - height, speed);
							index += 1;
						} else {
							moveY(index + 1, height, 0);
							moveY(index, slidePos[index] + height, speed);
							moveY(index - 1, slidePos[index - 1] + height, speed);
							index += -1;
						}

						options.callback && options.callback(index, slides[index]);
					} else {
						moveY(index - 1, -height, speed);
						moveY(index, 0, speed);
						moveY(index + 1, height, speed);
					}
				}
			}


			// kill touchmove and touchend event listeners until touchstart called again
			if (browser.touch) {
				element.removeEventListener('touchmove', events, false);
				element.removeEventListener('touchend', events, false);
			} else {
				document.removeEventListener('mousemove', events, false);
				document.removeEventListener('mouseup', events, false);
			}
		},
		transitionEnd: function (event) {
			if (parseInt(event.target.getAttribute('data-index'), 10) == index) {
				options.transitionEnd && options.transitionEnd.call(event, index, slides[index]);
			}
		}
	};

	// trigger setup
	setup();

	// add event listeners
	if (browser.addEventListener) {
		// set touchstart event on element
		if (browser.touch)
			element.addEventListener('touchstart', events, false);
		else
			element.addEventListener('mousedown', events, false);

		if (browser.transitions) {
			element.addEventListener('webkitTransitionEnd', events, false);
			element.addEventListener('msTransitionEnd', events, false);
			element.addEventListener('oTransitionEnd', events, false);
			element.addEventListener('otransitionend', events, false);
			element.addEventListener('transitionend', events, false);
		}

		// set resize event on window
		window.addEventListener('resize', events, false);
	}

	// expose the Swipe API
	return {
		setup: function () {
			setup();
		},
		refresh: function () {
			setup();
		},
		getPos: function () {
			// return current index position
			return index;
		},
		setPos: function (pos) {
			index = pos;
			setup();
		},
		prev: function () {
			prev();
		},
		next: function () {
			next();
		},
		kill: function () {
			// reset element
			element.style.width = 'auto';
			element.style.left = 0;

			// reset slides
			var pos = slides.length;
			while (pos--) {
				var slide = slides[pos];
				if (!vertical) {
					slide.style.width = '100%';
					slide.style.left = 0;
				} else {
					slide.style.height = '100%';
					slide.style.top = 0;
				}

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
			} else {
				window.onresize = null;
			}
		}
	}
}