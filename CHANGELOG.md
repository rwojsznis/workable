## 2.1.0

Date: 2017-06-19

- `application_form` endpoint handler [#11](https://github.com/emq/workable/pull/11) (@klaszcze)

## 2.0.0

Date: 2015-11-14

**Breaking change - Ruby >= 2.1 required**

## 2.0.0rc1

Date: 2015-11-02

**Breaking change - switched to v3 API**

https://workable.readme.io/docs/whats-new-in-v3

- Collections returned by workable API are now paginated - that enforced introducing
new `Workable::Collection` class that holds `data` (jobs/candidates) and reference
to next page of results.

- `jobs` method does not set default `stage` argument - please specify it explicitly!
Also - now it accepts a hash as more parameters are available in v3 API

## 1.0.0

Date: 2015-05-16

Full coverage of available Workable API.
