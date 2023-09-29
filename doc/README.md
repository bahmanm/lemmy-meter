# 1. lemmy-meter

A solution for Lemmy end-users, like me, to check the health of their favourite instance in 3
levels of details.

This is the source repository which is used to build and deploy [lemmy-meter.info](https://lemmy-meter.info).


# 2. Health Reports

lemmy-meter provides 3 levels of reports.

## 2.1 Overall Health

This is what you are, almost always, interested in.  

![](https://github.com/bahmanm/lemmy-meter/blob/main/doc/images/lemmy-meter-overall-health.png?raw=true)

| Colour        | Meaning                                      | Interpretation                                                                      |
| ------------- | -------------------------------------------- | ----------------------------------------------------------------------------------- |
| 🟢 Green 	    | **none** of the health checks are failing 🙂 | Your instance is healthy and doing well. 	                                         |
| 🟠 Orange	    | **some** of the health checks are failing 🫤 | Your instance may be partially down; _for example mobile APIs may not be working._  |
| 🔴 Red 	    | **all** health checks are failing 🙁	       | Your instance may be completely down; _for example during a planned maintenance._ 	 |


## 2.2 Endpoint Health

A breakdown of [overall health](#21-overall-health) by few, subjectively, important endpoints:

* Landing page: the web page users when they visit the instance.
* Select API endpoints which are used by mobile (and desktop) applications:
  - getPosts
  - getComments
  - getCmmunities

![](https://github.com/bahmanm/lemmy-meter/blob/main/doc/images/lemmy-meter-endpoint-health.png?raw=true)

## 2.3 Endpoint Response Time - Rate

*  A visual representation of how much the average response time has changed over time.
*  A flat line indicates a consistent response time, regardless of being slow or fast.
*  Spikes or changes in elevation mean changes in the response time.

_NB: It does not represent the actual response times but only the fluctuations._

![](https://github.com/bahmanm/lemmy-meter/blob/main/doc/images/lemmy-meter-response-time-rates.png?raw=true)

## 2.4 Endpoint Response Time - Raw

*  The raw response time per endpoint as it happend.
*  Lower is better. Anything below 500ms is quite decent.
*  Don't read too much into the actual values.  
   The server is currently located in Germany which means non-EU instances will always be slightly slower than you'd expect.

![](https://github.com/bahmanm/lemmy-meter/blob/main/doc/images/lemmy-meter-response-time-raw.png?raw=true)

# 3. How To Run

*The only dependency is [bmakelib](https://github.com/bahmanm/bmakelib).*

## 3.1 Locally

Simply run `make up` and `make down` to start the cluster and tear it down.

You can access Grafana at http://localhost:3000 *(admin/admin)*

## 3.2 Remote

Run `make deploy` to, well, deploy the lemmy-meter to the remote server.
