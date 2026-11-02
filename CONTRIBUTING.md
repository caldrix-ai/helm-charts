# Contributing

Bug reports and questions are welcome as [issues](https://github.com/caldrix-ai/helm-charts/issues/new/choose).

This repository is generated from caldrix's private source, and every change made here is overwritten by the next update, so pull requests are not accepted. If you found a mistake in a chart or its docs, open an issue and we will fix it at the source.

A useful bug report has:

- the output of `helm version`;
- the output of `kubectl version`;
- the chart version;
- the output of `helm get values <release>`, with secrets removed;
- the pod's logs (`kubectl logs <pod>`).
