Skuler
======

Simple, web-based sketching app using swappable Kuler themes/palettes/swatches. 

This was made to test an idea about restricting a drawing to a limited set of colors.


Usage
-----

0. Open http://senocular.github.io/skuler/skuler.html
0. Select a color
0. Draw something
0. Select another color
0. Draw some more
0. Visit [Adobe Kuler](https://kuler.adobe.com/explore/)
0. Download a new Kuler theme (.ASE)
0. Drag the .ASE file into the Skuler window
0. ...
0. Profit!!!

Have only tested on Chrome. Unsure of browser support.


Keyboard Shortcuts
------------------

CTRL + M: New document
CTRL + Z: Undo
CTRL + Y: Redo
Page Up: Select previous swatch
Page Down: Select next swatch
UP Arrow: Decrease lightness
DOWN Arrow: Increase lightness
LEFT Arrow: Increase saturation
RIGHT Arrow: Decrease saturation


TODO
----

- :grey_question: Load .ASE button vs just drag and drop
- :grey_question: Change brush size
- :grey_question: Required browser features detection


Known Issues
------------

- With keyboard shortcuts, lightness depends on saturation. To get full lightness (white/black) you need to fully desaturate first.  In other words, the arrow keys are a direct coorelation of the location of the selection within the triangle color picker.
- Using keyboard shortcuts in the middle of a stroke may prevent those changes to be saved with the document
- Color triangle doesn't register when interaction moves off the visible area of the triangle.  Probably won't fix
