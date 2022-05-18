install:
	cd site/
	docker run -v "$PWD":/usr/src/app -w /usr/src/app node npm install

build:
	cd site/
	docker run -v "$PWD":/usr/src/app -w /usr/src/app node npm run build

serve: site/docs/index.html site/docs/build.css
	cd site/docs && python -m http.server

tplan:
	terraform plan

tapply:
	terraform apply

tdestroy:
	terraform destroy
