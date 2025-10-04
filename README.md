# HtmzPhx

[![Elixir](https://img.shields.io/badge/Elixir-%234B275F.svg?&logo=elixir&logoColor=white)](#)
[![SQLite](https://img.shields.io/badge/SQLite-%2307405e.svg?logo=sqlite&logoColor=white)](#)
[![HTMX](https://img.shields.io/badge/HTMX-36C?logo=htmx&logoColor=fff)](#)

- SQLite rendering the SVGs
- ETS for shopping cart
- Presence to clean shopping cart on disconnection
  
## Local Grafana k6 stress test

23k req/s with 6.000 Virtual Users sending 10req/s (db lookup, ETS lookup, send response)

```sh
k6 run load-test/phoenix-progressive-test.js
```

```txt
=== PHOENIX LOAD TEST: PLATEAU PERFORMANCE ===
📊 PLATEAU 1 (2K VUs - 30s):
  Requests: 386494
  Req/s: 12883
  Avg Response Time: 3.57ms
  95th Percentile: 16.38ms

📊 PLATEAU 2 (6K VUs - 30s):
  Requests: 706950
  Req/s: 23565
  Avg Response Time: 66.53ms
  95th Percentile: 200.65ms

=== PHOENIX OVERALL RESULTS ===
Peak VUs: 6000
Total Requests: 1538330
Failed Requests: 0.00%
```

## Deploy on VPS

<https://phx.htmz.online>

```sh
git push
```

On VPS, with a non-root user ("nobody"):

```sh
apt install git, docker

git pull
docker build htmz-phx:local .
docker run -d \
    --name htmz-phx \
    --restart unless-stopped \
    -p 2082:2082 \
    -e PORT=2082 \
    -e SECRET_KEY_BASE=d72FrFMTI5mkBap9laia84J17Sb... \
    -e JWT_SECRET=ziggit \
    -e PHX_SERVER=true \
    htmz-phx:local
```

```sh
docker logs htmz-phx
```

Docker uses its own iptables. To use the VPS firewall rules:

```sh
// nano /etc/docker/daemon.json
{
  "iptables": false
}
```

```sh
sudo ufw reload
sudo ufw allow 2082/tcp
sudo docker restart htmz_phx
```
