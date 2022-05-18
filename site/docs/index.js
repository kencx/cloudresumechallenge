
var counterContainer = document.querySelector(".counter");

function updateVisitCount(url, data) {

	fetch(url, {
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
updateVisitCount("https://2a7xi2wqdk.execute-api.ap-southeast-1.amazonaws.com/", payload)

