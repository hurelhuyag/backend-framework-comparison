```sh
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o myapp main.go
./myapp
ab -n 10000 -c 1 http://localhost:8080/contents?size=20
```