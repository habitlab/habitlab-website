/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 1);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


/**
* FUNCTION: isArray( value )
*	Validates if a value is an array.
*
* @param {*} value - value to be validated
* @returns {Boolean} boolean indicating whether value is an array
*/
function isArray( value ) {
	return Object.prototype.toString.call( value ) === '[object Array]';
} // end FUNCTION isArray()

// EXPORTS //

module.exports = Array.isArray || isArray;


/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

median = __webpack_require__(2)


/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
*
*	COMPUTE: median
*
*
*	DESCRIPTION:
*		- Computes the median of an array.
*
*
*	NOTES:
*		[1]
*
*
*	TODO:
*		[1]
*
*
*	LICENSE:
*		MIT
*
*	Copyright (c) 2014. Athan Reines.
*
*
*	AUTHOR:
*		Athan Reines. kgryte@gmail.com. 2014.
*
*/



// MODULES //

var isArray = __webpack_require__( 0 ),
	isObject = __webpack_require__( 3 ),
	isBoolean = __webpack_require__( 4 ),
	isFunction = __webpack_require__( 5 );


// FUNCTIONS //

/**
* FUNCTION: ascending( a, b )
*	Comparator function used to sort values in ascending order.
*
* @private
* @param {Number} a
* @param {Number} b
* @returns {Number} difference between `a` and `b`
*/
function ascending( a, b ) {
	return a - b;
} // end FUNCTION ascending()


// MEDIAN //

/**
* FUNCTION: median( arr[, options] )
*	Computes the median of an array.
*
* @param {Array} arr - input array
* @param {Object} [options] - function options
* @param {Boolean} [options.sorted] - boolean flag indicating if the array is sorted in ascending order
* @param {Function} [options.accessor] - accessor function for accessing array values
* @returns {Number|null} median value or null
*/
function median( arr, options ) {
	var sorted,
		clbk,
		len,
		id,
		d, i;

	if ( !isArray( arr ) ) {
		throw new TypeError( 'median()::invalid input argument. Must provide an array. Value: `' + arr + '`.' );
	}
	if ( arguments.length > 1 ) {
		if ( !isObject( options) ) {
			throw new TypeError( 'median()::invalid input argument. Options must be an object. Value: `' + options + '`.' );
		}
		if ( options.hasOwnProperty( 'sorted' ) ) {
			sorted = options.sorted;
			if ( !isBoolean( sorted ) ) {
				throw new TypeError( 'median()::invalid option. Sorted flag must be a boolean. Option: `' + sorted + '`.' );
			}
		}
		if ( options.hasOwnProperty( 'accessor' ) ) {
			clbk = options.accessor;
			if ( !isFunction( clbk ) ) {
				throw new TypeError( 'median()::invalid option. Accessor must be a function. Option: `' + clbk + '`.' );
			}
		}
	}
	len = arr.length;
	if ( !len ) {
		return null;
	}
	if ( !clbk && sorted ) {
		d = arr;
	}
	else if ( !clbk ) {
		d = [];
		for ( i = 0; i < len; i++ ) {
			d.push( arr[ i ] );
		}
	}
	else {
		d = [];
		for ( i = 0; i < len; i++ ) {
			d.push( clbk( arr[ i ] ) );
		}
	}
	if ( !sorted ) {
		d.sort( ascending );
	}
	// Get the middle index:
	id = Math.floor( len / 2 );

	if ( len % 2 ) {
		// The number of elements is not evenly divisible by two, hence we have a middle index:
		return d[ id ];
	}
	// Even number of elements, so must take the mean of the two middle values:
	return ( d[ id-1 ] + d[ id ] ) / 2.0;
} // end FUNCTION median()


// EXPORTS //

module.exports = median;


/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// MODULES //

var isArray = __webpack_require__( 0 );


// ISOBJECT //

/**
* FUNCTION: isObject( value )
*	Validates if a value is a object; e.g., {}.
*
* @param {*} value - value to be validated
* @returns {Boolean} boolean indicating whether value is a object
*/
function isObject( value ) {
	return ( typeof value === 'object' && value !== null && !isArray( value ) );
} // end FUNCTION isObject()


// EXPORTS //

module.exports = isObject;


/***/ }),
/* 4 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
*
*	VALIDATE: boolean
*
*
*	DESCRIPTION:
*		- Validates if a value is a boolean.
*
*
*	NOTES:
*		[1] 
*
*
*	TODO:
*		[1] 
*
*
*	LICENSE:
*		MIT
*
*	Copyright (c) 2014. Athan Reines.
*
*
*	AUTHOR:
*		Athan Reines. kgryte@gmail.com. 2014.
*
*/



/**
* FUNCTION: isBoolean( value )
*	Validates if a value is a boolean.
*
* @param {*} value - value to be validated
* @returns {Boolean} boolean indicating whether value is a boolean
*/
function isBoolean( value ) {
	return ( typeof value === 'boolean' || Object.prototype.toString.call( value ) === '[object Boolean]' );
} // end FUNCTION isBoolean()


// EXPORTS //

module.exports = isBoolean;

/***/ }),
/* 5 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
*
*	VALIDATE: function
*
*
*	DESCRIPTION:
*		- Validates if a value is a function.
*
*
*	NOTES:
*		[1]
*
*
*	TODO:
*		[1]
*
*
*	LICENSE:
*		MIT
*
*	Copyright (c) 2014. Athan Reines.
*
*
*	AUTHOR:
*		Athan Reines. kgryte@gmail.com. 2014.
*
*/



/**
* FUNCTION: isFunction( value )
*	Validates if a value is a function.
*
* @param {*} value - value to be validated
* @returns {Boolean} boolean indicating whether value is a function
*/
function isFunction( value ) {
	return ( typeof value === 'function' );
} // end FUNCTION isFunction()


// EXPORTS //

module.exports = isFunction;


/***/ })
/******/ ]);