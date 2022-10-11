#! /usr/bin/python3

import unittest
from life import rle
from life import life

class TestRunLengthEncoding(unittest.TestCase):

    def test_rle(self):
        d = ('#comment Acorn\n' + 
             'x = 7, y = 3, rule = B3/S23\n' + 
             'bo5b$3bo3b$2o2b3o!\n')
        board = rle.rle(d)
        expected = [(-2, 2),
                    (0, 1),
                    (-3, 0), (-2, 0), (1, 0), (2, 0), (3, 0)]
        self.assertEqual(board, expected)

    def test_apply_updates(self):
        acorn = [(-2, 2),
                 (0, 1),
                 (-3, 0), (-2, 0), (1, 0), (2, 0), (3, 0)]
        board = life.start(acorn)
        board = life.nextGeneration(board)
        self.assertEqual(7, len(board.alive))
        board = life.nextGeneration(board)
        self.assertEqual(8, len(board.alive))
        

    def test_rle_r_pentomino(self):
        d = ('#N R-pentomino\n' +
             '#C A methuselah with lifespan 1103.\n'
             '#C www.conwaylife.com/wiki/index.php?title=R-pentomino\n'
             'x = 3, y = 0, rule = B3/S23\n'
             'b2o$2ob$bo!')
        board = rle.rle(d)
        expected = {(0, 0), (0, 1), (1, 1), (-1, 0), (0, -1)}
        self.assertEqual(set(board), expected)


if __name__ == '__main__':
    unittest.main()
