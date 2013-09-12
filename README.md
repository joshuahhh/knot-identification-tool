knot-identification-tool
========================

Hey! Got any [knots](http://en.wikipedia.org/wiki/Knot_%28mathematics%29) you need to identify? I made [this thing](http://web.mit.edu/joshuah/www/projects/kit) for you.

Draw the shadow of your knot by dragging inside the dashed box. Then, click intersections to flip crossings and recreate the 3D structure of your knot. Our advanced technology will compute the intrinsic topological identity of your knot and show it to you on the right-hand side of the screen. It will also let you know if it was only able to narrow down the identity to a (small) set of possibilities, or if your knot has so many crossings that it can't be sure at all what the knot is.

The trash can erases the current knot.

That's all for now!

## Technical Details

The app is at `index.html `, which loads JavaScript compiled from `kit.coffee`.

The [Alexander polynomial](http://en.wikipedia.org/wiki/Alexander_polynomial) is used to identify knots, which works fairly well, although there are many collisions and it would be great to add more invariants. Polynomials for *prime* knots up to 10 crossings were obtained from [Alexander Stoimenow's table](http://stoimenov.net/stoimeno/homepage/ptab/a10.html), then processed by `alex.py` to give polynomials for *all* knots up to 10 crossings. The output of this script is included in `kit.coffee` as the object `knots`.

To actually compute the polynomial of the drawn knot, I use an intersection/strand incidence matrix determinant. This is way more straightforward for us than the more typical intersection/region method. (I can't track down the origin of the intersection/strand method right now -- will update when I get that.)

Polynomials are represented as base-1000 integers, a trick made possible by Peter Olson's [BigInteger library](https://github.com/peterolson/BigInteger.js).

## Future Directions

As mentioned above, it would be great to get enough invariants together to uniquely identify all knots up to 10 (or more?) crossings.

For what it's worth, the original plan involved far more ambitious goals -- I wanted to create a system allowing the user to freely manipulate a knot diagram, pulling around strands, rotating models in 3D space, and exploring the structure of Reidemeister moves. But my commitment to this goal has waned somewhat since coming across [this wonderful work by Zhang et al.](http://www.computer.org/csdl/trans/tg/2012/12/ttg2012122051-abs.html).


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/joshuahhh/knot-identification-tool/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

