import unittest

from starter import sum_numbers


class SumTests(unittest.TestCase):
    def test_sum(self):
        self.assertEqual(sum_numbers([2, -1, 3]), 4)
        self.assertEqual(sum_numbers([]), 0)

    def test_invalid_inputs(self):
        for values in (None, "2", [float("nan")], [float("inf")], ["2"], [True]):
            with self.subTest(values=values):
                with self.assertRaises(TypeError):
                    sum_numbers(values)


if __name__ == "__main__":
    unittest.main()
