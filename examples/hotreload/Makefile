proj = hotreload

debug:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --target browser --outdir public
	bun run ./serve.js

watch:
	inotifywait -q -m -e close_write -r ./src | while read events; do gleam build; done

build:
	gleam build
	bun build ./build/dev/javascript/$(proj)/$(proj).mjs --minify --target browser --outdir public

zip:
	zip -9 public.zip public/* -x *.wav

run:
	bun run ./serve.js
