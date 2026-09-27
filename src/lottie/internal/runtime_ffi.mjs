/** @type {number | undefined} */
let id = undefined

/**
 * 
 * @param {function(number):void} tick 
 */
export function start(tick) {
  if (id != undefined) return;

  let previous = performance.now()

  function loop() {
    const now = performance.now()
    const dt = clamp((now - previous) / 1000, 0.001, 0.125)
    previous = now

    tick(dt)
    
    id = requestAnimationFrame(loop)
  }

  id = requestAnimationFrame(loop)
}

function clamp(a, min, max) {
  return a < max ? (a > min ? a : min) : max;
}

export function stop() {
  if (id != undefined) {
    cancelAnimationFrame(id)
    id = undefined
  }
}