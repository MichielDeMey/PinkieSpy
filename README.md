PinkieSpy
=========

A social reading experiment built with Node.js and Socket.io.

The Server
==========

The server will run on port 8080 (default) and will run the socket.io server.

The Client
==========

This is just an example implementation. It won't work out of the box because it needs certain DOM elements to be available.
But at least you have an example of how to implement it or how it all works.

Compiling
=========

You will need a coffeescript compiler to compile the .coffee files to JavaScript files.
If you have Node.js installed, simply install CoffeeScript.

> sudo npm install -g coffee-script

And then compile the files using

> coffee --compile file.coffee

Running
=======

Run the server using Node.js

> node server.js