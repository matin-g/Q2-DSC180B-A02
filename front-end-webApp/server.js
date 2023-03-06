const express = require("express");
const path = require("path");
const app = express();

app.use(express.static(__dirname));

app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname + "/homePage.html"));
})

const server = app.listen(8087);
const portNumber = server.address().port;
console.log(`port is open on ${portNumber}`);