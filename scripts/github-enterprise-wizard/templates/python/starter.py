import math


def sum_numbers(values):
    if not isinstance(values, (list, tuple)) or any(
        isinstance(value, bool)
        or not isinstance(value, (int, float))
        or not math.isfinite(value)
        for value in values
    ):
        raise TypeError("Expected a sequence of finite numbers")
    return sum(values)
