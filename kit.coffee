# IMMEDIATE TODO:
# x bizarre junk in beginning of alexpoly
# / prettier crossings
# * better isect selection
# x "reset" button
# x composite knots
# x bigger knots
# LONGER-TERM TODO:
# * knot manipulation
# * links
# * saving / linking to knots

# POLYNOMIALS

polyToInt = (l, base=1000) ->
  # Takes a list of (potentially) normal numbers, gives a BigInt.
  toReturn = bigInt(0)
  for coeff, i in l
    toReturn = bigInt(base).pow(i).times(coeff).plus(toReturn)
  return toReturn

intToPoly = (int, base=1000) ->
  # Takes a BigInt, gives a list of normal numbers.
  sign = if int.lesser(0) then -1 else 1
  int = int.times(sign)

  b = []  # Contains only normal numbers.
  while int.greater(0)
    divmod = int.divmod(base)
    b.push(divmod.remainder.toJSNumber())
    int = divmod.quotient
  b.push(0)

  # We are now operating on normal numbers...
  for i in [0...b.length]
    if b[i] >= base/2
      b[i] = b[i]-base
      b[i+1] = b[i+1]+1
    b[i] = b[i]*sign
  if b[b.length-1] == 0
    b.pop()

  return b

# MATRICES

det = (matrix) ->
  # Matrix can contain BigInts; will always return a BigInt.
  size = matrix.length
  sum = bigInt(0)
  if size == 1 then return matrix[0][0]

  for i in [0...size]
    if bigInt(matrix[0][i]).notEquals(0)   # ESSENTIAL for sparse matrices
      # construct minor
      smaller = ((0 for _ in [0...size-1]) for _ in [0...size-1])
      for a in [1...size]
        for b in [0...size]
          if b < i
            smaller[a-1][b] = matrix[a][b]
          else if b > i
            smaller[a-1][b-1] = matrix[a][b]
      # sign of minor
      s = if i%2 == 0 then 1 else -1
      sum = bigInt(matrix[0][i]).times(s).times(det(smaller)).plus(sum)
  return sum

# GEOMETRY

distance = ([x1, y1], [x2, y2]) ->
  Math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))

intersect = ([x1, y1], [x2, y2], [x3, y3], [x4, y4]) ->
  denom = (x1-x2)*(y3-y4)-(y1-y2)*(x3-x4)
  xi = ((x1*y2-y1*x2)*(x3-x4)-(x1-x2)*(x3*y4-y3*x4))/denom
  if (((x1 <= xi <= x2) or (x2 <= xi <= x1)) and
      ((x3 <= xi <= x4) or (x4 <= xi <= x3)))
    yi = ((x1*y2-y1*x2)*(y3-y4)-(y1-y2)*(x3*y4-y3*x4))/denom
    if (((y1 <= yi <= y2) or (y2 <= yi <= y1)) and
        ((y3 <= yi <= y4) or (y4 <= yi <= y3)))
      return [xi, yi]
  return false

minus = ([x1, y1], [x2, y2]) -> [x1-x2, y1-y2]
crossProd = ([x1, y1], [x2, y2]) -> x1*y2-y1*x2

starts = 0
stops = 0

allIntersects = (points) ->
  toReturn = []

  for i in [0...(points.length-1)] by 1
    for j in [(i+2)...(points.length-1)] by 1
      if i==0 and j==points.length-2 then continue
      isect = intersect(points[i], points[i+1], points[j], points[j+1])
      if isect
        cp = crossProd(minus(points[i], points[i+1]),
                       minus(points[j], points[j+1]))
        dir = if cp < 0 then -1 else 1
        toReturn.push({pt: isect, i: i, j: j, choice: 1, dir: dir})
  return toReturn

svg = d3.select("svg")

lineGen = d3.svg.line()
                .x((d) -> d[0]).y((d) -> d[1])
                .interpolate("cardinal");

dragging = false

points = []
isects = []

alexanderMatrix = ->
  skips = []
  for isect in isects
    if isect.choice
      skips.push(if isect.choice == 1 then isect.i else isect.j)
    else
      return false
  skips.sort((a,b)->a-b)
  posToStrand = (pos) ->
    i = 0
    while i < skips.length and pos > skips[i]
      i++
    return (if pos <= skips[i] then i else 0)
  numStrands = skips.length

  toReturn = []

  for isect in isects
    if isect.choice == 1
      [top, bot] = [isect.j, isect.i]
    else
      [top, bot] = [isect.i, isect.j]

    topStrand = posToStrand(top)
    botStrand1 = posToStrand(bot)
    botStrand2 = (botStrand1 + 1) % numStrands


    if isect.dir == -1 then [botStrand1, botStrand2] = [botStrand2, botStrand1]
    if isect.choice == 1 then [botStrand1, botStrand2] = [botStrand2, botStrand1]

    row = (0 for i in [0...numStrands])
    row[topStrand] += polyToInt([1,-1])
    row[botStrand1] += polyToInt([-1])
    row[botStrand2] += polyToInt([0, 1])

    toReturn.push(row)
  return toReturn

alexanderPoly = ->
  matrix = alexanderMatrix()
  if not matrix then return false
  if matrix.length <= 1 then return [1]
  matrix.pop()
  for row in matrix
    row.pop()
  poly = intToPoly(det(matrix))

  poly = (Math.round(x) for x in poly)

  poly = do ->
    for i in [0...poly.length]
      if poly[i] != 0 then return poly.slice(i)
    return []  # def shouldn't happen

  if poly.length > 0 and poly[0] < 0
    poly = (-x for x in poly)

  return poly

knots = {"1": [["0_1"]], "1,-5,9,-11,9,-5,1": [["9_20"], ["10_149"]], "2,-9,21,-27,21,-9,2": [["10_95"]], "1,-3,6,-8,9,-8,6,-3,1": [["10_62"]], "2,-10,20,-25,20,-10,2": [["10_92"]], "1,-4,7,-9,7,-4,1": [["3_1", "6_2"]], "1,-5,11,-17,19,-17,11,-5,1": [["10_112"]], "1,-7,18,-23,18,-7,1": [["9_40"], ["10_59"]], "1,-3,6,-7,7,-7,6,-3,1": [["10_47"]], "4,-12,15,-12,4": [["10_16"]], "1,-1,0,1,-1,1,0,-1,1": [["10_124"]], "1,-5,9,-5,1": [["7_7"]], "2,-3,3,-3,2": [["7_3"]], "2,-7,11,-7,2": [["8_13"]], "1,-6,15,-24,29,-24,15,-6,1": [["10_123"]], "2,-6,7,-6,2": [["8_6"]], "2,-3,2,-1,2,-3,2": [["10_142"]], "3,-9,16,-19,16,-9,3": [["10_66"]], "1,-2,4,-5,4,-2,1": [["10_126"]], "7,-21,29,-21,7": [["10_101"]], "4,-11,13,-11,4": [["10_11"]], "2,-10,17,-10,2": [["9_19"]], "2,-10,21,-27,21,-10,2": [["10_114"]], "1,-1,1,-1,1,-1,1,-1,1": [["9_1"]], "1,-3,3,-3,1": [["6_2"]], "1,-4,8,-9,8,-4,1": [["8_16"], ["10_156"]], "2,-10,24,-31,24,-10,2": [["10_117"]], "2,-8,13,-8,2": [["10_146"]], "2,-7,11,-13,11,-7,2": [["10_50"]], "4,-14,19,-14,4": [["10_18"], ["10_24"]], "2,-8,16,-21,16,-8,2": [["10_102"]], "2,-5,7,-7,7,-5,2": [["5_1", "5_2"]], "1,-7,18,-25,18,-7,1": [["10_71"]], "1,-6,9,-6,1": [["9_45"]], "1,-4,8,-10,11,-10,8,-4,1": [["10_85"]], "1,-3,5,-5,5,-3,1": [["8_7"]], "2,-9,20,-25,20,-9,2": [["10_84"]], "3,-7,3": [["8_1"]], "1,-1,0,2,-3,2,0,-1,1": [["10_139"]], "1,-7,16,-19,16,-7,1": [["10_70"]], "2,-5,8,-9,8,-5,2": [["9_16"], ["3_1", "7_3"]], "1,-5,7,-7,7,-5,1": [["9_11"]], "1,-7,11,-7,1": [["9_48"]], "1,-3,5,-7,7,-7,5,-3,1": [["10_9"]], "1,-7,20,-27,20,-7,1": [["10_73"]], "1,-6,14,-17,14,-6,1": [["9_32"]], "2,-4,6,-7,6,-4,2": [["9_9"]], "3,-13,19,-13,3": [["10_36"]], "2,-6,11,-13,11,-6,2": [["3_1", "7_5"]], "2,-6,7,-7,7,-6,2": [["10_6"]], "1,-6,13,-17,13,-6,1": [["3_1", "7_6"]], "1,-4,9,-15,19,-15,9,-4,1": [["10_104"]], "4,-11,15,-11,4": [["9_23"], ["3_1", "7_4"]], "3,-14,21,-14,3": [["9_39"]], "2,-7,15,-19,15,-7,2": [["10_51"]], "2,-7,13,-15,13,-7,2": [["10_23"], ["10_52"]], "2,-9,19,-25,19,-9,2": [["10_86"]], "1,-4,8,-12,13,-12,8,-4,1": [["10_82"]], "2,-3,3,-3,3,-3,2": [["9_3"]], "1,-3,3,-3,3,-3,1": [["8_2"]], "1,-1,1,-1,1": [["5_1"], ["10_132"]], "1,-5,8,-7,8,-5,1": [["10_138"]], "2,-4,4,-3,4,-4,2": [["10_134"]], "1,-3,4,-5,4,-3,1": [["8_5"], ["10_141"]], "1,-2,2,-1,2,-2,1": [["10_125"]], "1,-5,9,-9,9,-5,1": [["9_17"]], "2,-11,26,-33,26,-11,2": [["10_113"]], "4,-10,13,-10,4": [["9_18"]], "1,1,-3,1,1": [["10_145"]], "2,-9,18,-23,18,-9,2": [["10_87"], ["10_98"]], "2,-6,10,-11,10,-6,2": [["10_12"], ["10_54"]], "1,-1,0,1,0,-1,1": [["8_19"]], "2,-4,5,-4,2": [["7_5"], ["10_130"]], "3,-5,5,-5,3": [["9_4"]], "2,-11,27,-35,27,-11,2": [["10_121"]], "4,-8,9,-8,4": [["9_10"]], "1,-1,-1,3,-1,-1,1": [["10_153"]], "1,-2,3,-2,1": [["8_20"], ["10_140"], ["3_1", "3_1"]], "1,-8,24,-35,24,-8,1": [["10_88"]], "8,-26,37,-26,8": [["10_120"]], "2,-5,2": [["6_1"], ["9_46"]], "2,-8,15,-19,15,-8,2": [["10_32"]], "1,-6,15,-19,15,-6,1": [["3_1", "7_7"]], "6,-11,6": [["9_5"]], "2,-8,15,-17,15,-8,2": [["10_93"]], "4,-7,4": [["7_4"], ["9_2"]], "1,-7,19,-25,19,-7,1": [["10_44"]], "2,-9,16,-19,16,-9,2": [["10_72"]], "2,-7,9,-7,2": [["8_11"], ["10_147"], ["3_1", "6_1"]], "1,-7,21,-29,21,-7,1": [["10_69"]], "1,-4,10,-13,10,-4,1": [["10_151"]], "1,-5,11,-13,11,-5,1": [["9_26"]], "3,-10,13,-10,3": [["10_144"]], "4,-9,4": [["8_3"], ["10_1"]], "2,-3,1,1,1,-3,2": [["10_128"]], "2,-8,12,-13,12,-8,2": [["10_14"]], "1,-4,9,-14,15,-14,9,-4,1": [["10_94"]], "7,-13,7": [["9_35"]], "2,-9,19,-23,19,-9,2": [["10_83"]], "1,-7,22,-33,22,-7,1": [["10_96"]], "1,-6,15,-21,15,-6,1": [["4_1", "6_3"]], "1,-5,8,-9,8,-5,1": [["9_36"]], "2,-7,11,-11,11,-7,2": [["10_19"]], "2,-9,15,-9,2": [["9_14"]], "2,-5,5,-5,2": [["8_4"]], "2,-7,13,-17,13,-7,2": [["10_26"]], "5,-14,19,-14,5": [["9_38"], ["10_63"]], "3,-9,11,-9,3": [["10_20"], ["10_162"]], "3,-6,7,-6,3": [["9_49"]], "1,-4,8,-11,8,-4,1": [["8_17"]], "1,-4,10,-16,19,-16,10,-4,1": [["10_99"]], "1,-8,22,-31,22,-8,1": [["10_107"]], "3,-9,15,-17,15,-9,3": [["10_80"]], "1,-4,9,-14,17,-14,9,-4,1": [["10_91"]], "1,-7,17,-21,17,-7,1": [["10_41"]], "1,-1,1,-1,1,-1,1": [["7_1"]], "1,-5,12,-19,23,-19,12,-5,1": [["10_118"]], "1,-6,11,-6,1": [["10_137"], ["4_1", "4_1"]], "2,-9,17,-21,17,-9,2": [["10_111"]], "1,-2,3,-3,3,-3,3,-2,1": [["3_1", "7_1"]], "2,-6,9,-6,2": [["8_8"], ["10_129"]], "2,-11,19,-11,2": [["9_37"], ["4_1", "6_1"]], "1,-3,5,-5,5,-5,5,-3,1": [["10_5"]], "3,-12,19,-12,3": [["9_41"]], "1,-8,22,-29,22,-8,1": [["10_105"]], "3,-7,9,-7,3": [["9_7"]], "2,-8,11,-8,2": [["8_14"], ["9_8"], ["10_131"]], "2,-10,15,-10,2": [["9_15"], ["10_165"]], "1,-4,6,-5,6,-4,1": [["9_47"]], "1,-3,5,-7,5,-3,1": [["8_9"], ["10_155"]], "1,-9,26,-37,26,-9,1": [["10_115"]], "1,-6,16,-23,16,-6,1": [["9_34"]], "1,-3,6,-10,11,-10,6,-3,1": [["10_64"]], "1,-4,6,-7,6,-4,1": [["10_127"], ["10_150"]], "5,-22,33,-22,5": [["10_97"]], "1,-4,9,-11,9,-4,1": [["10_159"], ["3_1", "6_3"]], "1,-4,5,-5,5,-4,1": [["4_1", "5_1"]], "2,-8,14,-17,14,-8,2": [["10_25"], ["10_56"]], "1,0,-2,3,-2,0,1": [["10_161"]], "1,-1,1": [["3_1"]], "1,-8,24,-33,24,-8,1": [["10_89"]], "2,-5,6,-7,6,-5,2": [["10_61"]], "2,-8,13,-15,13,-8,2": [["10_39"]], "2,-10,23,-31,23,-10,2": [["10_119"]], "4,-12,17,-12,4": [["5_2", "5_2"]], "2,-6,10,-13,10,-6,2": [["10_22"]], "1,-3,6,-7,6,-3,1": [["8_10"], ["10_143"], ["3_1", "3_1", "3_1"]], "1,-2,3,-4,5,-4,3,-2,1": [["5_1", "5_1"]], "1,-4,4,-3,4,-4,1": [["10_160"]], "4,-16,23,-16,4": [["10_67"], ["10_74"]], "1,-7,15,-17,15,-7,1": [["10_29"]], "1,-4,7,-4,1": [["9_44"]], "3,-11,17,-11,3": [["10_10"], ["10_164"]], "1,-5,12,-17,12,-5,1": [["9_30"]], "5,-15,21,-15,5": [["10_55"]], "1,-6,13,-15,13,-6,1": [["4_1", "6_2"]], "3,-8,12,-13,12,-8,3": [["10_49"]], "1,-6,14,-19,14,-6,1": [["9_33"]], "1,-5,10,-11,10,-5,1": [["9_22"]], "1,-5,10,-13,10,-5,1": [["8_18"], ["9_24"], ["3_1", "3_1", "4_1"]], "2,-3,2": [["5_2"]], "1,-3,5,-3,1": [["6_3"]], "1,-5,13,-17,13,-5,1": [["9_31"]], "1,-5,12,-19,21,-19,12,-5,1": [["10_116"]], "1,-6,11,-13,11,-6,1": [["10_157"]], "2,-13,23,-13,2": [["10_13"]], "3,-5,3": [["7_2"]], "1,-5,11,-15,11,-5,1": [["9_27"]], "2,-8,16,-19,16,-8,2": [["10_27"]], "2,-8,17,-23,17,-8,2": [["10_90"]], "1,-3,6,-9,11,-9,6,-3,1": [["10_48"]], "2,-6,9,-9,9,-6,2": [["10_15"]], "1,-4,10,-17,21,-17,10,-4,1": [["10_109"]], "1,-3,2,-1,2,-3,1": [["9_43"]], "4,-15,21,-15,4": [["10_38"]], "2,-7,12,-15,12,-7,2": [["10_76"]], "6,-18,25,-18,6": [["10_53"]], "2,-5,7,-5,2": [["3_1", "5_2"]], "1,-7,19,-27,19,-7,1": [["10_42"], ["10_75"]], "2,-7,9,-9,9,-7,2": [["10_21"]], "4,-17,25,-17,4": [["10_30"]], "2,-4,5,-5,5,-4,2": [["9_6"]], "4,-16,25,-16,4": [["10_33"]], "3,-9,13,-9,3": [["10_34"], ["10_135"]], "2,-8,17,-21,17,-8,2": [["10_40"], ["10_103"]], "2,-5,5,-5,5,-5,2": [["10_8"]], "1,-7,20,-29,20,-7,1": [["10_60"]], "2,-12,21,-12,2": [["10_35"]], "1,-4,10,-15,10,-4,1": [["10_158"]], "1,-3,3,-3,3,-3,3,-3,1": [["10_2"]], "2,-9,13,-9,2": [["9_12"], ["4_1", "5_2"]], "1,-7,16,-21,16,-7,1": [["10_78"]], "4,-14,21,-14,4": [["10_31"], ["10_68"]], "1,-3,7,-12,15,-12,7,-3,1": [["10_79"]], "2,-8,18,-23,18,-8,2": [["10_57"]], "3,-11,15,-11,3": [["10_7"]], "4,-9,11,-9,4": [["9_13"]], "2,-7,14,-17,14,-7,2": [["10_65"], ["10_77"]], "4,-13,19,-13,4": [["10_28"], ["10_37"]], "2,-11,17,-11,2": [["9_21"]], "1,-4,9,-15,17,-15,9,-4,1": [["10_106"]], "3,-16,27,-16,3": [["10_58"]], "3,-8,11,-8,3": [["8_15"], ["3_1", "7_2"]], "2,-8,14,-15,14,-8,2": [["10_108"]], "1,-2,3,-3,3,-2,1": [["3_1", "5_1"]], "1,-3,5,-7,9,-7,5,-3,1": [["10_17"]], "1,-5,12,-15,12,-5,1": [["9_28"], ["9_29"], ["10_163"]], "1,-3,7,-9,7,-3,1": [["10_148"]], "1,-5,7,-5,1": [["7_6"], ["10_133"]], "1,-3,1": [["4_1"]], "1,-3,4,-5,5,-5,4,-3,1": [["10_46"]], "1,-1,-1,4,-5,4,-1,-1,1": [["10_152"]], "6,-13,6": [["10_3"]], "1,-4,5,-4,1": [["8_21"], ["10_136"], ["3_1", "4_1"]], "3,-12,17,-12,3": [["9_25"]], "1,0,-4,7,-4,0,1": [["10_154"]], "1,-8,20,-25,20,-8,1": [["10_110"]], "1,-7,13,-7,1": [["8_12"]], "2,-11,24,-31,24,-11,2": [["10_122"]], "1,-7,21,-31,21,-7,1": [["10_45"]], "3,-7,7,-7,3": [["10_4"]], "1,-4,9,-12,13,-12,9,-4,1": [["10_100"]], "1,-2,1,-2,1": [["9_42"]], "1,-7,17,-23,17,-7,1": [["10_43"]], "1,-8,20,-27,20,-8,1": [["10_81"]]}

fancy_names = {
  '0_1': 'unknot',
  '3_1': 'trefoil knot',
  '4_1': 'figure 8 knot',
  '5_1': 'cinquefoil',
  '5_2': 'three-twist',
  '6_1': 'stevedore knot',
  '7_1': 'septafoil',
  '7_4': 'endless knot'}

pixel = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

compositeCell = (composite) ->
  size = 240/composite.length
  html = "<td><table>"
  for prime in composite
    html += "<tr><td align='center'>
               <img src='diagrams/#{prime}.gif' style='width:#{size}; height:#{size}'/>
             </td></tr>"
  html += "<tr><td align='center'>"
  for prime, i in composite
    html += "<a href='http://katlas.math.toronto.edu/wiki/#{prime}'>#{prime}</a>"
    if i < composite.length-1
      html += " # "
  html += "</td></tr></table></td>"
  return html

compositeCrossingNum = (composite) ->
  crossingNums = (parseInt(prime.split("_")[0]) for prime in composite) 
  return crossingNums.reduce (x,y) -> x+y

identify = ->
  poly_row = d3.select("#poly_row")
  poly_row.selectAll("*").remove()
  id_row = d3.select("#id_row")
  id_row.selectAll("*").remove()

  poly = if points.length then alexanderPoly() else false

  if poly
    poly_text = String(poly)
    poly_row.html("<td style='padding-bottom:20px'>Alexander polynomial: #{poly_text}</td>")
    id = knots[poly_text]
    if id
      id_filtered = (p for p in id when compositeCrossingNum(p) <= isects.length)
      html = ""
      for poss, i in id_filtered
        html += compositeCell(poss)
        if i < id_filtered.length-1
          html += "<td style='padding:20px'>or</td>"
      if isects.length > 10
        html += "<td style='padding:20px'>or some knot with crossing number > 10</td>"
      id_row.html(html)
    else
      id_row.append("td").html("Unknown knot with crossing number > 10")

redraw = ->
  skips = {}
  for isect in isects
    switch isect.choice
      when 1
        skips[isect.i] = isect
      when 2
        skips[isect.j] = isect

  crossingR = 2

  strands = []
  curStrand = []
  lastIsect = false
  for pt, i in points
    if i of skips
      curStrand.push(pt)
      curStrand = (x for x in curStrand when distance(x, skips[i].pt) > crossingR)
      strands.push(curStrand)
      curStrand = []
      lastIsect = skips[i]
    else
      if not lastIsect or distance(pt, lastIsect.pt) > crossingR
        curStrand.push(pt)
  strands.push(curStrand)

  strands = svg.selectAll("path.strand").data(strands, String)
  strands.enter().append("path").classed("strand", true)
         .style("stroke", "black").style("stroke-width", 3)
         .style("fill", "none")
         .attr("d", (d) -> lineGen(d))
  strands.exit().remove()

  if false
    dots = svg.selectAll("circle.dot").data(points, String)
    dots.enter().append("circle").classed("dot", true)
        .attr("cx", (d) -> d[0]).attr("cy", (d) -> d[1])
        .attr("r", 5).style("stroke", "black").style("fill", "gray")
        .on("click", (d, i) -> console.log [d,i])
    dots.exit().remove()

  isec = svg.selectAll("circle.isect").data(isects, String)
  isec.enter().append("circle").classed("isect", true)
  isec.attr("cx", (d) -> d.pt[0]).attr("cy", (d) -> d.pt[1])
      .attr("r", 5).style("stroke", "black").style("fill", "black")
      .style("display", (d) -> if d.choice == 0 then "inline" else "none")
  isec.exit().remove()

  cover = svg.selectAll("circle.cover").data(isects, String)
  cover.enter().append("circle").classed("cover", true)
      .on("mouseover", ->
        d3.select(@).transition().style("fill-opacity", 0.2))
      .on("mouseout", ->
        d3.select(@).transition().style("fill-opacity", 0))
      .on("click", (d) ->
        d.choice = (d.choice % 2) + 1  # 0->1->2->1
        redraw()
        identify())
  cover.attr("cx", (d) -> d.pt[0]).attr("cy", (d) -> d.pt[1])
      .attr("r", 25).style("stroke", "black").style("stroke-opacity", 0)
      .style("fill", "black").style("fill-opacity",0)
  cover.exit().remove()

  d3.select("#trash").style("display", ->
    if points.length then "inline" else "none")

gap = 12

addPointToPoints = (pt) ->
  if points.length == 0
    points.push(pt)
  else
    last = points[points.length-1]
    dist = distance(pt, last)
    divs = Math.ceil(dist/gap)
    for i in [1...divs+1]
      points.push([(last[0]*(divs-i)+pt[0]*i)/divs,
                   (last[1]*(divs-i)+pt[1]*i)/divs])

svg.on("mousedown", ->
     if points.length == 0
       dragging = true)
   .on("mouseup", ->
     if dragging
       addPointToPoints(points[0])
       isects = allIntersects(points)
       redraw()
       identify()
       dragging = false)
   .on("mousemove", ->
     if dragging
       pt = d3.mouse(@)
       if points.length == 0 or distance(pt, points[points.length-1]) > gap/2
         pt = [pt[0]+Math.random()-0.5,pt[1]+Math.random()-0.5]
         addPointToPoints(pt)
         isects = allIntersects(points)
         redraw()
    )

d3.select("#trash").on("click", ->
  points = []
  isects = []
  redraw()
  identify()
)

redraw()
