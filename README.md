# HtmzPhx

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

```sh
docker run -p 4000:4000 \
    -e SECRET_KEY_BASE=d72FrFMTI5mkBap9laia/84J17SbQwe43O2UCPRWlZZ7UrztllT4C2705V8K8696 \
    -e JWT_SECRET=d72FrFMTI5mkBap9laia/84J17SbQwe43O2UCPRWlZZ7UrztllT4C2705V8K8696 \
    -e PHX_SERVER=true \
    htmz-phx
```
