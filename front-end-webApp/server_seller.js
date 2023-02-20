const express = require("express");
const path = require("path");
const app = express();

app.use(express.static(__dirname));

app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname + "/sellerDeployNewContract.html"));
})

const server = app.listen(8090);
const portNumber = server.address().port;
console.log(`port is open on ${portNumber}`);