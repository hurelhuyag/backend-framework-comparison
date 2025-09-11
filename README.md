# Performance comparison of popular backend frameworks in mongolia

Result:

![result](result.png)

| | Platform                   |     1   |    10   |   100   |   1000  |  10000  |
|-|----------------------------|---------|---------|---------|---------|---------|
|1| Nginx/Php8.4/Laravel       |  127.59 |  369.12 |  359.94 |  347.62 |  684.03 |
|2| Python3/Django5.2/Gunicorn |  110.88 |  352.01 |  325.06 |  330.88 |  Failed |
|3| Node21.7/NextJS/Prisma     |  374.42 |  623.05 |  643.12 |  Failed |  725.98 |
|4| Go1.25/Gorm/Gorilla        | 1704.49 | 3471.94 | 3304.11 | 3316.69 | 2229.02 |
|5| GraalVM24                  |  952.29 | 4186.83 | 4939.32 | 5401.67 | 3323.23 |
|6| OpenJDK25/Spring/Hibernate |   969.9 | 4334.65 | 5363.57 | 5545.18 | 4610.05 |

Test Command

```shell

ab -n 10000 -c 1 http://127.0.0.1:8001/api/contents
ab -n 10000 -c 10 http://127.0.0.1:8001/api/contents
ab -n 10000 -c 100 http://127.0.0.1:8001/api/contents
ab -n 10000 -c 1000 http://127.0.0.1:8001/api/contents
ab -n 10000 -c 10000 http://127.0.0.1:8001/api/contents
```