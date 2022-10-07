import unittest
from life import life

class TestLifeFunctions(unittest.TestCase):

    def test_eight(self):
        expected = {(-1, -1), (-1, 0), (-1, 1),
                    ( 0, -1),          ( 0, 1),
                    ( 1, -1), ( 1, 0), ( 1, 1)}
        self.assertEqual(expected, set(life.eight((0,0))))
        plusOne = {(x+1, y+1) for x, y in expected}
        self.assertEqual(plusOne, set(life.eight((1,1))))
