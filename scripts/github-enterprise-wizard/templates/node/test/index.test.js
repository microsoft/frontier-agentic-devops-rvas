import assert from 'node:assert/strict';
import test from 'node:test';
import {sum} from '../src/index.js';

test('sums finite numbers', () => {
  assert.equal(sum([2, -1, 3]), 4);
  assert.equal(sum([]), 0);
});

test('rejects invalid inputs', () => {
  for (const input of [null, '2', [NaN], [Infinity], ['2']]) {
    assert.throws(() => sum(input), TypeError);
  }
});
