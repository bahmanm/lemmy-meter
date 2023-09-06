# lemmy-clerk

**Aspiring to be** a web app which you can use to monitor a set of Lemmy instances for downtime,
performance.

**Aiming to** provide a set of visual representations of the servers performance over a period of
time w/, hopefully, queryable graphs.

## Current Status

```text
$ query

TIMESTAMP (UTC)          INSTANCE                                 ENDPOINT       STAT    DURATION
----------------------------------------------------------------------------------------------------
2023-09-06-23-28-45      lemmy.ml                                 /community     200     0.475052
2023-09-06-23-28-45      lemmy.ml                                 /post          200     0.555893
2023-09-06-23-28-45      lemmy.ml                                 /comment       200     0.620596
2023-09-06-23-28-45      ds9.lemmy.ml                             /community     502     0.682529
2023-09-06-23-28-45      ds9.lemmy.ml                             /comment       502     0.704248
2023-09-06-23-28-45      ds9.lemmy.ml                             /post          502     0.691088
2023-09-06-23-28-45      voyager.lemmy.ml                         /community     200     0.711423
2023-09-06-23-28-45      enterprise.lemmy.ml                      /community     200     0.751273
2023-09-06-23-28-45      enterprise.lemmy.ml                      /post          200     0.897077
2023-09-06-23-28-46      lemmy.world                              /post          200     0.398271
2023-09-06-23-28-46      lemmy.world                              /community     200     0.258447
2023-09-06-23-28-45      voyager.lemmy.ml                         /comment       200     0.939126
2023-09-06-23-28-45      enterprise.lemmy.ml                      /comment       200     0.987500
2023-09-06-23-28-45      voyager.lemmy.ml                         /post          200     1.007876
2023-09-06-23-28-46      lemmy.world                              /comment       200     0.426924
2023-09-06-23-28-45      lemmy.ml                                 /              200     1.020186
2023-09-06-23-28-46      lemmy.world                              /              200     0.645537
2023-09-06-23-28-45      voyager.lemmy.ml                         /              200     1.445046
2023-09-06-23-28-45      enterprise.lemmy.ml                      /              200     1.667865
2023-09-06-23-28-45      ds9.lemmy.ml                             /              500     5.736820
```

## How To Run

The only dependency is [bmakelib](https://github.com/bahmanm/bmakelib).

