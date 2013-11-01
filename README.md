Skuler
======

Simple, web-based sketching app using swappable Kuler themes/palettes/swatches. 

This was made to test an idea about restricting a drawing to a limited set of colors.  
It was built with HTML5 Canvas, SVG, and JavaScript (via CoffeeScript). Tested only with Chrome (v30).


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



Keyboard Shortcuts
------------------

- CTRL + M: New document
- CTRL + Z: Undo
- CTRL + Y: Redo
- Page Up: Select previous swatch
- Page Down: Select next swatch
- UP Arrow: Increase lightness
- DOWN Arrow: Decrease lightness
- LEFT Arrow: Increase saturation
- RIGHT Arrow: Decrease saturation
- ,: Decrease brush size
- .: Increase brush size


TODO
----

- :grey_question: Brush size UI
- :grey_question: Load .ASE button vs just drag and drop
- :grey_question: Required browser features detection


Known Issues
------------

- With keyboard shortcuts, lightness depends on saturation. To get full lightness (white/black) you need to fully desaturate first.  In other words, the arrow keys are a direct coorelation of the location of the selection within the triangle color picker.
- Color triangle doesn't register when interaction moves off the visible area of the triangle.  Probably won't fix.
- Undo will undo strokes as well as saturation and lightness settings, but not selected swatch or pen size.
