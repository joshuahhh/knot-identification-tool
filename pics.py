import urllib
import re
import json

index_url = "http://katlas.math.toronto.edu/wiki/The_Rolfsen_Knot_Table"
index_data = urllib.urlopen(index_url).read()

knots = re.findall("File:[0-9]*_[0-9]*.gif", index_data)

def chunks(l, n):
    return [l[i:i+n] for i in range(0, len(l), n)]

urls = []
for chunk in chunks(knots, 50):
    image_lookup_url = "http://katlas.math.toronto.edu/w/api.php?format=json&action=query&prop=imageinfo&iiprop=url&titles=%s" % '|'.join(chunk)
    image_lookup_data = json.loads(urllib.urlopen(image_lookup_url).read())
    new_urls = [v['imageinfo'][0]['url']
                for v in image_lookup_data['query']['pages'].values()]
    urls += new_urls

for url in urls:
    urllib.urlretrieve(url, "diagrams/" + url.split("/")[-1])
    print url
