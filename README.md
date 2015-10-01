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

#### Static domain & cookie safety

You are advised to create a static domain to serve all the HTML/JS sent by the remote host when using the [preview](https://github.com/hrefhref/news/blob/master/web/templates/cache/iframe_preview.html.eex) feature. This is because cookie leaking is a real world issue. Maybe you should even get another domain just for static content…

Here is an example with nginx and varnish:

```
# nginx.conf
server {
  # This variable is used by Nginx to set the static content host.
  set $static_host SET YOUR HOST FOR STATIC CONTENT HERE;
  # This one will be used to locate the SSL certificates, the log files and the Phoenix host.
  set $host PUT THE DOMAIN NAME HERE;
  # Phoenix endpoint
  set $port 4000;

  server_name $host;

  # PLAINTEXT:
  listen 80;
  listen [::]:80;

  # OR FOR SSL:
  #listen 443;
  #listen [::]:443;
  #ssl_certificate /usr/local/etc/nginx/ssl/$host.crt;
  #ssl_certificate_key /usr/local/etc/nginx/ssl/$host.key;

  error_log /var/log/nginx/$host/error.log;
  access_log /var/log/nginx/$host/access.log main;

  root /usr/home/www.webapps/news/news/priv/static/;
  try_files $uri @app;
  proxy_set_header Host $http_host;
  proxy_set_header "X-Forwarded-For" $proxy_add_x_forwarded_for;

  # Cache/Insecure content
  # Unsafe: Route cache directly, no protection
  #  location ~* /s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).* { proxy_pass http://127.0.0.1:82; }
  # Safe: Redirect all requests to static domain
  location ~* /s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).* {
    rewrite ^ $scheme://$static_host:$port$request_uri permanent;
  }

  # The App!
  location @app { proxy_pass http://$host:$port; }
}
```

#### Varnish 3
```
# varnish  - only partial because varnish configs are huuuuge
vcl 3.0;

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

#### Varnish 4

```
vcl 4.0;

backend psychodrame {
  .host = "127.0.0.1";
  .port = "4000";
}

sub vcl_recv {
    if (req.http.host == "static.YOURHOST") {
      set req.backend_hint = psychodrame;
      return (pass);
    }
    if (req.restarts == 0) {
      if (req.http.x-forwarded-for) {
          set req.http.X-Forwarded-For =
              req.http.X-Forwarded-For + ", " + client.ip;
      } else {
          set req.http.X-Forwarded-For = client.ip;
      }
    }
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }
    if (req.http.Authorization || req.http.Cookie) {
        /* Not cacheable by default */
        return (pass);
    }
    return (hash);
}

sub vcl_pipe {
    return (pipe);
}

sub vcl_pass {
    return (fetch);
}
sub vcl_miss {
    return (fetch);
}
sub vcl_backend_response {
    if (beresp.ttl <= 0s ||
        beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
              /*
               * Mark as "Hit-For-Pass" for the next 2 minutes
               */
              set beresp.uncacheable = true;
              set beresp.ttl = 120 s;
    }
    return (deliver);
}

sub vcl_deliver {
    return (deliver);
}

sub vcl_init {
      return (ok);
}

sub vcl_fini {
      return (ok);
}
```

```
# nginx - multiple static domains on subdirectories
location ~* /_MAIN_DOMAIN_/((css|js|fonts).*) {
  rewrite /_MAIN_DOMAIN_/(.*) /$1 break;
  root /usr/home/www.webapps/news/news/priv/static/;
  gzip_proxied any;
  gzip_types *;
  add_header "Access-Control-Allow-Origin" "https://_MAIN_DOMAIN_";
}
location ~* /_MAIN_DOMAIN_/(s/[A-Za-z0-9]+/.*/(cached|thumb|preview_html).*) {
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
