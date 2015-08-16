# news

A reddit-like app.

## setup

### installation

Dependencies: Elixir 1.x, PostgreSQL 9.4+, Redis, NodeJS, libsass, a web + caching server, ImageMagick, JPEGoptim.

1. Install dependencies: `mix deps.get && npm install`
2. Configure: `cp config/site.exs.sample config/site.exs && $EDITOR config/site.exs`
3. Migrate database: `(MIX_ENV=prod) mix ecto.migrate`
4. (production only) build assets: `./node_modules/.bin/brunch build --production`
5. (production only) build digest: `(MIX_ENV=prod) mix phoenix.digest`
6. Bootstrap default content: `(MIX_ENV=prod) mix news.bootstrap_initial_data`
7. Profit!

Notes for FreeBSD:

* python sucks: `export PYTHON=/usr/local/bin/python2`
* some users think gmake is everything... link /usr/local/bin/make->/usr/local/bin/gmake and `export PATH="/usr/local/bin:$PATH"`

### start

`mix phoenix.server`
`MIX_ENV=prod PORT=4000 mix phoenix.server`

Set yourself as an admin:

```elixir
  News.Flag.add_to_model(News.Repo.get_by(News.User, username: "YOUR_USERNAME"), "admin")
```

### deployement

For performances reasons and shit, the app needs to be hosted behind a reverse proxy, like nginx.

Some features (/cached.jpg) also requires a caching server, like Varnish.

Here is an example with nginx and varnish:

```
# nginx.conf
server {
  server_name deadly.io;

  # PLAINTEXT:
  listen 80;
  listen [::]:80;

  # OR FOR SSL:
  #listen 443;
  #listen [::]:443;
  #ssl_certificate /usr/local/etc/nginx/ssl/deadly.io.crt;
  #ssl_certificate_key /usr/local/etc/nginx/ssl/deadly.io.key;

  error_log /var/log/nginx/deadly/error.log;
  access_log /var/log/nginx/deadly/access.log main;

  root /usr/home/www.webapps/news/news/priv/static/;
  try_files $uri @app;
  proxy_set_header Host $http_host;
  proxy_set_header "X-Forwarded-For" $proxy_add_x_forwarded_for;

  # Cache/Insecure content
  # Unsafe: Route cache directly, no protection
  #  location ~* /s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).* { proxy_pass http://127.0.0.1:82; }
  # Safe: Redirect all requests to static domain
  location ~* /s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).* {
    rewrite ^ $scheme://static.host/$request_uri permanent;
  }

  # The App!
  location @app { proxy_pass http://news.cyclone.r:4000; }
}
```

```
# varnish  - only partial because varnish configs are huuuuge

backend deadly {
  .host = "10.66.69.55";
  .port = "4000";
}
sub vcl_recv {
  if (req.http.host == "deadly.io") {
    set req.backend = deadly;
  }
  # other stuff - just make sure it ends in `return (lookup);`
}
```

```
# nginx - multiple static domains on subdirectories
location ~* /_MAIN_DOMAIN_/(css|js|s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).*) {
  rewrite /_MAIN_DOMAIN_/(.*) /$1 break;
  proxy_set_header Host _MAIN_DOMAIN_;
  proxy_set_header "X-Forwarded-For" $proxy_add_x_forwarded_for;
  gzip_proxied any;
  gzip_types *;
  proxy_pass http://_CACHE_;
}
location /_MAIN_DOMAIN_ {
  rewrite /_MAIN_DOMAIN_/(.*) http://_MAIN_DOMAIN_/$1 permanent;
}
```
