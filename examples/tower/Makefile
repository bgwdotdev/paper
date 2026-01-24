proj = tower

debug:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --target browser --outdir public
	bun run ./serve.js

full:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --target browser --outdir public

build:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --minify --target browser --outdir public

zip:
	zip -9 public.zip public/* -x *.wav

run:
	bun run ./serve.js
