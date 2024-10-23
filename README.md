# JAK TO ODPALIĆ?

Na windowsie nawet nie próbuj się z tym bawić, żeby bez dockera to odpalać. Użyj dockera.

```
docker build .
```

Następnie odpal

```
docker run <nazwa obrazu>
```

## Skąd wziąć nazwę obrazu?

```
docker image ls
```

Powinieneś zobaczyć coś takiego

```
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
<none>                     <none>              123456789        39 seconds ago      422MB
```

Masz tutaj IMAGE ID
