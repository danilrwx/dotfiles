# Desktop themes

x-theme selects dark or light and starts one swaybg instance. Wallpapers fill
the display while preserving aspect ratio. Every theme switch and login in
Labwc picks a random painting from the matching collection, without
repeating the previous painting for that theme when several are available.

Run `wallpapers-fetch` to download the collection in `wallpapers.tsv` into
`${XDG_DATA_HOME:-~/.local/share}/wallpapers/paintings/{light,dark}`. The catalogue
records each painting's author, title, museum page and public-domain image URL.
The collection lives outside the repository and is not downloaded by the base
installer. Add your own JPEG files to either directory to include them.

The last choice for each theme is recorded in
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/wallpaper-{light,dark}`.
Without a collection, the two bundled paintings below remain available.

## Light

J. M. W. Turner, The Dogana and Santa Maria della Salute, Venice (1843).
National Gallery of Art, accession 1961.2.3. Public-domain museum image.

Work: https://www.nga.gov/artworks/46089-dogana-and-santa-maria-della-salute-venice
Image: https://api.nga.gov/iiif/132e789c-27da-4f54-a68d-3e2b691a9448/full/3000,/0/default.jpg

## Dark

James McNeill Whistler, Nocturne: Blue and Gold—Southampton Water (1872).
Art Institute of Chicago, accession 1900.52. Public-domain painting, CC0
reproduction obtained from Wikimedia Commons.

Work: https://www.artic.edu/artworks/56905/nocturne-blue-and-gold-southampton-water
Image: https://commons.wikimedia.org/wiki/File:James_McNeill_Whistler_-_Nocturne,_Blue_and_Gold%E2%80%94Southampton_Water_-_1900.52_-_Art_Institute_of_Chicago.jpg
