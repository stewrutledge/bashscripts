### gencsr.sh
Skapa nyckel/csr på kommandlinjen lätt:

```
./gencsr.sh [-iS] [-d] [-l -c -s -o -u]
-l <Location> [Default: Stockholm]
-c <Two Letter Country Code Country> [Default: SE]
-s <State [Default: Stockholm]
-o <Organization> [Default: Kungliga Biblioteket]
-u <Organizational Unit> (optional)
-d <Domain> (Required)
-i (Generate insecure key)
-n (Do not create a password protected key)
-S (Generate SAN)
-h Show more help
```

### SAN (Subject Alternative Name) Certifikator

Om du vill lägga in flera domän namn på en CSR, så måste du både ge -S för att generera ett SAN csr samt ange domän namn som en komma sepererad lista:

```
./gencsr.sh -S -d "test1.kb.se,test2.kb.se"
```

