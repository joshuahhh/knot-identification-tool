# Alexander polynomials must first be copied from
#   http://stoimenov.net/stoimeno/homepage/ptab/a10.html
# into the file alex.html in this directory. 

# Running this script generates a JavaScript object which is set as
# the value of "knots" in kit.coffee.

import re
from itertools import combinations_with_replacement
from collections import defaultdict
import json

regex = "(.*)<sub>(.*)</sub>:(.*)<br>\n"

lines = open("alex.html").readlines()
groupss = [re.match(regex, line).groups() for line in lines]

def process_poly(s):
    raw_ints = map(int, s.replace('[','').replace(']','').strip().split())
    sign = 1 if raw_ints[0]>0 else -1
    normal_ints = [x*sign for x in raw_ints]
    return normal_ints

prime_knots = [{'components': ['%s_%s' % groups[:2]],
                'poly': process_poly(groups[2]),
                'crossings': int(groups[0])}
               for groups in groupss]

def poly_mul(p1, p2):
    to_return = [0]*(len(p1)+len(p2)-1)
    for o1, coeff1 in enumerate(p1):
        for o2, coeff2 in enumerate(p2):
            to_return[o1+o2] += coeff1*coeff2
    return to_return

def compose(knots):
    components = sum((knot['components'] for knot in knots), [])
    poly = reduce(poly_mul, (knot['poly'] for knot in knots))
    return {'components': components, 'poly': poly}

max_crossings = 10
composite_knots = sum(([compose(col)
                        for col in combinations_with_replacement(prime_knots, num)
                        if sum(knot['crossings'] for knot in col) <= max_crossings]
                       for num in range(1, 4)), [])

poly_dict = defaultdict(list)
for knot in composite_knots:
    poly_string = ",".join(map(str, knot['poly']))
    poly_dict[poly_string].append(knot['components'])

poly_dict['1'] = [['0_1']]

print json.dumps(poly_dict)
