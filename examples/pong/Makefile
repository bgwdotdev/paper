debug:
	gleam build
	bun build ./build/dev/javascript/pong/pong.mjs --target browser --outdir public
	bun run ./serve.js

build:
	gleam build
	bun build ./build/dev/javascript/pong/pong.mjs --minify --target browser --outdir public

zip:
	zip -9 public.zip public/* -x *.wav

run:
	bun run ./serve.js
