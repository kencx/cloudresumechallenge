install:
	cd site/
	docker run -v "$PWD":/usr/src/app -w /usr/src/app node npm install

build:
	cd site/
	docker run -v "$PWD":/usr/src/app -w /usr/src/app node npm run build
