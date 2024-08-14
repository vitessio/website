# Kubernetes Version Support and Recommendations

The Vitess operator supports a range of Kubernetes versions, with varying levels of support and recommendation.

## Support Policy Schedule

The following schedule outlines when a Kubernetes version will start being supported, become the primary recommendation, and eventually stop being supported:

* **Support start**: When a new Kubernetes version is released, we will start supporting it within 2-3 months, pending compatibility testing.
* **Primary recommendation**: We will recommend the latest Kubernetes version that has been supported for at least 6 months, and has been tested extensively with the Vitess operator.
* **Support end**: We will stop supporting a Kubernetes version 12 months after its initial release, or when it reaches end-of-life (EOL) according to the Kubernetes project, whichever comes first.

## Recommended Kubernetes Versions

The Vitess operator recommends using Kubernetes versions 1.15 through 1.17, which have been extensively tested and validated.

## Cloud Provider Support

For explicitly supported cloud providers, such as GKE and EKS, we guarantee to support at least one Kubernetes version that overlaps with the versions they offer.

## Current Recommendation

As of the latest Vitess operator release (2.0.0), we recommend using Kubernetes 1.16, which is the primary version tested against.
