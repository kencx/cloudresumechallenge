
var counterContainer = document.querySelector(".counter");

function updateVisitCount(api, data) {

	fetch(api, {
		method: 'POST',
		mode: 'cors',
		body: JSON.stringify(data),
		headers: {"Content-Type": "application/json"}
	})
	.then(res => res.json())
	.then(res => {
		counterContainer.innerHTML = JSON.parse(res);
	})
}

const payload = { table: "siteVisits", url: "resume.cheo.dev" }
var url = JSON.parse(api_url).url;
updateVisitCount(url, payload)

