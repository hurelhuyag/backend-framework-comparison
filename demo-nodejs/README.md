```sh
npm install --production
npx prisma generate
npm run build
npm run start
```

```sh

ab -n 10000 -c 1 http://localhost:3000/api/contents?pageSize=20
```