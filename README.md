```
docker build . -t openresty-example
```

```
docker run \
  -p 80:80 \
  -p 443:443 \
  -v $(pwd):/app \
  -v $(pwd)/self-signed:/etc/ssl/self-signed \
  openresty-example \
  -p /app \
  -c nginx.conf
```
