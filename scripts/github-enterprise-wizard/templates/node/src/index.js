export function sum(values) {
  if (!Array.isArray(values) || values.some(value => !Number.isFinite(value))) {
    throw new TypeError('Expected an array of finite numbers');
  }
  return values.reduce((total, value) => total + value, 0);
}
