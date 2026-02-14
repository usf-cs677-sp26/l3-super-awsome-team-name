# file-transfer

It might work.

## Results

```
#     File                           Size         Operation  Time (s)     Status
----------------------------------------------------------------------
1     nonexistent                    -            GET        -            PASS
2     duplicate                      -            PUT        -            PASS
3     small-text (1 KB)              1.00 KB      PUT        .016187120   PASS
4     small-text (1 KB)              1.00 KB      GET        .015834763   PASS
5     small-binary (10 KB)           10.00 KB     PUT        .016454447   PASS
6     small-binary (10 KB)           10.00 KB     GET        .016376609   PASS
7     medium-text (1 MB)             1.00 MB      PUT        .024653640   PASS
8     medium-text (1 MB)             1.00 MB      GET        .024205888   PASS
9     medium-binary (1 MB)           1.00 MB      PUT        .025892470   PASS
10    medium-binary (1 MB)           1.00 MB      GET        .024007741   PASS
11    large-log.txt                  1.12 GB      PUT        9.253775944  PASS
12    large-log.txt                  1.12 GB      GET        9.204514171  PASS
13    venti-frappuchino-log.txt      6.75 GB      PUT        55.756395139 PASS
14    venti-frappuchino-log.txt      6.75 GB      GET        55.529368078 PASS
```
