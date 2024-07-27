debug:
	gleam build
	bun build ./build/dev/javascript/pong/pong.mjs --target browser --outdir public
	bun run ./serve.js

build:
	gleam build
	bun build ./build/dev/javascript/pong/pong.mjs --minify --target browser --outdir public

zip:
	zip public.zip public/*

run:
	bun run ./serve.js
