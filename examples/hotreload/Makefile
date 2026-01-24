proj = hotreload

debug:
	gleam build
	gleam run -m paper/dev

build:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --minify --target browser --outdir public

zip:
	zip -9 public.zip public/* -x *.wav

run:
	bun run ./serve.js
