app = bun

r:
	$(app) run start

t: tailwind

up: 
	cp -rf img ../../docs
	cp -rf videos ../../docs
	cp -rf plugin ../../docs/dist
	cp -rf index.html ../../docs
	cp -rf dist/tailwind.css ../../docs/dist

down: 
	cp -rf ../../docs/videos .
	cp -rf ../../docs/img .
	cp -rf ../../docs/index.html .

tw: tailwind
	
tailwind:
	$(app) run tw