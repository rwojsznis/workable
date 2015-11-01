## 2.0.0

Date: unreleased

**Breaking change - switched to v3 API**

https://workable.readme.io/docs/whats-new-in-v3

- Collections returned by workable API are now paginated - that enforced introducing
new `Workable::Collection` class that holds `data` (jobs/candidates) and reference
to next page of results.

- `jobs` method does not set default `stage` argument (please specify it explicitly!)

## 1.0.0

Date: 2015-05-16

Full coverage of available Workable API.
