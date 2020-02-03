#!/bin/bash

id
mkdir -v /app

cat > /app/package.json <<EOF
{
  "name": "node-token-jwt",
  "main": "server.js",
  "dependencies": {
    "body-parser": "^1.19.0",
    "express": "^4.17.1",
    "morgan": "^1.9.1"
  }
}
EOF

cat > /app/server.js <<EOF
var express     = require('express');
var app         = express();
var bodyParser  = require('body-parser');
var morgan      = require('morgan');

var port = process.env.PORT || 8080; // used to create, sign, and verify tokens

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.use(morgan('dev'));

app.get('/', function(req, res) {
    res.send('Hello! The API is at http://localhost:' + port + '/builds');
});

var buildRoutes = express.Router();

buildRoutes.post('/', function(req, res) {
    builds_from_req = req.body.jobs['Build base AMI'].Builds
    const builds_successful = builds_from_req.filter(build => build["result"] == "SUCCESS");
    builds_successful.sort( compare_build_date );
    build_latest_successful = builds_successful[0]
    latest_build_resp = {
      "build_date": build_latest_successful["build_date"],
      "ami_id": build_latest_successful["output"].split(" ")[2],
      "commit_hash": build_latest_successful["output"].split(" ")[3]}
    res.json(latest_build_resp);
});

app.use('/builds', buildRoutes);

app.listen(port);
console.log('Magic happens at http://localhost:' + port);

function compare_build_date( a, b ) {
  if ( a.build_date < b.build_date ){
    return -1;
  }
  if ( a.build_date > b.build_date ){
    return 1;
  }
  return 0;
}

// END
EOF

#nohup busybox httpd -f -p ${server_port} &

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install node

cd /app
npm install
npm start &
