/**
 * @typedef {Object} MutableCounter
 * @property {number} value
 */

/**
 * @returns {MutableCounter}
 */
export function new_() {
  return { value: 0 };
}

/**
 * @param {MutableCounter} counter 
 */
export function next(counter) {
  // const value = counter.value;
  // counter.value += 1;
  // return value;
  return counter.value++;
}