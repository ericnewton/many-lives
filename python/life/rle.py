import re
import sys
import collections
from functools import reduce

'''
Decode the following into coordinates

#N Acorn
#O Charles Corderman
#C A methuselah with lifespan 5206.
#C www.conwaylife.com/wiki/index.php?title=Acorn
x = 7, y = 3, rule = B3/S23
bo5b$3bo3b$2o2b3o!
'''

Decoder = collections.namedtuple('Decoder', 'start pos run board')

# generate the start state from an initial offset
def start(x, y):
    c = (x, y)
    return Decoder(start=c, pos=c, run='', board=[])

# the current run length
def run(d):
    if d.run == '':
        return 1
    return int(d.run)

# generate a sequence of coords in increasing x coordinates
def cells(d):
    x, y = d.pos
    more = [(x + i, y) for i in range(run(d))]
    return d._replace(board=d.board + more)

# move current x pos by the run
def skip(d):
    x, y = d.pos
    return d._replace(pos=(x + run(d), y), run='')

# generate a new state from a single character
def decode1(d, c):
    # more digits of run
    if c >= '0' and c <= '9':
        return d._replace(run=d.run + c)
    # skip blanks
    if c == 'b':
        return skip(d)
    # more cells
    if c == 'o':
        return skip(cells(d))
    # more lines
    if c == '$':
        x, _ = d.start
        _, y = d.pos
        return d._replace(pos=(x, y - run(d)), run='')
    if c == '!':
        return d
    raise Exception('Unknown encoding character ' + c)

def decode_rle(d, line):
    return reduce(decode1, line, d)

# decode whole lines, processing comments, offsets and encoding
def top_decode(decoder, raw):
    line = raw.strip()
    if line:
        if line[0] == '#':
            return decoder
        if line[0] == 'x':
            # decode offsets
            result = re.match(r'x = (\d+), y = (\d+).*', line)
            if not result:
                raise Exception('Unable to parse ' + line)
            xoffset = int(result.group(1))
            yoffset = int(result.group(2))
            return start(- (xoffset // 2), yoffset // 2 + 1)
        else:
            return decode_rle(decoder, line)
    return decoder

def rle(encoded):
    return reduce(top_decode, encoded.split('\n'), start(0, 0)).board

