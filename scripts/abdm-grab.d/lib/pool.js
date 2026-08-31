'use strict';
/** Run `worker` over `items` with bounded concurrency, preserving order. */
async function pool(items, concurrency, worker) {
  const results = new Array(items.length);
  let next = 0;
  const run = async () => {
    for (;;) {
      const i = next++;
      if (i >= items.length) return;
      results[i] = await worker(items[i], i);
    }
  };
  const n = Math.max(1, Math.min(concurrency, items.length));
  await Promise.all(Array.from({ length: n }, run));
  return results;
}
module.exports = { pool };
