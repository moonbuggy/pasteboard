# Pasteboard
Pasteboard is my redesigned and renamed update to PasteShack, a web app for easy image uploading. The live version is available at [http://pasteboard.co](http://pasteboard.co), and a development version that's running the code from the dev branch is up at [http://dev.pasteboard.co](http://dev.pasteboard.co).

Chrome extension repo: [https://github.com/JoelBesada/pasteboard-extension](https://github.com/JoelBesada/pasteboard-extension)

MIT Licensed (http://www.opensource.org/licenses/mit-license.php)
Copyright 2012, Joel Besada

## Why this is open source
While future plans for Pasteboard might prevent me from keeping it open source, I've decided to share
the code for now for people to learn from. I'm also hoping that there are developers out there
who would like to contribute to the project by helping out with fixing bugs and adding / discussing new features.

I've provided instructions on how to set up your own copy of the app, but this is mainly to allow people
to fiddle around with the code and test it locally. Please don't publically host a copy of the app in an effort
to drive traffic to your site instead of mine for the exact same functionality. In other words, don't be a jerk.

## Running Locally
Here are the instructions for running the app for local testing:

__Step 1:__ Install [Node](http://nodejs.org/) and [Node Package Manager](https://npmjs.org/).  
__Step 2:__ Run the following commands in the terminal  
```
git clone https://github.com/JoelBesada/pasteboard.git
cd pasteboard
git checkout dev
npm install
sudo apt-get install imagemagick
./run_local
```
__Step 3 (Optional):__ Edit the example files in the _/auth_ folder with your credentials and rename them according to
the instructions inside the files. You can still run the app without doing this, but certain functions will be missing.

## Running Docker Container

#### ENV Var

This option are optional, this is default value.

##### URL
```
ORIGIN=pasteboard.co
```

##### Time sewage

Time, in days, to keep images. Set to `false` for unlimited.

```
MAX=7
```

#### Exposition

You can expose the port 4000 on all interface like that :

```
docker run --name pastebaord \
-e ORIGIN=mydomain.tld \
-p 4000:4000 \
anthodingo/docker-pasteboard
```

Or you can bind the port 4000 only on loopback (127.0.0.1) like : (more secure)
```
docker run -d --name pastebaord \
 -e ORIGIN=mydomain.tld \
 -p 127.0.0.1:4000:4000 \
 anthodingo/docker-pasteboard
```


#### Folder

You can store data and config externaly of container :
```
docker run -d --name pasteboard \
-p 4000:4000 \
-v /srv/pasteboard/images:/pasteboard/public/storage \
anthodingo/docker-pasteboard
```


#### Nginx exemple

This exemple work in production :

```
upstream pasteboard {
   server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    location / {
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-NginX-Proxy true;

        proxy_pass http://pasteboard/;
        proxy_redirect off;
        proxy_buffering off;
    }
}
```

You can change max image size in : client_max_body_size

#### Running behind a load balancer

If you are running Pasteboard behind a loadbalancer, you should add the following environment variables:

```bash
TRUST_PROXY: loopback, linklocal, 123.123.123.123
```

See https://expressjs.com/en/guide/behind-proxies.html for more information about proxies.

#### Pasteboard auth

All auth exemple are present on source repo : https://github.com/JoelBesada/pasteboard/tree/master/auth

Exemple for hashing.js :
```javascript
exports.keyHash = function(key) {
	var hashedKey;
	var crypto = require('crypto');
	var shasum = crypto.createHash('sha1');
	shasum.update(key);
	hashedKey = shasum.digest('hex');
	return hashedKey;
};
```

##### How to install auth

Write the file on your server and push to container:
```
cat << EOF > /tmp/hashing.js
exports.keyHash = function(key) {
	var hashedKey;
	var crypto = require('crypto');
	var shasum = crypto.createHash('sha1');
	shasum.update(key);
	hashedKey = shasum.digest('hex');
	return hashedKey;
};
EOF

docker cp /tmp/hashing.js pasteboard:/pasteboard/auth/hashing.js
rm /tmp/hashing.js
```


#### Why my repo and not official ?

I included all pull request from official repo.

[Official source repo Pasteboard](https://github.com/JoelBesada/pasteboard)
[My repo Pasteboard](https://github.com/Janus-SGN/pasteboard.git)
